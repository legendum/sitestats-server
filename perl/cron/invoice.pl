#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Getopt::Long;
use Data::Site;
use Data::SiteStats;
use Utils::PidFile;

my $pid_file = Utils::PidFile->new("$ENV{CRON_DIR}/pids");
exit unless $pid_file->create();

# Get the currency, prices and reseller

my ($ccy, $prices, $reseller_id);
GetOptions("ccy=s"      => \$ccy,
           "prices=s"   => \$prices,
           "reseller=i" => \$reseller_id,
           );
$ccy ||= 'GBP';
$prices ||= '20,30,40,50,10';
die "usage: invoice.pl -ccy=CCY -prices=10,20,30 -reseller=NNN" unless $ccy && $prices && $reseller_id;

# Get a list of sites for the reseller

Data::Site->connect();
my $query = 'status <> "S" and reseller_id = ?';
my @sites;
for (my $site = Data::Site->select($query, $reseller_id);
        $site->{site_id};
        $site = Data::Site->next($query))
{
    push @sites, $site;
}
Data::Site->disconnect();

# Get monthly traffic for the reseller's sites

Data::SiteStats->connect();
$query = 'period = "month" and site_id = ? order by the_date desc';
foreach my $site (@sites)
{
    my $site_id = $site->{site_id};
    my $traffic = Data::SiteStats->select($query, $site_id);
    $site->{hits} = $traffic->{hits} + 0;
    print "$site->{url} had $traffic->{hits} hits last month\n";
}
Data::SiteStats->disconnect();

# Now work out the bill

my %totals;
foreach my $site (@sites)
{
    my $url = $site->{url};
    $url =~ s/^www\.//;
    $url =~ s/\..+$//;
    $totals{$url} += $site->{hits};
}

my @prices = split /[,\s+]/, $prices;
my $total_hits = 0;
my $total_price = 0;
print "\n";
print "URL\tHits\tPrice\tCcy\n";
while (my ($url, $hits) = each %totals)
{
    $hits = int($hits / 1000);
    my $price = 0;
    if ($hits == 0) { $price = 0; }
    elsif ($hits < 100) { $price = $prices[0] + 0; }
    elsif ($hits < 250) { $price = $prices[1] + 0; }
    elsif ($hits < 500) { $price = $prices[2] + 0; }
    elsif ($hits < 1_000) { $price = $prices[3] + 0; }
    else {
        my $h = $hits;
        $price = $prices[3] + 0;
        $price += $prices[4] while (($h -= 1_000) > 0);
    }
    print "$url\t$hits\t$price\t$ccy\n";
    $total_hits += $hits;
    $total_price += $price;
}
print "Total\t$total_hits\t$total_price\t$ccy\n";
print "\n";

# Clean up and finish

$pid_file->remove();

__END__

=head1 DEPENDENCIES

Data::Site, Data::SiteStats, Utils::PidFile

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
