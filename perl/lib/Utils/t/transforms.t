#!/usr/bin/env perl -w

use strict;

use Test::More tests => 19;
use Utils::Transforms;
use Constants::Events;

my $transforms = Utils::Transforms->new();
is($transforms->event_type_id('http'), Constants::Events::TYPE_PAGE, "'http' is a type of page");

is($transforms->time2id('1234567890'), '1234567890000000', "time2id() appends 6 zeros to an epoch time");

my $visit_id = $transforms->host2id(13631, '74.86.126.155', 1234567890);
is($transforms->host2id(13631, '74.86.126.155', 1234567890, '9999999999999999'), $visit_id, "host2id() prevents visit ID miscounting");

is($transforms->is_new_cookie_refuser('1234567890000000'), 1, "is_new_cookie_refuser() returns 1 first");
is($transforms->is_new_cookie_refuser('1234567890000000'), 0, "is_new_cookie_refuser() returns 0 after");

$transforms->clean(2000000000);
is($transforms->is_new_cookie_refuser('1234567890000000'), 1, "is_new_cookie_refuser() returns 1 first after a clean");

is($transforms->is_spider('Slurp'), 1, "is_spider() identifies spiders");
is($transforms->is_spider('Googlebot'), 1, "is_spider() identifies spiders");
is($transforms->is_spider('Kevin'), 0, "is_spider() identifies non-spiders");

is($transforms->computer('Windows XP'), 'WinXP', "computer() identifies operating systems");
is($transforms->computer('Apple Macintosh'), 'Mac', "computer() identifies operating systems");

my $array_ref = [['XPerform(.).(.)' => 'XP'], ['XIgnore(.).(.)' => 'XI']];
is($transforms->match('XPerform1.0', $array_ref), 'XP10', "match() matches array refs");

my $geo = $transforms->geo('74.86.126.155', 'en', 0, 1211846400);
is($geo->{country}, 'us', "geo() identifies country");
is($geo->{city}, 'Dallas', "geo() identifies city");
is($geo->{language}, 'en', "geo() identifies language");
is($geo->{time_zone}, '0', "geo() identifies time zone");

my ($referrer, $search) = $transforms->referrer('www.google.com/?q=blah', 'en');
is($referrer, 'www.google.com', "referrer() extracts the domain name");
is($search, 'blah', "referrer() extracts the search terms");

my $hash = $transforms->user_data("x=[1]");
is($hash->{x}, 1, "user_data() parses 'x=[1]'");

__END__
