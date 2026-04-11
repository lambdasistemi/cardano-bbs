# Build everything
build: build-offchain build-onchain

# Build off-chain Haskell library
build-offchain:
    cd offchain && cabal build all

# Build on-chain Aiken validators
build-onchain:
    cd onchain && aiken build

# Run all tests
test: test-offchain test-onchain

# Run off-chain tests
test-offchain:
    cd offchain && cabal test all

# Run on-chain tests
test-onchain:
    cd onchain && aiken check

# Format check (CI)
format-check: format-check-offchain format-check-onchain

format-check-offchain:
    cd offchain && fourmolu -m check $(find src test -name '*.hs')

format-check-onchain:
    cd onchain && aiken fmt --check

# Format (fix)
format:
    cd offchain && fourmolu -i $(find src test -name '*.hs')
    cd onchain && aiken fmt

# Lint
hlint:
    cd offchain && hlint src test

# Build Rust FFI
build-ffi:
    cd offchain/cbits/zkryptium-ffi && cargo build --release

# CI: full check
ci: build test format-check hlint
