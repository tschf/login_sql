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

-- APEX
set define #
alias ae=q'<
set define &
-- no space between id and assignment is important
tosub id=:app_id
apex export -applicationid &id -split -exptype APPLICATION_SOURCE,READABLE_YAML
>'
/

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