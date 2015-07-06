#!/usr/bin/env perl

=head1 NAME

Utils::Country - Reference information about the countries of the world

=head1 VERSION

This document refers to version 1.0 of Utils::Country, released Jul 07, 2015

=head1 DESCRIPTION

Utils::Country holds reference information about the countries of the world.

=head2 Properties

=over 4

None

=back

=cut
package Utils::Country;
$VERSION = "1.0";

use strict;
use Constants::Countries;
{
    # Class static properties

    my @_Country_codes = sort keys(%{(Constants::Countries::NAMES)});
    my %_Country_ids; my $_Country_id = 0; # zero = "unknown"
    map {$_Country_ids{$_} = $_Country_id++} @_Country_codes;

=head2 Class Methods

=over 4

=item name($code)

Return the name of a country, given its 2-letter ISO code

=cut
sub name
{
    my ($class, $code) = @_;
    return (Constants::Countries::NAMES)->{$code} || '';
}

=item id($code)

Return an ID number for a country code - i.e. where it appears in the list

=cut
sub id
{
    my ($class, $code) = @_;
    return $_Country_ids{$code} || 0;
}

=item for_id($id)

Return a country code and name for an ID number - i.e. its position in the list

=cut
sub for_id
{
    my ($class, $id) = @_;
    return unless $id >= 0;
    my $code = $_Country_codes[$id] || '';
    return ($code, $class->name($code));
}

}1;

=back

=head1 DEPENDENCIES

None

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
