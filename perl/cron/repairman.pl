#!/usr/bin/env perl

use strict;

use lib "$ENV{SERVER_HOME}/perl/lib";
use Data::Site;
use Utils::Time;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

my $days_ago = shift || 1;
my $date = Utils::Time->get_date(time() - $days_ago * Utils::Time::DAY_SECS);
open (LOG, "$ENV{LOGS_DIR}/reporter/$date.txt");
my @crashed = grep /crashed/, <LOG>;
close LOG;

my %sites = ();
foreach (@crashed)
{
    my ($site_id, $table) = ($1, $2) if m#stats(\d+)/(\w+)#;
    my $tables = $sites{$site_id} ||= {};
    $tables->{$table} = 'crashed';
}

Data::Site->connect();
while (my ($site_id, $tables) = each %sites)
{
    my $site = Data::Site->row($site_id);
    if ($site->{site_id})
    {
        my $data_server = $site->data_server();
        my $database    = $site->database();
        foreach my $table (keys %{$tables})
        {
            my $sql = "repair table $database.$table";
            print "Running SQL: $sql\n";
            $data_server->sql($sql);
        }
        $data_server->disconnect();
    }
}
Data::Site->disconnect();

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Data::Site, Utils::Time, Utils::PidFile

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
