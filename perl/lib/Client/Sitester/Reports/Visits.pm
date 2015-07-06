#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Reports::Visits - Read web site visits and generate reports

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Visits, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Visits reads web site visits and generates reports

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Visits;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports';
use Data::SiteStats;
use Utils::Time;
{
    use constant DAY_SECS => 86400;

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Visits subclass object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{order} = 'keys';
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item get_stats($channel_id, $report_id, $start_date, $end_date)

Get a report by analysing visits and deriving reports about visits

=cut
sub get_stats
{
    my ($self, $channel_id, $report_id, $start_date, $end_date) = @_;
    my $site = $self->{site} or die "no site";

    # Get the start and end times from the dates

    my $start_time = Utils::Time->get_time($start_date, '00:00:00', $site->{time_zone});
    my $end_time = Utils::Time->get_time($end_date, '23:59:59', $site->{time_zone});

    # Connect to the site's data server

    Data::SiteStats->connect(host => $site->data_server()->{host});

    my $database = $site->database();
    my $clause = $self->user_clause();
    $clause .= $self->channels_clause($channel_id) if $channel_id;
    $self->log("Running query: select user_id, time from $database.TrafficStats where time between $start_time and $end_time $clause");
    my $query = Data::SiteStats->sql("select user_id, time from $database.TrafficStats where time between ? and ? $clause", $start_time, $end_time);

    my $stats;
    $stats = $self->get_recency_stats($query, $end_time)
                            if $report_id == $self->report_id('recency');

    $stats = $self->get_frequency_stats($query)
                            if $report_id == $self->report_id('frequency');

    $self->log("Finished query");

    # Disconnect from the database

    Data::SiteStats->disconnect();

    return $stats;
}

=item get_recency_stats($query, $end_time)

Get recency stats for visits to a site between a start and end time

=cut
sub get_recency_stats
{
    my ($self, $query, $end_time) = @_;

    # Get most recent visits in the time period

    my %users = ();
    while (my $row = $query->fetchrow_hashref())
    {
        my $days_ago = int(($end_time - $row->{time}) / DAY_SECS);
        $days_ago = 0 if $days_ago < 0;# catch strange time values
        $users{$row->{user_id}} = $days_ago;
    }

    # Generate a recency stats report from the user "days ago" counts

    my $stats = {};
    map {$stats->{$_}++} values %users;
    return $stats;
}

=item get_frequency_stats($query)

Get frequency stats for visits to a site between a start and end time

=cut
sub get_frequency_stats
{
    my ($self, $query) = @_;

    # Count user visits in the time period

    my %users = ();
    while (my $row = $query->fetchrow_hashref())
    {
        $users{$row->{user_id}}++;
    }

    # Generate a frequency stats report from the user visit counts

    my $stats = {};
    map {$stats->{$_}++} values %users;
    return $stats;
}

}1;

=back

=head1 DEPENDENCIES

Client::Sitester::Reports, Data::SiteStats, Utils::Time

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
