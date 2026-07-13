use std::fmt;
use std::sync::{Arc, Mutex};

pub const CRATE_NAME: &str = "otask-service";
pub const LOCAL_IPC_PROTOCOL: &str = "otask.local.v1";
pub const STATUS_METHOD: &str = "service.get_status";
pub const PING_METHOD: &str = "service.ping";
pub const RESTART_METHOD: &str = "service.restart";

/// The lifecycle states that are visible to the GUI and local IPC clients.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ServiceState {
    Stopped,
    Starting,
    Running,
    Stopping,
    Failed,
}

impl ServiceState {
    pub const fn is_running(self) -> bool {
        matches!(self, Self::Running)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ServiceSnapshot {
    pub state: ServiceState,
    pub generation: u64,
    pub accepted_requests: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ServiceError {
    InvalidTransition,
}

/// In-memory lifecycle owner. The production process can wrap this in
/// [`LocalIpcServer`] without replacing the state during a GUI restart.
#[derive(Debug)]
pub struct ServiceController {
    state: ServiceState,
    generation: u64,
    accepted_requests: u64,
}

impl Default for ServiceController {
    fn default() -> Self {
        Self::new()
    }
}

impl ServiceController {
    pub const fn new() -> Self {
        Self {
            state: ServiceState::Stopped,
            generation: 0,
            accepted_requests: 0,
        }
    }

    pub const fn snapshot(&self) -> ServiceSnapshot {
        ServiceSnapshot {
            state: self.state,
            generation: self.generation,
            accepted_requests: self.accepted_requests,
        }
    }

    pub fn start(&mut self) -> Result<ServiceSnapshot, ServiceError> {
        match self.state {
            ServiceState::Stopped | ServiceState::Failed => {
                self.state = ServiceState::Starting;
                self.state = ServiceState::Running;
                self.generation = self.generation.saturating_add(1);
                Ok(self.snapshot())
            }
            ServiceState::Running => Ok(self.snapshot()),
            ServiceState::Starting | ServiceState::Stopping => Err(ServiceError::InvalidTransition),
        }
    }

    pub fn stop(&mut self) -> Result<ServiceSnapshot, ServiceError> {
        match self.state {
            ServiceState::Stopped => Ok(self.snapshot()),
            ServiceState::Running | ServiceState::Failed => {
                self.state = ServiceState::Stopping;
                self.state = ServiceState::Stopped;
                Ok(self.snapshot())
            }
            ServiceState::Starting | ServiceState::Stopping => Err(ServiceError::InvalidTransition),
        }
    }

    /// Performs an orderly stop/start on the same controller. Durable service
    /// counters stay attached to the controller, so a GUI restart cannot
    /// silently replace the service state or lose accepted-request accounting.
    pub fn restart(&mut self) -> Result<ServiceSnapshot, ServiceError> {
        if matches!(self.state, ServiceState::Starting | ServiceState::Stopping) {
            return Err(ServiceError::InvalidTransition);
        }

        if self.state.is_running() || matches!(self.state, ServiceState::Failed) {
            self.state = ServiceState::Stopping;
            self.state = ServiceState::Stopped;
        }
        self.state = ServiceState::Starting;
        self.state = ServiceState::Running;
        self.generation = self.generation.saturating_add(1);
        Ok(self.snapshot())
    }

    fn record_request(&mut self) {
        self.accepted_requests = self.accepted_requests.saturating_add(1);
    }
}

/// A caller-provided high-entropy secret authenticates local IPC. The secret
/// is intentionally injected by the platform layer (secure storage or an
/// inherited private channel) rather than generated or persisted here.
#[derive(Clone)]
pub struct IpcAuthenticator {
    secret: Arc<[u8]>,
}

impl fmt::Debug for IpcAuthenticator {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("IpcAuthenticator(REDACTED)")
    }
}

impl IpcAuthenticator {
    pub fn new(secret: impl AsRef<[u8]>) -> Result<Self, IpcError> {
        let secret = secret.as_ref();
        if secret.is_empty() {
            return Err(IpcError::MissingAuthenticator);
        }
        Ok(Self {
            secret: Arc::from(secret.to_vec()),
        })
    }

    fn authorize(&self, candidate: &str) -> bool {
        constant_time_equal(&self.secret, candidate.as_bytes())
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IpcRequest {
    pub request_id: String,
    pub method: String,
    pub auth_token: String,
}

impl IpcRequest {
    pub fn new(
        request_id: impl Into<String>,
        method: impl Into<String>,
        auth_token: impl Into<String>,
    ) -> Self {
        Self {
            request_id: request_id.into(),
            method: method.into(),
            auth_token: auth_token.into(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IpcResponseStatus {
    Ok,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IpcResponse {
    pub request_id: String,
    pub status: IpcResponseStatus,
    pub body: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IpcError {
    MissingAuthenticator,
    Unauthorized,
    InvalidRequest,
    ServiceUnavailable,
    UnsupportedMethod,
}

/// Thread-safe local IPC boundary. Authentication happens before acquiring
/// the mutable service lock, and unauthorized requests never mutate state.
#[derive(Clone)]
pub struct LocalIpcServer {
    controller: Arc<Mutex<ServiceController>>,
    authenticator: IpcAuthenticator,
}

impl LocalIpcServer {
    pub fn new(controller: ServiceController, authenticator: IpcAuthenticator) -> Self {
        Self {
            controller: Arc::new(Mutex::new(controller)),
            authenticator,
        }
    }

    pub fn snapshot(&self) -> Result<ServiceSnapshot, IpcError> {
        self.controller
            .lock()
            .map(|controller| controller.snapshot())
            .map_err(|_| IpcError::ServiceUnavailable)
    }

    pub fn dispatch(&self, request: IpcRequest) -> Result<IpcResponse, IpcError> {
        if request.request_id.trim().is_empty() || request.method.trim().is_empty() {
            return Err(IpcError::InvalidRequest);
        }
        if !self.authenticator.authorize(&request.auth_token) {
            return Err(IpcError::Unauthorized);
        }

        let mut controller = self
            .controller
            .lock()
            .map_err(|_| IpcError::ServiceUnavailable)?;
        let body = match request.method.as_str() {
            STATUS_METHOD => format_snapshot(controller.snapshot()),
            PING_METHOD if controller.snapshot().state.is_running() => "pong".to_owned(),
            RESTART_METHOD => format_snapshot(
                controller
                    .restart()
                    .map_err(|_| IpcError::ServiceUnavailable)?,
            ),
            _ => return Err(IpcError::UnsupportedMethod),
        };
        controller.record_request();
        Ok(IpcResponse {
            request_id: request.request_id,
            status: IpcResponseStatus::Ok,
            body,
        })
    }
}

fn format_snapshot(snapshot: ServiceSnapshot) -> String {
    format!(
        "state={:?};generation={};accepted_requests={}",
        snapshot.state, snapshot.generation, snapshot.accepted_requests
    )
}

fn constant_time_equal(left: &[u8], right: &[u8]) -> bool {
    let max_len = left.len().max(right.len());
    let mut difference = (left.len() ^ right.len()) as u8;
    for index in 0..max_len {
        let left_byte = left.get(index).copied().unwrap_or_default();
        let right_byte = right.get(index).copied().unwrap_or_default();
        difference |= left_byte ^ right_byte;
    }
    difference == 0
}

#[cfg(test)]
mod tests {
    use super::{
        IpcAuthenticator, IpcError, IpcRequest, IpcResponseStatus, LocalIpcServer,
        ServiceController, ServiceState, PING_METHOD, RESTART_METHOD, STATUS_METHOD,
    };

    fn server() -> LocalIpcServer {
        LocalIpcServer::new(
            ServiceController::default(),
            IpcAuthenticator::new("test-local-secret").unwrap(),
        )
    }

    fn request(method: &str, token: &str) -> IpcRequest {
        IpcRequest::new("request-1", method, token)
    }

    #[test]
    fn lifecycle_restart_is_orderly_and_idempotent() {
        let mut controller = ServiceController::default();
        assert_eq!(controller.snapshot().state, ServiceState::Stopped);
        let first = controller.start().unwrap();
        assert_eq!(first.state, ServiceState::Running);
        assert_eq!(controller.start().unwrap(), first);
        let restarted = controller.restart().unwrap();
        assert_eq!(restarted.state, ServiceState::Running);
        assert_eq!(restarted.generation, first.generation + 1);
        assert_eq!(controller.stop().unwrap().state, ServiceState::Stopped);
    }

    #[test]
    fn unauthorized_local_client_is_rejected_without_state_change() {
        let server = server();
        let before = server.snapshot().unwrap();
        assert_eq!(
            server.dispatch(request(STATUS_METHOD, "wrong-secret")),
            Err(IpcError::Unauthorized)
        );
        assert_eq!(server.snapshot().unwrap(), before);
    }

    #[test]
    fn authenticated_ipc_can_restart_and_report_status() {
        let server = server();
        let restart = server
            .dispatch(request(RESTART_METHOD, "test-local-secret"))
            .unwrap();
        assert_eq!(restart.status, IpcResponseStatus::Ok);
        assert!(restart.body.contains("state=Running"));
        let ping = server
            .dispatch(request(PING_METHOD, "test-local-secret"))
            .unwrap();
        assert_eq!(ping.body, "pong");
        let status = server
            .dispatch(request(STATUS_METHOD, "test-local-secret"))
            .unwrap();
        assert!(status.body.contains("accepted_requests=2"));
    }

    #[test]
    fn authenticator_rejects_empty_secret_and_compares_full_length() {
        assert!(matches!(
            IpcAuthenticator::new(""),
            Err(IpcError::MissingAuthenticator)
        ));
        let server = LocalIpcServer::new(
            ServiceController::default(),
            IpcAuthenticator::new("abc").unwrap(),
        );
        assert_eq!(
            server.dispatch(request(STATUS_METHOD, "abc-extra")),
            Err(IpcError::Unauthorized)
        );
    }
}
