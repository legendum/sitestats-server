<?php
/*  SiteStats Server PHP Sensor, version 1.0 (c) 2015 Legendum Ltd (UK) 
 *
 *  SiteStats Server PHP Sensor is freely distributable under the terms of an
 *  MIT-style license. For details, see http://www.sitestats.com/
 *
 *--------------------------------------------------------------------------*/

// This PHP script expects a URL of the form "sensor.php?12345"
// where "12345" is the ID of the web site being measured.

// Optionally, the site ID may have a channel ID (for example "1")
// appended so the URL would be of the form "sensor.php?12345/1".

header('Content-type: text/javascript');
header('Expires: ' . gmdate('D, d M Y H:i:s', time() + 86400*90) . ' GMT');

// First, load the vanilla JavaScript sensor code

require_once('sensor.js');

// Now customize the sensor code with our web site ID and optional channel ID

list($site, $channel) = split('/', $_SERVER[QUERY_STRING]);
?>

Guanoo.Sensor.data = { site: <?=$site+0?>, channel: <?=$channel+0?> };
Guanoo.callbacks.onEvent = window.onGuanoo;
Guanoo.Sensor.load();
