#!/usr/bin/env perl

=head1 NAME

Data::SiteStats - Manages overall stats for customer sites

=head1 VERSION

This document refers to version 1.0 of Data::SiteStats, released Jul 07, 2015

=head1 DESCRIPTION

Data::SiteStats manages stats for customer sites, e.g. users, visits and hits.
Be sure to call the class static method connect() before using Data::SiteStats
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item site_id

The site

=item channel_id

The channel

=item the_date

The date

=item period

The stats period - "day", "week" or "month"

=item users

The number of unique users over the period

=item visits

The number of visits over the period

=item hits

The number of hits (page views) over the period

=item duration

The duration of traffic in seconds over the period

=item first_times

The number of first time visits over the period

=item first_times_duration

The duration of traffic in seconds over the period for first-time users

=item cookies

The number of visits with cookies enabled over the period

=item flash

The number of visits with Flash enabled over the period

=item java

The number of visits with Java enabled over the period

=item javascript

The number of visits with JavaScript enabled over the period

=item spider_visits

The number of visits by search engine spiders

=back

=cut
package Data::SiteStats;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
use Data::Site;
use Data::SiteChannel;
use Data::SiteConfig;
use Utils::Time;
use Utils::LogFile;
{
    my $_Connection;

=head2 Class Methods

=over 4

=item connect(driver=>'mysql', database=>'dbname', user=>'username', password=>'pass')

Initialise a connection to the database with optional details

=cut
sub connect
{
    my ($class, %args) = @_;
    return $_Connection if $_Connection;

    $args{host} ||= $ENV{MASTER_SERVER};
    eval {
        $_Connection = $class->SUPER::connect(%args);
    }; if ($@) {
        $args{host} = $ENV{BACKUP_SERVER};
        $_Connection = $class->SUPER::connect(%args);
    }
    $class->fields(qw(site_stats_id site_id channel_id the_date period users visits hits duration first_times first_times_duration cookies flash java javascript spider_visits));

    return $_Connection;
}

=item disconnect()

Disconnect from the database cleanly

=cut
sub disconnect
{
    my ($class) = @_;
    return unless $_Connection;

    $_Connection = undef;
    $class->SUPER::disconnect();
}

=item period_stats($period, $days_ago, $site_id)

Store period stats in the SiteStats table for a particular web site

=cut
sub period_stats
{
    my ($class, $period, $days_ago, $site_id) = @_;
    die 'bad period' unless $period eq 'week' or $period eq 'month';
    die 'no days ago' unless $days_ago > 0;
    die 'no site id' unless $site_id > 0;

    # Open a log file

    my $log_file = Utils::LogFile->new("$ENV{LOGS_DIR}/sitestats"),

    # Get the site's time zone, host filters and data server

    my $site = Data::Site->row($site_id);
    my $time_zone = $site->{time_zone};
    my $filter_clause = $site->filter_clause();

    # Get the start and end dates for the period

    my ($start_date, $end_date) = Utils::Time->get_date_range($period, $days_ago, $time_zone);

    # Sum the hits and visits over the period for each channel

    my $sql = "select channel_id, sum(SS.hits) as hits, sum(SS.visits) as visits, sum(SS.duration) as duration, sum(SS.first_times) as first_times, sum(SS.first_times_duration) as first_times_duration, sum(SS.cookies) as cookies, sum(SS.flash) as flash, sum(SS.java) as java, sum(SS.javascript) as javascript, sum(SS.spider_visits) as spider_visits from SiteStats SS, Site S where SS.the_date between ? and ? and SS.period = 'day' and SS.site_id = S.site_id and S.status <> 'S' and SS.site_id = ? group by SS.channel_id";
    my %site_stats = ();
    eval
    {
        my $query = $class->sql($sql, $start_date, $end_date, $site_id);
        while (my $traffic = $query->fetchrow_hashref())
        {
            $site_stats{$traffic->{channel_id}} = $traffic;
        }
    };
    $log_file->error($@) if $@;

    # Get the start and end times for the period

    my $start_time = (Utils::Time->get_time_range($start_date, $time_zone))[0];
    my $end_time   = (Utils::Time->get_time_range($end_date,   $time_zone))[1];

    # Get array of site channels

    Data::SiteChannel->connect();
    my $channels = Data::SiteChannel->get($site_id);
    Data::SiteChannel->disconnect();

    # Get the database query optimize setting

    Data::SiteConfig->connect();
    my $config = Data::SiteConfig->get($site_id);
    my $optimize = lc Data::SiteConfig->find($config, 'optimize') eq 'yes';

    # Connect to the data server to get users

    $class->disconnect();
    my $dbh = $class->connect(host => $site->data_server()->{host});
    my $database = $site->database();

    # Get unique users for the current period

    my $users = {};
    $sql = "select T.user_id, T.channels from $database.Traffic T where T.time between ? and ?";
    eval
    {
        $class->get_users($dbh, $sql, $users, $channels, $start_time, $end_time, $optimize);
    };
    $log_file->error($@) if $@;

    # Get unique users in the previous period

    my $rollover = lc Data::SiteConfig->find($config, 'rollover') eq 'yes';
    my $year_month = substr($start_date, 0, 6);
    my $today = Utils::Time->get_date(time(), $time_zone);
    if ($rollover && $year_month != substr($today, 0, 6))
    {
        $sql = "select T.user_id, T.channels from $database.Traffic$year_month T where T.time between ? and ?";
        eval
        {
            $class->get_users($dbh, $sql, $users, $channels, $start_time, $end_time, $optimize);
        };
        $log_file->error($@) if $@;
    }
    Data::SiteConfig->disconnect();

    # Store the user counts for each channel

    while (my ($channel_id, $channel_users) = each %{$users})
    {
        $site_stats{$channel_id}{users} = scalar keys %{$channel_users};
    }

    # Connect to the master database to store results

    $class->disconnect();
    $class->connect();

    # Store the web traffic stats for the period

    while (my ($channel_id, $traffic) = each (%site_stats))
    {
        $class->traffic($site_id, $channel_id, $end_date, $period, $traffic);

        # Write to the log file

        my $hits = $traffic->{hits} || 0;
        my $visits = $traffic->{visits} || 0;
        my $users = $traffic->{users} || 0;
        $log_file->info("Site $site_id channel $channel_id from $start_date to $end_date had $hits hits, $visits visits and $users users");
    }

    # Return the start and end date

    return ($start_date, $end_date);
}

=item get_users($dbh, $sql, $users, $channels, $start_time, $end_time, [$optimize])

Get users between a start and end time, optionally optimizing the query

=cut
sub get_users
{
    my ($class, $dbh, $sql, $users, $channels, $start_time, $end_time, $optimize) = @_;
    $optimize ||= 0;

    my $query = $dbh->prepare($sql, {'mysql_use_result' => $optimize});
    $query->execute($start_time, $end_time);
    while (my $row = $query->fetchrow_hashref())
    {
        my $user_id = $row->{user_id};
        my @channel_ids = split /,/, $row->{channels};
        foreach my $channel_id (@channel_ids)
        {
            # Count the hit for the channel and its parents

            $users->{$channel_id}{"$user_id"}++ if $channel_id;
            my $parents = $channels->[$channel_id]{parents};
            map {$users->{$_}{"$user_id"}++} @{$parents};
        }
    }
    $query->finish();
}

=item traffic($site_id, $channel_id, $date, $period, $traffic_hash)

Store web site traffic stats on a date for a period of day/week/month

=cut
sub traffic
{
    my ($class, $site_id, $channel_id, $date, $period, $traffic_hash) = @_;

    # Delete any old site stats record

    my $site_stats = $class->select("site_id = ? and channel_id = ? and the_date = ? and period = ?", $site_id, $channel_id, $date, $period);

    # Create a new site stats record

    $site_stats = $class->new(
        site_stats_id        => $site_stats->{site_stats_id} || 0,
        site_id              => $site_id,
        channel_id           => $channel_id,
        the_date             => $date,
        period               => $period,
        users                => $traffic_hash->{users}                || 0,
        visits               => $traffic_hash->{visits}               || 0,
        hits                 => $traffic_hash->{hits}                 || 0,
        duration             => $traffic_hash->{duration}             || 0,
        first_times          => $traffic_hash->{first_times}          || 0,
        first_times_duration => $traffic_hash->{first_times_duration} || 0,
        cookies              => $traffic_hash->{cookies}              || 0,
        flash                => $traffic_hash->{flash}                || 0,
        java                 => $traffic_hash->{java}                 || 0,
        javascript           => $traffic_hash->{javascript}           || 0,
        spider_visits        => $traffic_hash->{spider_visits}        || 0,
    );
    $site_stats->update(); # or insert
}

=back

=head2 Object Methods

=over 4

=item None

=cut

}1;

=back

=head1 DEPENDENCIES

Data::Object, Data::Site, Data::SiteChannel, Data::SiteConfig, Utils::Time, Utils::LogFile

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
