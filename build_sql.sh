# Run this where the sql data base exists.
# I kept it outside of the container so that the config is not lost when I rebuild the
# contianer.

# login in as root
mysql -u root -p
create user 'sip'@'localhost' identified by 'ChangeMe';

#login as sip
mysql -u sip -p
drop database asteriskcdrdb;
drop database asterisk;
create database asteriskcdrdb;
create database asterisk;
