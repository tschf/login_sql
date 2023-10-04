-- Logger Related
alias logger_debug_on=begin
update logger_prefs set pref_value='DEBUG' where pref_name='LOG_LEVEL';
commit;
end;
/

alias logger_debug_off=begin
update logger_prefs set pref_value='ERROR' where pref_name='LOG_LEVEL';
commit;
end;
/

alias logger_prefs=select pref_name, pref_value from logger_prefs;
alias logger_pref_level=select pref_name, pref_value from logger_prefs where pref_name = 'LOG_LEVEL';

-- COMMON
alias dbusers=select username, created from all_users where oracle_maintained = 'N' order by 1;
alias dbusersf=select username, created from all_users where oracle_maintained = 'N' and username like '%'||upper(:input)||'%' order by 1;
alias desc2=select
    column_name "Name",
    case when nullable = 'N' then 'NOT NULL' end "Nullable?",
    data_type || case when char_col_decl_length is not null then '(' || char_col_decl_length || ')' end "Type"
from all_tab_cols
where owner = sys_context('USERENV','CURRENT_SCHEMA')
and table_name = upper(:table_name)
order by internal_column_id;

-- Query to find FK's without an index. Adapted from Rich Soule:
-- https://carsandcode.com/2023/09/01/finding-unindexed-foreign-keys-in-oracle-now-with-index-creation-ddl/
alias fkindexes=with owner_exclusion_list as (
  select username from all_users where oracle_maintained ='Y'
  union all select 'ORDS_METADATA' from dual
  union all select 'ORDS_PUBLIC_USER' from dual
  union all select 'ORDS_PUBLIC_USER2' from dual
), constraint_columns as (
  select
    owner,
    table_name,
    constraint_name,
    listagg(column_name, ', ') within group(order by position) as constraint_column_list
  from all_cons_columns
  join all_constraints using (owner, table_name, constraint_name)
  where
    constraint_type = 'R' -- R = Referential Foreign Key Constraint
    and owner not in (
      select username from owner_exclusion_list
    )
  group by owner, table_name, constraint_name
), index_columns as (
  select
    index_owner owner,
    table_name,
    index_name,
    listagg(column_name, ', ') within group(order by column_position) as index_column_list
  from all_ind_columns
  where index_owner not in (select * from owner_exclusion_list)
  group by index_owner, table_name, index_name
), foreign_key_index_query as (
  select
    decode(ic.table_name, null, 'Missing', 'Exists') as index_existence,
    cc.owner as table_owner,
    cc.table_name,
    constraint_name as foreign_key_name,
    constraint_column_list as foreign_key_column_list,
    index_name,
    index_column_list,
    decode(ic.table_name, null, 'create index '||lower(cc.table_name)||'_idxN'||' on "'||
                                  cc.owner || '"."'||cc.table_name||'"("'||
                                  replace(replace(constraint_column_list,',','","'),' ')||'");'
                                , null ) as create_index_ddl
  from constraint_columns cc
  join all_tables dbat on (
    dbat.owner = cc.owner
    and dbat.table_name = cc.table_name
  )
  left join index_columns ic on (
    cc.owner = ic.owner
    and cc.table_name = ic.table_name
    and ic.index_column_list like cc.constraint_column_list || '%'
  )
)
select
  table_owner,
  table_name,
  foreign_key_name,
  index_existence,
  foreign_key_column_list,
  index_name,
  index_column_list,
  create_index_ddl
from foreign_key_index_query
order by
  table_owner,
  table_name,
  foreign_key_column_list
