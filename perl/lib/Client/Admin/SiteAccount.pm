#!/usr/bin/env perl

=head1 NAME

Client::Admin::SiteAccount - Perform admin actions on site accounts

=head1 VERSION

This document refers to version 1.0 of Client::Admin::SiteAccount, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin::SiteAccount performs admin actions on site accounts

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin::SiteAccount;
$VERSION = "1.0";

use strict;
use base 'Client::Admin';
use Data::SiteAccount;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($self)

Create a new Client::Admin::SiteAccount object

=cut
sub new
{
    my ($class, $self) = @_;

    # Return the new Client::Admin::SiteAccount object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create($values)

Create a site account

=cut
sub create
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $account_id = $values->{account_id}+0 or die "no account_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id);

    # Set the site account defaults

    $values->{(Client::Admin::CAN_READ)}  ||= 'yes';
    $values->{(Client::Admin::CAN_WRITE)} ||= 'yes';
    $values->{channel_id} += 0;

    # Create a new site account from the values, unless it already exists

    Data::SiteAccount->connect();
    my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
    die "site account already exists" if $site_account->{site_account_id};
    $site_account = new Data::SiteAccount(%{$values});
    $site_account->insert();
    Data::SiteAccount->disconnect();

    # Return the new site account ID

    return { status => 'ok', id => $site_account->{site_account_id}, site_account => $site_account };
}

=item select($values)

Select a site account

=cut
sub select
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $account_id = $values->{account_id}+0 or die "no account_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_READ, $site_id);

    # Get the site account

    Data::SiteAccount->connect();
    my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
    Data::SiteAccount->disconnect();
    die "no matching site account" unless $site_account->{site_account_id};

    return { status => 'ok', site_account => $site_account };
}

=item update($values)

Update a site account

=cut
sub update
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $account_id = $values->{account_id}+0 or die "no account_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id);

    # Get the site account to update

    Data::SiteAccount->connect();
    my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
    die "no matching site account" unless $site_account->{site_account_id};

    # Update the site account

    foreach my $key (keys %{$values})
    {
        $site_account->{$key} = $values->{$key};
    }
    $site_account->update();
    Data::SiteAccount->disconnect();

    return { status => 'ok', site_account => $site_account };
}

=item delete($values)

Delete a site account

=cut
sub delete
{
    my ($self, $values) = @_;
    my $site_id = $values->{site_id}+0 or die "no site_id";
    my $account_id = $values->{account_id}+0 or die "no account_id";

    # Check the account ID for permission

    die "no permission" unless $self->check_permission(Client::Admin::CAN_WRITE, $site_id);

    # Get the site account to delete

    Data::SiteAccount->connect();
    my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
    die "no matching site account" unless $site_account->{site_account_id};

    # Delete the object

    $site_account->delete();
    Data::SiteAccount->disconnect();

    return { status => 'ok' };
}

}1;

=back

=head1 DEPENDENCIES

Data::SiteAccount

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
