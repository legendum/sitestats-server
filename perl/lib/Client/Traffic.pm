#!/usr/bin/env perl 

=head1 NAME

Client::Traffic - Write daily web traffic data as CSV, XML, HTML or JSON

=head1 VERSION

This document refers to version 1.0 of Client::Traffic, released Jul 07, 2015

=head1 DESCRIPTION

Client::Traffic writes daily web traffic data as CSV, XML, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Traffic;
$VERSION = "1.0";

use strict;
use base 'Client::API';
use Client::Reporter;
use Utils::Time;
{
    # Class static properties

    use constant STALE_TIME => 120; # 2 minutes

=head2 Class Methods

=over 4

=item new()

Create a new Client::Traffic object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(
        date => 0,
        channels => 0,
        traffic_days => 0,
        date_requested => undef,
    );
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item refresh()

Refresh today's traffic data if it's stale

=cut
sub refresh
{
    my ($self) = @_;
    return if $self->{site}{report_time} > time() - STALE_TIME;
    $self->{site} = Client::Reporter->new($self->{site}{site_id})->generate();
}

=item generate(date => $date, channel => $channel_id, name => $name, format => $format, include => $include, exclude => $exclude, request => $request)

Generate daily traffic data from web site activity records

=cut
sub generate
{
    my ($self, %args) = @_;
    my $date = $args{date} || 0; # default to today
    my $channel_id = $args{channel} || 0;
    my $format = $args{format} || 'html';
    my $limit = $args{limit} || '';
    my $include = $args{include} || '';
    my $exclude = $args{exclude} || '';
    my $request = $args{request} || '';

    # Prepare empty traffic data

    my $traffic = {};
    $self->{date_requested} = $date;

    # Get a channel list (if used)

    my @channel_ids = split /,/, $channel_id;
    foreach my $channel_id (@channel_ids)
    {
        # Get a date list (if used)

        my @dates = split /,/, $date;
        foreach my $date (@dates)
        {
            # Get a date range (if used)

            my $days_from = $date;
            my $days_to = $date;
            ($days_from, $days_to) = split /\.\./, $date if $date =~ /\.\./;

            # Generate reports for dates for channel

            for ($date = $days_from; $date <= $days_to; $date++)
            {
                # Refresh today's traffic data

                $self->refresh() unless $date;

                # Get traffic data

                $self->get_traffic( traffic => $traffic,
                                    request => $request,
                                    date => $date,
                                    channel_id => $channel_id,
                                    limit => $limit,
                                    include => $include,
                                    exclude => $exclude );
            } # date range
        } # date list
    } # channel list

    # Return the traffic reports

    return $self->format_reports($traffic);
}

=item get_channel($traffic, $site_id, $channel_id)

Return channel data hash for a web site channel ID

=cut
sub get_channel
{
    my ($self, $traffic, $site_id, $channel_id) = @_;

    # Return the current channel if it has the right channel ID

    if ($self->{channels} > 0)
    {
        my $current = $traffic->{site}{channel}[$self->{channels}-1];
        return $current if $current && $current->{id} == $channel_id;
    }

    # Get the channel name if we were given an ID

    my $channel_name = '';
    if ($channel_id)
    {
        Data::SiteChannel->connect();
        my $site_channel = Data::SiteChannel->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
        Data::SiteChannel->disconnect();
        $channel_name = $site_channel->{name};
    }

    # Create a new channel with an ID and name

    my $channel = $traffic->{site}{channel}[$self->{channels}++] = { id => $channel_id, name => $channel_name };
    $self->{traffic_days} = 0;
    return $channel;
}

=item get_traffic(%args)

Get traffic on a date for a channel with optional filters to include and exclude

=cut
sub get_traffic
{
    my ($self, %args) = @_;
    my $site = $self->{site} or die "no site";
    my $traffic = $args{traffic} or die "no traffic";
    my $channel_id = $args{channel_id} || 0;
    my $date = $args{date} || 0;
    my $limit = $args{limit};
    my $include = $args{include};
    my $exclude = $args{exclude};

    # Convert "days ago" to a date and time

    my $date = Utils::Time->normalize_date($date, $site->{time_zone});
    my ($start_time, $end_time) = Utils::Time->get_start_and_end_times($date, $date, $site->{time_zone});
    my $secs = time() - $start_time;

    # Create the Perl data structure

    $traffic->{site} ||= { id => $site->{site_id}, url => $site->{url}, time_zone => $site->{time_zone} };
    my $channel = $self->get_channel($traffic, $site->{site_id}, $channel_id);
    my $traffic_day = $channel->{traffic}[$self->{traffic_days}++] = { date_requested => $self->{date_requested}, date => $date, time => $start_time, secs => $secs, visit => [] };

    # Connect to the site's data server

    my $data_server = $site->data_server();

    # Store the traffic rows in the data structure

    my $database = "stats" . $site->{site_id};
    my $channel_clause = '';
    $channel_clause = " and concat('|', T.channels, '|') like \"%|$channel_id|%\"" if $channel_id;
    $limit = " limit $limit" if $limit; # lovely alliteration
    my $query = $data_server->sql("select *, V.visit_id, V.campaign from $database.Visit V join $database.Traffic T on T.visit_id = V.visit_id where T.time between ? and ? $channel_clause order by V.visit_id desc$limit", $start_time, $end_time);
    while (my $row = $query->fetchrow_hashref())
    {
        next if $include && $row->{referrer} !~ /$include/;
        next if $exclude && $row->{referrer} =~ /$exclude/;
        my $visit = {};
        while (my ($key, $value) = each(%{$row}))
        {
            $visit->{$key} = $value if defined $value && length $value;
        }
        unshift @{$traffic_day->{visit}}, $visit;
    }

    # Disconnect from the database

    $data_server->disconnect();

    # Return the traffic as a hash-ref data structure with request stats

    $traffic->{stats} ||= $self->api_stats();
    return $traffic;
}

}1;

=back

=head1 DEPENDENCIES

Client::Reporter, Utils::Time

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
