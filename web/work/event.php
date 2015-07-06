<?php
/*  SiteStats Server PHP Event, version 1.0 (c) 2015 Legendum Ltd (UK) 
 *
 *  SiteStats Server PHP Event is freely distributable under the terms of an
 *  MIT-style license. For details, see http://www.sitestats.com/
 *
 *--------------------------------------------------------------------------*/

# Send a P3P privacy header

header('P3P: policyref="http://www.sitestats.com/w3c/p3p.xml", CP="BUS DSP COR ADM DEV PSA PSD OUR"');

# Get the web site id

$site = $_GET[site];
if (!$site) exit;

# Get all the event details

list($usec, $now) = explode(" ", microtime());
$load_time = $_GET[load_time] + 0;
$type = $_GET[type];
$name = stripslashes(preg_replace('/\|/', '%7C', $_GET[name])); #query strings
$desc = stripslashes(preg_replace('/\|/', '&#124;', $_GET[desc])); # HTML code
$class = stripslashes($_GET['class']);
$host_ip = $_SERVER[REMOTE_ADDR];
$forward = $_SERVER[HTTP_X_FORWARDED_FOR];
if ($forward) $host .= ",$forward";
$visit_id = $_GET[visit_id];
$user_id = $_GET[user_id];
$campaign = $_GET[campaign];
$referrer = $_GET[referrer];
$refer_id = $_GET[refer_id] + 0;
$flash = $_GET[flash]; if (!$flash) $flash = 'no';
$java = substr($_GET[java], 0, 3);
$javascript = $_GET[javascript] ? $_GET[javascript] : 'yes';
$clock_time = $_GET[clock_time];
$color_bits = $_GET[color_bits] + 0;
$resolution = $_GET[resolution];
$language = str_replace("\n", ' ', $_SERVER[HTTP_ACCEPT_LANGUAGE]);
$user_agent = str_replace('|', ' ', $_SERVER[HTTP_USER_AGENT]);

# Make default visit/user ids

$cookies = 'yes';
if (!$visit_id || !$user_id) {
	$visit_id = $user_id = $now . substr($usec, 2, 6);
    $cookies = 'no';
}

# Get/set the global id cookie

$global_id = $_COOKIE[guanoo_global_id];
if ($global_id == 'optout') exit;
if (!$global_id) {
    $global_id = $user_id;
    $domain = preg_replace('/^\w+/', '', $_SERVER[SERVER_NAME]);
	setcookie('guanoo_global_id', $global_id, $now + 31536000, '/', $domain);
}

# Create an event data string

$event = "event:si=$site|ip=$host_ip|tm=$now|lt=$load_time|et=$type|en=$name|ed=$desc|ec=$class|vi=$visit_id|ui=$user_id|gi=$global_id|co=$cookies|ca=$campaign|ri=$refer_id|re=$referrer";
if ($_GET[new_visit] == 'true')
	$event .= "|fl=$flash|ja=$java|js=$javascript|ct=$clock_time|cb=$color_bits|sr=$resolution|la=$language|ua=$user_agent";

# Use Apache to log the event

apache_note('xperform', $event);

# Calculate the time zone

$hour_utc = strftime('%H');
list ($hour, $mins, $secs) = split(':', $clock_time);
$time_zone = $hour - $hour_utc;
if ($time_zone < -12) $time_zone += 24;
if ($time_zone > 12) $time_zone -= 24;
$clock_time = sprintf('%02d:%02d:%02d', $hour, $mins, $secs);

# Return JavaScript feedback

header('Content-type: text/javascript');
header('Cache-control: no-cache');
header('Expires: now');
?>
if (!window.Guanoo) Guanoo = { callbacks : {} };
if (!Guanoo.Sensor) Guanoo.Sensor = { data : {} };
var data = Guanoo.Sensor.data;
data.visitId = '<?= addslashes($visit_id) ?>';
data.userId = '<?= addslashes($user_id) ?>';
data.globalId = '<?= addslashes($global_id) ?>';
data.referrer = '<?= addslashes($referrer) ?>';
data.hostIp = '<?= addslashes($host_ip) ?>';
data.clockTime = '<?= addslashes($clock_time) ?>';
data.timeZone = '<?= addslashes($time_zone) ?>';
data.loadTime = '<?= addslashes($load_time) ?>';
data.eventName = '<?= addslashes($name) ?>';
data.eventClass = '<?= addslashes($class) ?>';
data.colorDepth = '<?= addslashes($color_bits) ?>';
data.resolution = '<?= addslashes($resolution) ?>';
data.language = '<?= addslashes($language) ?>';
data.userAgent = '<?= addslashes($user_agent) ?>';
data.javaVersion = '<?= addslashes($java) ?>';
data.flashVersion = '<?= addslashes($flash) ?>';
if (Guanoo.callbacks.onEvent) Guanoo.callbacks.onEvent.call(Guanoo, data);
