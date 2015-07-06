#!/usr/bin/env perl

=head1 NAME

Utils::Env - Load the "env.yaml" config file in the "config" directory

=head1 VERSION

This document refers to version 1.0 of Utils::Env, released Jul 07, 2015

=head1 DESCRIPTION

Utils::Env loads the "env.yaml" config file in the "config" directory.

=head2 Properties

=over 4

None

=back

=cut
package Utils::Env;
$VERSION = "1.0";

use strict;
use Utils::Config;
use Sys::Hostname;
{
    # Class static properties

    # NONE

=head2 Class Methods

=over 4

=item setup()

Load the "env.yaml" file in the "config" directory to setup environment vars

=cut
sub setup
{
    my ($class) = @_;

    # Setup the environment variables

    my $env_config = Utils::Config->load('env') or die 'no "env.yaml" config file';
    my $env = $env_config->{env} or die 'no "env" section in config file "env.yaml"';
    while (my ($var, $value) = each %$env)
    {
        $var = uc $var; # coz all environment variables are uppercase
        $value = "$ENV{SERVER_HOME}/$value" if $var =~ /_DIR$/
                                            && $value !~ m#^/#;
        $ENV{$var} ||= $value; # et voila!
    }

    # Set the hostname (just in case!)

    $ENV{HOSTNAME} = hostname();

    # Get the default database settings

    my $data_config = Utils::Config->load('data_servers') or die 'no "data_servers.yaml" config file';
    my $default = $data_config->{default} or die 'no "default" section in config file "data_servers.yaml"';
    $ENV{DB_USER} = $default->{username};
    $ENV{DB_PASSWORD} = $default->{password};
    $ENV{DB_DATABASE} = $default->{database};
}

}1;

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
