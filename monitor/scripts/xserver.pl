#!/usr/bin/env perl

=head1 NAME

xserver - Check that the SiteStats Server processes are running

=head1 DESCRIPTION

This program checks that the SiteStats Server processes are running.

=cut

use strict;
use warnings;

# Check the SiteStats Server processes

my $xserver = "$ENV{SERVER_HOME}/bin/xserver";
open (STATUS, "$xserver -status|");
my $return_code = 0;
while (<STATUS>)
{
	if (/not running/i)
	{
		$return_code = 1;
		print STDERR $_;
	}
}
close STATUS;

system("$xserver -start") if $return_code;
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
