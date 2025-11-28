module main

import os
import encoding.xml
import db.sqlite
import logging { log_info }
import common { extract_catalog, get_parts, process_dbcalls, setup_logging }

fn process_parts(mut parts []xml.XMLNode, brand_name string, mut con sqlite.DB, parts_ch chan string, input_ch chan common.SQLQuery) !int {
	mut result := []sqlite.Row{}
	result = con.exec_param('SELECT brand_name FROM brands WHERE pu_brand_name == ?',
		brand_name) or {
		eprintln('Select on Brand: ${brand_name} resulted in Error: ${err.code()}')
		exit(1)
	}
	// Brand Name not found
	if result.len == 0 {
		result = con.exec_param_many('INSERT into Brands values(?, ?, ?, ?)', [
			brand_name,
			'',
			brand_name,
			'NEW',
		]) or {
			eprintln('Insert of new Brand: ${brand_name} resulted in Error: ${err.code()}')
			exit(1)
		}
		con.commit()!
	}
	con.close()!

	mut threads := 2
	if parts.len > 1000 {
		threads = 3
	}
	chunks := common.make_chunks(mut parts, threads)

	// Setup Brand
	mut tlist := []thread int{}
	for i in 1 .. threads + 1 {
		tname := 'BrandWorker_${i}'
		tlist << spawn get_parts(tname, chunks[i - 1], parts_ch, brand_name, input_ch)
	}
	tlist.wait()

	log_info('Exiting processing_parts()', 3, module_name, '')
	return 0
}

fn main() {
	setup_logging(false)
	log_info('PartsUnlimited Processing has started', 1, module_name, '')
	log_info('Download Path: ${common.download_path}', 2, module_name, '')
	input_ch := chan common.SQLQuery{cap: 100}
	spawn process_dbcalls('DBHandler', input_ch)

	mut con := sqlite.connect(common.db_fpath)!

	catalogs := os.walk_ext(common.download_path, '.zip')
	for fpath in catalogs {
		data := extract_catalog(fpath)!
		doc := xml.XMLDocument.from_string(data)!
		mut allparts := doc.get_elements_by_tag('part')
		brand_name := common.get_tag_value(allparts[0], 'brandName')
		if brand_name !in common.process_only_brands {
			continue
		} else if brand_name in common.skip_brands {
			continue
		}

		total_parts := allparts.len
		log_info('Processing Brand ${brand_name} consisting of ${total_parts} parts',
			2, module_name, '')

		parts_ch := chan string{cap: total_parts}

		cnt_new := process_parts(mut allparts, brand_name, mut con, parts_ch, input_ch)!
		log_info('Exiting Catalog loop', 3, module_name, '')
		break
	}
}
