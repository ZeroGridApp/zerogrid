use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;

const BLE_CHUNK_SIZE: usize = 512;
const MAX_QUEUE_SIZE: usize = 100;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BTMessageType {
    Text,
    FileChunk,
    ContactExchange,
    Ping,
    Ack,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BTMessage {
    pub msg_type: BTMessageType,
    pub sender_id: String,
    pub payload: Vec<u8>,
    pub sequence: u32,
    pub timestamp: u64,
    pub needs_ack: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BTDeviceInfo {
    pub device_id: String,
    pub zero_id: Option<String>,
    pub display_name: String,
    pub rssi: i32,
    pub last_seen: u64,
}

#[derive(Debug)]
pub struct BLEMeshNode {
    pub node_id: String,
    pub zero_id: String,
    pub hop_count: u8,
    pub signal_strength: i32,
}

pub struct BLEProtocol {
    local_zero_id: String,
    message_queue: VecDeque<BTMessage>,
    known_devices: Vec<BTDeviceInfo>,
    mesh_nodes: Vec<BLEMeshNode>,
    sequence_counter: u32,
}

impl BLEProtocol {
    pub fn new(local_zero_id: String) -> Self {
        Self {
            local_zero_id,
            message_queue: VecDeque::new(),
            known_devices: Vec::new(),
            mesh_nodes: Vec::new(),
            sequence_counter: 0,
        }
    }

    pub fn create_text_message(&mut self, text: &str) -> BTMessage {
        self.sequence_counter += 1;
        BTMessage {
            msg_type: BTMessageType::Text,
            sender_id: self.local_zero_id.clone(),
            payload: text.as_bytes().to_vec(),
            sequence: self.sequence_counter,
            timestamp: now_millis(),
            needs_ack: true,
        }
    }

    pub fn create_contact_exchange(&mut self) -> BTMessage {
        self.sequence_counter += 1;
        let payload = serde_json::to_vec(&json!({
            "zero_id": self.local_zero_id,
            "version": "zero/1.0.0"
        })).unwrap_or_default();

        BTMessage {
            msg_type: BTMessageType::ContactExchange,
            sender_id: self.local_zero_id.clone(),
            payload,
            sequence: self.sequence_counter,
            timestamp: now_millis(),
            needs_ack: true,
        }
    }

    pub fn serialize_message(msg: &BTMessage) -> Result<Vec<u8>> {
        let mut data = Vec::with_capacity(32 + msg.payload.len());

        let msg_type_byte = match msg.msg_type {
            BTMessageType::Text => 0u8,
            BTMessageType::FileChunk => 1u8,
            BTMessageType::ContactExchange => 2u8,
            BTMessageType::Ping => 3u8,
            BTMessageType::Ack => 4u8,
        };
        data.push(msg_type_byte);

        let id_bytes = msg.sender_id.as_bytes();
        let mut id_buf = [0u8; 12];
        let copy_len = id_bytes.len().min(12);
        id_buf[..copy_len].copy_from_slice(&id_bytes[..copy_len]);
        data.extend_from_slice(&id_buf);

        data.extend_from_slice(&msg.sequence.to_be_bytes());
        data.extend_from_slice(&msg.timestamp.to_be_bytes());
        data.push(msg.needs_ack as u8);

        let payload_len = msg.payload.len() as u16;
        data.extend_from_slice(&payload_len.to_be_bytes());
        data.extend_from_slice(&msg.payload);

        Ok(data)
    }

    pub fn deserialize_message(data: &[u8]) -> Option<BTMessage> {
        if data.len() < 24 {
            return None;
        }

        let msg_type = match data[0] {
            0 => BTMessageType::Text,
            1 => BTMessageType::FileChunk,
            2 => BTMessageType::ContactExchange,
            3 => BTMessageType::Ping,
            4 => BTMessageType::Ack,
            _ => return None,
        };

        let id_bytes = &data[1..13];
        let sender_id = String::from_utf8_lossy(id_bytes)
            .trim_end_matches('\0')
            .to_string();

        let sequence = u32::from_be_bytes(data[13..17].try_into().ok()?);
        let timestamp = u64::from_be_bytes(data[17..25].try_into().ok()?);
        let needs_ack = data[25] != 0;

        let payload_len = u16::from_be_bytes(data[26..28].try_into().ok()?) as usize;
        if data.len() < 28 + payload_len {
            return None;
        }

        let payload = data[28..28 + payload_len].to_vec();

        Some(BTMessage {
            msg_type,
            sender_id,
            payload,
            sequence,
            timestamp,
            needs_ack,
        })
    }

    pub fn register_device(&mut self, device: BTDeviceInfo) {
        if let Some(existing) = self.known_devices.iter_mut().find(|d| d.device_id == device.device_id) {
            existing.rssi = device.rssi;
            existing.last_seen = device.last_seen;
            if device.zero_id.is_some() {
                existing.zero_id = device.zero_id;
            }
        } else {
            self.known_devices.push(device);
        }
    }

    pub fn enqueue_message(&mut self, msg: BTMessage) {
        if self.message_queue.len() >= MAX_QUEUE_SIZE {
            self.message_queue.pop_front();
        }
        self.message_queue.push_back(msg);
    }

    pub fn dequeue_message(&mut self) -> Option<BTMessage> {
        self.message_queue.pop_front()
    }

    pub fn update_mesh_node(&mut self, node: BLEMeshNode) {
        if let Some(existing) = self.mesh_nodes.iter_mut().find(|n| n.node_id == node.node_id) {
            existing.hop_count = node.hop_count;
            existing.signal_strength = node.signal_strength;
        } else {
            self.mesh_nodes.push(node);
        }
    }

    pub fn known_devices(&self) -> &[BTDeviceInfo] {
        &self.known_devices
    }

    pub fn mesh_nodes(&self) -> &[BLEMeshNode] {
        &self.mesh_nodes
    }

    pub fn queue_size(&self) -> usize {
        self.message_queue.len()
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
    fn test_ble_message_roundtrip() {
        let mut protocol = BLEProtocol::new("Z8P2K5W1RT".to_string());
        let msg = protocol.create_text_message("Hello via BLE!");

        let serialized = BLEProtocol::serialize_message(&msg).unwrap();
        let deserialized = BLEProtocol::deserialize_message(&serialized).unwrap();

        assert_eq!(deserialized.sender_id, "Z8P2K5W1RT");
        assert_eq!(String::from_utf8_lossy(&deserialized.payload), "Hello via BLE!");
    }

    #[test]
    fn test_contact_exchange() {
        let mut protocol = BLEProtocol::new("Z3K7M2N8XP".to_string());
        let msg = protocol.create_contact_exchange();
        assert!(matches!(msg.msg_type, BTMessageType::ContactExchange));
    }
}