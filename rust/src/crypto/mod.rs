pub mod double_ratchet;
pub mod session;
pub mod x3dh;

pub use double_ratchet::{
    deserialize_ratchet_message, ratchet_decrypt, ratchet_encrypt, serialize_ratchet_message,
    CipherSuite, MessageKey, RatchetHeader, RatchetMessage, RatchetState, RatchetStateSnapshot,
    ReceivingChainKey, RootKey, SendingChainKey,
};
pub use session::E2EESessionManager;
pub use x3dh::{
    x3dh_recv, x3dh_recv_with_prekey_bundle, x3dh_send, x3dh_send_with_prekey_bundle,
    IdentityKeyPair, OneTimePreKey, PreKeyBundle, SignedPreKey, X3DHKeyBundle, X3DHResult,
};

use anyhow::Result;
use sha2::{Digest, Sha256};

pub fn compute_message_id(sender_id: &str, recipient_id: &str, ciphertext: &[u8], timestamp: u64) -> String {
    let mut hasher = Sha256::new();
    hasher.update(sender_id.as_bytes());
    hasher.update(recipient_id.as_bytes());
    hasher.update(ciphertext);
    hasher.update(timestamp.to_be_bytes());
    let hash = hasher.finalize();
    hex::encode(&hash[..16])
}