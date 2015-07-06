#!/usr/bin/env perl

use strict;

use lib "$ENV{SERVER_HOME}/perl/lib";
use Client::WorldStats;

# Get the number of days ago to report

my $days_ago = shift || 1;

# Get any day range

my $days_from = $days_ago;
my $days_to = $days_ago;
($days_from, $days_to) = split /\.\./, $days_ago if $days_ago =~ /\.\./;

# Generate world stats for the specified date range

my $world_stats = Client::WorldStats->new();
for ($days_ago = $days_from; $days_ago <= $days_to; $days_ago++)
{
    print "Generating world stats for $days_ago days ago\n";
    $world_stats->generate($days_ago);
}

__END__

=head1 DEPENDENCIES

Client::WorldStats

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
