#!/bin/sh

# Create data directories

mkdir -p  data/apache
mkdir -p  data/api
chmod 777 data/api
mkdir -p  data/extractor
mkdir -p  data/reporter
chmod 777 data/reporter
mkdir -p  data/sitester
chmod 777 data/sitester

# Create log directories

mkdir -p  logs/browser
mkdir -p  logs/cron
mkdir -p  logs/extractor
mkdir -p  logs/gridengine
mkdir -p  logs/reporter
chmod 777 logs/reporter
mkdir -p  logs/sitestats
mkdir -p  logs/sitester
chmod 777 logs/sitester
mkdir -p  logs/transformer
mkdir -p  logs/userdata
mkdir -p  logs/worldstats
mkdir -p  logs/xserver

# End of "dirs.sh"
