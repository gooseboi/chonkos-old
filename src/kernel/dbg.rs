use core::sync::atomic;
use core::fmt;

/// A formatter object
pub struct Writer(bool);

/// A primitive lock for the logging output
///
/// This is not really a lock. Since there is no threading at the moment, all
/// it does is prevent writing when a collision would occur.
static LOGGING_LOCK: atomic::AtomicBool = atomic::AtomicBool::new(false);

impl Writer {
	/// Obtain a logger for the specified module
	pub fn get(module: &str) -> Writer {
		// This "acquires" the lock (actually just disables output if parallel writes are attempted)
		let mut ret = Writer(!LOGGING_LOCK.swap(true, atomic::Ordering::Acquire));
		
		// Print the module name before returning (prefixes all messages)
		{
			use core::fmt::Write;
			let _ = write!(&mut ret, "[{}] ", module);
		}
		ret
	}
}

impl ::core::ops::Drop for Writer {
	fn drop(&mut self) {
		// Write a terminating newline before releasing the lock
		{
			use core::fmt::Write;
			let _ = write!(self, "\n");
		}
		// On drop, "release" the lock
		if self.0 {
			LOGGING_LOCK.store(false, atomic::Ordering::Release);
		}
	}
}

impl fmt::Write for Writer {
	fn write_str(&mut self, s: &str) -> fmt::Result
	{
		// If the lock is owned by this instance, then we can safely write to the output
		if self.0 {
			unsafe { ::arch::debug::puts( s ); }
		}
        Ok(())
	}
}

/// A very primitive logging macro
///
/// Obtaines a logger instance (locking the log channel) with the current module name passed
/// then passes the standard format! arguments to it
macro_rules! dbgln {
	( $($arg:tt)* ) => {{
		// Import the Writer trait (required by write!)
		use core::fmt::Write;
		let _ = write!(&mut ::dbg::Writer::get(module_path!()), $($arg)*);
	}}
}

