use anyhow::Result;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

const CID_VERSION: u8 = 1;
const DEFAULT_REPLICATION: u8 = 3;
const MAX_OBJECT_SIZE: u64 = 24 * 1024 * 1024; // 24MB

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentId {
    pub hash: [u8; 32],
    pub size: u64,
    pub mime_type: String,
    pub created_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StorageObject {
    pub cid: ContentId,
    pub data: Vec<u8>,
    pub pinned: bool,
    pub replicated_to: Vec<String>,
    pub access_count: u64,
}

pub struct DASNStorage {
    local_store: HashMap<String, StorageObject>,
    cid_index: HashMap<String, ContentId>,
    max_capacity: u64,
    current_usage: u64,
    replication_factor: u8,
    peer_replicas: HashMap<String, Vec<String>>,
}

impl DASNStorage {
    pub fn new(max_capacity_mb: u64, replication_factor: u8) -> Self {
        Self {
            local_store: HashMap::new(),
            cid_index: HashMap::new(),
            max_capacity: max_capacity_mb * 1024 * 1024,
            current_usage: 0,
            replication_factor,
            peer_replicas: HashMap::new(),
        }
    }

    pub fn store(&mut self, data: &[u8], mime_type: &str, pinned: bool) -> Result<ContentId> {
        if data.len() as u64 > MAX_OBJECT_SIZE {
            anyhow::bail!("object exceeds max size (24MB)");
        }

        let hash: [u8; 32] = Sha256::digest(data).into();
        let hash_hex = hex::encode(&hash);

        if let Some(existing) = self.local_store.get_mut(&hash_hex) {
            existing.access_count += 1;
            return Ok(existing.cid.clone());
        }

        if self.current_usage + data.len() as u64 > self.max_capacity {
            self.evict_lru();
        }

        let cid = ContentId {
            hash,
            size: data.len() as u64,
            mime_type: mime_type.to_string(),
            created_at: now_millis(),
        };

        let object = StorageObject {
            cid: cid.clone(),
            data: data.to_vec(),
            pinned,
            replicated_to: Vec::new(),
            access_count: 0,
        };

        self.current_usage += data.len() as u64;
        self.cid_index.insert(hash_hex.clone(), cid.clone());
        self.local_store.insert(hash_hex, object);

        Ok(cid)
    }

    pub fn retrieve(&mut self, hash_hex: &str) -> Option<Vec<u8>> {
        if let Some(obj) = self.local_store.get_mut(hash_hex) {
            obj.access_count += 1;
            Some(obj.data.clone())
        } else {
            None
        }
    }

    pub fn pin(&mut self, hash_hex: &str) -> Result<()> {
        let obj = self.local_store.get_mut(hash_hex)
            .ok_or_else(|| anyhow::anyhow!("object not found"))?;
        obj.pinned = true;
        Ok(())
    }

    pub fn unpin(&mut self, hash_hex: &str) -> Result<()> {
        let obj = self.local_store.get_mut(hash_hex)
            .ok_or_else(|| anyhow::anyhow!("object not found"))?;
        obj.pinned = false;
        Ok(())
    }

    pub fn register_replica(&mut self, cid_hex: &str, peer_id: &str) {
        self.peer_replicas
            .entry(cid_hex.to_string())
            .or_default()
            .push(peer_id.to_string());
    }

    pub fn get_replicas(&self, cid_hex: &str) -> Vec<String> {
        self.peer_replicas.get(cid_hex).cloned().unwrap_or_default()
    }

    pub fn stats(&self) -> DASNStats {
        DASNStats {
            total_objects: self.local_store.len(),
            total_size: self.current_usage,
            max_capacity: self.max_capacity,
            pinned_count: self.local_store.values().filter(|o| o.pinned).count(),
            usage_percent: if self.max_capacity > 0 {
                (self.current_usage as f64 / self.max_capacity as f64) * 100.0
            } else {
                0.0
            },
        }
    }

    pub fn list_cids(&self) -> Vec<ContentId> {
        self.cid_index.values().cloned().collect()
    }

    pub fn has_object(&self, hash_hex: &str) -> bool {
        self.local_store.contains_key(hash_hex)
    }

    fn evict_lru(&mut self) {
        let mut candidates: Vec<_> = self.local_store
            .iter()
            .filter(|(_, obj)| !obj.pinned)
            .collect();

        candidates.sort_by_key(|(_, obj)| obj.access_count);

        let freed = 0u64;
        for (key, _) in candidates.iter().take(10) {
            if let Some(obj) = self.local_store.remove(*key) {
                self.current_usage -= obj.data.len() as u64;
                self.cid_index.remove(*key);
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DASNStats {
    pub total_objects: usize,
    pub total_size: u64,
    pub max_capacity: u64,
    pub pinned_count: usize,
    pub usage_percent: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IPFSBridgeConfig {
    pub api_endpoint: String,
    pub gateway: String,
    pub enabled: bool,
}

pub struct IPFSBridge {
    config: IPFSBridgeConfig,
}

impl IPFSBridge {
    pub fn new(config: IPFSBridgeConfig) -> Self {
        Self { config }
    }

    pub fn to_ipfs_cid(cid: &ContentId) -> String {
        let mut multicodec = Vec::new();
        multicodec.push(CID_VERSION);
        multicodec.push(0x12);
        multicodec.push(32);
        multicodec.extend_from_slice(&cid.hash);

        bs58::encode(&multicodec).into_string()
    }

    pub fn enabled(&self) -> bool {
        self.config.enabled
    }

    pub fn gateway_url(&self, cid: &ContentId) -> String {
        format!("{}/ipfs/{}", self.config.gateway, Self::to_ipfs_cid(cid))
    }
}

fn now_millis() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_store_and_retrieve() {
        let mut dasn = DASNStorage::new(100, 3);
        let data = b"zero decentralized storage test data";

        let cid = dasn.store(data, "text/plain", true).unwrap();
        assert_eq!(cid.size, data.len() as u64);

        let hash_hex = hex::encode(cid.hash);
        let retrieved = dasn.retrieve(&hash_hex).unwrap();
        assert_eq!(retrieved, data);
    }

    #[test]
    fn test_dedup() {
        let mut dasn = DASNStorage::new(100, 3);
        let data = b"dedup test";

        let cid1 = dasn.store(data, "text/plain", false).unwrap();
        let cid2 = dasn.store(data, "text/plain", false).unwrap();

        assert_eq!(cid1.hash, cid2.hash);
        assert_eq!(dasn.stats().total_objects, 1);
    }

    #[test]
    fn test_ipfs_cid_format() {
        let cid = ContentId {
            hash: [0x42u8; 32],
            size: 100,
            mime_type: "text/plain".to_string(),
            created_at: 0,
        };

        let ipfs_cid = IPFSBridge::to_ipfs_cid(&cid);
        assert!(ipfs_cid.starts_with('b'));
    }
}