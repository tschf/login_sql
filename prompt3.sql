define gname=idle
column global_name new_value gname

select
  sys_context('USERENV', 'SERVER_HOST')
  || '/'
  || sys_context('USERENV', 'SERVICE_NAME')
  || ': '
  || lower(sys_context('USERENV', 'SESSION_USER'))
  global_name
from dual;

set sqlprompt '&gname> '