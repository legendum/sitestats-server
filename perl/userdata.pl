#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Data::Site;
use Client::UserData;

# Get the number of days ago to report

my $days_ago = shift;
my @site_ids = @ARGV;
die "usage: $0 days_ago site1 [site2...]" unless @site_ids;

# Get the web site IDs

foreach my $site_id (@site_ids)
{
    # Translate URL to site ID

    if ($site_id !~ /^\d+$/)
    {
        my $url = $site_id;
        Data::Site->connect();
        my $site = Data::Site->select('url = ?', $url);
        Data::Site->disconnect();
        $site_id = $site->{site_id} or die "site $url not found";
    }

    # Get any day range

    my $days_from = $days_ago;
    my $days_to = $days_ago;
    ($days_from, $days_to) = split /\.\./, $days_ago if $days_ago =~ /\.\./;

    # Generate user data for the specified date range

    my $user_data = Client::UserData->new($site_id);
    for ($days_ago = $days_from; $days_ago <= $days_to; $days_ago++)
    {
        $user_data->generate($days_ago);
    }
}

__END__

=head1 DEPENDENCIES

Data::Site, Client::UserData

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
