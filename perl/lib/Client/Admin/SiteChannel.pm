#!/usr/bin/env perl

=head1 NAME

Client::Admin::SiteChannel - Perform admin actions on site channels

=head1 VERSION

This document refers to version 1.0 of Client::Admin::SiteChannel, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin::SiteChannel performs admin actions on site channels

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin::SiteChannel;
$VERSION = "1.0";

use strict;
use base 'Client::Admin';
use Data::SiteChannel;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($self)

Create a new Client::Admin::SiteChannel object

=cut
sub new
{
    my ($class, $self) = @_;

    # Return the new Client::Admin::SiteChannel object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create($values)

Create a site channel

=cut
sub create
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0 or die "no channel_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id);

    # Set the site channel defaults

    $values->{parent_id} ||= 0;

    # Create a new site channel from the values, unless it already exists

    Data::SiteChannel->connect();
    my $site_channel = Data::SiteChannel->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
    die "site channel already exists" if $site_channel->{site_channel_id};
    $site_channel = new Data::SiteChannel(%{$values});
    $site_channel->insert();
    Data::SiteChannel->disconnect();

    # Return the new site channel ID

    return { status => 'ok', id => $site_channel->{site_channel_id}, site_channel => $site_channel };
}

=item select($values)

Select a site channel

=cut
sub select
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0 or die "no channel_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site channel

    Data::SiteChannel->connect();
    my $site_channel = Data::SiteChannel->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
    Data::SiteChannel->disconnect();
    die "no matching site channel" unless $site_channel->{site_channel_id};

    return { status => 'ok', site_channel => $site_channel };
}

=item update($values)

Update a site channel

=cut
sub update
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0 or die "no channel_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site channel to update

    Data::SiteChannel->connect();
    my $site_channel = Data::SiteChannel->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
    die "no matching site channel" unless $site_channel->{site_channel_id};

    # Update the site channel

    foreach my $key (keys %{$values})
    {
        $site_channel->{$key} = $values->{$key};
    }
    $site_channel->update();
    Data::SiteChannel->disconnect();

    return { status => 'ok', site_channel => $site_channel };
}

=item delete($values)

Delete a site channel

=cut
sub delete
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $channel_id = $values->{channel_id}+0 or die "no channel_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id, $channel_id);

    # Get the site channel to delete

    Data::SiteChannel->connect();
    my $site_channel = Data::SiteChannel->select('site_id = ? and channel_id = ?', $site_id, $channel_id);
    die "no matching site channel" unless $site_channel->{site_channel_id};

    # Delete the object

    $site_channel->delete();
    Data::SiteChannel->disconnect();

    return { status => 'ok' };
}

}1;

=back

=head1 DEPENDENCIES

Data::SiteChannel

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
