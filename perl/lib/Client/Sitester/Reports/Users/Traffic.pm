#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Reports::Users::Traffic - Make traffic reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users::Traffic, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users::Traffic makes traffic reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users::Traffic;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports::Users';
{
=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users::Traffic subclass object

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

    my %users = ();
    my $visits = 0;
    my $hits = 0;
    my $first_times = 0;
    my $search_visits = 0;
    my $referrer_visits = 0;
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        $users{"$visit->{ui}"}++;
        $visits++;
        my $sequence = $visit->{sq};
        my @events = split /\|/, $sequence;
        foreach my $event (@events)
        {
            $hits++ if $event =~ /^0:/; # "0" means page view
        }
        $first_times++ if $visit->{ui} eq $visit->{vi};
        $search_visits++ if $visit->{se};
        $referrer_visits++ if $visit->{re};
    }

    return {
        users => scalar keys %users,
        visits => $visits,
        hits => $hits,
        first_times => $first_times,
        search_visits => $search_visits,
        referrer_visits => $referrer_visits,
    };
}

}1;

=back

=head1 DEPENDENCIES

Client::Sitester::Reports::Users

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
