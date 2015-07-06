#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Utils::Time;
use Getopt::Long;
use Data::Site;
use Server::DataServer;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

my ($session_age_in_mins, $sites, $server, $reseller_id);
GetOptions("session_age_in_mins=i"  => \$session_age_in_mins,
           "sites:s"                => \$sites,
           "server=s"               => \$server,    # server receiving the data
           "reseller:i"             => \$reseller_id, # optional reseller
           );

Data::Site->connect();
$reseller_id += 0; # just to be safe!
my @sites = $reseller_id ? Data::Site->matching("reseller_id=$reseller_id and status='L'") : ();
my @site_ids = $sites ? split(',', $sites) : map {$_->{site_id}} @sites;
foreach my $site_id (@site_ids)
{
    eval {
        # Connect to the data server

        my $ds = Server::DataServer->new($server);

        # Update the visit durations

        my $db = "stats$site_id";
        my $session_age_in_secs = $session_age_in_mins * 60;
        my $cutoff = time() - $session_age_in_secs;
        my $yesterday = $cutoff - Utils::Time::DAY_SECS;
        my $sql = "update $db.Visit V set V.duration = least($session_age_in_secs, (select max(E.time) - min(E.time) from $db.Event E where V.visit_id = E.visit_id)) where V.duration is null and V.time > $yesterday and V.time < $cutoff";
        print "Running query on $server: $sql\n";
        $ds->sql($sql);
        print "Finished query on $server\n";
    };
    print "ERROR: $@\n" if $@;
}
Data::Site->disconnect();

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Data::Site, Server::DataServer, Utils::PidFile

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
