#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Reports::Users::Visit - Make visit reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users::Visit, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users::Visit makes visit reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users::Visit;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports::Users';

use Constants::Events;
use Constants::Reports;
use Client::Reporter::Traffic;
{
=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users::Visit subclass object

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

=item traffic_stats($channel_id, $report_id, $traffic)

Turn web traffic into a stats report

=cut
sub traffic_stats
{
    my ($self, $channel_id, $report_id, $traffic) = @_;

    return $self->visit_duration($channel_id, $traffic)
        if $report_id == Constants::Reports::VISIT_DURATION;

    return $self->visit_pages($channel_id, $traffic)
        if $report_id == Constants::Reports::VISIT_PAGES;

    return $self->bounce_page($channel_id, $traffic)
        if $report_id == Constants::Reports::BOUNCE_PAGE;

    return $self->entry_page($channel_id, $traffic)
        if $report_id == Constants::Reports::ENTRY_PAGE;

    return $self->exit_page($channel_id, $traffic)
        if $report_id == Constants::Reports::EXIT_PAGE;
}

=item visit_duration($channel_id, $traffic)

Generate a visit duration report from web traffic data

=cut
sub visit_duration
{
    my ($self, $channel_id, $traffic) = @_;
    my %durations = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $stats = $self->parse_sequence($visit);
        my $mins = int($stats->{secs} / 60 + 0.5);
        $mins = 21 if $mins > 21;
        $durations{$mins}++;
    }

    return \%durations;
}

=item visit_pages($channel_id, $traffic)

Generate a visit pages report from web traffic data

=cut
sub visit_pages
{
    my ($self, $channel_id, $traffic) = @_;
    my %page_counts = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $stats = $self->parse_sequence($visit);
        my $count = $stats->{hits};
        $count = 21 if $count > 21;
        $page_counts{$count}++;
    }

    return \%page_counts;
}

=item bounce_page($channel_id, $traffic)

Generate a bounce page report from web traffic data

=cut
sub bounce_page
{
    my ($self, $channel_id, $traffic) = @_;
    my %bounce_pages = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $stats = $self->parse_sequence($visit);
        my $page = $stats->{bounce_page} || '';
        $bounce_pages{$page}++ if $page;
    }

    return \%bounce_pages;
}

=item entry_page($channel_id, $traffic)

Generate an entry page report from web traffic data

=cut
sub entry_page
{
    my ($self, $channel_id, $traffic) = @_;
    my %entry_pages = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $stats = $self->parse_sequence($visit);
        my $page = $stats->{entry_page} || '';
        $entry_pages{$page}++ if $page;
    }

    return \%entry_pages;
}

=item exit_page($channel_id, $traffic)

Generate an exit page report from web traffic data

=cut
sub exit_page
{
    my ($self, $channel_id, $traffic) = @_;
    my %exit_pages = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $stats = $self->parse_sequence($visit);
        my $page = $stats->{exit_page} || '';
        $exit_pages{$page}++ if $page;
    }

    return \%exit_pages;
}

=item parse_sequence($visit)

Parse a sequence of page views to return a hashref of stats about the visit

=cut
sub parse_sequence
{
    my ($self, $visit) = @_;

    # Parse the page sequence to get stats

    # TODO: Use the Traffic.duration instead

    my @events = split /\|/, $visit->{sq};
    my $secs = 0;
    my @pages = ();
    foreach my $event (@events)
    {
        my ($type_id, $durn, $event, $refer_id) = Client::Reporter::Traffic->parse_sequence_event($event);
        $secs += $durn if $durn;
        push @pages, $event if $type_id eq Constants::Events::TYPE_PAGE;
    }

    # Get stats about the page sequence

    my $hits = scalar @pages;
    my $bounce_page = $hits == 1 ? $pages[0] : '';
    my $entry_page = $pages[0];
    my $exit_page = $pages[-1];

    # Return stats about the page sequence

    return {
        hits => $hits,
        secs => $secs,
        bounce_page => $bounce_page,
        entry_page  => $entry_page,
        exit_page   => $exit_page,
    };
}

}1;

=back

=head1 DEPENDENCIES

Constants::Events, Constants::Reports, Client::Reporter::Traffic, Client::Sitester::Reports::Users

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
