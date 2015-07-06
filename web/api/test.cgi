#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use CGI qw/:cgi -debug/;

# Return an error message to the user

sub error
{
    my $message = shift;
    print "Content-type: text/plain\n\nERROR: $message\n";
    exit;
}

# Get the query parameters

my $cgi = new CGI;
my $format = 'xml';

# Store the remote host address

my $host_ip = $ENV{HTTP_REMOTE_ADDR} = $cgi->remote_host();

# Wrap the code in an eval to catch errors

eval {

my $output = "<message>test from $host_ip</message>";
print "Content-type: text/$format\n\n$output";

}; # End of the eval block
error $@ if $@;

__END__

=head1 DEPENDENCIES

Just CGI

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
