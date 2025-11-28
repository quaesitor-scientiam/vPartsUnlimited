module common

import os
import db.sqlite

pub const module_name = 'common'
pub const logfile_name = 'PartsUnlimited.log'

pub const db_name = 'parts_unlimited.db'
pub const project_path = os.getwd()
pub const data_path = os.join_path_single(project_path, 'data')
pub const download_path = os.join_path_single(data_path, 'downloads')
pub const db_path = os.join_path_single(project_path, 'database')
pub const db_fpath = os.join_path_single(db_path, db_name)
pub const db_backup_path = os.join_path_single(db_path, 'backup')
pub const backup_dbfpath = os.join_path_single(db_backup_path, db_name)
pub const logging_path = os.join_path_single(project_path, 'logs')

pub const process_only_brands = ['100%']
pub const process_only_parts = []string{}
pub const skip_brands = []string{}

pub struct SQLQuery {
	sql_str string
	params  []string
	output  chan SQLResults
}

pub struct SQLResults {
	rows []sqlite.Row
}
