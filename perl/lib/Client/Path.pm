#!/usr/bin/env perl 

=head1 NAME

Client::Path - Write web traffic path report data as CSV, XML, HTML or JSON

=head1 VERSION

This document refers to version 2.1 of Client::Path, released Jul 07, 2015

=head1 DESCRIPTION

Client::Path writes web traffic path report data as CSV, XML, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Path;
$VERSION = "2.0";

use strict;
use base 'Client::API';
use Client::Reporter;
use Data::SiteChannel;
use Data::Page;
use Utils::Time;
{
    # Class static properties

    use constant STALE_TIME => 120; # 2 minutes

=head2 Class Methods

=over 4

=item new()

Create a new Client::Path object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new(
        channels => 0,
        titles => {},
    );
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item refresh()

Refresh today's traffic path data if it's stale

=cut
sub refresh
{
    my ($self) = @_;
    return if $self->{site}{report_time} > time() - STALE_TIME;
    $self->{site} = Client::Reporter->new($self->{site}{site_id})->generate();
}

=item generate(date => $date, channel => $channel_id, name => $name, format => $format, include => $include, exclude => $exclude)

Generate traffic path data from web site activity records

=cut
sub generate
{
    my ($self, %args) = @_;
    my $channel_id = $args{channel} || 0;

    # Prepare empty traffic path reports

    my $reports = {};

    # Get a channel list (if used)

    my @channel_ids = split /,/, $channel_id;
    foreach my $channel_id (@channel_ids)
    {
        # Refresh today's traffic path data

        $self->refresh() unless $args{end_date};

        # Get traffic path data through a page

        $self->get_path_report( reports => $reports,
                                channel_id => $channel_id,
                                hosts => $args{hosts},
                                users => $args{users},
                                page => $args{page},
                                start_date => $args{start_date},
                                end_date => $args{end_date},
                                include => $args{include},
                                exclude => $args{exclude} );
    } # channel list

    # Return the traffic path reports

    return $self->format_reports($reports);
}

=item get_path_report(%args)

Get traffic path data for a channel with optional filters to include and exclude

=cut
sub get_path_report
{
    my ($self, %args) = @_;
    my $reports = $args{reports} or die "no reports";
    my $site = $self->site() or die "no site";
    my $channel_id = $args{channel_id} || 0;
    my $hosts = $args{hosts};
    my $users = $args{users};
    my $page = $args{page};
    my $include = $args{include};
    my $exclude = $args{exclude};

    # Get the start and end times from normalized dates

    my $start_date = Utils::Time->normalize_date($args{start_date}, $site->{time_zone});
    my $end_date = Utils::Time->normalize_date($args{end_date}, $site->{time_zone});
    my ($start_time, $end_time) = Utils::Time->get_start_and_end_times($start_date, $end_date, $site->{time_zone});

    # Setup the reports data structure

    $reports->{site} ||= { id => $site->{site_id}, url => $site->{url}, time_zone => $site->{time_zone}, start_time => $start_time, end_time => $end_time, start_date => $start_date, end_date => $end_date };
    my $channel = $self->get_channel($reports, $site->{site_id}, $channel_id);

    # Connect to the site's main data server

    my $data_server = $site->data_server();
    my $dbh = $data_server->connect();

    # Get path data passing through the page

    my $total = 0;
    my $paths = {};
    my $database = 'stats' . $site->{site_id};
    my $host_clause = $self->host_clause($site, $hosts, 'V');
    my $user_clause = $self->user_clause($users, 'T');
    my $query = $dbh->prepare("select T.sequence, T.channels from $database.Traffic T, $database.Visit V where T.visit_id = V.visit_id and T.time between ? and ? $user_clause $host_clause");
    $query->execute($start_time, $end_time);
    while (my $row = $query->fetchrow_hashref())
    {
        # Check that the path includes our page (with optional query string)

        next if $page && "$row->{sequence}|" !~ /\s$page\/?(\?.*)?[\|\s]/;
        next if $channel_id and ",$row->{channels}," !~ /,$channel_id,/;

        # Process a traffic row to extract the path

        my $skip = $include ? 1 : 0;
        my $path = '';
        my @pages = ();
        my @sequence = split '\|', $row->{sequence};
        foreach my $p (@sequence)
        {
            my ($event_id, $duration) = ($1, $2) if $p =~ s/^(\d+):(\d+)\s//;
            next unless $event_id == Constants::Events::TYPE_PAGE || $event_id == Constants::Events::TYPE_FILE;
            my $refer_id = $1 if $p =~ s/\s(\d+)$//;
            push @pages, $p;
            $p =~ s/\/$//; # strip any trailing slash
            $skip = 0 if $include && $p =~ /$include/;
            $skip = 1 if $exclude && $p !~ /$exclude/;
            $path .= '|' if $path;
            $path .= $p;
        }
        next if $skip;

        # Count the path and remember to find the page titles

        $total++;
        $paths->{$path}++;
        foreach my $p (@pages)
        {
            $self->{titles}{$p}++;
        }
    }

    # Add page titles to the report

    $self->get_page_titles($channel, $dbh);

    # Include the number of matching visits

    $reports->{site}{total} = $total;
    $reports->{site}{units} = 'various';
    $reports->{stats} = $self->api_stats();

    # Disconnect from the data server

    $data_server->disconnect();

    # Return the path list in and out

    $channel->{report} = [
        {
            page => $page,
            start_date => $start_date,
            start_time => $start_time,
            end_date => $end_date,
            end_time => $end_time,
            include => $include,
            exclude => $exclude,
            path => $self->get_path_list($paths),
        },
    ];
}

=item get_path_list($paths)

Turn a paths hash into a list

=cut
sub get_path_list
{
    my ($self, $paths) = @_;
    my @list = ();
    foreach my $pages (sort keys %{$paths})
    {
        push @list, { pagepath => [split '\|', $pages], visits => $paths->{$pages} };
    }
    return \@list;
}

=item get_page_titles($channel, $dbh)

Get the titles for all the page URLs

=cut
sub get_page_titles
{
    my ($self, $channel, $dbh) = @_;
    my $site = $self->site();
    my $database = 'stats' . $site->{site_id};

    # Get a hash of page titles for URLs

    my $query = $dbh->prepare("select url, title from $database.Page");
    $query->execute();
    my %pages = ();
    while (my $row = $query->fetchrow_hashref())
    {
        my $url = $row->{url}; $url =~ s/\/$//; # remove trailing slash
        $pages{$url} = $row->{title} if $self->{titles}{$row->{url}};
    }

    # List all the pages in the hash

    my @pages;
    while (my ($url, $title) = each(%pages))
    {
        push @pages, { url => $url, title => $title };
    }

    # Add the list to the report XML

    $channel->{pages} = { page => \@pages };
}

=item get_channel($reports, $site_id, $channel_id)

Return channel data hash for a web site channel ID

=cut
sub get_channel
{
    my ($self, $reports, $site_id, $channel_id) = @_;

    # Return the current channel if it has the right channel ID

    if ($self->{channels} > 0)
    {
        my $current = $reports->{site}{channel}[$self->{channels}-1];
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

    my $channel = $reports->{site}{channel}[$self->{channels}++] = { id => $channel_id, name => $channel_name };
    return $channel;
}

}1;

=back

=head1 DEPENDENCIES

Client::Reporter, Data::SiteChannel, Data::Page, Utils::Time

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
