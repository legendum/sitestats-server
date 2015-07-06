Be sure to append and modify the httpd.conf file to
your own Apache httpd.conf file or apache2.conf file
typically found in the directory /etc/apache2 or
/etc/httpd/conf if you're using an older Apache 1.3

You'll also need to change the "base" variable in
the sensor.js JavaScript file in the "scripts" folder
to your WEB_ROOT_SERVER followed by the "work" folder
as setup in your edited ~/perform/x/config/env.yaml

Please note that the PHP and JavaScript code in this 
project are licensed under the MIT license, not GPL.
