#!/usr/bin/env perl

=head1 NAME

Data::SiteConfig - Manages the configuration options of customer web sites

=head1 VERSION

This document refers to version 1.1 of Data::SiteConfig, released Jul 07, 2015

=head1 DESCRIPTION

Data::SiteConfig manages the configuration options of all customer web sites.
Be sure to call the class static method connect() before using Data::SiteConfig
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item site_id

The site being configured

=item channel_id

The channel being configured

=item report_id

The report being configured

=item field

The configuration field

=item value

The configuration value

=back

=cut
package Data::SiteConfig;
$VERSION = "1.1";

use strict;
use base 'Data::Object';
{
    # Class static properties

    my $_Connection;

=head2 Class Methods

=over 4

=item connect(driver=>'mysql', database=>'dbname', user=>'username', password=>'pass')

Initialise a connection to the database with optional details

=cut
sub connect
{
    my ($class, %args) = @_;
    return $_Connection if $_Connection;

    $args{host} ||= $ENV{MASTER_SERVER};
    eval {
        $_Connection = $class->SUPER::connect(%args);
    }; if ($@) {
        $args{host} = $ENV{BACKUP_SERVER};
        $_Connection = $class->SUPER::connect(%args);
    }
    $class->fields(qw(site_config_id site_id channel_id report_id field value));

    return $_Connection;
}

=item disconnect()

Disconnect from the database cleanly

=cut
sub disconnect
{
    my ($class) = @_;
    return unless $_Connection;

    $_Connection = undef;
    $class->SUPER::disconnect();
}

=item find($config, $field, $channel_id, $report_id)

Find the value of a field for a channel and report using "zero" defaults

=cut
sub find
{
    my ($class, $config, $field, $channel_id, $report_id) = @_;
    die "no config" unless $config;
    die "no field" unless $field;
    $channel_id ||= 0;
    $report_id ||= 0;

    return $config->[$channel_id][$report_id]{$field}
        || $config->[$channel_id][0]{$field}
        || $config->[0][$report_id]{$field}
        || $config->[0][0]{$field} || '';
}

=item get($site_id)

Get a site configuration as a channel array of report arrays of fields & values

=cut
sub get
{
    my ($class, $site_id) = @_;
    die "no site" unless $site_id;

    my $sql = 'site_id = ?';
    my $config = [];
    for (my $site_config = $class->select($sql, $site_id);
        $site_config->{site_config_id};
        $site_config = $class->next($sql))
    {
        my $channel_id = $site_config->{channel_id};
        my $report_id = $site_config->{report_id};
        my $field = $site_config->{field};
        my $value = $site_config->{value};
        $config->[$channel_id][$report_id]{$field} = $value;
    }

    return $config;
}

=item set($site_id, $channel_id, $report_id, $field, $value)

Set a configuration value for a site channel report

=cut
sub set
{
    my ($class, $site_id, $channel_id, $report_id, $field, $value) = @_;

    my $sql = 'site_id = ? and channel_id = ? and report_id = ? and field = ?';
    my $site_config = $class->select($sql, $site_id, $channel_id, $report_id, $field);
    if ($site_config->{site_config_id})
    {
        if ($value)
        {
            $site_config->{value} = $value;
            $site_config->update();
        }
        else
        {
            $site_config->delete();
        }
    }
    else
    {
        $site_config->{site_id} = $site_id;
        $site_config->{channel_id} = $channel_id;
        $site_config->{report_id} = $report_id;
        $site_config->{field} = $field;
        $site_config->{value} = $value;
        $site_config->insert();
    }
}

=back

=head2 Object Methods

=over 4

=item None

=cut

}1;

=back

=head1 DEPENDENCIES

Data::Object

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
