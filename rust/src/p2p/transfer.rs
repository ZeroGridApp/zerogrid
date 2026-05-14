use anyhow::Result;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::time::Instant;

const CHUNK_SIZE: usize = 256 * 1024; // 256KB per chunk
const MAX_CONCURRENT_CHUNKS: usize = 4;
const HASH_LENGTH: usize = 32;

#[derive(Debug, Clone)]
pub struct FileMetadata {
    pub file_name: String,
    pub file_size: u64,
    pub mime_type: String,
    pub chunk_count: u32,
    pub chunk_size: u32,
    pub file_hash: [u8; HASH_LENGTH],
}

#[derive(Debug, Clone)]
pub struct ChunkHeader {
    pub transfer_id: String,
    pub chunk_index: u32,
    pub offset: u64,
    pub size: u32,
    pub is_last: bool,
}

#[derive(Debug)]
pub struct TransferChunk {
    pub header: ChunkHeader,
    pub data: Vec<u8>,
}

pub struct TransferSession {
    pub transfer_id: String,
    pub metadata: FileMetadata,
    pub chunks: HashMap<u32, Vec<u8>>,
    pub received_count: u32,
    pub total_chunks: u32,
    pub bytes_received: u64,
    pub started_at: Instant,
    pub completed: bool,
}

impl TransferSession {
    pub fn new(metadata: FileMetadata) -> Self {
        let transfer_id = generate_transfer_id(&metadata.file_name);
        Self {
            transfer_id,
            total_chunks: metadata.chunk_count,
            metadata,
            chunks: HashMap::new(),
            received_count: 0,
            bytes_received: 0,
            started_at: Instant::now(),
            completed: false,
        }
    }

    pub fn add_chunk(&mut self, chunk: TransferChunk) -> Result<bool> {
        let index = chunk.header.chunk_index;
        if self.chunks.contains_key(&index) {
            return Ok(false);
        }

        self.chunks.insert(index, chunk.data.clone());
        self.received_count += 1;
        self.bytes_received += chunk.data.len() as u64;

        if self.received_count >= self.total_chunks {
            self.completed = true;
        }

        Ok(true)
    }

    pub fn progress(&self) -> f64 {
        if self.total_chunks == 0 {
            return 1.0;
        }
        self.received_count as f64 / self.total_chunks as f64
    }

    pub fn assemble(&self) -> Result<Vec<u8>> {
        let mut data = Vec::with_capacity(self.metadata.file_size as usize);
        for i in 0..self.total_chunks {
            if let Some(chunk) = self.chunks.get(&i) {
                data.extend_from_slice(chunk);
            } else {
                anyhow::bail!("missing chunk {}", i);
            }
        }

        let hash = Sha256::digest(&data);
        if hash.as_slice() != self.metadata.file_hash {
            anyhow::bail!("hash mismatch, file may be corrupted");
        }

        Ok(data)
    }
}

pub fn create_file_metadata(file_name: &str, data: &[u8], mime_type: &str) -> FileMetadata {
    let file_size = data.len() as u64;
    let chunk_count = ((file_size as usize + CHUNK_SIZE - 1) / CHUNK_SIZE) as u32;
    let file_hash: [u8; HASH_LENGTH] = Sha256::digest(data).into();

    FileMetadata {
        file_name: file_name.to_string(),
        file_size,
        mime_type: mime_type.to_string(),
        chunk_count,
        chunk_size: CHUNK_SIZE as u32,
        file_hash,
    }
}

pub fn split_into_chunks(transfer_id: &str, metadata: &FileMetadata, data: &[u8]) -> Vec<TransferChunk> {
    let mut chunks = Vec::new();
    let total_chunks = metadata.chunk_count;

    for i in 0..total_chunks {
        let offset = i as u64 * CHUNK_SIZE as u64;
        let end = ((offset + CHUNK_SIZE as u64) as usize).min(data.len());
        let chunk_data = data[offset as usize..end].to_vec();
        let is_last = i == total_chunks - 1;

        chunks.push(TransferChunk {
            header: ChunkHeader {
                transfer_id: transfer_id.to_string(),
                chunk_index: i,
                offset,
                size: (end - offset as usize) as u32,
                is_last,
            },
            data: chunk_data,
        });
    }

    chunks
}

pub fn serialize_chunk(chunk: &TransferChunk) -> Vec<u8> {
    let mut data = Vec::with_capacity(64 + chunk.data.len());

    let header_bytes = chunk.header.transfer_id.as_bytes();
    let mut id_bytes = [0u8; 32];
    let copy_len = header_bytes.len().min(32);
    id_bytes[..copy_len].copy_from_slice(&header_bytes[..copy_len]);
    data.extend_from_slice(&id_bytes);

    data.extend_from_slice(&chunk.header.chunk_index.to_be_bytes());
    data.extend_from_slice(&chunk.header.offset.to_be_bytes());
    data.extend_from_slice(&chunk.header.size.to_be_bytes());
    data.push(chunk.header.is_last as u8);

    data.extend_from_slice(&chunk.data);

    data
}

pub fn deserialize_chunk(data: &[u8]) -> Option<TransferChunk> {
    if data.len() < 49 {
        return None;
    }

    let id_bytes = &data[..32];
    let transfer_id = String::from_utf8_lossy(id_bytes)
        .trim_end_matches('\0')
        .to_string();

    let chunk_index = u32::from_be_bytes(data[32..36].try_into().ok()?);
    let offset = u64::from_be_bytes(data[36..44].try_into().ok()?);
    let size = u32::from_be_bytes(data[44..48].try_into().ok()?);
    let is_last = data[48] != 0;

    let chunk_data = data[49..49 + size as usize].to_vec();

    Some(TransferChunk {
        header: ChunkHeader {
            transfer_id,
            chunk_index,
            offset,
            size,
            is_last,
        },
        data: chunk_data,
    })
}

fn generate_transfer_id(file_name: &str) -> String {
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;
    let hash = Sha256::digest(format!("{}-{}", file_name, timestamp).as_bytes());
    hex::encode(&hash[..16])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_file_transfer_workflow() {
        let file_data = vec![0x42u8; 1024 * 1024];
        let metadata = create_file_metadata("test.bin", &file_data, "application/octet-stream");

        assert_eq!(metadata.chunk_count, 4);

        let transfer_id = "test-transfer-001".to_string();
        let chunks = split_into_chunks(&transfer_id, &metadata, &file_data);

        assert_eq!(chunks.len(), 4);

        let mut session = TransferSession::new(metadata.clone());
        for chunk in &chunks {
            let serialized = serialize_chunk(chunk);
            let deserialized = deserialize_chunk(&serialized).unwrap();
            session.add_chunk(deserialized).unwrap();
        }

        assert!(session.completed);
        assert!((session.progress() - 1.0).abs() < 0.001);

        let assembled = session.assemble().unwrap();
        assert_eq!(assembled.len(), file_data.len());
        assert_eq!(assembled, file_data);
    }
}