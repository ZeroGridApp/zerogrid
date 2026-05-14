use anyhow::Result;
use sha2::{Digest, Sha256};
use hkdf::Hkdf;

pub fn derive_evm_address(seed: &[u8], path: &str) -> Result<String> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"evm-seed"), seed);
    let mut derived = vec![0u8; 32];
    hkdf.expand(path.as_bytes(), &mut derived)
        .map_err(|e| anyhow::anyhow!("hkdf expand failed: {}", e))?;

    let mut hasher = Sha256::new();
    hasher.update(b"zero-evm-wallet-v1");
    hasher.update(&derived);
    let hash = hasher.finalize();

    let address = format!("0x{}", hex::encode(&hash[12..32]));

    Ok(address)
}