#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Data::GridJob;
use Data::Site;
use Data::SiteStats;
use IO::Socket;

$ENV{LOGLEVEL} = 1;

my $period = shift;
die "usage: $0 period [days_ago [site1 [site2...]]]" unless defined($period);
my $days_ago = shift || 1;

# Connect to the database

Data::Site->connect();
Data::SiteStats->connect();

# Get this server's IP address

my $host_ip = inet_ntoa(inet_aton($ENV{HOSTNAME}));

# Get web sites whose site stats are due this hour

my @site_ids = @ARGV;
if (!@site_ids)
{
    # Calculate stats for the right time zone

    my $time_zone = 2 + $ENV{REPORTS_HOURS} - (gmtime())[2];
    my $query = "status <> 'S'";
    if ($time_zone == 1)
    {
        # East of GMT - calculate all eastern stats

        $query .= " and time_zone > 0";
    }
    elsif ($time_zone <= 0)
    {
        # West of GMT - calculate this hour's stats

        $query .= " and time_zone = $time_zone";
    }
    else
    {
        # No more stats to calculate

        exit;
    }

    # Get a list of sites for this data server

    $query .= " and (comp_server like '$ENV{HOSTNAME}%' or comp_server like '$host_ip%')";
    for (my $site = Data::Site->select($query);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        push @site_ids, $site->{site_id};
    }
}
elsif ($site_ids[0] eq 'all') # all time zones
{
    @site_ids = ();

    # Get a list of sites for this data server

    my $query = "status <> 'S' and (comp_server like '$ENV{HOSTNAME}%' or comp_server like '$host_ip%')";
    for (my $site = Data::Site->select($query);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        push @site_ids, $site->{site_id};
    }
}

# Generate site stats for each site

if (@site_ids > 1)
{
    # Many sites, so submit to grid

    foreach my $site_id (@site_ids)
    {
        Data::GridJob->submit(
            command     => "$ENV{SERVER_HOME}/perl/sitestats.pl $period $days_ago $site_id",
            comp_server => $host_ip,
        );
    }
}
elsif (@site_ids)
{
    my $site_id = $site_ids[0];

    # Translate URL to site ID

    if ($site_id !~ /^\d+$/)
    {
        my $url = $site_id;
        my $site = Data::Site->select('url = ?', $url);
        $site_id = $site->{site_id} or die "site $url not found";
    }

    # Just one site, so report

    Data::SiteStats->period_stats($period, $days_ago, $site_id);
}

# Disconnect from the database

Data::Site->disconnect();
Data::SiteStats->disconnect();

__END__

=head1 DEPENDENCIES

Data::GridJob, Data::Site, Data::SiteStats, IO::Socket

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
