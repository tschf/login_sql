define gname=idle
column global_name new_value gname
with instance_info as (
    select
        lower(global_name) global_name,
        instr(global_name, '.') dot_index
    from
        global_name
)
select
    -- 04/11/2022: Switch to builtin for connection identifier to get a better
    -- value for ldap based connections (_CONNECT_IDENTIFIER)
    -- Found example from here: https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:446220075876
    -- Keeping as SQL query so the username can be kept in lowercase (instead of _USER
    -- which will be upper-case).
    -- If it has a dot in the name, use the first part of the string instead
    case
        when dot_index > 0 then substr(global_name, 1, decode(dot_index, 0, length(global_name), dot_index-1))
        else '_CONNECT_IDENTIFIER'
    end
    || ': '
    || lower(user)
    global_name
from instance_info;

set sqlprompt '&gname> '