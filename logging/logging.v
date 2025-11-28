module logging

import log { ThreadSafeLog }
import strings

__global (
	logger ThreadSafeLog
)

fn init() {
	logger.set_level(.info)
	logger.set_custom_time_format('M/D/YYYY HH:mm:ss A')
	logger.set_local_time(true)
}

pub fn log_info(msg string, level int, module_name string, thread_name string) {
	space := strings.repeat_string('  ', level)
	logger.info('${module_name:-10} ${thread_name:-15} ${space}${msg}')
	logger.flush()
}

pub fn log_error(msg string, level int, module_name string, thread_name string) {
	space := strings.repeat_string('  ', level)
	logger.error('${module_name:-10} ${thread_name:-15} ${space}${msg}')
	logger.flush()
}

pub fn set_output_file(path string) {
	logger.set_output_path(path)
}
