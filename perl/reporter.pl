#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Utils::PidFile;
use Data::Site;
use Data::GridJob;
use Client::Reporter;
use IO::Socket;

# Get the number of days ago to report

my $days_ago = shift;
die "usage: $0 days_ago [site1 [site2...]]" unless defined($days_ago);

# Get this server's IP address

my $host_ip = inet_ntoa(inet_aton($ENV{HOSTNAME}));

# Get web sites whose reports are due this hour

my @site_ids = @ARGV;
if (!@site_ids)
{
    # Get all sites with the correct time zone

    my $time_zone = $ENV{REPORTS_HOURS} - (gmtime())[2];
    $time_zone += 24 if $time_zone < -11;
    $time_zone -= 24 if $time_zone >  12;

    # Get a list of sites for this data server

    Data::Site->connect();
    my $query = "time_zone = ? and (comp_server like '$ENV{HOSTNAME}%' or comp_server like '$host_ip%') and status <> 'S'";
    for (my $site = Data::Site->select($query, $time_zone);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        push @site_ids, $site->{site_id};
    }
    Data::Site->disconnect();
}
elsif ($site_ids[0] eq 'hour') # sites with report_time > time()
{
    # Get all sites with future report times

    @site_ids = ();

    # Get a list of sites for this data server

    Data::Site->connect();
    my $query = "report_time > ? and (comp_server like '$ENV{HOSTNAME}%' or comp_server like '$host_ip%') and status <> 'S'";
    for (my $site = Data::Site->select($query, time);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        push @site_ids, $site->{site_id};
    }
    Data::Site->disconnect();
}

# Generate reports for each site, for each day

if (@site_ids > 1)
{
    # Many sites, so submit to grid

    foreach my $site_id (@site_ids)
    {
        Data::GridJob->submit(
            command     => "$ENV{SERVER_HOME}/perl/reporter.pl $days_ago $site_id",
            comp_server => $host_ip,
        );
    }
}
elsif (@site_ids)
{
    # Just one site, so report and use a pid file to prevent contention

    my $site_id = $site_ids[0];
    my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids", "reporter-$site_id");
    exit unless $pid_file->create();

    # Translate URL to site ID

    if ($site_id !~ /^\d+$/)
    {
        my $url = $site_id;
        Data::Site->connect();
        my $site = Data::Site->select('url = ?', $url);
        Data::Site->disconnect();
        $site_id = $site->{site_id} or die "site $url not found";
    }

    # Get any day range

    my $days_from = $days_ago;
    my $days_to = $days_ago;
    ($days_from, $days_to) = split /\.\./, $days_ago if $days_ago =~ /\.\./;

    # Generate reports for the specified date range

    for ($days_ago = $days_from; $days_ago <= $days_to; $days_ago++)
    {
        my $reporter = Client::Reporter->new($site_id);
        $reporter->generate($days_ago);
    
        # Submit a grid job to generate user data

        Data::GridJob->submit(
            command     => "$ENV{SERVER_HOME}/perl/userdata.pl $days_ago $site_id",
            comp_server => $host_ip,
        );
    }

    $pid_file->remove();
}

__END__

=head1 DEPENDENCIES

Data::Site, Data::GridJob, Client::Reporter, IO::Socket

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
