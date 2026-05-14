use anyhow::Result;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallOffer {
    pub call_id: String,
    pub caller_zero_id: String,
    pub callee_zero_id: String,
    pub sdp: String,
    pub media_types: Vec<MediaType>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MediaType {
    Audio,
    Video,
    Both,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallAnswer {
    pub call_id: String,
    pub sdp: String,
    pub accepted_media: Vec<MediaType>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IceCandidate {
    pub call_id: String,
    pub candidate: String,
    pub sdp_mid: String,
    pub sdp_mline_index: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CallSignal {
    Offer(CallOffer),
    Answer(CallAnswer),
    IceCandidate(IceCandidate),
    HangUp { call_id: String },
    Busy { call_id: String },
    Rejected { call_id: String, reason: String },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CallSession {
    pub call_id: String,
    pub peer_zero_id: String,
    pub direction: CallDirection,
    pub state: CallState,
    pub media_types: Vec<MediaType>,
    pub started_at: u64,
    pub e2ee_enabled: bool,
    pub encryption_key: Option<[u8; 32]>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum CallDirection {
    Outgoing,
    Incoming,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum CallState {
    Ringing,
    Connecting,
    Connected,
    Ended,
    Failed,
}

pub struct WebRTCSignaling {
    active_calls: HashMap<String, CallSession>,
    call_history: Vec<CallSession>,
}

impl WebRTCSignaling {
    pub fn new() -> Self {
        Self {
            active_calls: HashMap::new(),
            call_history: Vec::new(),
        }
    }

    pub fn create_offer(&mut self, caller_id: &str, callee_id: &str, media_types: Vec<MediaType>) -> Result<CallSignal> {
        let call_id = generate_call_id(caller_id, callee_id);

        let session = CallSession {
            call_id: call_id.clone(),
            peer_zero_id: callee_id.to_string(),
            direction: CallDirection::Outgoing,
            state: CallState::Ringing,
            media_types: media_types.clone(),
            started_at: now_millis(),
            e2ee_enabled: true,
            encryption_key: Some(generate_call_key()),
        };

        self.active_calls.insert(call_id.clone(), session);

        Ok(CallSignal::Offer(CallOffer {
            call_id,
            caller_zero_id: caller_id.to_string(),
            callee_zero_id: callee_id.to_string(),
            sdp: String::new(),
            media_types,
        }))
    }

    pub fn handle_answer(&mut self, answer: CallAnswer) -> Result<()> {
        if let Some(session) = self.active_calls.get_mut(&answer.call_id) {
            session.state = CallState::Connecting;
        }
        Ok(())
    }

    pub fn accept_call(&mut self, offer: &CallOffer) -> Result<CallAnswer> {
        let session = CallSession {
            call_id: offer.call_id.clone(),
            peer_zero_id: offer.caller_zero_id.clone(),
            direction: CallDirection::Incoming,
            state: CallState::Connecting,
            media_types: offer.media_types.clone(),
            started_at: now_millis(),
            e2ee_enabled: true,
            encryption_key: Some(generate_call_key()),
        };

        self.active_calls.insert(offer.call_id.clone(), session);

        Ok(CallAnswer {
            call_id: offer.call_id.clone(),
            sdp: String::new(),
            accepted_media: offer.media_types.clone(),
        })
    }

    pub fn end_call(&mut self, call_id: &str) {
        if let Some(mut session) = self.active_calls.remove(call_id) {
            session.state = CallState::Ended;
            self.call_history.push(session);
        }
    }

    pub fn active_call_count(&self) -> usize {
        self.active_calls.len()
    }
}

fn generate_call_id(caller: &str, callee: &str) -> String {
    let input = format!("{}-{}-{}", caller, callee, now_millis());
    let hash = Sha256::digest(input.as_bytes());
    format!("call_{}", hex::encode(&hash[..8]))
}

fn generate_call_key() -> [u8; 32] {
    use rand::RngCore;
    let mut key = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut key);
    key
}

fn now_millis() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64
}