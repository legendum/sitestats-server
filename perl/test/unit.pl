#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Test::Harness;
use Getopt::Long;

# What are we testing?

my $constants = 0;
my $clients = 0;
my $servers = 0;
my $data = 0;
my $utils = 0;
my $all = 0;
GetOptions("constants" => \$constants,
           "clients"   => \$clients,
           "servers"   => \$servers,
           "data"      => \$data,
           "utils"     => \$utils,
           "all"       => \$all);

die "usage: $0 --all --constants --clients --data --servers --utils"
    unless $all || $constants || $clients || $data || $servers || $utils;

# Look in a perl lib directory for unit tests to run

sub unit_test
{
	my $dir = shift or die "no directory to unit test";
	chdir "$ENV{SERVER_HOME}/perl/lib/$dir/t";
	opendir (DIR, '.');
	my @tests = grep /\.t$/, readdir(DIR);
	closedir DIR;
	runtests @tests; 
}

# Run the unit tests

unit_test('Constants') if $constants || $all;
unit_test('Client') if $clients || $all;
unit_test('Data') if $data || $all;
unit_test('Server') if $servers || $all;
unit_test('Utils') if $utils || $all;

__END__

=head1 DEPENDENCIES

All the test files in the "t" subdirectories

=head1 AUTHOR

Kevin Hutchinson <kevin.hutchinson@legendum.com>

=head1 COPYRIGHT

Copyright (c) 2015 Legendum Ltd (UK)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
