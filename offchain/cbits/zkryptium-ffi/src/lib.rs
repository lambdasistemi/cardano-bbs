#![allow(clippy::missing_safety_doc)]

use std::ffi::CString;
use std::os::raw::c_char;
use std::ptr;

use rand::Rng;
use zkryptium::{
    bbsplus::ciphersuites::Bls12381Sha256,
    bbsplus::keys::{BBSplusPublicKey, BBSplusSecretKey},
    errors::Error,
    keys::pair::KeyPair,
    schemes::{
        algorithms::BBSplus,
        generics::{PoKSignature, Signature},
    },
};

const SECRET_KEY_BYTES: usize = 32;
const PUBLIC_KEY_BYTES: usize = 96;
const SIGNATURE_BYTES: usize = 80;
const IKM_LEN: usize = 32;

thread_local! {
    static LAST_ERROR: std::cell::RefCell<Option<CString>> =
        const { std::cell::RefCell::new(None) };
}

fn set_last_error(message: impl Into<String>) {
    let message = message.into();
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = Some(CString::new(message).unwrap_or_default());
    });
}

fn clear_last_error() {
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = None;
    });
}

fn write_output(src: &[u8], out_ptr: *mut u8, out_len: usize) -> Result<(), Error> {
    if out_ptr.is_null() {
        return Err(Error::DeserializationError("null output buffer".to_owned()));
    }
    if out_len < src.len() {
        return Err(Error::DeserializationError(format!(
            "output buffer too small: need {}, got {}",
            src.len(),
            out_len
        )));
    }

    unsafe {
        ptr::copy_nonoverlapping(src.as_ptr(), out_ptr, src.len());
    }
    Ok(())
}

fn read_input(ptr: *const u8, len: usize, label: &str) -> Result<Vec<u8>, Error> {
    if ptr.is_null() {
        return Err(Error::DeserializationError(format!("null input pointer: {label}")));
    }
    let bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    Ok(bytes.to_vec())
}

fn decode_frames(ptr: *const u8, len: usize) -> Result<Vec<Vec<u8>>, Error> {
    let bytes = read_input(ptr, len, "frames")?;
    if bytes.len() < 4 {
        return Err(Error::DeserializationError("frame buffer too short".to_owned()));
    }

    let mut cursor = 0usize;
    let count = u32::from_be_bytes(bytes[cursor..cursor + 4].try_into().unwrap()) as usize;
    cursor += 4;

    let mut frames = Vec::with_capacity(count);
    for _ in 0..count {
        if cursor + 4 > bytes.len() {
            return Err(Error::DeserializationError(
                "truncated frame length prefix".to_owned(),
            ));
        }
        let frame_len = u32::from_be_bytes(bytes[cursor..cursor + 4].try_into().unwrap()) as usize;
        cursor += 4;
        if cursor + frame_len > bytes.len() {
            return Err(Error::DeserializationError("truncated frame payload".to_owned()));
        }
        frames.push(bytes[cursor..cursor + frame_len].to_vec());
        cursor += frame_len;
    }

    if cursor != bytes.len() {
        return Err(Error::DeserializationError(
            "unexpected trailing bytes in frame buffer".to_owned(),
        ));
    }

    Ok(frames)
}

fn decode_usize_frames(ptr: *const u8, len: usize) -> Result<Vec<usize>, Error> {
    let frames = decode_frames(ptr, len)?;
    frames
        .into_iter()
        .map(|frame| {
            if frame.len() != 4 {
                return Err(Error::DeserializationError(
                    "index frame must be 4 bytes".to_owned(),
                ));
            }
            Ok(u32::from_be_bytes(frame.try_into().unwrap()) as usize)
        })
        .collect()
}

fn optional_input(ptr: *const u8, len: usize) -> Result<Option<Vec<u8>>, Error> {
    if ptr.is_null() {
        return Ok(None);
    }
    Ok(Some(read_input(ptr, len, "optional input")?))
}

type Scheme = BBSplus<Bls12381Sha256>;

