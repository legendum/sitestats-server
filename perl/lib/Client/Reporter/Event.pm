#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Event - parse and match events in visit data

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Event, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Event parses and matches events in visit data.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Event;
$VERSION = "1.0";

use strict;
use Constants::Events;
{
    use constant TOO_MANY_EVENTS => 1000;

=head2 Class Methods

=over 4

=item parse($event)

Parse an event into its channel_id, type_id, duration, name, refer id, class

=cut
sub parse
{
    my ($class, $event) = @_;
    return () unless $event;
    my @parts = split / /, $event;
    $parts[Constants::Events::PART_NAME] =~ s/%20/ /g;
    $parts[Constants::Events::PART_CLASS] =~ s/%20/ /g if $parts[Constants::Events::PART_CLASS];
    return @parts;
}

=item find_first_page($visit_data)

Find the first page in the visit data, or return an empty string otherwise

=cut
sub find_first_page
{
    my ($class, $visit_data) = @_;

    # Look at all events in turn

    for (my $i = 1; $i < TOO_MANY_EVENTS; $i++)
    {
        my $event = $visit_data->{"e$i"} or last;
        my @parts = $class->parse($event);
        return $parts[Constants::Events::PART_NAME]
            if $parts[Constants::Events::PART_TYPE_ID] == Constants::Events::TYPE_PAGE;
    }

    # No page was found

    return '';
}

=back

=head2 Object Methods

=over 4

None

=cut

}1;

=back

=head1 DEPENDENCIES

Constants::Events

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
