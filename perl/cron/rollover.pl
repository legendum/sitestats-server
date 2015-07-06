#!/usr/bin/env perl

use strict;

use lib "$ENV{SERVER_HOME}/perl/lib";
use Sys::Hostname;
use Data::Site;
use Data::SiteConfig;
use IO::Socket;

# Get last month number

my $tomorrow = time() + 86400 / 2;
my ($mday, $month, $year) = (gmtime($tomorrow))[3, 4, 5];

# Correct for new years

if ($month == 0)
{
    $month = 12;
    $year--;
}
my $date = sprintf("%04d%02d", $year + 1900, $month);
my $hour = (gmtime())[2]; # for time zones

# Get this server's IP address

my $host_ip = inet_ntoa(inet_aton($ENV{HOSTNAME}));

# Connect to the master database

Data::Site->connect();
Data::SiteConfig->connect();

# Rollover stats for the right time zone

my $time_zone = 0 - $hour;
$time_zone += 24 if $time_zone < -11;
$time_zone -= 24 if $time_zone >  12;
$time_zone = 0;

# Rollover stats for all sites in the time zone

my $query = "time_zone = ? and (comp_server like '%$ENV{HOSTNAME}%' or comp_server like '%$host_ip%') and status <> 'S'";
for (my $site = Data::Site->select($query, $time_zone);
        $site->{site_id};
        $site = Data::Site->next($query))
{
    my $site_id = $site->{site_id} or next;
    my $site_config = Data::SiteConfig->get($site_id);
    next unless lc Data::SiteConfig->find($site_config, 'rollover') eq 'yes';

    # Rename the larger database tables to include the year and month

    my $data_server = $site->data_server();
    my $database    = $site->database();
    $data_server->sql("rename table $database.Traffic to $database.Traffic$date");
    $data_server->sql("rename table $database.Visit to $database.Visit$date");
    $data_server->sql("rename table $database.Event to $database.Event$date");

    # Disconnect from the local database

    $data_server->disconnect();

    # Create new vanilla database tables

    my $host = $data_server->{host};
    my $driver = $data_server->{driver};
    my $username = $data_server->{username};
    my $password = $data_server->{password};
    my $cmd = "/usr/bin/mysql -u$username -p$password -h$host $database <$ENV{SERVER_HOME}/mysql/stats.sql";
    print "Running $cmd\n" if $driver eq 'mysql';
    system($cmd) if $driver eq 'mysql';

    # TODO: Create new MS SQL tables too
}

# Disconnect from the master database

Data::Site->disconnect();
Data::SiteConfig->disconnect();

__END__

=head1 DEPENDENCIES

Data::Site, Data::SiteConfig, IO::Socket

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
