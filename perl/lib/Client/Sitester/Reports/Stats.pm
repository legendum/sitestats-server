#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Reports::Stats - Read web summary stats and generate reports

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Stats, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Stats reads web summary stats and generates reports

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Stats;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports';
use Data::SiteStats;
use Utils::Time;
{
=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Stats subclass object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item get_stats($channel_id, $report_id, $start_date, $end_date)

Get a report by running a simple select query on the Stats table of the database

=cut
sub get_stats
{
    my ($self, $channel_id, $report_id, $start_date, $end_date) = @_;
    my $site = $self->{site} or die "no site";

    # Connect to the site's data server

    Data::SiteStats->connect(host => $site->data_server()->{host});

    # Store the report rows in the data structure

    my $database = $site->database();
    my $channels_clause = $self->channels_clause($channel_id, $report_id);
    my $fn = ($report_id == $self->report_id('page_duration') ? 'avg' : 'sum');
    $self->log("Running query: select field, $fn(value) as value from $database.Stats where the_date between $start_date and $end_date and report_id = $report_id $channels_clause group by field");
    my $query = Data::SiteStats->sql("select field, $fn(value) as value from $database.Stats where the_date between ? and ? and report_id = ? $channels_clause group by field", $start_date, $end_date, $report_id);
    my %stats;
    while (my $row = $query->fetchrow_hashref())
    {
        my $field = $row->{field};
        next if $self->{key_map} && !$self->{key_map}{$field}; # apply a key map
        $field =~ s/\|.*//; # for locations
        $stats{$field} = int($row->{value});
    }
    $self->log("Finished query");

    # Get a unique user count for web traffic reports

    if ($report_id == $self->report_id('traffic'))
    {
        ($stats{users}, $stats{first_times}) = $self->get_user_counts($start_date, $end_date, $channel_id) if $start_date != $end_date;

        # Only include the fields we're interested in

        %stats = (
            hits => $stats{hits},
            visits => $stats{visits},
            users => $stats{users},
            first_times => $stats{first_times},
            search_visits => $stats{search_visits},
            referrer_visits => $stats{referrer_visits},
        );
    }

    # Disconnect from the database

    Data::SiteStats->disconnect();

    return \%stats;
}

=item get_user_counts($start_date, $end_date, [$channel_id])

Get a count of the unique users and first time users between two dates

=cut
sub get_user_counts
{
    my ($self, $start_date, $end_date, $channel_id) = @_;
    my $site = $self->{site} or die "no site";
    my $start_time = Utils::Time->get_time($start_date, '00:00:00', $site->{time_zone});
    my $end_time = Utils::Time->get_time($end_date, '23:59:59', $site->{time_zone});

    # Connect to the site's data server

    Data::SiteStats->connect(host => $site->data_server()->{host});

    # Get query parameters

    my $database = $site->database();
    my $channels_clause = $self->channels_clause($channel_id);

    # Get the unique user count

    $self->log("Running query: select count(distinct(user_id)) as users from $database.TrafficStats where time between $start_time and $end_time $channels_clause");
    my $query = Data::SiteStats->sql("select count(distinct(user_id)) as users from $database.TrafficStats where time between ? and ? $channels_clause", $start_time, $end_time);
    my $row = $query->fetchrow_hashref();
    my $users = $row->{users};
    $self->log("Finished query");

    # Get the first time user count

    $self->log("Running query: select count(distinct(user_id)) as first_times from $database.TrafficStats where time between $start_time and $end_time and user_id = visit_id $channels_clause");
    $query = Data::SiteStats->sql("select count(distinct(user_id)) as first_times from $database.TrafficStats where time between ? and ? and user_id = visit_id $channels_clause", $start_time, $end_time);
    $row = $query->fetchrow_hashref();
    my $first_times = $row->{first_times};
    $self->log("Finished query");

    # Disconnect from the database

    Data::SiteStats->disconnect();

    # Return the user counts

    return ($users, $first_times);
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
