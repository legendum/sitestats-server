#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Reports::Range - Read web visits to generate range reports

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Range, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Range reads web visits to generates range reports

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Range;
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

Create a new Client::Sitester::Reports::Range subclass object

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

Get a report by analysing visits and deriving range reports about visits

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
    my $channels_clause = $self->channels_clause($channel_id);
    my $then = 1000000000;
    my $now = time();

    my $stats;

    # Select the earliest and most recent access times

    $self->log("Running query: select min(time) as min_time, max(time) as max_time from $database.TrafficStats where time between $then and $now $channels_clause");
    my $query = Data::SiteStats->sql("select min(time) as min_time, max(time) as max_time from $database.TrafficStats where time between $then and $now $channels_clause");
    my $row = $query->fetchrow_hashref();
    $stats->{first_date_time} = $self->format_time($row->{min_time});
    $stats->{last_date_time} = $self->format_time($row->{max_time});
    $self->log("Finished query");

    # Disconnect from the database

    Data::SiteStats->disconnect();

    return $stats;
}

=item format_time($time)

Format a Unix epoch time as YYYYMMDD HH:MM:SS by using the Utils::Time module

=cut
sub format_time
{
    my ($self, $time) = @_;
    my $site = $self->{site} or die "no site";

    return Utils::Time->get_date_time($time, $site->{time_zone});
}

=item filename($site_id, $channel_id, $report_id, $start_date, $end_date)

Return the filename for the cache file used to save the report data

=cut
sub filename
{
    my ($self, $site_id, $channel_id, $report_id, $start_date, $end_date) = @_;
    $start_date = '19700101';
    $end_date = Utils::Time->get_date();

    return "$site_id.$channel_id.$report_id.$start_date.$end_date";
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
