#!/usr/bin/env perl

=head1 NAME

disk - List all disk partitions that are too full

=head1 DESCRIPTION

This program lists all disk partitions that are too full, and exits with an
error code if it finds any.

=cut

use strict;
use warnings;
use constant TOO_FULL_OF_DATA => 90; # percent

open (DF, "df -k|");
my $return_code = 0;
while (<DF>)
{
	chomp;
	my ($dev, $kbytes, $used, $avail, $capacity, $mount) = split;
	next unless $dev =~ /dev/;
	$capacity =~ s/%$//;
	if ($capacity >= TOO_FULL_OF_DATA)
	{
		print STDERR "$mount is $capacity% full\n";
		$return_code = 1;
	}
}
close DF;

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
