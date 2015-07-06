#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Reports::Users::Location - Make location reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users::Location, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users::Location makes location reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users::Location;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports::Users';
{
=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users::Location subclass object

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

    my %locations = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $location = $visit->{co};
        $location = "$visit->{ci},$location" if $visit->{ci}; # prefix a city
        $locations{$location}++;
    }

    return \%locations;
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
