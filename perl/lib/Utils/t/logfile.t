#!/usr/bin/env perl -w

use strict;

use Test::More tests => 1;
use Utils::LogFile;

my $log_file = Utils::LogFile->new("$ENV{LOGDIR}/xperform");
my $time = time();
$log_file->info("Testing that time is $time");
is($log_file->grep("Testing that time is $time"), 1, 'Wrote info then grepped it');

__END__
