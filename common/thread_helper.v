module common

import time
import os
import encoding.xml
import logging { log_error, log_info }
import db.sqlite

pub fn process_dbcalls(tname string, input_ch chan SQLQuery) {
	info('Waiting for work', 3, tname)
	mut con := sqlite.connect_full(db_fpath, [.readwrite, .create, .nomutex], '') or {
		error_log('Database connection to ${db_fpath} failed with ${err.code()}', 3, tname)
		exit(1)
	}
	mut sqlparams := SQLQuery{}
	mut result := []sqlite.Row{}
	mut output_ch := chan SQLResults{}

	for {
		sqlparams = <-input_ch or {
			info('Nothing in Input Channel sleeping for 3 secs', 4, tname)
			time.sleep(3 * time.second)
			continue
		}
		sql_str := sqlparams.sql_str
		params := sqlparams.params
		output_ch = sqlparams.output
		info('Processing part ${params[1]}', 4, tname)
		if params.len == 1 {
			result = con.exec_param(sql_str, params[0]) or {
				error_log('Query: ${sql_str} with params ${params} resulted in Error: ${err.code()}',
					3, tname)
				exit(1)
			}
		}
		if params.len >= 2 {
			result = con.exec_param_many(sql_str, params) or {
				error_log('Query: ${sql_str} with params ${params} resulted in Error: ${err.code()}',
					3, tname)
				exit(1)
			}
		}
		con.commit() or { error_log('Commit failed with ${err.code()}', 3, tname) }
		output_ch <- SQLResults{
			rows: result
		}
	} // End for loop

	info('End of process_dbcalls()', 4, tname)
}

pub fn get_parts(tname string, parts []xml.XMLNode, parts_ch chan string, brand_name string, input_ch chan SQLQuery) int {
	info('Processing ${parts.len} parts', 3, tname)

	mut cnt_new := 0
	mut punctuated_part_number := ''
	mut part_image_url := ''
	mut product_image_url := ''
	mut value := ''
	output_ch := chan SQLResults{}

	for part in parts {
		mut fields_checked_cnt := 0
		value = get_tag_value(part, 'brandName')
		if value != brand_name {
			error_log('Brand name ${value} does not match expected ${brand_name}', 3,
				tname)
		}
		log_info('Part ${part}', 4, module_name, '')
		punctuated_part_number = get_tag_value(part, 'punctuatedPartNumber')
		part_image_url = get_tag_value(part, 'partImage')
		product_image_url = get_tag_value(part, 'productImage')
		info('Part number: ${punctuated_part_number}', 4, tname)

		if process_only_parts.len > 0 {
			if punctuated_part_number !in process_only_parts {
				continue
			}
		}

		mut part_status := 'SAME'

		// info('Sending SQL Query via input channel', 4, tname)
		input_ch <- SQLQuery{
			sql_str: 'SELECT ID FROM parts_unlimited WHERE brand_name == ? and part_number == ?'
			params:  [brand_name, punctuated_part_number]
			output:  output_ch
		}
		sqlresults := <-output_ch
		info('${punctuated_part_number} has ID:${sqlresults.rows[0].vals[0]}', 5, tname)
	}

	info('End of get_parts()', 4, tname)
	return cnt_new
}

fn info(msg string, level int, thread_name string) {
	log_info(msg, level, module_name, thread_name)
}

fn error_log(msg string, level int, thread_name string) {
	log_error(msg, level, module_name, thread_name)
}