;
alias lspdbs=select name, open_mode from v$pdbs order by 1;
alias lspdbsf=select name, open_mode from v$pdbs where name like '%' || :name || '%' order by 1;
alias invalids=select owner, object_type, object_name, status
from all_objects objs
join all_users usr on (usr.username = objs.owner and usr.oracle_maintained = 'N')
where objs.status != 'VALID';
alias errinfo=select sys.standard.sqlerrm(-abs(:error_code)) error_text from dual;
alias ls=script
sqlcl.setStmt('host ls')
sqlcl.run()
/
alias params=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, substr(value, 1, 20) value, substr(description, 1, 50) description from v$parameter order by 1;
alias paramsf=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, substr(value, 1, 20) value, substr(description, 1, 50) description from v$parameter where name like '%' || :name || '%' order by 1;
alias paramsdefault=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, substr(value, 1, 20) value, substr(description, 1, 50) description from v$parameter where isdefault = 'TRUE' order by 1;
alias paramsndefault=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, substr(value, 1, 20) value, substr(description, 1, 50) description from v$parameter where isdefault != 'TRUE' order by 1;
alias paramsses=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, substr(value, 1, 20) value, substr(description, 1, 50) description from v$parameter where isses_modifiable = 'TRUE' and ismodified = 'MODIFIED' or isadjusted = 'TRUE' order by 1;
alias param=select name, decode(type, 1, 'Bool', 2, 'String', 3, 'Int', 4, 'Param File', 5, 'Reserved', 6, 'Big Int') type, value, description from v$parameter where name = :param;
alias trans=select case when dbms_transaction.step_id() is not null then 'Yes' else 'No' end pending_transaction from dual;
alias tracefile=select value "Session Trace File" from v$diag_info where name = 'Default Trace File';
alias desc tracefile The full path and filename on the database server of the tracefile for this session
alias objects=select object_name, object_type, status from all_objects where owner = upper(:input) order by 1,2;
alias session_user=select sys_context('USERENV', 'SESSION_USER') session_user from dual;
alias current_schema=select sys_context('USERENV', 'CURRENT_SCHEMA') current_schema from dual;
alias epoch=select (sysdate-to_date('01-01-1970', 'DD-MM-YYYY'))*86400 epoch from dual;
alias env=select res.*
from (
  select *
  from (
    select
      sys_context ('userenv','ACTION') ACTION,
      sys_context ('userenv','AUDITED_CURSORID') AUDITED_CURSORID,
      sys_context ('userenv','AUTHENTICATED_IDENTITY') AUTHENTICATED_IDENTITY,
      sys_context ('userenv','AUTHENTICATION_DATA') AUTHENTICATION_DATA,
      sys_context ('userenv','AUTHENTICATION_METHOD') AUTHENTICATION_METHOD,
      sys_context ('userenv','BG_JOB_ID') BG_JOB_ID,
      sys_context ('userenv','CLIENT_IDENTIFIER') CLIENT_IDENTIFIER,
      sys_context ('userenv','CLIENT_INFO') CLIENT_INFO,
      sys_context ('userenv','CURRENT_BIND') CURRENT_BIND,
      sys_context ('userenv','CURRENT_EDITION_ID') CURRENT_EDITION_ID,
      sys_context ('userenv','CURRENT_EDITION_NAME') CURRENT_EDITION_NAME,
      sys_context ('userenv','CURRENT_SCHEMA') CURRENT_SCHEMA,
      sys_context ('userenv','CURRENT_SCHEMAID') CURRENT_SCHEMAID,
      sys_context ('userenv','CURRENT_SQL') CURRENT_SQL,
      sys_context ('userenv','CURRENT_SQLn') CURRENT_SQLn,
      sys_context ('userenv','CURRENT_SQL_LENGTH') CURRENT_SQL_LENGTH,
      sys_context ('userenv','CURRENT_USER') CURRENT_USER,
      sys_context ('userenv','CURRENT_USERID') CURRENT_USERID,
      sys_context ('userenv','DATABASE_ROLE') DATABASE_ROLE,
      sys_context ('userenv','DB_DOMAIN') DB_DOMAIN,
      sys_context ('userenv','DB_NAME') DB_NAME,
      sys_context ('userenv','DB_UNIQUE_NAME') DB_UNIQUE_NAME,
      sys_context ('userenv','DBLINK_INFO') DBLINK_INFO,
      sys_context ('userenv','ENTRYID') ENTRYID,
      sys_context ('userenv','ENTERPRISE_IDENTITY') ENTERPRISE_IDENTITY,
      sys_context ('userenv','FG_JOB_ID') FG_JOB_ID,
      sys_context ('userenv','GLOBAL_CONTEXT_MEMORY') GLOBAL_CONTEXT_MEMORY,
      sys_context ('userenv','GLOBAL_UID') GLOBAL_UID,
      sys_context ('userenv','HOST') HOST,
      sys_context ('userenv','IDENTIFICATION_TYPE') IDENTIFICATION_TYPE,
      sys_context ('userenv','INSTANCE') INSTANCE,
      sys_context ('userenv','INSTANCE_NAME') INSTANCE_NAME,
      sys_context ('userenv','IP_ADDRESS') IP_ADDRESS,
      sys_context ('userenv','ISDBA') ISDBA,
      sys_context ('userenv','LANG') LANG,
      sys_context ('userenv','LANGUAGE') LANGUAGE,
      sys_context ('userenv','MODULE') MODULE,
      sys_context ('userenv','NETWORK_PROTOCOL') NETWORK_PROTOCOL,
      sys_context ('userenv','NLS_CALENDAR') NLS_CALENDAR,
      sys_context ('userenv','NLS_CURRENCY') NLS_CURRENCY,
      sys_context ('userenv','NLS_DATE_FORMAT') NLS_DATE_FORMAT,
      sys_context ('userenv','NLS_DATE_LANGUAGE') NLS_DATE_LANGUAGE,
      sys_context ('userenv','NLS_SORT') NLS_SORT,
      sys_context ('userenv','NLS_TERRITORY') NLS_TERRITORY,
      sys_context ('userenv','OS_USER') OS_USER,
      sys_context ('userenv','POLICY_INVOKER') POLICY_INVOKER,
      sys_context ('userenv','PROXY_ENTERPRISE_IDENTITY') PROXY_ENTERPRISE_IDENTITY,
      sys_context ('userenv','PROXY_USER') PROXY_USER,
      sys_context ('userenv','PROXY_USERID') PROXY_USERID,
      sys_context ('userenv','SERVER_HOST') SERVER_HOST,
      sys_context ('userenv','SERVICE_NAME') SERVICE_NAME,
      sys_context ('userenv','SESSION_EDITION_ID') SESSION_EDITION_ID,
      sys_context ('userenv','SESSION_EDITION_NAME') SESSION_EDITION_NAME,
      sys_context ('userenv','SESSION_USER') SESSION_USER,
      sys_context ('userenv','SESSION_USERID') SESSION_USERID,
      sys_context ('userenv','SESSIONID') SESSIONID,
      sys_context ('userenv','SID') SID,
      sys_context ('userenv','STATEMENTID') STATEMENTID,
      sys_context ('userenv','TERMINAL') TERMINAL
    from dual
  )
  unpivot include nulls (
    val for name in (action, audited_cursorid, authenticated_identity, authentication_data, authentication_method, bg_job_id, client_identifier, client_info, current_bind, current_edition_id, current_edition_name, current_schema, current_schemaid, current_sql, current_sqln, current_sql_length, current_user, current_userid, database_role, db_domain, db_name, db_unique_name, dblink_info, entryid, enterprise_identity, fg_job_id, global_context_memory, global_uid, host, identification_type, instance, instance_name, ip_address, isdba, lang, language, module, network_protocol, nls_calendar, nls_currency, nls_date_format, nls_date_language, nls_sort, nls_territory, os_user, policy_invoker, proxy_enterprise_identity, proxy_user, proxy_userid, server_host, service_name, session_edition_id, session_edition_name, session_user, session_userid, sessionid, sid, statementid, terminal)
  )
) res;
alias tabs=select table_name from all_tables where owner = sys_context('USERENV', 'CURRENT_SCHEMA') order by 1;
alias ut_grant=begin
  execute immediate 'grant execute on ut3.ut to ' || sys_context('USERENV', 'CURRENT_SCHEMA');
