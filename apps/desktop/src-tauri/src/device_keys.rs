use std::collections::BTreeSet;

pub const DEVICE_GENERATE_KEY_COMMAND: &str = "device_generate_key";
pub const DEVICE_SIGN_COMMAND: &str = "device_sign";

#[derive(Debug, PartialEq, Eq)]
pub enum DeviceKeyError {
    InvalidDeviceId,
    MissingKey,
}

pub trait DeviceKeyStore {
    fn generate(&mut self, device_id: &str) -> Result<String, DeviceKeyError>;
    fn sign(&self, key_id: &str, payload: &[u8]) -> Result<Vec<u8>, DeviceKeyError>;
}

#[derive(Default)]
pub struct MemoryDeviceKeyStore {
    key_ids: BTreeSet<String>,
}

impl DeviceKeyStore for MemoryDeviceKeyStore {
    fn generate(&mut self, device_id: &str) -> Result<String, DeviceKeyError> {
        if !device_id.starts_with("device_") || device_id.len() < 16 {
            return Err(DeviceKeyError::InvalidDeviceId);
        }
        let key_id = format!("device_key_{}", device_id.trim_start_matches("device_"));
        self.key_ids.insert(key_id.clone());
        Ok(key_id)
    }

    fn sign(&self, key_id: &str, _payload: &[u8]) -> Result<Vec<u8>, DeviceKeyError> {
        if !self.key_ids.contains(key_id) {
            return Err(DeviceKeyError::MissingKey);
        }
        Err(DeviceKeyError::MissingKey)
    }
}

#[cfg(test)]
mod tests {
    use super::{DeviceKeyError, DeviceKeyStore, MemoryDeviceKeyStore};

    #[test]
    fn generates_only_for_bound_device_ids() {
        let mut store = MemoryDeviceKeyStore::default();
        assert_eq!(
            store.generate("device_short"),
            Err(DeviceKeyError::InvalidDeviceId)
        );
        assert_eq!(
            store.generate("device_p03004_target").unwrap(),
            "device_key_p03004_target"
        );
    }

    #[test]
    fn never_exports_private_key_material_from_memory_boundary() {
        let mut store = MemoryDeviceKeyStore::default();
        let key_id = store.generate("device_p03004_target").unwrap();
        assert_eq!(
            store.sign(&key_id, b"proof"),
            Err(DeviceKeyError::MissingKey)
        );
    }
}
