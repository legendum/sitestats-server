#!/usr/bin/env perl

=head1 NAME

Utils::LoadAvg - Check the server load average

=head1 VERSION

This document refers to version 1.0 of Utils::LoadAvg, released Jul 07, 2015

=head1 DESCRIPTION

Utils::LoadAvg checks the server load average

=head2 Properties

=over 4

=item path

The path to a logging directory

=item level

The level of logging to write

=back

=cut
package Utils::LoadAvg;
$VERSION = "1.0";

use strict;
{
    use constant DEFAULT_MAX_LOAD_AVG => 5.0;

=head2 Class Methods

=over 4

=item new($max_load_avg)

Open a log file at a logging level

=cut
sub new
{
    my ($class, $max_load_avg) = @_;

    my $self = {
        maximum => $max_load_avg || DEFAULT_MAX_LOAD_AVG,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item maximum()

Get/set the maximum load average that's considered ok

=cut
sub maximum
{
    my ($self, $max_load_avg) = @_;
    $self->{maximum} = $max_load_avg if $max_load_avg;
    return $self->{maximum};
}

=item now()

Get the load average right now

=cut
sub now
{
    open (LOAD_AVG, "cat /proc/loadavg|");
    my $load_avg = <LOAD_AVG>;
    close LOAD_AVG;
    my @loads = split(/\s+/, $load_avg);
    return $loads[0];
}

=item too_high()

Return whether the load average is too high

=cut
sub too_high
{
    my ($self) = @_;
    return $self->now() > $self->{maximum} ? 1 : 0;
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
