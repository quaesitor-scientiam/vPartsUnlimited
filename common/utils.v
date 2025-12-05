module common

import compress.szip
import encoding.xml
import math { divide_floored }
import os
import logging { log_error, set_output_file }

pub fn extract_catalog(fp string) !string {
	mut size := 0
	mut tmp_str := ''
	if fp != '' {
		mut zf := szip.open(fp, szip.CompressionLevel.best_speed, szip.OpenMode.read_only)!
		unsafe {
			zf.open_entry_by_index(0)!
			size = int(zf.size())

			// allocate the memory
			buf := malloc(zf.size())
			zf.read_entry_buf(buf, size)!
			buf[size] = 0
			tmp_str = tos(buf, size)
			zf.close_entry()
		}
		zf.close()
	}
	return tmp_str
}

pub fn get_tag_value(part xml.XMLNode, tag_name string) string {
	mut contents := ''
	node := part.get_elements_by_tag(tag_name)
	if node.len > 0 {
		if node[0].children.len > 0 {
			contents = node[0].children[0] as string
		}
	}

	return contents
}

pub fn make_chunks(mut data []xml.XMLNode, size int) [][]xml.XMLNode {
	chunk := divide_floored(data.len, size).quot
	mut results := [][]xml.XMLNode{cap: chunk}
	for data.len > chunk {
		results << data[..chunk]
		data = unsafe{ data[chunk..] }
		if (size - results.len) == 1 {
			break
		}
	}
	results << data[..chunk]
	return results
}

pub fn setup_logging(keep_log bool) {
	if !os.exists(logging_path) {
		os.mkdir_all(logging_path) or {
			log_error('Failure to setup logging path ${logging_path} with error ${err.code()}',
				1, module_name, '')
			exit(1)
		}
	}
	logfile := os.join_path_single(logging_path, logfile_name)
	if !keep_log {
		if os.exists(logfile) {
			os.rm(logfile) or {
				eprintln('Unable to remove logfile: ${logfile} resulted in Error: ${err.code()}')
				exit(1)
			}
		}
	}
	set_output_file(logfile)
}

pub fn reset_database() {
	if !production_run {
		if os.exists(backup_dbfpath) {
			os.cp(backup_dbfpath, db_fpath) or {
				error_log('Unabled to copy backup db at f${backup_dbfpath} to current at ${db_fpath} with error: ${err.code()}', 2, '')
				exit(1)
			}
		}
	} else {
		if os.exists(db_fpath) {
			os.cp(db_fpath, backup_dbfpath) or {
				error_log('Unabled to copy db at f${db_fpath} to current at ${backup_dbfpath} with error: ${err.code()}', 2, '')
				exit(1)
			}
		}
	}
}