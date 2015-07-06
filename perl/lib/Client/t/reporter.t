#!/usr/bin/env perl -w

use strict;

use Test::More tests => 6;
use Client::Reporter;
use Data::Site;

use constant REPORT_DATE => 20080614; # matches data in sql/reporter.sql

sub setup
{
    # Ensure that site 2 is set up as a test site

    Data::Site->connect();
    my $site = Data::Site->row(2);
    return 0 unless $site->{site_id};
    $site->{url} = 'www.test-site.com';
    $site->{data_server} = $site->{comp_server} = 'localhost';
    $site->{host_filter} = $site->{host_ip_filter} = '';
    $site->{campaign_pages} = 'campaign1.html, campaign2.html';
    $site->{commerce_pages} = 'buy/this.html, buy/that.html';
    $site->update();
    Data::Site->disconnect();

    # Create a populated test database for site 2

    system "mysql -u$ENV{USER} -p$ENV{PASSWORD} < sql/reporter.sql";

    # Create stats reports

    my $reporter = Client::Reporter->new(2);
    $reporter->generate(REPORT_DATE);

    return 1; # success
}

sub stats_match
{
    my ($report_id, $field) = @_;

    # Get a list of all rows matching a field for a particular report ID

    Data::Site->connect();
    my $dbh = Data::Site->sql("select * from stats2.Stats where the_date = ? and report_id = ? and field = ?", REPORT_DATE, $report_id, $field);
    my $row = $dbh->fetchrow_hashref();
    my $value = $row ? $row->{value} : 0;
    Data::Site->disconnect();

    # Return the value

    return $value;
}

is(setup(), 1, 'created a test database for site 2');
is(stats_match(Constants::Reports::TRAFFIC, 'hits'), 5, '5 page views');
is(stats_match(Constants::Reports::TRAFFIC, 'visits'), 3, '3 visits');
is(stats_match(Constants::Reports::TRAFFIC, 'users'), 2, '2 users');
is(stats_match(Constants::Reports::PAGE, 'Home page'), 2, 'home page seen twice');
is(stats_match(Constants::Reports::CAMPAIGN_COMMERCE, 'campaign1.html test search->buy/that.html'), 1, 'link first campaign visit to second conversion visit');

__END__
