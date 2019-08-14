#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Getopt::Long;
use Data::Site;
use Server::DataServer;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

# What fields are we feeding?

my $Visit_fields = 'visit_id, user_id, global_id, time, cookies, flash, java, javascript, browser, region, country, language, latitude, longitude, time_zone, color_bits, resolution, op_sys, host_ip, city, campaign, referrer, search, user_agent';
my $Event_fields = 'visit_id, user_id, channel_id, type_id, refer_id, msecs, time, name, class, referrer, description';

# Get the options

my ($sites, $server, $reseller_id);
GetOptions("sites:s"                => \$sites,
           "server=s"               => \$server,    # server receiving the data
           "reseller:i"             => \$reseller_id, # optional reseller
           );

# Feed data for all sites in the list

$reseller_id += 0; # just to be safe!
my $hostname = $ENV{HOSTNAME};
my @sites = $reseller_id ? Data::Site->matching("reseller_id=$reseller_id and status='L'") : ();
my @site_ids = $sites ? split(',', $sites) : map {$_->{site_id}} @sites;
my $time = time() - 10 * 60;
foreach my $site_id (@site_ids)
{
    eval {
        my $visit_file = "/var/lib/mysql-files/stats$site_id.Visit.$$";
        my $event_file = "/var/lib/mysql-files/stats$site_id.Event.$$";
        unlink $visit_file if -f $visit_file;
        unlink $event_file if -f $event_file;

        my $stats = "stats$site_id";

        # Connect to the local data server

        my $ds_local = Server::DataServer->new($hostname);

        # Get data from the local data server

        $ds_local->sql("select $Visit_fields from $stats.Visit where time >= $time into outfile '$visit_file'");
        $ds_local->sql("select $Event_fields from $stats.Event where time >= $time into outfile '$event_file'");

        # Connect to the remote data server

        my $ds_remote = Server::DataServer->new($server);
        my $remote_host = $ds_remote->{host};

        # Feed data into the remote data server

        print "Feeding data file $visit_file to $remote_host\n";
        $ds_remote->sql_cmd("load data local infile '$visit_file' into table $stats.Visit ($Visit_fields)");
        print "Feeding data file $event_file to $remote_host\n";
        $ds_remote->sql_cmd("load data local infile '$event_file' into table $stats.Event ($Event_fields)");
        print "Finished feeding to $remote_host\n";

        # Delete the temporary data files

        unlink $visit_file if -f $visit_file;
        unlink $event_file if -f $event_file;
    };
    print "ERROR: $@\n" if $@;
}

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Data::Site, Data::Page, Server::DataServer, Utils::PidFile

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
