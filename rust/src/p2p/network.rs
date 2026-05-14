use crate::crypto::E2EESessionManager;
use anyhow::Result;
use libp2p::{
    autonat,
    core::upgrade,
    gossipsub::{self, MessageAuthenticity, MessageId},
    identify,
    identity::Keypair,
    kad::{self, store::MemoryStore, Mode},
    noise,
    relay,
    swarm::{NetworkBehaviour, SwarmEvent},
    tcp, yamux, Multiaddr, PeerId, Swarm, SwarmBuilder, Transport,
};
use std::collections::{HashMap, HashSet};
use std::time::Duration;
use tokio::sync::mpsc;

const DM_TOPIC_PREFIX: &str = "zero-dm-";
const SPACE_TOPIC: &str = "zero-space-global-v1";
const GROUP_TOPIC_PREFIX: &str = "zero-group-";
const PROTOCOL_VERSION: &str = "/zero/1.0.0";
const HEARTBEAT_INTERVAL: u64 = 15;
const BOOTSTRAP_INTERVAL: u64 = 60;

#[derive(NetworkBehaviour)]
#[behaviour(to_swarm = "ZeroEvent")]
pub struct ZeroNetworkBehaviour {
    pub gossipsub: gossipsub::Behaviour,
    pub kademlia: kad::Behaviour<MemoryStore>,
    pub identify: identify::Behaviour,
    pub autonat: autonat::Behaviour,
    pub relay: relay::Behaviour,
}

#[derive(Debug)]
pub enum ZeroEvent {
    GossipsubMessage(gossipsub::Event),
    Kademlia(kad::Event),
    Identify(identify::Event),
    Autonat(autonat::Event),
    Relay(relay::Event),
}

impl From<gossipsub::Event> for ZeroEvent {
    fn from(e: gossipsub::Event) -> Self { ZeroEvent::GossipsubMessage(e) }
}
impl From<kad::Event> for ZeroEvent {
    fn from(e: kad::Event) -> Self { ZeroEvent::Kademlia(e) }
}
impl From<identify::Event> for ZeroEvent {
    fn from(e: identify::Event) -> Self { ZeroEvent::Identify(e) }
}
impl From<autonat::Event> for ZeroEvent {
    fn from(e: autonat::Event) -> Self { ZeroEvent::Autonat(e) }
}
impl From<relay::Event> for ZeroEvent {
    fn from(e: relay::Event) -> Self { ZeroEvent::Relay(e) }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NatStatus {
    Unknown,
    Public,
    Private,
    Unreachable,
}

#[derive(Debug, Clone)]
pub struct KnownPeer {
    pub peer_id: PeerId,
    pub zero_id: String,
    pub addresses: Vec<Multiaddr>,
    pub last_seen: u64,
    pub connected: bool,
}

pub struct ZeroP2PNetwork {
    swarm: Swarm<ZeroNetworkBehaviour>,
    event_sender: mpsc::UnboundedSender<P2PEvent>,
    event_receiver: mpsc::UnboundedReceiver<P2PEvent>,
    local_peer_id: PeerId,
    local_zero_id: String,
    e2ee: Option<E2EESessionManager>,
    known_peers: HashMap<PeerId, KnownPeer>,
    zero_id_to_peer_id: HashMap<String, PeerId>,
    nat_status: NatStatus,
    external_addresses: Vec<Multiaddr>,
    connected_peers: HashSet<PeerId>,
    subscribed_topics: HashSet<String>,
}

#[derive(Debug, Clone)]
pub enum P2PEvent {
    NetworkReady {
        peer_id: String,
        external_addrs: Vec<String>,
        nat_status: String,
    },
    PeerDiscovered {
        peer_id: String,
        zero_id: Option<String>,
        addresses: Vec<String>,
    },
    PeerConnected {
        peer_id: String,
        zero_id: Option<String>,
    },
    PeerDisconnected {
        peer_id: String,
    },
    DirectMessage {
        from_peer_id: String,
        from_zero_id: Option<String>,
        encrypted_content: Vec<u8>,
        timestamp: u64,
    },
    SpacePost {
        from_peer_id: String,
        from_zero_id: Option<String>,
        encrypted_content: Vec<u8>,
        timestamp: u64,
        topic: String,
    },
    GroupMessage {
        from_peer_id: String,
        group_id: String,
        encrypted_content: Vec<u8>,
        timestamp: u64,
    },
    NatStatusChanged {
        status: NatStatus,
    },
    Error {
        message: String,
    },
}

impl ZeroP2PNetwork {
    pub async fn new(
        keypair: Keypair,
        local_zero_id: String,
        e2ee: Option<E2EESessionManager>,
    ) -> Result<Self> {
        let local_peer_id = keypair.public().to_peer_id();

        let (tx, rx) = mpsc::unbounded_channel();

        let mut swarm = SwarmBuilder::with_existing_identity(keypair)
            .with_tokio()
            .with_tcp(
                tcp::Config::default().port_reuse(true),
                noise::Config::new,
                yamux::Config::default,
            )?
            .with_behaviour(|key| {
                let message_authenticity = MessageAuthenticity::Signed(key.clone());
                let gossipsub_config = gossipsub::ConfigBuilder::default()
                    .heartbeat_interval(Duration::from_secs(HEARTBEAT_INTERVAL))
                    .validation_mode(gossipsub::ValidationMode::Strict)
                    .message_id_fn(|message| {
                        let mut s = DefaultHasher::new();
                        message.data.hash(&mut s);
                        MessageId::from(s.finish().to_string())
                    })
                    .build()
                    .expect("valid gossipsub config");
                let gossipsub = gossipsub::Behaviour::new(
                    message_authenticity,
                    gossipsub_config,
                ).expect("valid gossipsub");

                let kademlia = kad::Behaviour::new(
                    key.public().to_peer_id(),
                    MemoryStore::new(key.public().to_peer_id()),
                );

                let identify = identify::Behaviour::new(
                    identify::Config::new(
                        PROTOCOL_VERSION.to_string(),
                        key.public(),
                    )
                    .with_agent_version(format!("zero/{}", env!("CARGO_PKG_VERSION"))),
                );

                let autonat = autonat::Behaviour::new(
                    key.public().to_peer_id(),
                    autonat::Config::default(),
                );

                let relay = relay::Behaviour::new(
                    key.public().to_peer_id(),
                    Default::default(),
                );

                ZeroNetworkBehaviour {
                    gossipsub,
                    kademlia,
                    identify,
                    autonat,
                    relay,
                }
            })?
            .with_swarm_config(|cfg| {
                cfg.with_idle_connection_timeout(Duration::from_secs(120))
            })
            .build();

        Ok(Self {
            swarm,
            event_sender: tx,
            event_receiver: rx,
            local_peer_id,
            local_zero_id,
            e2ee,
            known_peers: HashMap::new(),
            zero_id_to_peer_id: HashMap::new(),
            nat_status: NatStatus::Unknown,
            external_addresses: Vec::new(),
            connected_peers: HashSet::new(),
            subscribed_topics: HashSet::new(),
        })
    }

