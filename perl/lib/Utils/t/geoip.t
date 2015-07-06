#!/usr/bin/env perl -w

use strict;

use Test::More tests => 1;
use Utils::GeoIP;

is(Utils::GeoIP->new()->lookup('74.86.126.155')->{city}, 'Dallas', 'IP 74.86.126.155 is in Dallas');

__END__
