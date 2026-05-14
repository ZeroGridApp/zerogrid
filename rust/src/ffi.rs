use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Mutex;

use once_cell::sync::Lazy;

use crate::crypto::E2EESessionManager;
use crate::identity::ZeroIdentity;
use crate::p2p::ZeroP2PNetwork;
use crate::wallet::MultiChainWallet;

static ZERO_CORE: Lazy<Mutex<Option<ZeroCore>>> = Lazy::new(|| Mutex::new(None));
static LAST_ERROR: Lazy<Mutex<Option<String>>> = Lazy::new(|| Mutex::new(None));

pub const ZERO_OK: i32 = 0;
pub const ZERO_ERR_NOT_INITIALIZED: i32 = -1;
pub const ZERO_ERR_INVALID_MNEMONIC: i32 = -2;
pub const ZERO_ERR_ENCRYPT_FAILED: i32 = -3;
pub const ZERO_ERR_DECRYPT_FAILED: i32 = -4;
pub const ZERO_ERR_NO_SESSION: i32 = -5;
pub const ZERO_ERR_INTERNAL: i32 = -6;
pub const ZERO_ERR_INVALID_ARG: i32 = -7;

pub struct ZeroCore {
    pub identity: ZeroIdentity,
    pub e2ee: E2EESessionManager,
    pub wallet: MultiChainWallet,
    pub network: Option<ZeroP2PNetwork>,
    pub wallet_addresses: Vec<crate::wallet::WalletAddress>,
}

fn set_last_error(msg: String) {
    let mut guard = LAST_ERROR.lock().unwrap();
    *guard = Some(msg);
}

fn clear_last_error() {
    let mut guard = LAST_ERROR.lock().unwrap();
    *guard = None;
}

impl ZeroCore {
    pub fn initialize(mnemonic: &str) -> Result<(), String> {
        let mnemonic_parsed = bip39::Mnemonic::parse(mnemonic)
            .map_err(|e| format!("Invalid mnemonic: {}", e))?;

        let identity = ZeroIdentity::from_mnemonic(mnemonic_parsed)
            .map_err(|e| format!("Identity failed: {}", e))?;

        let seed_32: [u8; 32] = identity.seed[..32]
            .try_into()
            .map_err(|_| "Seed conversion failed".to_string())?;

        let e2ee = E2EESessionManager::new(&seed_32);

        let wallet = MultiChainWallet::new(identity.clone());
        let wallet_addresses = wallet
            .derive_addresses()
            .map_err(|e| format!("Wallet derivation failed: {}", e))?;

        let core = ZeroCore {
            identity,
            e2ee,
            wallet,
            network: None,
            wallet_addresses,
        };

        let mut guard = ZERO_CORE.lock().unwrap();
        *guard = Some(core);

        Ok(())
    }

    pub fn get_zero_id() -> Result<String, String> {
        let guard = ZERO_CORE.lock().unwrap();
        match guard.as_ref() {
            Some(core) => Ok(core.identity.zero_id().to_string()),
            None => Err("Not initialized".to_string()),
        }
    }

    pub fn get_wallet_addresses() -> Result<String, String> {
        let guard = ZERO_CORE.lock().unwrap();
        match guard.as_ref() {
            Some(core) => serde_json::to_string(&core.wallet_addresses)
                .map_err(|e| format!("Serialization error: {}", e)),
            None => Err("Not initialized".to_string()),
        }
    }

    pub fn encrypt_for_peer(peer_zero_id: &str, plaintext: &str) -> Result<Vec<u8>, String> {
        let mut guard = ZERO_CORE.lock().unwrap();
        match guard.as_mut() {
            Some(core) => core
                .e2ee
                .encrypt_message(peer_zero_id, plaintext.as_bytes())
                .map(|msg| msg.ciphertext)
                .map_err(|e| format!("Encrypt failed: {}", e)),
            None => Err("Not initialized".to_string()),
        }
    }

    pub fn decrypt_from_peer(peer_zero_id: &str, ciphertext: &[u8]) -> Result<String, String> {
        let mut guard = ZERO_CORE.lock().unwrap();
        match guard.as_mut() {
            Some(core) => {
                let plaintext = core
                    .e2ee
                    .decrypt_message(peer_zero_id, ciphertext)
                    .map_err(|e| format!("Decrypt failed: {}", e))?;
                String::from_utf8(plaintext).map_err(|e| format!("UTF-8 error: {}", e))
            }
            None => Err("Not initialized".to_string()),
        }
    }
}

pub fn initialize_core(mnemonic: &str) -> Result<(), String> {
    ZeroCore::initialize(mnemonic)
}

pub fn get_zero_id() -> Result<String, String> {
    ZeroCore::get_zero_id()
}

pub fn get_wallet_addresses_json() -> Result<String, String> {
    ZeroCore::get_wallet_addresses()
}

pub fn encrypt_message(peer_id: &str, plaintext: &str) -> Result<Vec<u8>, String> {
    ZeroCore::encrypt_for_peer(peer_id, plaintext)
}

pub fn decrypt_message(peer_id: &str, ciphertext: Vec<u8>) -> Result<String, String> {
    ZeroCore::decrypt_from_peer(peer_id, &ciphertext)
}

fn c_str_to_string(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr) }.to_str().ok().map(|s| s.to_string())
}

fn string_to_c(s: String) -> *mut c_char {
    CString::new(s).unwrap_or_default().into_raw()
}