    pub fn bootstrap(&mut self, bootstrap_addrs: Vec<String>) -> Result<()> {
        for addr_str in &bootstrap_addrs {
            if let Ok(addr) = addr_str.parse::<Multiaddr>() {
                self.swarm.dial(addr)?;
            }
        }

        self.subscribe_dm("*");
        self.subscribe_space();

        Ok(())
    }

    pub fn subscribe_dm(&mut self, zero_id_or_peer: &str) {
        let topic_name = if zero_id_or_peer == "*" {
            format!("{}{}", DM_TOPIC_PREFIX, self.local_zero_id)
        } else {
            format!("{}{}", DM_TOPIC_PREFIX, zero_id_or_peer)
        };

        let topic = gossipsub::IdentTopic::new(&topic_name);
        if let Err(e) = self.swarm.behaviour_mut().gossipsub.subscribe(&topic) {
            let _ = self.event_sender.send(P2PEvent::Error {
                message: format!("subscribe failed: {}", e),
            });
        } else {
            self.subscribed_topics.insert(topic_name);
        }
    }

    pub fn subscribe_space(&mut self) {
        let topic = gossipsub::IdentTopic::new(SPACE_TOPIC);
        if let Err(e) = self.swarm.behaviour_mut().gossipsub.subscribe(&topic) {
            let _ = self.event_sender.send(P2PEvent::Error {
                message: format!("space subscribe failed: {}", e),
            });
        } else {
            self.subscribed_topics.insert(SPACE_TOPIC.to_string());
        }
    }

    pub fn subscribe_group(&mut self, group_id: &str) {
        let topic_name = format!("{}{}", GROUP_TOPIC_PREFIX, group_id);
        let topic = gossipsub::IdentTopic::new(&topic_name);
        if let Err(e) = self.swarm.behaviour_mut().gossipsub.subscribe(&topic) {
            let _ = self.event_sender.send(P2PEvent::Error {
                message: format!("group subscribe failed: {}", e),
            });
        } else {
            self.subscribed_topics.insert(topic_name);
        }
    }

