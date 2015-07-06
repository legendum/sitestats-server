#!/usr/bin/env perl

use strict;
use Config;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();

my $transformer;
if ($Config{useithreads})
{
    require "Server/TransformerMT.pm"; # multi-thread
    $transformer = Server::TransformerMT->new();
}
else
{
    require "Server/Transformer.pm";
    $transformer = Server::Transformer->new();
}
$transformer->find_files();

__END__

=head1 DEPENDENCIES

Server::Transformer or Server::TransformerMT (multi-threaded version)

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
