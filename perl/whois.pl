#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Data::WhoIs;

my $domain = shift or die "usage: $0 domain.com";

Data::WhoIs->connect(database => 'site');
my $who_is = Data::WhoIs->lookup($domain);
Data::WhoIs->disconnect();
print "Lookup: $domain\n";
print "Name: ", $who_is->name(), "\n" if $who_is->{who_is_id};
print "Address: ", $who_is->address(), "\n" if $who_is->{who_is_id};
print "Phone: ", $who_is->phone(), "\n" if $who_is->{who_is_id};
print "Email: ", $who_is->email(), "\n" if $who_is->{who_is_id};
print "\n";

__END__

=head1 DEPENDENCIES

Browser

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
