{ pkgs }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "zkryptium-ffi";
  version = "0.1.0";

  src = ../offchain/cbits/zkryptium-ffi;
  cargoLock.lockFile = ../offchain/cbits/zkryptium-ffi/Cargo.lock;

  nativeBuildInputs = [ pkgs.pkg-config ];
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    lib_path="$(find target -name 'libzkryptium_ffi*${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}' | head -n 1)"
    if [ -z "$lib_path" ]; then
      echo "zkryptium_ffi shared library not found under target" >&2
      find target -maxdepth 4 -type f | sort >&2
      exit 1
    fi
    cp "$lib_path" "$out/lib/libzkryptium_ffi${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}"
    runHook postInstall
  '';
}
