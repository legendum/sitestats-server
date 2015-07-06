#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::EN::Resolution looks up popular screen resolutions

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::EN::Resolution, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::EN::Resolution looks up popular screen resolutions

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::EN::Resolution;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
        '640x480'=>'640x480 (very small)',
        '800x600'=>'800x600 (small size)',
        '1024x768'=>'1024x768 (medium size)',
        '1280x800'=>'1280x800 (wide screen)',
        '1280x1024'=>'1280x1024 (large size)',
        '1600x1200'=>'1600x1200 (very large)',
    );

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Lookups::EN::Resolution object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new(\%_Lookup);
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

None

=cut
sub dummy
{
    my ($self) = @_;
}

}1;

=back

=head1 DEPENDENCIES

Client::Sitester::Lookups

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
