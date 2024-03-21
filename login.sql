REM whilst setting up the environment, I will turn off termout. After everything
REM is set up as I like it, I will turn it back on so everything behaves as
REM expect
set termout off
set sqlblanklinkes on

define _editor=vim

REM A size of 130 gives a good width for the explain plan to be rendered properly
set linesize 130

REM When there is a low latency, massive page size is no good.
set pagesize 100

REM The default length of object_name is too long. Reduce the default width
REM so the query is more readable on the screen. Add any other commonly queried
REM table columns.
column object_name format a30

REM prompt style 1 - uses global_name view to get information about the connection
REM prompt style 2 - uses defined variables so no logic - fastest
REM prompt style 3 - uses sys_context('userenv', ..)
REM prompt style 4 - colourised prompt
-- note this (prompt4) doesn't always work with sqlplus since it can evaluate too
-- long of a prompt
@prompt4.sql

REM If we are using SQLcl, it supports the ansiconsole format which gives a much
REM more pleasant feel. This will silently die in SQL*Plus
set sqlformat ansiconsole

REM status bar preferences. Turned off because experienced weirdness with it enabled
REM in the VSCode terminal
-- set statusbar cwd git timing txn

REM history should log everything
set history fails
set history filter none

REM load aliases from a separate file
@sqlcl_aliases.sql

REM Attempt to run a project_login.sql if it exists. This file might have interesting
REM assignments specific to your project. Assumes you launch SQLcl from your
REM project root
@@project_login.sql

alter session set nls_date_format='DD-MON-YYYY';

REM We are all done now, so we can turn termout back on
set termout on

REM Put serveroutput on so we see output in plsql
set serveroutput on