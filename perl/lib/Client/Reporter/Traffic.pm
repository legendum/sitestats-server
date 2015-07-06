#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Traffic - Write traffic data to a site's Traffic data table

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Traffic, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Traffic writes traffic data to a site's Traffic data table.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Traffic;
$VERSION = "1.0";

use strict;
use Constants::General;
use Constants::Events;
use Data::Site;
use Utils::Time;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Traffic object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    # Get details from the reporter's site

    my $self = {
        database       => $reporter->{site}->database(),
        host           => $reporter->{site}->data_server()->{host},
        commerce_pages => $reporter->{site}{commerce_pages} || '',
    };

    bless $self, $class;
}

=item get_channels($visit_data)

Get a list of channels from some visit data

=cut
sub get_channels
{
    my ($class, $visit_data) = @_;
    return split /,/, $visit_data->{ch};
}

=item get_sequence_events($visit_data)

Get a list of sequence events from some visit data

=cut
sub get_sequence_events
{
    my ($class, $visit_data) = @_;
    return split /\|/, $visit_data->{sq};
}

=item parse_sequence_event($event)

Parse an event in a sequence from a Traffic record (see "insert" method below)

=cut
sub parse_sequence_event
{
    my ($class, $event) = @_;

    my $durn = $1 if $event =~ s/^([\d:]+)\s//;
    my $refer_id = 0; $refer_id = $1 if $event =~ s/\s(\d+)$//;
    my $type_id = 0; $type_id = $1 if $durn =~ s/^(\d+)://;
    $durn ||= 1; # minimum of 1 second event duration
    $event =~ s/%20/ /g;

    return ($type_id, $durn, $event, $refer_id);
}

=back

=head2 Object Methods

=over 4

=item connect()

Connect to a site's data server

=cut
sub connect
{
    my ($self) = @_;
    my $host = $self->{host} or die "no host";
    Data::Site->connect(host => $host);
}

=item disconnect()

Disconnect from a site's data server

=cut
sub disconnect
{
    my ($self) = @_;

    Data::Site->disconnect();
}

=item delete($start_time)

Delete a day of traffic data from a site's Traffic and TrafficStats data tables

=cut
sub delete
{
    my ($self, $start_time) = @_;
    my $database = $self->{database} or die "no database";
    my $end_time = $start_time + Utils::Time::DAY_SECS;

    Data::Site->sql("delete from $database.Traffic where time between $start_time and $end_time");
    Data::Site->sql("delete from $database.TrafficStats where time between $start_time and $end_time");
}

=item insert($visit_data)

Insert traffic data to a site's Traffic data table

=cut
sub insert
{
    my ($self, $visit_data) = @_;
    my $database = $self->{database} or die "no database";

    # Get traffic data from visit data

    my %stats = ();
    my $hits = 0;
    my $duration = 0;
    my $sequence = '';
    my $classes = '';
    my $channels = '';
    my $commerce = '';
    my $i = 1;
    while (my $event = $visit_data->{"e$i"})
    {
        $i++; # next event

        my ($channel_id, $type_id, $durn, $name, $refer_id, $class) = split / /, $event;
        next unless length $name;

        # Measure traffic stats in the content channel and for the whole site

        $stats{$channel_id}{"event$type_id"}++;
        $stats{$channel_id}{"durn"} += $durn;
        if ($channel_id > Constants::General::WHOLE_SITE_CHANNEL_ID)
        {
            $stats{Constants::General::WHOLE_SITE_CHANNEL_ID}{"event$type_id"}++;
            $stats{Constants::General::WHOLE_SITE_CHANNEL_ID}{"durn"} += $durn;
        }

        # Measure traffic data as a detailed sequence of events

        $sequence .= " $refer_id" if $refer_id && $sequence;
        $sequence .= '|' if $sequence;
        $classes .= ',' if $sequence;
        $channels .= ',' if $sequence; # coz zero is false in Perl!

        $sequence .= "$type_id:$durn $name";
        $classes .= $class || '';
        $channels .= $channel_id;

        $duration += $durn;
        $hits++ if $type_id == Constants::Events::TYPE_PAGE;

        $name =~ s/\?.*//; # remove any query string to match commerce pages
        if ($self->{commerce_pages} =~ /\Q$name\E/)
        {
            $commerce .= '|' if $commerce;
            $commerce .= $name;
        }
    }

    # Insert the traffic stats into the site's TrafficStats table

    while (my ($channel_id, $stats) = each %stats)
    {
        my $events = '';
        my $places = '';
        my @values = ();
        my $durn = 0;
        while (my ($event, $value) = each %{$stats})
        {
            if ($event eq 'durn') # special case
            {
                $durn = $value;
                next;
            }
            $events .= "$event,";
            $places .= "?,";
            push @values, $value;
        }
        chop $events;
        chop $places;

        my $sql = "insert into $database.TrafficStats (visit_id, user_id, time,  channel_id, duration, $events) values (?, ?, ?, ?, ?, $places)";
        eval {
            Data::Site->sql($sql, $visit_data->{vi}, $visit_data->{ui}, $visit_data->{tm}, $channel_id, $durn, @values);
        }; # just in case
    }

    # Insert the traffic data into the site's Traffic data table

    eval {
        Data::Site->sql("insert into $database.Traffic (visit_id, user_id, time, hits, duration, sequence, classes, channels, campaign, commerce) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", $visit_data->{vi}, $visit_data->{ui}, $visit_data->{tm}, $hits, $duration, $sequence, $classes, $channels, $visit_data->{ca}, $commerce);
    }; # just in case
}

}1;

=back

=head1 DEPENDENCIES

Data::Site, Utils::Time

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
