#!/usr/bin/env perl

=head1 NAME

Utils::Config - Load YAML config files in the "config" directory

=head1 VERSION

This document refers to version 1.0 of Utils::Config, released Jul 07, 2015

=head1 DESCRIPTION

Utils::Config loads YAML config files in the "config" directory.

=head2 Properties

=over 4

None

=back

=cut
package Utils::Config;
$VERSION = "1.0";

use strict;
use YAML;
{
    # Class static properties

    # NONE

=head2 Class Methods

=over 4

=item load($filename)

Read a filename (with a ".yaml" extension) and return a hashref of config data

=cut
sub load
{
    my ($class, $filename) = @_;

    my $config = YAML::LoadFile("$ENV{CONFIG_DIR}/$filename.yaml");
    my $default = $config->{default};
    $class->set_default($config, $default) if $default;

    return $config;
}

=item set_default($config, $default)

Set the default fields and values for all hashrefs

=cut
sub set_default
{
    my ($class, $config, $default) = @_;

    while (my ($name, $hash) = each %$config)
    {
        next if $name eq 'default';

        foreach my $field (keys %$default)
        {
            $hash->{$field} ||= $default->{$field};
        }
    }
}

=item is_true($value)

Return whether a value is true

=cut
sub is_true
{
    my ($class, $value) = @_;

    return 1 if lc $value eq 'true' or $value == 1;
    return 0;
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
