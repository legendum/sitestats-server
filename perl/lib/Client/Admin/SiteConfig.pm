#!/usr/bin/env perl

=head1 NAME

Client::Admin::SiteConfig - Perform admin actions on site configs

=head1 VERSION

This document refers to version 1.0 of Client::Admin::SiteConfig, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin::SiteConfig performs admin actions on site configs

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin::SiteConfig;
$VERSION = "1.0";

use strict;
use base 'Client::Admin';
use Data::SiteConfig;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($self)

Create a new Client::Admin::SiteConfig object

=cut
sub new
{
    my ($class, $self) = @_;

    # Return the new Client::Admin::SiteConfig object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create($values)

Create a site config

=cut
sub create
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0;
    my $report_id = $values->{report_id}+0;
    my $field = $values->{field} or die "need a site config 'field'";
    my $value = $values->{value} or die "need a site config 'value'";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Set the site config defaults

    $values->{parent_id} ||= 0;

    # Create a new site config from the values, unless it already exists

    Data::SiteConfig->connect();
    my $site_config = Data::SiteConfig->select('site_id = ? and channel_id = ? and report_id = ? and field = ?', $site_id, $channel_id, $report_id, $field);
    die "site config already exists" if $site_config->{site_config_id};
    $site_config = new Data::SiteConfig(%{$values});
    $site_config->insert();
    Data::SiteConfig->disconnect();

    # Return the new site config ID

    return { status => 'ok', id => $site_config->{site_config_id}, site_config => $site_config };
}

=item select($values)

Select a site config

=cut
sub select
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0;
    my $report_id = $values->{report_id}+0;
    my $field = $values->{field} or die "need a site config 'field'";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site config

    Data::SiteConfig->connect();
    my $site_config = Data::SiteConfig->select('site_id = ? and channel_id = ? and report_id = ? and field = ?', $site_id, $channel_id, $report_id, $field);
    Data::SiteConfig->disconnect();
    die "no matching site config" unless $site_config->{site_config_id};

    return { status => 'ok', site_config => $site_config };
}

=item update($values)

Update a site config

=cut
sub update
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0;
    my $report_id = $values->{report_id}+0;
    my $field = $values->{field} or die "need a site config 'field'";
    my $value = $values->{value} or die "need a site config 'value'";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site config to update

    Data::SiteConfig->connect();
    my $site_config = Data::SiteConfig->select('site_id = ? and channel_id = ? and report_id = ? and field = ?', $site_id, $channel_id, $report_id, $field);
    die "no matching site config" unless $site_config->{site_config_id};

    # Update the site config value

    $site_config->{value} = $value;
    $site_config->update();
    Data::SiteConfig->disconnect();

    return { status => 'ok', site_config => $site_config };
}

=item delete($values)

Delete a site config

=cut
sub delete
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0;

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site config to delete

    Data::SiteConfig->connect();
    my $site_config = Data::SiteConfig->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
    die "no matching site config" unless $site_config->{site_config_id};

    # Delete the object

    $site_config->delete();
    Data::SiteConfig->disconnect();

    return { status => 'ok' };
}

}1;

=back

=head1 DEPENDENCIES

Data::SiteConfig

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
