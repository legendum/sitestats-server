#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Stats::Report - the stats report base class

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats::Report, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats::Report is the base class for the stats report classes.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats::Report;
$VERSION = "1.0";

use strict;
use Constants::Reports;
use Constants::Events;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

None 

=cut

=back

=head2 Object Methods

=over 4

=item report($visit_data, $visit)

Report the visit - this MUST be subclasses in your stats report class

=cut
sub report
{
    my ($self, $visit_data, $visit) = @_;
    die "Subclass this in your stats report class";
}

=item start()

Start the report - this MAY be subclasses in your stats report class

=cut
sub start
{
    my ($self) = @_;
}

=item finish()

Finish the report - this MAY be subclasses in your stats report class

=cut
sub finish
{
    my ($self) = @_;
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports, Constants::Events

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