    pub fn send_direct_message(&mut self, target_zero_id: &str, plaintext: &[u8]) -> Result<String> {
        let encrypted = if let Some(ref mut e2ee) = self.e2ee {
            e2ee.encrypt_message(target_zero_id, plaintext)?.ciphertext
        } else {
            plaintext.to_vec()
        };

        let header = DirectMessageHeader {
            sender_zero_id: self.local_zero_id.clone(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as u64,
            msg_type: 0u8,
        };
        let mut payload = header.serialize();
        payload.extend_from_slice(&encrypted);

        let topic = gossipsub::IdentTopic::new(format!("{}{}", DM_TOPIC_PREFIX, target_zero_id));
        let msg_id = self
            .swarm
            .behaviour_mut()
            .gossipsub
            .publish(topic, payload)?;

        Ok(format!("{}", msg_id))
    }

    pub fn publish_space_post(&mut self, content: &[u8]) -> Result<String> {
        let encrypted = if let Some(ref mut e2ee) = self.e2ee {
            e2ee.encrypt_message("SPACE", content)?.ciphertext
        } else {
            content.to_vec()
        };

        let header = DirectMessageHeader {
            sender_zero_id: self.local_zero_id.clone(),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis() as u64,
            msg_type: 1u8,
        };
        let mut payload = header.serialize();
        payload.extend_from_slice(&encrypted);

        let topic = gossipsub::IdentTopic::new(SPACE_TOPIC);
        let msg_id = self
            .swarm
            .behaviour_mut()
            .gossipsub
            .publish(topic, payload)?;

        Ok(format!("{}", msg_id))
    }

    pub async fn next_event(&mut self) -> Option<P2PEvent> {
        tokio::select! {
            event = self.swarm.select_next_some() => {
                self.handle_swarm_event(event)
            }
            event = self.event_receiver.recv() => {
                event
            }
        }
    }

    fn handle_swarm_event(&mut self, event: SwarmEvent<ZeroEvent>) -> Option<P2PEvent> {
        match event {
            SwarmEvent::Behaviour(ZeroEvent::GossipsubMessage(gossipsub::Event::Message {
                propagation_source: peer_id,
                message_id: _,
                message,
            })) => {
                self.handle_gossipsub_message(peer_id, &message.topic, &message.data)
            }

            SwarmEvent::Behaviour(ZeroEvent::Kademlia(
                kad::Event::RoutingUpdated { peer, .. }
            )) => {
                Some(P2PEvent::PeerDiscovered {
                    peer_id: peer.to_string(),
                    zero_id: self.known_peers.get(&peer).map(|p| p.zero_id.clone()),
                    addresses: self.known_peers.get(&peer)
                        .map(|p| p.addresses.iter().map(|a| a.to_string()).collect())
                        .unwrap_or_default(),
                })
            }

            SwarmEvent::Behaviour(ZeroEvent::Identify(identify::Event::Received {
                peer_id,
                info,
            })) => {
                let mut addrs = info.listen_addrs.clone();
                if Self::is_address_routable(&addrs) {
                    for addr in &addrs {
                        self.swarm
                            .behaviour_mut()
                            .kademlia
                            .add_address(&peer_id, addr.clone());
                    }
                }

                let zero_id = info.agent_version.clone();

                let peer = KnownPeer {
                    peer_id,
                    zero_id: zero_id.clone(),
                    addresses: addrs.clone(),
                    last_seen: std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap()
                        .as_secs(),
                    connected: true,
                };

                if !zero_id.is_empty() && zero_id != "unknown" {
                    self.zero_id_to_peer_id.insert(zero_id.clone(), peer_id);
                }
                self.known_peers.insert(peer_id, peer);

                Some(P2PEvent::PeerDiscovered {
                    peer_id: peer_id.to_string(),
                    zero_id: Some(zero_id),
                    addresses: addrs.iter().map(|a| a.to_string()).collect(),
                })
            }

            SwarmEvent::Behaviour(ZeroEvent::Autonat(
                autonat::Event::StatusChanged { old: _, new },
            )) => {
                self.nat_status = match new {
                    autonat::NatStatus::Public(_) => NatStatus::Public,
                    autonat::NatStatus::Private => NatStatus::Private,
                    autonat::NatStatus::Unknown => NatStatus::Unknown,
                };
                Some(P2PEvent::NatStatusChanged {
                    status: self.nat_status.clone(),
                })
            }

            SwarmEvent::NewListenAddr { address, .. } => {
                if Self::is_address_routable(&[address.clone()]) {
                    self.external_addresses.push(address.clone());
                    self.swarm
                        .behaviour_mut()
                        .kademlia
                        .add_address(&self.local_peer_id, address);
                }
                None
            }

            SwarmEvent::ConnectionEstablished { peer_id, .. } => {
                self.connected_peers.insert(peer_id);
                self.swarm
                    .behaviour_mut()
                    .kademlia
                    .set_mode(Some(Mode::Server));

                self._announce_network_ready();

                Some(P2PEvent::PeerConnected {
                    peer_id: peer_id.to_string(),
                    zero_id: self.known_peers.get(&peer_id).map(|p| p.zero_id.clone()),
                })
            }

            SwarmEvent::ConnectionClosed { peer_id, .. } => {
                self.connected_peers.remove(&peer_id);
                if self.connected_peers.is_empty() {
                    self.swarm
                        .behaviour_mut()
                        .kademlia
                        .set_mode(Some(Mode::Client));
                }
                Some(P2PEvent::PeerDisconnected {
                    peer_id: peer_id.to_string(),
                })
            }

            _ => None,
        }
    }

    fn handle_gossipsub_message(
        &mut self,
        _from_peer: PeerId,
        topic: &str,
        data: &[u8],
    ) -> Option<P2PEvent> {
        if data.len() < 9 {
            return None;
        }

        let header = DirectMessageHeader::deserialize(&data[..9]);
        let encrypted_content = data[9..].to_vec();

        if topic.starts_with(DM_TOPIC_PREFIX) {
            Some(P2PEvent::DirectMessage {
                from_peer_id: _from_peer.to_string(),
                from_zero_id: Some(header.sender_zero_id),
                encrypted_content,
                timestamp: header.timestamp,
            })
        } else if topic == SPACE_TOPIC {
            Some(P2PEvent::SpacePost {
                from_peer_id: _from_peer.to_string(),
                from_zero_id: Some(header.sender_zero_id),
                encrypted_content,
                timestamp: header.timestamp,
                topic: SPACE_TOPIC.to_string(),
            })
        } else if topic.starts_with(GROUP_TOPIC_PREFIX) {
            let group_id = topic.strip_prefix(GROUP_TOPIC_PREFIX).unwrap_or("unknown");
            Some(P2PEvent::GroupMessage {
                from_peer_id: _from_peer.to_string(),
                group_id: group_id.to_string(),
                encrypted_content,
                timestamp: header.timestamp,
            })
        } else {
            None
        }
    }

    fn is_address_routable(addrs: &[Multiaddr]) -> bool {
        addrs.iter().any(|addr| {
            let addr_str = addr.to_string();
            !addr_str.starts_with("/ip4/127.")
                && !addr_str.starts_with("/ip6/::1")
                && !addr_str.starts_with("/ip4/192.168.")
                && !addr_str.starts_with("/ip4/10.")
                && !addr_str.starts_with("/ip4/172.16.")
                && !addr_str.starts_with("/ip4/172.17.")
                && !addr_str.starts_with("/ip4/172.18.")
                && !addr_str.starts_with("/ip4/172.19.")
                && !addr_str.starts_with("/ip4/172.20.")
                && !addr_str.starts_with("/ip4/172.21.")
                && !addr_str.starts_with("/ip4/172.22.")
                && !addr_str.starts_with("/ip4/172.23.")
                && !addr_str.starts_with("/ip4/172.24.")
                && !addr_str.starts_with("/ip4/172.25.")
                && !addr_str.starts_with("/ip4/172.26.")
                && !addr_str.starts_with("/ip4/172.27.")
                && !addr_str.starts_with("/ip4/172.28.")
                && !addr_str.starts_with("/ip4/172.29.")
                && !addr_str.starts_with("/ip4/172.30.")
                && !addr_str.starts_with("/ip4/172.31.")
        })
    }

    fn _announce_network_ready(&self) {
        let _ = self.event_sender.send(P2PEvent::NetworkReady {
            peer_id: self.local_peer_id.to_string(),
            external_addrs: self.external_addresses.iter().map(|a| a.to_string()).collect(),
            nat_status: format!("{:?}", self.nat_status),
        });
    }

    pub fn find_peer_by_zero_id(&self, zero_id: &str) -> Option<&KnownPeer> {
        self.zero_id_to_peer_id
            .get(zero_id)
            .and_then(|pid| self.known_peers.get(pid))
    }

    pub fn connected_peer_count(&self) -> usize {
        self.connected_peers.len()
    }

    pub fn nat_status(&self) -> &NatStatus {
        &self.nat_status
    }

    pub fn local_peer_id(&self) -> &PeerId {
        &self.local_peer_id
    }
}

struct DirectMessageHeader {
    sender_zero_id: String,
    timestamp: u64,
    msg_type: u8,
}

impl DirectMessageHeader {
    fn serialize(&self) -> Vec<u8> {
        let mut v = Vec::with_capacity(9);
        v.push(self.msg_type);
        v.extend_from_slice(&self.timestamp.to_be_bytes());
        v
    }

    fn deserialize(data: &[u8]) -> Self {
        let msg_type = data[0];
        let timestamp = u64::from_be_bytes(data[1..9].try_into().unwrap());
        Self {
            sender_zero_id: String::new(),
            timestamp,
            msg_type,
        }
    }
}

use std::hash::{DefaultHasher, Hash, Hasher};