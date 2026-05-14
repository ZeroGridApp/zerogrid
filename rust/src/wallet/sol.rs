use anyhow::Result;
use sha2::{Digest, Sha256};
use hkdf::Hkdf;
use bs58;

pub fn derive_sol_address(seed: &[u8], path: &str) -> Result<String> {
    let hkdf = Hkdf::<Sha256>::new(Some(b"solana-seed"), seed);
    let mut derived = vec![0u8; 32];
    hkdf.expand(path.as_bytes(), &mut derived)
        .map_err(|e| anyhow::anyhow!("hkdf expand failed: {}", e))?;

    let mut hasher = Sha256::new();
    hasher.update(b"zero-sol-wallet-v1");
    hasher.update(&derived);
    let hash = hasher.finalize();

    let address = bs58::encode(&hash[..32]).into_string();

    Ok(address)
}