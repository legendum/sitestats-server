#!/usr/bin/env perl

=head1 NAME

Constants::Reports - Contains all the web traffic report name/ID constants

=head1 VERSION

This document refers to version 1.0 of Constants::Reports, released Jul 07, 2015

=head1 DESCRIPTION

Constants::Reports contains all the web traffic repeort name/ID constants

=head2 Properties

=over 4

None

=back

=cut
package Constants::Reports;
$VERSION = "1.0";

use strict;

# Report ID numbers

use constant CHANNEL                => 0; # virtual report
use constant MIN_REPORTS            => 1; # first real report
use constant TRAFFIC                => 1;
use constant BROWSER                => 2;
use constant COUNTRY                => 3;
use constant LANGUAGE               => 4;
use constant TIME_ZONE              => 5;
use constant COLOR_BITS             => 6;
use constant RESOLUTION             => 7;
use constant OP_SYS                 => 8;
use constant HOST                   => 9;
use constant REFERRER_PAGE          => 10;
use constant REFERRER_SITE          => 11;
use constant REFERRER_SEARCH        => 12;
use constant SEARCH_WORD            => 13;
use constant SEARCH_PHRASE          => 14;
use constant PAGE                   => 15;
use constant DIRECTORY              => 16;
use constant ENTRY_PAGE             => 17;
use constant EXIT_PAGE              => 18;
use constant PAGE_NAVIGATION        => 19;
use constant PAGE_VISITS            => 20;
use constant COMMERCE_REFERRER      => 21;
use constant COMMERCE_ENTRY_PAGE    => 22;
use constant PAGE_DURATION          => 23;
use constant HOUR_OF_DAY_VISITS     => 24;
use constant COMMERCE_WORD          => 25;
use constant COMMERCE_PHRASE        => 26;
use constant BOUNCE_PAGE            => 27;
use constant REFERRER_HITS          => 28;
use constant VISIT_DURATION         => 29;
use constant VISIT_PAGES            => 30;
use constant SEARCH_ENGINE_PHRASE   => 31;
use constant COMMERCE_ENGINE_PHRASE => 32;
use constant MAIL                   => 33;
use constant HOUR_OF_DAY_HITS       => 34;
use constant SPIDER                 => 35;
use constant USER                   => 36;
use constant REFERRER_PATH          => 37;
use constant LOCATION               => 38;
use constant CAMPAIGN_ENTRY_PAGE    => 39;
use constant CAMPAIGN_COMMERCE      => 40;
use constant COMMERCE_PATH          => 41;
use constant LINK                   => 42;
use constant FILE                   => 43;
use constant JAVA_VERSION           => 44;
use constant JAVASCRIPT_VERSION     => 45;
use constant FLASH_VERSION          => 46;
use constant PAGE_LOAD_TIME         => 47;
use constant PAGE_CLASS             => 48;
use constant CAMPAIGN               => 49;
use constant SITE_SEARCH_WORD       => 50;
use constant SITE_SEARCH_PHRASE     => 51;
use constant MAX_REPORTS            => 51; # last generated report

# Dynamic reports that are generated as-needed but not stored in the database

use constant FREQUENCY              => 55;
use constant RECENCY                => 56;
use constant RANGE                  => 57;

# Pseudo-reports that are used for the measurement of each visit to the site

use constant THIS_VISIT_DURATION    => 58;
use constant THIS_VISIT_PAGES       => 59;
use constant THIS_VISIT_PATH        => 60;

# Field positions in detailed reports

use constant PART_FIRST_TIMES       => 0;
use constant PART_USERS             => 1;
use constant PART_VISITS            => 2;
use constant PART_HITS              => 3;
use constant PART_MAILS             => 4;
use constant PART_BOUNCES           => 5;
use constant PART_SUSPECT           => 6;
use constant PART_DURATION          => 7;
use constant PART_CAMPAIGNS         => 8;
use constant PART_CONVERSIONS       => 8;
use constant PART_CAMPAIGN_CONVS    => 10;
use constant PART_CAMPAIGN_GOALS    => 11;
use constant PART_GOALS             => 12;
use constant PART_COST              => 13;
use constant PART_REVENUE           => 14;
use constant PART_MAX               => 14;

=back

=head1 DEPENDENCIES

None

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
