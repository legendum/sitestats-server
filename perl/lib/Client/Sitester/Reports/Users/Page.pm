#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Reports::Users::Page - Make visit reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users::Page, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users::Page makes visit reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users::Page;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports::Users';

use Constants::Events;
use Client::Reporter::Traffic;
{
    my $_Max_session_length_in_secs = 30 * 60;

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users::Page subclass object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{site_search} = Data::SiteConfig->find($self->{config}, 'site_search');
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item traffic_stats($channel_id, $report_id, $traffic)

Turn web traffic into a stats report

=cut
sub traffic_stats
{
    my ($self, $channel_id, $report_id, $traffic) = @_;
    my $page_stats = $self->page_stats($channel_id, $traffic);

    return $page_stats->{page}
        if $report_id == Constants::Reports::PAGE;

    return $page_stats->{directory}
        if $report_id == Constants::Reports::DIRECTORY;

    return $page_stats->{duration}
        if $report_id == Constants::Reports::PAGE_DURATION;

    return $page_stats->{navigation}
        if $report_id == Constants::Reports::PAGE_NAVIGATION;

    return $page_stats->{visits}
        if $report_id == Constants::Reports::PAGE_VISITS;

    return $page_stats->{'file'}
        if $report_id == Constants::Reports::FILE;

    return $page_stats->{'link'}
        if $report_id == Constants::Reports::LINK;

    return $page_stats->{'mail'}
        if $report_id == Constants::Reports::MAIL;

    return $page_stats->{'site_search_phrase'}
        if $report_id == Constants::Reports::SITE_SEARCH_PHRASE;

    return $page_stats->{'site_search_word'}
        if $report_id == Constants::Reports::SITE_SEARCH_WORD;
}

=item page_stats($channel_id, $traffic)

Generate a page stats report from web traffic data

=cut
sub page_stats
{
    my ($self, $channel_id, $traffic) = @_;

    # Collate stats by looking at every visit

    my $stats = {};
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        $self->parse_sequence($stats, $channel_id, $visit);
    }

    # Set the page durations to be averages

    $self->page_duration_averages($stats);

    return $stats;
}

=item parse_sequence($stats, $channel_id, $visit)

Parse a sequence of page views to update a hashref of stats about the visit

=cut
sub parse_sequence
{
    my ($self, $stats, $channel_id, $visit) = @_;

    # Parse the page sequence to get stats

    my @channels = Client::Reporter::Traffic->get_channels($visit);
    my @events = Client::Reporter::Traffic->get_sequence_events($visit);
    my %pages_seen = ();
    my $last_page = '';
    foreach my $event (@events)
    {
        next if $channel_id && $channel_id != shift @channels;

        # Extract the type_id, duration, page and any referrer ID from the event

        my ($type_id, $durn, $page, $refer_id) = Client::Reporter::Traffic->parse_sequence_event($event);

        # Increment the stats

        $stats->{page}{$page}++ if $type_id == Constants::Events::TYPE_PAGE;
        $stats->{file}{$page}++ if $type_id == Constants::Events::TYPE_FILE;
        $stats->{link}{$page}++ if $type_id == Constants::Events::TYPE_LINK;
        $stats->{mail}{$page}++ if $type_id == Constants::Events::TYPE_MAIL;

        next unless $type_id == Constants::Events::TYPE_PAGE;

        $pages_seen{$page}++;
        $stats->{duration}{$page} += $durn;
        $stats->{navigation}{"${last_page}->$page"}++ if $last_page;
        my $directory = ($page =~ m#^([^\?]+)/# ? $1 : '/');
        $stats->{directory}{$directory}++;

        $last_page = $page;

        $self->site_search($stats, $page) if $self->{site_search};
    }

    # Increment pages that were visited

    foreach my $seen (keys %pages_seen)
    {
        $stats->{visits}{$seen}++;
    }
}

=item site_search($stats, $page)

Measure any search inside the web site

=cut
sub site_search
{
    my ($self, $stats, $page) = @_;
    my $pos = rindex $page, $self->{site_search};
    if ($pos > -1)
    {
        $pos += length $self->{site_search};
        my $search = substr $page, $pos;
        $stats->{site_search_phrase}{$search} = 1;
        foreach my $word (split /\s+/, $search)
        {
            $stats->{site_search_word}{lc($word)}++ if length $word;
        }
    }
}

=item page_duration_averages($stats)

Update page durations

=cut
sub page_duration_averages
{
    my ($self, $stats) = @_;

    map { $stats->{duration}{$_} /= ($_ =~ /mail:(.+)/ ?
                               $stats->{mail}{$1} || 1 :
                               $stats->{page}{$_} || 1) }
                               keys %{$stats->{duration}};

    while (my ($page, $secs) = each %{$stats->{duration}})
    {
        $stats->{duration}{$page} = int($secs); # round down the seconds
    }
}

}1;

=back

=head1 DEPENDENCIES

Constants::Events, Client::Sitester::Reports::Users

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
