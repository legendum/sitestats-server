#!/usr/bin/env perl

=head1 NAME

Client::Reporter::StatReporter::Stats - generate reports about web site visits

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats::Visits, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats::Visits generates reports about web site visits

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats::Visits;
$VERSION = "1.0";

use strict;
use base 'Client::Reporter::Stats::Report';
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Stats::Visits object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    my $self = {
        site        => $reporter->{site},
        stats       => $reporter->{stats},
        channels    => $reporter->{channels},
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item report($visit_data, $visit)

Report the visit

=cut
sub report
{
    my ($self, $visit_data, $visit) = @_;

    if (!$visit_data->{ui})
    {
        $visit->[Constants::Reports::TRAFFIC]{unknown_visits} = 1;
        return 0;
    }

    # First time visitor if user and viist ids match

    if ($visit_data->{ui} eq $visit_data->{vi})
    {
        $visit->[Constants::Reports::TRAFFIC]{first_times} = 1;
        my $visit_duration = $visit->[Constants::Reports::THIS_VISIT_DURATION] || 0;
        $visit->[Constants::Reports::TRAFFIC]{first_times_duration} = $visit_duration;
    }

    $visit->[Constants::Reports::TRAFFIC]{visits_interested} = 1 if $visit->[Constants::Reports::THIS_VISIT_DURATION] > 1;
    $visit->[Constants::Reports::TRAFFIC]{cookies} = 1 if $visit_data->{co} ne 'no';
    $visit->[Constants::Reports::TRAFFIC]{java} = 1 if $visit_data->{ja} ne 'no';
    $visit->[Constants::Reports::TRAFFIC]{javascript} = 1 if $visit_data->{js} ne 'no';
    $visit->[Constants::Reports::TRAFFIC]{flash} = 1 if $visit_data->{fl} ne 'no';
    $visit->[Constants::Reports::JAVA_VERSION]{$visit_data->{ja}} = 1;
    $visit->[Constants::Reports::JAVASCRIPT_VERSION]{$visit_data->{js}} = 1;
    $visit->[Constants::Reports::FLASH_VERSION]{$visit_data->{fl}} = 1;
    $visit->[Constants::Reports::OP_SYS]{$visit_data->{os}} = 1;
    $visit->[Constants::Reports::BROWSER]{$visit_data->{ua}} = 1;
    $visit->[Constants::Reports::COUNTRY]{$visit_data->{gc}} = 1;
    my $city = $visit_data->{gt} || ''; $city .= ',' if $city;
    my $region = $visit_data->{gr} || ''; $region .= ',' if $region;
    $region = '' if $region =~ /\d+/;
    my $longitude = $visit_data->{go} || 0; $longitude /= 10_000;
    my $latitude = $visit_data->{ga} || 0;   $latitude /= 10_000;
    $visit->[Constants::Reports::LOCATION]{"$city$region$visit_data->{gc}|$latitude,$longitude"} = 1;
    $visit->[Constants::Reports::LANGUAGE]{$visit_data->{la}} = 1;
    $visit->[Constants::Reports::COLOR_BITS]{$visit_data->{cb}} = 1;
    $visit->[Constants::Reports::RESOLUTION]{$visit_data->{sr}} = 1;
    $visit->[Constants::Reports::HOST]{$visit_data->{ho}} = 1;
    $visit->[Constants::Reports::TIME_ZONE]{$visit_data->{tz}} = 1;

    # Report any referrer

    $self->referrer($visit_data, $visit) if $visit_data->{re} && !$visit->[Constants::Reports::CAMPAIGN_ENTRY_PAGE];

    # Measure the user id

    $visit->[Constants::Reports::USER]{"$visit_data->{ui}"} = 1 if $visit_data->{ui};

    # Don't filter

    return 0;
}

=item referrer($visit_data, $visit)

Report the referrer

=cut
sub referrer
{
    my ($self, $visit_data, $visit) = @_;
    my $referrer = $visit_data->{re} or return;

    $visit->[Constants::Reports::TRAFFIC]{referrer_visits} = 1;
    $visit->[Constants::Reports::REFERRER_PAGE]{$referrer} = 1;
    $referrer =~ s#(\.\w+)/.*$#$1#; # remove directory and page
    $visit->[Constants::Reports::REFERRER_SITE]{$referrer} = 1;

    # Report any search phrase

    if (my $search = lc $visit_data->{se})
    {
        $visit->[Constants::Reports::TRAFFIC]{search_visits} = 1;
        $visit->[Constants::Reports::REFERRER_SEARCH]{$referrer} = 1;
        $visit->[Constants::Reports::SEARCH_PHRASE]{$search} = 1;
        $visit->[Constants::Reports::SEARCH_ENGINE_PHRASE]{"$referrer $search"} = 1;

        foreach my $word (split /\s+/, $search)
        {
            $visit->[Constants::Reports::SEARCH_WORD]{lc($word)}++ if length $word;
        }
    }
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports

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