end;
/
alias utp=exec ut3.ut.run(:1);

-- APEX
alias ausers=select workspace_name, user_name, email, date_created, account_locked from apex_workspace_apex_users;
alias ausersf=select workspace_name, user_name, email, date_created, account_locked from apex_workspace_apex_users where workspace_name like '%' || upper(:ws) || '%';
alias aver=select version_no apex_version from apex_release;
set define #
alias ae=q'<
set define &
-- no space between id and assignment is important
tosub id=:app_id
apex export -applicationid &id -exptranslations -split -exptype APPLICATION_SOURCE
>'
/
alias aey=q'<
set define &
-- no space between id and assignment is important
tosub id=:app_id
apex export -applicationid &id -exptranslations -split -exptype APPLICATION_SOURCE,READABLE_YAML
>'
/

-- ORDS
alias ords_version=select ords.installed_version from dual;

-- To see if something was compiled with warnings on, query this view:
-- select * from user_plsql_object_settings
-- When you do `alter procedure compile` it won't present the warnings on screen
-- you will have to subsequently query `(USER_ALL)_ERRORS` views.
-- You can also compile a particular procedure with warnings on via:
-- alter procedure compile plsql_warnings = 'ENABLE:ALL';
-- More info:
-- https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/PLSQL_WARNINGS.html#GUID-B28D6852-61DB-47E4-B681-C185ABF1BF21
-- https://docs.oracle.com/en/database/oracle/oracle-database/23/lnpls/overview.html#GUID-DF63BC59-22C2-4BA8-9240-F74D505D5102
-- https://docs.oracle.com/en/database/oracle/oracle-database/23/lnpls/plsql-error-handling.html#GUID-3311B813-3185-4751-A3A6-309B93973366
alias warnings_on=alter session set plsql_warnings='ENABLE:ALL';
alias warnings_off=alter session set plsql_warnings='DISABLE:ALL';
alias warnings_status=select value plsql_warnings from v$parameter where name = 'plsql_warnings';
alias warning_objects=select owner, name, type from all_plsql_object_settings where plsql_warnings like '%ENABLE%' order by 1,3,2;
