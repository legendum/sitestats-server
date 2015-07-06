#!/usr/bin/env perl

use strict;
use LWP::UserAgent;

# Purge old reporter data files

my $reporter_days = $ENV{REPORTER_DAYS} || 1;
my $cmd = "/usr/bin/find $ENV{DATA_DIR}/reporter -type f -mtime +$reporter_days -exec rm -f {} \\;";
print "Running: $cmd\n";
system($cmd);

# Purge old sitester data files

my $url = "$ENV{WEB_ROOT_CLIENT}/purge.cgi";
print "Getting: $url\n";
LWP::UserAgent->new->get($url);

# Purge old Apache log files

my $web_data_days = $ENV{WEB_DATA_DAYS} || 1;
$cmd = "/usr/bin/find $ENV{DATA_DIR}/apache -type f -mtime +$web_data_days -exec rm -f {} \\;";
print "Running: $cmd\n";
system($cmd);

__END__

=head1 DEPENDENCIES

LWP::UserAgent

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
