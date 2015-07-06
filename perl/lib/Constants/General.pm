#!/usr/bin/env perl

=head1 NAME

Constants::General - Contains general web traffic reporting constants

=head1 VERSION

This document refers to version 1.1 of Constants::General, released Jul 07, 2015

=head1 DESCRIPTION

Constants::General contains general web traffic reporting constants

=head2 Properties

=over 4

None

=back

=cut
package Constants::General;
$VERSION = "1.1";

use strict;

# General constants

use constant HOME_PAGE              => 'Home page';
use constant DEFAULT_ENCODING       => 'utf-8';
use constant VISIT_DURATION         => 1800; # 30 minutes
use constant CACHE_DURATION         => 2400; # 40 minutes
use constant CACHE_BUSY_WAIT_SECS   => 120;  #  2 minutes
use constant DEFAULT_JOB_PRIORITY   => 100;
use constant WHOLE_SITE_CHANNEL_ID  => 0;

# Various service levels

use constant PRODUCT_CODE_ALERTS    => 'A';
use constant PRODUCT_CODE_LITE      => 'L';
use constant PRODUCT_CODE_PRO       => 'P';
use constant PRODUCT_CODE_COMMERCE  => 'C';

# Web site and account status values

use constant STATUS_LIVE            => 'L';
use constant STATUS_TRIAL           => 'T';
use constant STATUS_SUSPENDED       => 'S';

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
