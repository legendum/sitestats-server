#!/usr/bin/env perl 

=head1 NAME

Client::Funnel - Write web traffic funnel report data as CSV, XML, HTML or JSON

=head1 VERSION

This document refers to version 1.0 of Client::Funnel, released Jul 07, 2015

=head1 DESCRIPTION

Client::Funnel writes web traffic funnel report data as CSV, XML, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Funnel;
$VERSION = "1.0";

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
    );
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item refresh()

Refresh today's traffic funnel data if it's stale

=cut
sub refresh
{
    my ($self) = @_;
    return if $self->{site}{report_time} > time() - STALE_TIME;
    $self->{site} = Client::Reporter->new($self->{site}{site_id})->generate();
}

=item generate(date => $date, channel => $channel_id, name => $name, format => $format, include => $include, exclude => $exclude)

Generate traffic funnel data from web site activity records

=cut
sub generate
{
    my ($self, %args) = @_;
    my $channel_id = $args{channel} || 0;

    # Prepare empty traffic funnel reports

    my $reports = {};

    # Get a channel list (if used)

    my @channel_ids = split /,/, $channel_id;
    foreach my $channel_id (@channel_ids)
    {
        # Refresh today's traffic funnel data

        $self->refresh() unless $args{end_date};

        # Get traffic funnel data through a page

        $self->get_funnel_report( reports => $reports,
                                  channel_id => $channel_id,
                                  hosts => $args{hosts},
                                  users => $args{users},
                                  pages => $args{pages},
                                  match => $args{match},
                                  start_date => $args{start_date},
                                  end_date => $args{end_date},
                                  include => $args{include},
                                  exclude => $args{exclude} );
    } # channel list

    # Return the traffic funnel reports

    return $self->format_reports($reports);
}

=item get_funnel_report(%args)

Get traffic funnel data for a channel with optional include and exclude filters

=cut
sub get_funnel_report
{
    my ($self, %args) = @_;
    my $reports = $args{reports} or die "no reports";
    my $site = $self->site() or die "no site";
    my $channel_id = $args{channel_id} || 0;
    my $hosts = $args{hosts};
    my $users = $args{users};
    my @pages = split /,/, $args{pages};
    my $match = $args{match};
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

    # Get funnel data passing through the page

    my $total = 0;
    my $funnels = {};
    my $database = 'stats' . $site->{site_id};
    my $host_clause = $self->host_clause($site, $hosts, 'V');
    my $user_clause = $self->user_clause($users, 'T');
    my $page_clause = $self->page_clause($pages[0], 'T');
    my $query = $dbh->prepare("select T.sequence, T.channels from $database.Traffic T, $database.Visit V where T.visit_id = V.visit_id and T.time between ? and ? $user_clause $host_clause $page_clause");
    $query->execute($start_time, $end_time);
    while (my $row = $query->fetchrow_hashref())
    {
        # Check that the funnel includes our page (with optional query string)

        next if $channel_id and ",$row->{channels}," !~ /,$channel_id,/;

        # Process a traffic row to extract the funnel

        my $skip = $include ? 1 : 0;
        my $path = '';
        my @to_match = @pages;
        my @sequence = split '\|', $row->{sequence};
        foreach my $p (@sequence)
        {
            my ($event_id, $duration) = ($1, $2) if $p =~ s/^(\d+):(\d+)\s//;
            next unless $event_id == Constants::Events::TYPE_PAGE || $event_id == Constants::Events::TYPE_FILE;
            my $refer_id = $1 if $p =~ s/\s(\d+)$//;
            my $next_page_to_match = $to_match[0];
            $next_page_to_match = 'Home%20page' if $next_page_to_match eq 'Home page';
            if ($p !~ /^$next_page_to_match\/?$/)
            {
                $match eq 'exact' ? last : next;
            }
            shift @to_match;
            $p =~ s/\/$//; # strip any trailing slash
            $skip = 0 if $include && $p =~ /$include/;
            $skip = 1 if $exclude && $p !~ /$exclude/;
            $path .= '|' if $path;
            $p = 'Home page' if $p eq 'Home%20page';
            $path .= $p;
            last unless @to_match;
        }
        next if $skip;

        # Count the funnel paths that were matched, including ancestor paths

        while ($path =~ /\|/)
        {
            $funnels->{$path}++;
            $path =~ s/\|.*$//;
        }
        $funnels->{$path}++ if $path;

        # Update the total

        $total++;
    }

    # Add page titles to the report

    $self->get_page_titles($channel, $dbh, @pages);

    # Include the number of matching visits

    $reports->{site}{total} = $total;
    $reports->{site}{units} = 'various';
    $reports->{stats} = $self->api_stats();

    # Disconnect from the data server

    $data_server->disconnect();

    # Return the funnel list in and out

    $channel->{report} = [
        {
            funnel => {page => \@pages},
            start_date => $start_date,
            start_time => $start_time,
            end_date => $end_date,
            end_time => $end_time,
            include => $include,
            exclude => $exclude,
            funnel => $self->get_funnel_list($funnels),
        },
    ];
}

=item get_funnel_list($funnels)

Turn a funnels hash into a list

=cut
sub get_funnel_list
{
    my ($self, $funnels) = @_;
    my @list = ();
    foreach my $pages (sort keys %{$funnels})
    {
        push @list, { pagepath => [split '\|', $pages], visits => $funnels->{$pages} };
    }
    return \@list;
}

=item get_page_titles($channel, $dbh, @pages)

Get the titles for all the page URLs

=cut
sub get_page_titles
{
    my ($self, $channel, $dbh, @pages) = @_;
    my $site = $self->site();
    my $database = 'stats' . $site->{site_id};

    # Get a list of pages whose titles we need to find

    my @page_list = ();
    foreach my $page (@pages)
    {
        $page =~ s/'//g;
        $page =~ s/\/$//;
        push @page_list, "'$page'";
        push @page_list, "'$page/'";
    }
    my $page_list = join ',', @page_list;

    # Get a hash of page titles for URLs

    my $query = $dbh->prepare("select url, title from $database.Page where url in ($page_list)");
    $query->execute();
    my %pages = ();
    while (my $row = $query->fetchrow_hashref())
    {
        my $url = $row->{url}; $url =~ s/\/$//; # remove trailing slash
        $pages{$url} = $row->{title};
    }

    # List all the pages in the hash

    my @pages_with_titles;
    while (my ($url, $title) = each(%pages))
    {
        push @pages_with_titles, { url => $url, title => $title };
    }

    # Add the list to the report XML

    $channel->{pages} = { page => \@pages_with_titles };
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

=item get_channel($reports, $site_id, $channel_id)

Return channel data hash for a web site channel ID

=cut
sub page_clause
{
    my ($self, $page, $table) = @_;
    $page =~ s/'//g; # can't parse apostrophes
    $page = 'Home%20page' if $page eq 'Home page';

    return "and $table.sequence regexp ' $page/?[ \\|]'";
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
