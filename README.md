# sitestats-server

### Back end data processing for sitestats.com

This is a highly scalable web analytics server designed to measure a number
of web sites for a number of users. It does the following jobs:
- Receives web site events (page views, visits, etc.)
- Processes these events to add extra information (location, hostname, etc.)
- Loads these events into MySQL databases (one database per web site)
- Generates ad hoc, daily, weekly and monthly reports (see the crontab.txt file)
- Provides a flexible CGI API to get report data in XML and JSON formats

To set up this software, you'll need to:
1. be running Apache with PHP so you can measure web site traffic
2. be running a MySQL database server with permission to create databases
3. have Perl version 5 installed on your system
4. be able to run cronjobs to schedule system monitoring and reporting

If you've ticked all the boxes, here's how to get it up and running:
1. add the line "export SERVER_HOME=~/sitestats-server" to your .bashrc file
2. add the "bin" directory to your path (e.g. edit your ~/.bashrc file)
3. edit the config/env.yaml file with your particular configuration settings
4. put your email address in the monitor/notify.txt file for notifications
5. edit the perl/crontab.txt file then run "crontab perl/crontab.txt"
6. run "xmanage -install" to install the database
7. run "xmanage -newsite" to add a new web site to be measured

Now you'll need to make sure the "api" and "php" directories are available
via your web server. To do this, create symbolic links like this:
> ln -s ~/sitestats-server/api .
> ln -s ~/sitestats-server/php .
and ensure ~/sitestats-server/data/sitester and ~/sitestats-server/data/reporter
are writable by your web server so that they can cache data files for reports.

Now create a file called ".htaccess" in your web root directory like this:

# --- Start of .htaccess file ---
#
Options FollowSymLinks ExecCGI
AddHandler cgi-script .cgi
Setenv SERVER_HOME /PATH/TO/sitestats-server
#
# --- End of .htaccess file ---

Be sure to replace "/PATH/TO/sitestats-server" with your own directory path,
typically something like "/home/username/sitestats-server" for user "username".
You'll need AllowOverride permissions in the main apache.conf or
httpd.conf file to allow your .htaccess file to make this changes.

Please email kevin.hutchinson@legendum.com if you'd like any help with this.

This product includes GeoLite data created by MaxMind, available from
http://www.maxmind.com/
