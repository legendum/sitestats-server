#!/usr/bin/env perl -w

use strict;

use Test::More tests => 18;
use Constants::Events;

ok(defined Constants::Events::TYPE_PAGE, "Page type defined");
ok(defined Constants::Events::TYPE_FILE, "File type defined");
ok(defined Constants::Events::TYPE_LINK, "Link type defined");
ok(defined Constants::Events::TYPE_MAIL, "Mail type defined");
ok(defined Constants::Events::TYPE_EXIT, "Exit type defined");
ok(defined Constants::Events::TYPE_ALERT, "Alert type defined");
ok(defined Constants::Events::TYPE_ASK, "Ask type defined");
ok(defined Constants::Events::TYPE_CALL, "Call type defined");
ok(defined Constants::Events::TYPE_CART, "Cart type defined");
ok(defined Constants::Events::TYPE_CHAT, "Chat type defined");
ok(defined Constants::Events::TYPE_FEED, "Feed type defined");
ok(defined Constants::Events::TYPE_GOAL, "Goal type defined");
ok(defined Constants::Events::TYPE_USER, "User type defined");
ok(defined Constants::Events::TYPE_VIDEO, "Video type defined");
ok(defined Constants::Events::TYPE_VIRAL, "Viral type defined");
ok(defined Constants::Events::MAX_TYPES, "Max types defined");
ok(defined Constants::Events::TYPE_IDS, "Event type IDs defined");
is((Constants::Events::TYPE_IDS)->{http}, Constants::Events::TYPE_PAGE, "Event type for HTTP is a page");
