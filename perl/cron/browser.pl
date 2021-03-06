#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Server::Browser;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

eval {
    my $browser = Server::Browser->new();
    $browser->browse(@ARGV);
};
print "ERROR: $@\n" if $@;

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Server::Browser, Utils::PidFile

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