#[no_mangle]
pub extern "C" fn bbs_bls12_381_sha_256_keygen(
    sk_out: *mut u8,
    sk_out_len: usize,
    pk_out: *mut u8,
    pk_out_len: usize,
) -> i32 {
    clear_last_error();

    let mut rng = rand::thread_rng();
    let key_material: Vec<u8> = (0..IKM_LEN).map(|_| rng.gen()).collect();

    let result = KeyPair::<Scheme>::generate(&key_material, None, None).and_then(|pair| {
        write_output(&pair.private_key().to_bytes(), sk_out, sk_out_len)?;
        write_output(&pair.public_key().to_bytes(), pk_out, pk_out_len)
    });

    match result {
        Ok(()) => 0,
        Err(err) => {
            set_last_error(err.to_string());
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn bbs_bls12_381_sha_256_sign(
    sk_ptr: *const u8,
    sk_len: usize,
    pk_ptr: *const u8,
    pk_len: usize,
    header_ptr: *const u8,
    header_len: usize,
    messages_ptr: *const u8,
    messages_len: usize,
    sig_out: *mut u8,
    sig_out_len: usize,
) -> i32 {
    clear_last_error();

    let result = (|| -> Result<(), Error> {
        let sk = BBSplusSecretKey::from_bytes(&read_input(sk_ptr, sk_len, "secret key")?)?;
        let pk = BBSplusPublicKey::from_bytes(&read_input(pk_ptr, pk_len, "public key")?)?;
        let header = optional_input(header_ptr, header_len)?;
        let messages = decode_frames(messages_ptr, messages_len)?;

        let signature =
            Signature::<Scheme>::sign(Some(&messages), &sk, &pk, header.as_deref())?;
        write_output(&signature.to_bytes(), sig_out, sig_out_len)
    })();

    match result {
        Ok(()) => 0,
        Err(err) => {
            set_last_error(err.to_string());
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn bbs_bls12_381_sha_256_verify(
    pk_ptr: *const u8,
    pk_len: usize,
    header_ptr: *const u8,
    header_len: usize,
    messages_ptr: *const u8,
    messages_len: usize,
    sig_ptr: *const u8,
    sig_len: usize,
) -> i32 {
    clear_last_error();

    let result = (|| -> Result<(), Error> {
        let pk = BBSplusPublicKey::from_bytes(&read_input(pk_ptr, pk_len, "public key")?)?;
        let header = optional_input(header_ptr, header_len)?;
        let messages = decode_frames(messages_ptr, messages_len)?;
        let sig_bytes = read_input(sig_ptr, sig_len, "signature")?;
        let signature = Signature::<Scheme>::from_bytes(
            &sig_bytes
                .as_slice()
                .try_into()
                .map_err(|_| Error::InvalidSignature)?,
        )?;
        signature.verify(&pk, Some(&messages), header.as_deref())
    })();

    match result {
        Ok(()) => 0,
        Err(err) => {
            set_last_error(err.to_string());
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn bbs_bls12_381_sha_256_proof_gen(
    pk_ptr: *const u8,
    pk_len: usize,
    sig_ptr: *const u8,
    sig_len: usize,
    header_ptr: *const u8,
    header_len: usize,
    presentation_header_ptr: *const u8,
    presentation_header_len: usize,
    messages_ptr: *const u8,
    messages_len: usize,
    disclosed_indexes_ptr: *const u8,
    disclosed_indexes_len: usize,
    proof_out: *mut u8,
    proof_out_len: usize,
    proof_written_out: *mut usize,
) -> i32 {
    clear_last_error();

    let result = (|| -> Result<(), Error> {
        if proof_written_out.is_null() {
            return Err(Error::DeserializationError(
                "null proof length output pointer".to_owned(),
            ));
        }

        let pk = BBSplusPublicKey::from_bytes(&read_input(pk_ptr, pk_len, "public key")?)?;
        let sig_bytes = read_input(sig_ptr, sig_len, "signature")?;
        let header = optional_input(header_ptr, header_len)?;
        let presentation_header =
            optional_input(presentation_header_ptr, presentation_header_len)?;
        let messages = decode_frames(messages_ptr, messages_len)?;
        let disclosed_indexes = decode_usize_frames(disclosed_indexes_ptr, disclosed_indexes_len)?;

        let proof = PoKSignature::<Scheme>::proof_gen(
            &pk,
            &sig_bytes,
            header.as_deref(),
            presentation_header.as_deref(),
            Some(&messages),
            Some(&disclosed_indexes),
        )?;
        let proof_bytes = proof.to_bytes();
        unsafe {
            *proof_written_out = proof_bytes.len();
        }
        write_output(&proof_bytes, proof_out, proof_out_len)
    })();

    match result {
        Ok(()) => 0,
        Err(err) => {
            set_last_error(err.to_string());
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn bbs_bls12_381_sha_256_proof_verify(
    pk_ptr: *const u8,
    pk_len: usize,
    header_ptr: *const u8,
    header_len: usize,
    presentation_header_ptr: *const u8,
    presentation_header_len: usize,
    disclosed_messages_ptr: *const u8,
    disclosed_messages_len: usize,
    disclosed_indexes_ptr: *const u8,
    disclosed_indexes_len: usize,
    proof_ptr: *const u8,
    proof_len: usize,
) -> i32 {
    clear_last_error();

    let result = (|| -> Result<(), Error> {
        let pk = BBSplusPublicKey::from_bytes(&read_input(pk_ptr, pk_len, "public key")?)?;
        let header = optional_input(header_ptr, header_len)?;
        let presentation_header =
            optional_input(presentation_header_ptr, presentation_header_len)?;
        let disclosed_messages = decode_frames(disclosed_messages_ptr, disclosed_messages_len)?;
        let disclosed_indexes = decode_usize_frames(disclosed_indexes_ptr, disclosed_indexes_len)?;
        let proof_bytes = read_input(proof_ptr, proof_len, "proof")?;
        let proof = PoKSignature::<Scheme>::from_bytes(&proof_bytes)?;
        proof.proof_verify(
            &pk,
            Some(&disclosed_messages),
            Some(&disclosed_indexes),
            header.as_deref(),
            presentation_header.as_deref(),
        )
    })();

    match result {
        Ok(()) => 0,
        Err(err) => {
            set_last_error(err.to_string());
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn bbs_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| {
        slot.borrow()
            .as_ref()
            .map_or(ptr::null(), |msg| msg.as_ptr())
    })
}

#[no_mangle]
pub extern "C" fn bbs_secret_key_bytes() -> usize {
    SECRET_KEY_BYTES
}

#[no_mangle]
pub extern "C" fn bbs_public_key_bytes() -> usize {
    PUBLIC_KEY_BYTES
}

#[no_mangle]
pub extern "C" fn bbs_signature_bytes() -> usize {
    SIGNATURE_BYTES
}
