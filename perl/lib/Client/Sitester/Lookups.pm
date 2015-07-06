#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Lookups - look up report fields to get friendly field names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups looks up report fields to get friendly field names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups;
$VERSION = "1.0";

use strict;
{
=head2 Class Methods

=over 4

=item new($lookup)

Create a new Client::Sitester::Lookups object with a hashref lookup parameter

=cut
sub new
{
    my ($class, $lookup, $regex) = @_;

    my $self = {
        lookup => $lookup,  # A hashref of code/name pairs
        regex  => $regex,   # Optional regex to find the code in the field
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item lookup($field)

Lookup a field to get a name

=cut
sub lookup
{
    my ($self, $field) = @_;

    # Don't lookup any "others" or empty field name

    return $field if $field eq 'others' or !$field;

    # Apply any regular expression

    if (my $regex = $self->{regex})
    {
        $field =~ s/$regex/$self->{lookup}{$1}/e;
        return $field;
    }

    # Default case is to lookup the field

    return $self->{lookup}{$field} || '';
}

=item language()

Return the langauge of this lookup object

=cut
sub language
{
    my ($self) = @_;
    my $class = ref($self) || $self;
    my $language = $1 if $class =~ /Lookups::(\w{2})/;
    return $language;
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
