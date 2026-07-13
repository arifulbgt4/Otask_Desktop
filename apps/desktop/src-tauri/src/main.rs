#[allow(dead_code)]
mod device_keys;
#[allow(dead_code)]
mod secure_settings;

use otask_service::LOCAL_IPC_PROTOCOL;

fn main() {
    println!("OTask desktop native shell bootstrap ({LOCAL_IPC_PROTOCOL})");
}
