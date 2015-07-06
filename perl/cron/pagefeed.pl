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
use Data::Page;
use Server::DataServer;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

# What fields are we feeding?

my $Page_fields = 'page_id, url, url_thumb, last_seen, days_seen, failures, title, keywords, description, content';

# Get the options

my ($sites, $server, $reseller_id);
GetOptions("sites:s"                => \$sites,
           "server=s"               => \$server,    # server receiving pages
           "reseller:i"             => \$reseller_id, # optional reseller
           );

# Sync pages for all sites in the list

$reseller_id += 0; # just to be safe!
my $hostname = $ENV{HOSTNAME};
my @sites = $reseller_id ? Data::Site->matching("reseller_id=$reseller_id and status='L'") : ();
my @site_ids = $sites ? split(',', $sites) : map {$_->{site_id}} @sites;
foreach my $site_id (@site_ids)
{
    eval {

        # First deduplicate pages

        print "Deduping pages in stats$site_id.Page\n";
        Data::Page->connect(host => $hostname, database => "stats$site_id");
        my ($pages, $dupes) = Data::Page->dedupe_pages();
        Data::Page->disconnect();
        print "Deduped $dupes out of $pages pages\n";

        # Now synchronize page data with the remote data server

        my $page_file = "/tmp/stats$site_id.Page.$$";
        unlink $page_file if -f $page_file;

        my $stats = "stats$site_id";

        # Connect to the local data server

        my $ds_local = Server::DataServer->new($hostname);

        # Get data from the local data server

        print "Creating page file $page_file\n";
        $ds_local->sql("select $Page_fields from $stats.Page into outfile '$page_file'");

        # Connect to the remote data server

        my $ds_remote = Server::DataServer->new($server);
        my $remote_host = $ds_remote->{host};

        # Feed data into the remote data server

        print "Syncing page file $page_file to $remote_host\n";
        $ds_remote->sql("delete from $stats.Page");
        $ds_remote->sql_cmd("load data local infile '$page_file' into table $stats.Page ($Page_fields)");
        print "Finished syncing page file $page_file to $remote_host\n";

        # Delete the temporary data file

        unlink $page_file if -f $page_file;
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
