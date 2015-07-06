#!/usr/bin/env perl

=head1 NAME

mysql - Check that the standard server processes are running

=head1 DESCRIPTION

This program checks that the standard server processes are running, including
Apache, MySQL and Postfix.

=cut

use strict;
use warnings;

my $httpd_ok = 0;
my $mysql_ok = 0;
open (PS, "ps -e|");
while (<PS>)
{
	$httpd_ok = 1 if /apache2?/ or /httpd/;
	$mysql_ok = 1 if /mysqld/;
}
close PS;

print STDERR "Apache processes are not running\n" unless $httpd_ok;
print STDERR "MySQL processes are not running\n" unless $mysql_ok;

exit !($httpd_ok && $mysql_ok);
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
