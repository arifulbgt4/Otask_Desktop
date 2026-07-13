use std::collections::BTreeMap;

pub const CREDENTIAL_GET_COMMAND: &str = "credential_get";
pub const CREDENTIAL_SET_COMMAND: &str = "credential_set";
pub const CREDENTIAL_DELETE_COMMAND: &str = "credential_delete";

#[derive(Debug, PartialEq, Eq)]
pub enum CredentialError {
    InvalidName,
    EmptyValue,
    ValueTooLarge,
}

pub trait CredentialStore {
    fn get(&self, name: &str) -> Result<Option<String>, CredentialError>;
    fn set(&mut self, name: &str, value: &str) -> Result<(), CredentialError>;
    fn delete(&mut self, name: &str) -> Result<(), CredentialError>;
}

#[derive(Default)]
pub struct MemoryCredentialStore {
    values: BTreeMap<String, String>,
}

fn valid_name(name: &str) -> bool {
    matches!(
        name,
        "auth.accessToken" | "auth.refreshToken" | "device.privateKey"
    )
}

fn validate_value(value: &str) -> Result<(), CredentialError> {
    if value.is_empty() {
        return Err(CredentialError::EmptyValue);
    }
    if value.len() > 16_384 {
        return Err(CredentialError::ValueTooLarge);
    }
    Ok(())
}

impl CredentialStore for MemoryCredentialStore {
    fn get(&self, name: &str) -> Result<Option<String>, CredentialError> {
        if !valid_name(name) {
            return Err(CredentialError::InvalidName);
        }
        Ok(self.values.get(name).cloned())
    }

    fn set(&mut self, name: &str, value: &str) -> Result<(), CredentialError> {
        if !valid_name(name) {
            return Err(CredentialError::InvalidName);
        }
        validate_value(value)?;
        self.values.insert(name.to_owned(), value.to_owned());
        Ok(())
    }

    fn delete(&mut self, name: &str) -> Result<(), CredentialError> {
        if !valid_name(name) {
            return Err(CredentialError::InvalidName);
        }
        self.values.remove(name);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{CredentialError, CredentialStore, MemoryCredentialStore};

    #[test]
    fn allowlisted_memory_store_round_trips_and_deletes() {
        let mut store = MemoryCredentialStore::default();
        store.set("auth.accessToken", "token").unwrap();
        assert_eq!(
            store.get("auth.accessToken").unwrap().as_deref(),
            Some("token")
        );
        store.delete("auth.accessToken").unwrap();
        assert_eq!(store.get("auth.accessToken").unwrap(), None);
    }

    #[test]
    fn rejects_unknown_names_and_empty_or_oversized_values() {
        let mut store = MemoryCredentialStore::default();
        assert_eq!(
            store.get("settings.token"),
            Err(CredentialError::InvalidName)
        );
        assert_eq!(
            store.set("device.privateKey", ""),
            Err(CredentialError::EmptyValue)
        );
        assert_eq!(
            store.set("device.privateKey", &"x".repeat(16_385)),
            Err(CredentialError::ValueTooLarge)
        );
    }
}