#[no_mangle]
pub extern "C" fn zero_initialize(mnemonic: *const c_char) -> i32 {
    let mnemonic_str = match c_str_to_string(mnemonic) {
        Some(s) => s,
        None => {
            set_last_error("null mnemonic pointer".to_string());
            return ZERO_ERR_INVALID_ARG;
        }
    };

    match ZeroCore::initialize(&mnemonic_str) {
        Ok(()) => {
            clear_last_error();
            ZERO_OK
        }
        Err(e) => {
            set_last_error(e);
            ZERO_ERR_INVALID_MNEMONIC
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_generate_mnemonic(out_mnemonic: *mut *mut c_char) -> i32 {
    if out_mnemonic.is_null() {
        set_last_error("null output pointer".to_string());
        return ZERO_ERR_INVALID_ARG;
    }

    match crate::identity::generate_mnemonic_phrase() {
        Ok(phrase) => {
            unsafe { *out_mnemonic = string_to_c(phrase) };
            clear_last_error();
            ZERO_OK
        }
        Err(e) => {
            set_last_error(format!("{}", e));
            ZERO_ERR_INTERNAL
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_get_id(out_id: *mut *mut c_char) -> i32 {
    if out_id.is_null() {
        set_last_error("null output pointer".to_string());
        return ZERO_ERR_INVALID_ARG;
    }

    match ZeroCore::get_zero_id() {
        Ok(id) => {
            unsafe { *out_id = string_to_c(id) };
            clear_last_error();
            ZERO_OK
        }
        Err(e) => {
            set_last_error(e);
            ZERO_ERR_NOT_INITIALIZED
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_validate_mnemonic(mnemonic: *const c_char) -> i32 {
    let mnemonic_str = match c_str_to_string(mnemonic) {
        Some(s) => s,
        None => return 0,
    };

    if crate::identity::mnemonic_validate(&mnemonic_str) {
        1
    } else {
        0
    }
}

#[no_mangle]
pub extern "C" fn zero_encrypt(
    peer_id: *const c_char,
    plaintext: *const u8,
    plaintext_len: u32,
    out_ciphertext: *mut *mut u8,
    out_len: *mut u32,
) -> i32 {
    let peer_id_str = match c_str_to_string(peer_id) {
        Some(s) => s,
        None => {
            set_last_error("null peer_id pointer".to_string());
            return ZERO_ERR_INVALID_ARG;
        }
    };

    if plaintext.is_null() || out_ciphertext.is_null() || out_len.is_null() {
        set_last_error("null argument pointer".to_string());
        return ZERO_ERR_INVALID_ARG;
    }

    let plaintext_slice = unsafe { std::slice::from_raw_parts(plaintext, plaintext_len as usize) };
    let plaintext_str = match std::str::from_utf8(plaintext_slice) {
        Ok(s) => s,
        Err(e) => {
            set_last_error(format!("invalid utf-8: {}", e));
            return ZERO_ERR_INVALID_ARG;
        }
    };

    match ZeroCore::encrypt_for_peer(&peer_id_str, plaintext_str) {
        Ok(ciphertext) => {
            let len = ciphertext.len() as u32;
            let buf = ciphertext.leak();
            unsafe {
                *out_ciphertext = buf.as_mut_ptr();
                *out_len = len;
            }
            clear_last_error();
            ZERO_OK
        }
        Err(e) => {
            set_last_error(e);
            ZERO_ERR_ENCRYPT_FAILED
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_decrypt(
    peer_id: *const c_char,
    ciphertext: *const u8,
    ciphertext_len: u32,
    out_plaintext: *mut *mut c_char,
) -> i32 {
    let peer_id_str = match c_str_to_string(peer_id) {
        Some(s) => s,
        None => {
            set_last_error("null peer_id pointer".to_string());
            return ZERO_ERR_INVALID_ARG;
        }
    };

    if ciphertext.is_null() || out_plaintext.is_null() {
        set_last_error("null argument pointer".to_string());
        return ZERO_ERR_INVALID_ARG;
    }

    let ciphertext_slice =
        unsafe { std::slice::from_raw_parts(ciphertext, ciphertext_len as usize) };

    match ZeroCore::decrypt_from_peer(&peer_id_str, ciphertext_slice) {
        Ok(plaintext) => {
            unsafe { *out_plaintext = string_to_c(plaintext) };
            clear_last_error();
            ZERO_OK
        }
        Err(e) => {
            set_last_error(e);
            ZERO_ERR_DECRYPT_FAILED
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_last_error(out_error: *mut *mut c_char) -> i32 {
    if out_error.is_null() {
        return ZERO_ERR_INVALID_ARG;
    }

    let guard = LAST_ERROR.lock().unwrap();
    match guard.as_ref() {
        Some(err) => {
            unsafe { *out_error = string_to_c(err.clone()) };
            1
        }
        None => {
            unsafe { *out_error = std::ptr::null_mut() };
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_free_bytes(data: *mut u8, len: u32) {
    if !data.is_null() && len > 0 {
        unsafe {
            let _ = Vec::from_raw_parts(data, len as usize, len as usize);
        }
    }
}

#[no_mangle]
pub extern "C" fn zero_identity_public_key_hex(out_key: *mut *mut c_char) -> i32 {
    if out_key.is_null() {
        return ZERO_ERR_INVALID_ARG;
    }

    let guard = ZERO_CORE.lock().unwrap();
    match guard.as_ref() {
        Some(core) => {
            let key_hex = core.identity.public_key_hex();
            unsafe { *out_key = string_to_c(key_hex) };
            ZERO_OK
        }
        None => {
            set_last_error("Not initialized".to_string());
            ZERO_ERR_NOT_INITIALIZED
        }
    }
}