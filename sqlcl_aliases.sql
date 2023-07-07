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