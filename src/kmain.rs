#![feature(panic_info_message)]
#![no_main]
#![no_std]

/// Logging code
#[macro_use]
mod dbg;

// Achitecture-specific modules
#[cfg(target_arch="x86_64")] #[path="arch/amd64/mod.rs"]
pub mod arch;
#[cfg(target_arch="x86")] #[path="arch/x86/mod.rs"]
pub mod arch;

/// Exception handling (panic)
pub mod unwind;

// Kernel entrypoint
#[no_mangle]
pub fn kernel_main() {
    dbgln!("Hello World!");

    #[cfg(test)]
    test_main();

    loop {}
}
