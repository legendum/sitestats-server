#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();

# Get the date and site ID from the command line

my ($date, $site_id, $format) = @ARGV;
die "usage: $0 date site_id [format]" unless $site_id;

# Get any channel ID from the site ID via the ID/N convention

my $channel_id = 0;
$channel_id = $1 if $site_id =~ s#/(\d+)##;
$format ||= 'xml';

# Generate the traffic as XML output by reading traffic stats

use Client::Traffic;
my $traffic = Client::Traffic->new($site_id);
print $traffic->generate(date   => $date,
                         channel => $channel_id,
                         format  => $format);

__END__

=head1 DEPENDENCIES

Client::Traffic

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
