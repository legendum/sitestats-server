#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Reports::Content - generate reports about web site visits

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Reports::Content, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Reports::Content generates reports about web site visits

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Reports::Content;
$VERSION = "1.0";

use strict;
use Constants::Reports;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reports)

Create a new Client::Reporter::Reports::Content object

=cut
sub new
{
    my ($class, $reports) = @_;

    my $self = {
        reports => $reports,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item visit($visit_data)

Measure the visit

=cut
sub visit
{
    my ($self, $visit_data) = @_;
    my $entry_page = $visit_data->{e1};

    # TODO

    #$self->{reports}
    #->report(Constants::Reports::TIME_ZONE, $time_zone, $visit_data);
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
