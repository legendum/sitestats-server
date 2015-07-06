#!/usr/bin/env perl -w

use strict;

use Test::More tests => 2;
use Constants::General;

ok(length Constants::General::HOME_PAGE, 'Home page is set');
ok(Constants::General::VISIT_DURATION >= 1800, 'Visit lasts at least 30 mins');

__END__
