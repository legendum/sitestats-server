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
use Data::SiteStats;
use Utils::Time;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

# Get the date to fix

my $date;
GetOptions("date=i" => \$date);
die "usage fixer.pl -date=(days_ago|YYYYMMDD)" unless $date;
$date = Utils::Time->normalize_date($date);

# Get a list of live sites

Data::Site->connect();
my @site_ids = ();
my %site_urls = ();
my $query = "status in ('T', 'L') and data_server like '$ENV{HOSTNAME}%'";
for (my $site = Data::Site->select($query);
        $site->{site_id};
        $site = Data::Site->next($query))
{
    my $site_id = $site->{site_id};
    push @site_ids, $site_id;
    $site_urls{$site_id} = $site->{url};
}
Data::Site->disconnect();

# Look for sites that are missing reports

sub find_site_ids_to_fix
{
    my ($period, $date, @site_ids) = @_;
    Data::SiteStats->connect();
    $query = "period = '$period' and the_date = ? and site_id = ?";
    my @site_ids_to_fix = ();
    foreach my $site_id (@site_ids)
    {
        my $site_stats = Data::SiteStats->select($query, $date, $site_id);
        next if $site_stats->{site_stats_id};
        push @site_ids_to_fix, $site_id;
    }
    Data::SiteStats->disconnect();
    return @site_ids_to_fix;
}

# Fix missing daily reports

my @site_ids_to_fix = find_site_ids_to_fix('day', $date, @site_ids);
foreach my $site_id (@site_ids_to_fix)
{
    system "$ENV{SERVER_HOME}/perl/reporter.pl $date $site_id";
    my $url = $site_urls{$site_id};
    print "Fixed daily report for site $site_id $url on $date\n";
}
print "No daily reports need fixing on $date\n" unless @site_ids_to_fix > 0;

# Fix missing weekly reports

if (Utils::Time->get_day_of_week($date) == Utils::Time::SUNDAY)
{
    @site_ids_to_fix = find_site_ids_to_fix('week', $date, @site_ids);
    my $days_ago = Utils::Time->get_days_ago($date);
    foreach my $site_id (@site_ids_to_fix)
    {
        system "$ENV{SERVER_HOME}/perl/sitestats.pl week $days_ago $site_id";
        my $url = $site_urls{$site_id};
        print "Fixed weekly report for site $site_id $url on $date\n";
    }
    print "No weekly reports need fixing on $date\n" unless @site_ids_to_fix > 0;
}

# Fix missing monthly reports

if (substr($date, 6, 2) == '01') # 1st of the month
{
    my $days_ago = Utils::Time->get_days_ago($date) + 1; # last day of the month
    $date = Utils::Time->normalize_date($days_ago);
    @site_ids_to_fix = find_site_ids_to_fix('month', $date, @site_ids);
    foreach my $site_id (@site_ids_to_fix)
    {
        system "$ENV{SERVER_HOME}/perl/sitestats.pl month $days_ago $site_id";
        my $url = $site_urls{$site_id};
        print "Fixed monthly report for site $site_id $url on $date\n";
    }
    print "No monthly reports need fixing on $date\n" unless @site_ids_to_fix > 0;
}

# Clean up and go home

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Data::Site, Data::SiteStats, Utils::Time, Utils::PidFile

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
