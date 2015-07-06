#!/usr/bin/env perl

=head1 NAME

loadavg - Check that the server load average is not too high

=head1 DESCRIPTION

This program checks the server load average, and exits with an error code if it
is too high.

=cut

use strict;
use warnings;
use constant TOO_HIGH_LOAD_AVG => 4.5;

my $return_code = 0;

open (AVG, "/proc/loadavg");
while (<AVG>)
{
	my ($now, $recent, $old) = split /\s+/;
	if ($now > TOO_HIGH_LOAD_AVG || $recent > TOO_HIGH_LOAD_AVG)
	{
		# Print the load average

		print STDERR "Load average is $now $recent $old:";

		# Print the busiest programs

		open (TOP, '/usr/bin/top -bn1|');
		my @top_lines = <TOP>;
		close TOP;
		print STDERR @top_lines;

		$return_code = 1;
	}
}
close AVG;

exit $return_code;
__END__

=head1 DEPENDENCIES

None

=head1 AUTHOR

Kevin Hutchinson (kevin.hutchinson@legendum.com)

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
