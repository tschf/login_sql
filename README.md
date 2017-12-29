# login.sql

Adaption from the login script in Effective Oracle by Design. SQLPlus will run
login.sql whenever you connect to the database, provided login.sql is in your
working directory or within the SQLPATH environment variable. 

Since this folder is stored in my Projects folder, I simply need to add:

```
export SQLPATH=/home/trent/Projects/login.sql 
```

To my `~/.bash_profile`.

# License

The Unlicense

# Author

Trent Schafer
