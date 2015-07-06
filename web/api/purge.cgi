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
my %params = $cgi->Vars;

# Store the remote host address

$ENV{HTTP_REMOTE_ADDR} = $cgi->remote_host();

# Wrap the code in an eval to catch errors

eval {

# Purge old data files

my $sitester_days = $ENV{SITESTER_DAYS} || 1;
system("/usr/bin/find $ENV{DATA_DIR}/sitester -type f -mtime +$sitester_days -exec rm -f {} \\;");
system("/usr/bin/find $ENV{DATA_DIR}/sitester -type f -name \\*.part -exec rm -f {} \\;");

# Finally, write "OK"

print "Content-type: text/plain\n\nOK\n";

}; # End of the eval block
error $@ if $@;

__END__

=head1 DEPENDENCIES

Data::APIToken, Client::Sites

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
