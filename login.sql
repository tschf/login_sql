REM whilst setting up the environment, I will turn off termout. After everything
REM is set up as I like it, I will turn it back on so everything behaves as
REM expect
set termout off
set sqlblanklinkeson

define _editor=vim

REM I like to have serveroutput on by default. Set with a large size so I can
REM have lots of output.
set serveroutput on size 100000

REM A size of 130 gives a good width for the explain plan to be rendered properly
set linesize 130

REM I do not need SQL*Plus to continually print the column headers, so I will
REM use a large pagesize
set pagesize 9999

REM The default length of object_name is too long. Reduce the default width
REM so the query is more readable on the screen. Add any other commonly queried
REM table columns.
column object_name format a30

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
    substr(global_name, 1, decode(dot_index, 0, length(global_name), dot_index-1))
    || ': '
    || lower(user)
    global_name
from instance_info;

set sqlprompt '&gname> '

REM If we are using SQLcl, it supports the ansiconsole format which gives a much
REM more pleasant feel. This will silently die in SQL*Plus
set sqlformat ansiconsole

REM We are all done now, so we can turn termout back on
set termout on
