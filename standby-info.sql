select database_role, db_unique_name INSTANCE, open_mode, protection_mode, protection_level, switchover_status
FROM v$database;