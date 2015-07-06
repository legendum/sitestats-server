#!/usr/bin/env perl -w

use strict;

use Test::More tests => 4;
use Utils::Country;

is(Utils::Country->name('uk'), "United Kingdom", "Name of UK is United Kingdom");
is(Utils::Country->id('uk'), 224, "UK is position 224 in the country list");
is((Utils::Country->for_id(224))[0], 'uk', "ID 224 is the uk");
is((Utils::Country->for_id(224))[1], 'United Kingdom', "ID 224 is the United Kingdom");

__END__
