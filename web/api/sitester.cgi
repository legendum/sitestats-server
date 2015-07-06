#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Client::Sitester;

# Make a new Page report API object

my $api = Client::Sitester->new();

# Wrap the code in an eval to catch errors

eval {

$api->call_token();

# Get the report

my $site_id = $api->{site}{site_id};
my $host = $api->{site}->data_server()->{host};
my $log_info = `$ENV{SERVER_HOME}/bin/xlocks -site=$site_id -host=$host`;
$ENV{DEBUG} = $ENV{LOGGING_LEVEL} = 1 if $api->param('debug');

my $date = $api->param('date');
my $output = $api->generate( start_date => $api->param('start_date', $date),
                             end_date   => $api->param('end_date', $date),
                             hosts      => $api->param('hosts'),
                             users      => $api->param('users'),
                             name       => $api->param('report'),
                             channel    => $api->param('channel'),
                             include    => $api->param('include'),
                             exclude    => $api->param('exclude'),
                             group_by   => $api->param('group_by'),
                             language   => $api->param('language'),
                             log_info   => $log_info );

# Finally, write the report

$api->display($output);

}; # End of the eval block
$api->error($@) if $@;

__END__

=head1 DEPENDENCIES

Client::Sitester, the "xlocks" program to check for MySQL table locks

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
