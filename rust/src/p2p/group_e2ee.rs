use anyhow::Result;
use sha2::{Digest, Sha256};
use chacha20poly1305::{
    aead::{Aead, KeyInit},
    ChaCha20Poly1305, Nonce,
};
use std::collections::HashMap;

pub struct GroupKeyManager {
    groups: HashMap<String, GroupEncryption>,
}

struct GroupEncryption {
    sender_keys: HashMap<String, [u8; 32]>,
    current_key: [u8; 32],
    epoch: u32,
}

impl GroupKeyManager {
    pub fn new() -> Self {
        Self {
            groups: HashMap::new(),
        }
    }

    pub fn create_group(&mut self, group_id: &str, creator_id: &str) -> Result<()> {
        let key = generate_sender_key(group_id, creator_id, 0);
        self.groups.insert(group_id.to_string(), GroupEncryption {
            sender_keys: HashMap::new(),
            current_key: key,
            epoch: 0,
        });
        Ok(())
    }

    pub fn register_member(&mut self, group_id: &str, member_id: &str) -> Result<()> {
        let group = self.groups.get_mut(group_id)
            .ok_or_else(|| anyhow::anyhow!("group not found"))?;

        let key = generate_sender_key(group_id, member_id, group.epoch);
        group.sender_keys.insert(member_id.to_string(), key);
        Ok(())
    }

    pub fn encrypt_group_message(&self, group_id: &str, sender_id: &str, plaintext: &[u8]) -> Result<Vec<u8>> {
        let group = self.groups.get(group_id)
            .ok_or_else(|| anyhow::anyhow!("group not found"))?;

        let key = group.sender_keys.get(sender_id)
            .unwrap_or(&group.current_key);

        let cipher = ChaCha20Poly1305::new_from_slice(key)
            .map_err(|e| anyhow::anyhow!("create cipher: {}", e))?;

        let nonce_bytes = &key[..12];
        let nonce = Nonce::from_slice(nonce_bytes);

        cipher.encrypt(nonce, plaintext)
            .map_err(|e| anyhow::anyhow!("encrypt failed: {}", e))
    }

    pub fn decrypt_group_message(&self, group_id: &str, sender_id: &str, ciphertext: &[u8]) -> Result<Vec<u8>> {
        let group = self.groups.get(group_id)
            .ok_or_else(|| anyhow::anyhow!("group not found"))?;

        let key = group.sender_keys.get(sender_id)
            .unwrap_or(&group.current_key);

        let cipher = ChaCha20Poly1305::new_from_slice(key)
            .map_err(|e| anyhow::anyhow!("create cipher: {}", e))?;

        let nonce_bytes = &key[..12];
        let nonce = Nonce::from_slice(nonce_bytes);

        cipher.decrypt(nonce, ciphertext)
            .map_err(|e| anyhow::anyhow!("decrypt failed: {}", e))
    }

    pub fn ratchet_group(&mut self, group_id: &str) -> Result<()> {
        let group = self.groups.get_mut(group_id)
            .ok_or_else(|| anyhow::anyhow!("group not found"))?;

        group.epoch += 1;
        group.current_key = derive_key_from_epoch(&group.current_key, group.epoch);
        group.sender_keys.clear();
        Ok(())
    }

    pub fn remove_member(&mut self, group_id: &str, member_id: &str) -> Result<()> {
        let group = self.groups.get_mut(group_id)
            .ok_or_else(|| anyhow::anyhow!("group not found"))?;

        group.sender_keys.remove(member_id);
        self.ratchet_group(group_id)?;
        Ok(())
    }
}

fn generate_sender_key(group_id: &str, member_id: &str, epoch: u32) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(b"zero-group-sender-key-v1");
    hasher.update(group_id.as_bytes());
    hasher.update(member_id.as_bytes());
    hasher.update(epoch.to_be_bytes());
    let hash = hasher.finalize();
    hash.into()
}

fn derive_key_from_epoch(old_key: &[u8; 32], epoch: u32) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(old_key);
    hasher.update(epoch.to_be_bytes());
    hasher.update(b"zero-group-ratchet");
    let hash = hasher.finalize();
    hash.into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_group_encryption() {
        let mut manager = GroupKeyManager::new();
        manager.create_group("test_group", "alice").unwrap();
        manager.register_member("test_group", "bob").unwrap();

        let plaintext = b"Hello group!";
        let encrypted = manager.encrypt_group_message("test_group", "alice", plaintext).unwrap();
        let decrypted = manager.decrypt_group_message("test_group", "alice", &encrypted).unwrap();
        assert_eq!(plaintext, decrypted.as_slice());

        manager.remove_member("test_group", "bob").unwrap();

        let plaintext2 = b"Bob left";
        let encrypted2 = manager.encrypt_group_message("test_group", "alice", plaintext2).unwrap();
        let decrypted2 = manager.decrypt_group_message("test_group", "alice", &encrypted2).unwrap();
        assert_eq!(plaintext2, decrypted2.as_slice());
    }
}