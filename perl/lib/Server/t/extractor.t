#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Test::More tests => 1;
use Server::Extractor;

my $line = 'si=36592|en=http://www.staythirstymedia.com/kevin/test.php|bl=blah';
my $extractor = Server::Extractor->new();
$extractor->begin_files();
print $extractor->parse($line) . "\n";
#is(1, 1, '1=1');

__END__
