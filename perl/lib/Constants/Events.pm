#!/usr/bin/env perl

=head1 NAME

Constants::Events - Contains all the web traffic event type constants

=head1 VERSION

This document refers to version 1.0 of Constants::Events, released Jul 07, 2015

=head1 DESCRIPTION

Constants::Events contains all the web traffic event type constants

=head2 Properties

=over 4

None

=back

=cut
package Constants::Events;
$VERSION = "1.0";

use strict;

# Event parts (extracted from a list of parts)
# see Client::Reporter::DayFile->parse_event()

use constant PART_CHANNEL_ID        => 0;
use constant PART_TYPE_ID           => 1;
use constant PART_DURATION          => 2;
use constant PART_NAME              => 3;
use constant PART_REFER_ID          => 4;
use constant PART_CLASS             => 5;

# Event type ID numbers

use constant TYPE_PAGE              => 0;
use constant TYPE_FILE              => 1;
use constant TYPE_LINK              => 2;
use constant TYPE_MAIL              => 3;
use constant TYPE_EXIT              => 4;
use constant TYPE_PING              => 5;
use constant TYPE_ALERT             => 6;
use constant TYPE_ASK               => 7;
use constant TYPE_CALL              => 8;
use constant TYPE_CART              => 9;
use constant TYPE_CHAT              => 10;
use constant TYPE_FEED              => 11;
use constant TYPE_GOAL              => 12;
use constant TYPE_USER              => 13;
use constant TYPE_VIDEO             => 14;
use constant TYPE_VIRAL             => 15;
use constant MAX_TYPES              => 15;

use constant TYPE_IDS => {
    'page'          => Constants::Events::TYPE_PAGE,
    'http'          => Constants::Events::TYPE_PAGE,
    'https'         => Constants::Events::TYPE_PAGE,
    'file'          => Constants::Events::TYPE_FILE,
    'link'          => Constants::Events::TYPE_LINK,
    'mail'          => Constants::Events::TYPE_MAIL,
    'exit'          => Constants::Events::TYPE_EXIT,
    'ping'          => Constants::Events::TYPE_PING,
    'alert'         => Constants::Events::TYPE_ALERT,
    'ask'           => Constants::Events::TYPE_ASK,
    'call'          => Constants::Events::TYPE_CALL,
    'cart'          => Constants::Events::TYPE_CART,
    'chat'          => Constants::Events::TYPE_CHAT,
    'feed'          => Constants::Events::TYPE_FEED,
    'goal'          => Constants::Events::TYPE_GOAL,
    'user'          => Constants::Events::TYPE_USER,
    'video'         => Constants::Events::TYPE_VIDEO,
    'viral'         => Constants::Events::TYPE_VIRAL,
};

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
