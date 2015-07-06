#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Reports::Users - Read traffic and make reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users reads traffic and makes reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports';
use Client::Sitester::Cache;
use Data::SiteStats;
use Utils::Time;
{
    my %_Report_keys = (
         1 => 'tr', # traffic
         2 => 'ua', # user agent
         3 => 'co', # country
         4 => 'la', # language
         5 => 'tz', # time zone
         6 => 'cb', # color bits
         7 => 'sr', # screen resolution
         8 => 'os', # op sys
         9 => 'ho', # host
        10 => 're', # referrer page
        11 => 're', # referrer domain
        12 => 're', # referrer search engine
        13 => 'se', # search word
        14 => 'se', # search phrase
    );

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users subclass object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    bless $self, $class;
}

=item report_key($report_id)

Return the report key for a report ID, e.g. "ua" for browser report ID = 2

=cut
sub report_key
{
    my ($class, $report_id) = @_;
    return $_Report_keys{$report_id} or die "user report not supported (yet)";
}

=back

=head2 Object Methods

=over 4

=item get_stats($channel_id, $report_id, $start_date, $end_date)

Get web traffic stats for particular users between a start and end date

=cut
sub get_stats
{
    my ($self, $channel_id, $report_id, $start_date, $end_date) = @_;

    # Get traffic data for the users for the period

    my $traffic = [];
    my $filename = "$self->{site}{site_id}.log.$start_date.$end_date." . $self->signature();
    my $cache = Client::Sitester::Cache->new($filename);
    if ($cache->is_empty())
    {
        $traffic = $self->get_traffic($start_date, $end_date);
        $cache->write_traffic($traffic);
    }
    else
    {
        $cache->read_traffic($traffic);
    }

    # Now, generate stats from the traffic data

    return $self->traffic_stats($channel_id, $report_id, $traffic); #over-ridden
}

=item traffic_stats($channel_id, $report_id, $traffic)

Turn web traffic into a stats report - this is over-ridden in special subclasses

=cut
sub traffic_stats
{
    my ($self, $channel_id, $report_id, $traffic) = @_;

    my %stats;
    my $key = $self->report_key($report_id);
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $field = $visit->{$key};
        $stats{$field}++;
    }

    return \%stats;
}

=item get_traffic($start_date, $end_date)

Get web traffic data for particular web site users between a start and end date

=cut
sub get_traffic
{
    my ($self, $start_date, $end_date) = @_;
    my $site = $self->{site} or die "no site";
    my $start_time = Utils::Time->get_time($start_date, '00:00:00', $site->{time_zone});
    my $end_time = Utils::Time->get_time($end_date, '23:59:59', $site->{time_zone});

    # Connect to the site's data server

    Data::SiteStats->connect(host => $site->data_server()->{host});

    # Make a query for a user or visit list

    my $database = $site->database();
    my $query; # for users or visits
    my $host_clause = $self->host_clause('V');
    my $user_clause = $self->user_clause('T');
    my $visit_clause = $self->visit_clause('T');
    my $sql = "select V.*, T.channels, T.sequence from $database.Visit V, $database.Traffic T where T.time between $start_time and $end_time and V.visit_id = T.visit_id $host_clause $user_clause $visit_clause order by T.visit_id";
    $self->log("Running query: $sql");
    $query = Data::SiteStats->sql($sql);

    # Store the visit rows in the traffic list

    my @traffic;
    while (my $row = $query->fetchrow_hashref())
    {
        unshift @traffic, $self->get_visit($row);
    }
    $self->log("Finished query");

    # Disconnect from the database

    Data::SiteStats->disconnect();
    return \@traffic;
}

=item get_visit($row)

Get a visit hashref from a row of visit details and a sequence of page views

=cut
sub get_visit
{
    my ($self, $row) = @_;

    return {
        ui => $row->{user_id},
        vi => $row->{visit_id},
        ip => $row->{host_ip},
        ho => $row->{host},
        os => $row->{op_sys},
        ua => $row->{browser},
        tz => $row->{time_zone},
        la => $row->{language},
        co => $row->{country},
        ci => $row->{city},
        cb => $row->{color_bits},
        sr => $row->{resolution},
        re => $row->{referrer},
        se => $row->{search},
        ch => $row->{channels},
        sq => $row->{sequence},
    };
}

}1;

=back

=head1 DEPENDENCIES

Client::Sitester::Reports, Client::Sitester::Cache, Data::SiteStats, Utils::Time

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
