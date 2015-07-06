#!/usr/bin/env perl

=head1 NAME

apache - Check that the web server is running

=head1 DESCRIPTION

This program checks that the web server is running fine, and exits with an error
code if it isn't.

=cut

use strict;
use warnings;

use constant TOO_SLOW => 10; # seconds
use constant TOO_MANY => (`grep MaxClients /etc/apache2/httpd.conf` =~ /(\d+)/ ? $1 - 20 : 200); # processes

use Sys::Hostname;

# Find the Apache port by reading the config file

sub port
{
    my $config_file = '/etc/apache2/ports.conf';
    return 80 unless -f $config_file;
    open (CFG, $config_file);
    my $line = <CFG>;
    close CFG;
    return $3 if $line =~ /(Listen|NameVirtualHost) ([\w\.]+:)?(\d+)$/;
    return 80;
}

# Is the web server running too slowly?

my $hostname = hostname();
my $port = port();
my $then = time();
open (GET, "/usr/bin/wget -O- http://$hostname:$port/ 2>/dev/null |");
my $return_code = 0;
my @page = <GET>;
close GET;
my $secs = time() - $then;
if (!grep /body/, @page)
{
	print STDERR "Web server is not running\n";
	$return_code = 1
}
elsif ($secs >= TOO_SLOW)
{
	print STDERR "Web server is running slowly\n";
	$return_code = 1
}

# Is the web server running too many processes?

open (PS, "ps -e|");
my $processes = grep /httpd/, <PS>;
close PS;
if ($processes > TOO_MANY)
{
	print STDERR "Web server is too busy - running $processes processes\n";
	$return_code = 1
}

exit $return_code;
__END__

=head1 DEPENDENCIES

Sys::Hostname

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
