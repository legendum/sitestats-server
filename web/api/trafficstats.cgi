#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Client::TrafficStats;

# Make a new Traffic report API object

my $api = Client::TrafficStats->new();

# Wrap the code in an eval to catch errors

eval {

$api->call_token();

# Get the report

my $output = $api->generate( date    => $api->param('date'),
                             channel => $api->param('channel_id'),
                             limit   => $api->param('limit'),
                             include => $api->param('include'),
                             exclude => $api->param('exclude') );

# Finally, write the report

$api->display($output);

}; # End of the eval block
$api->error($@) if $@;

__END__

=head1 DEPENDENCIES

Client::TrafficStats

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
