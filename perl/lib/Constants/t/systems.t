#!/usr/bin/env perl -w

use strict;

use Test::More tests => 4;
use Constants::Systems;

ok(defined Constants::Systems::WINDOWS, "Windows systems defined");
ok(defined Constants::Systems::OTHERS, "Other systems defined");
ok(defined Constants::Systems::BROWSERS, "Browser systems defined");
ok(defined Constants::Systems::SPIDERS, "Spider systems defined");
