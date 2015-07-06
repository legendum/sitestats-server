#!/usr/bin/env perl

=head1 NAME

Client::Admin::Account - Perform admin actions on user accounts

=head1 VERSION

This document refers to version 1.0 of Client::Admin::Account, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin::Account performs admin actions on user accounts

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin::Account;
$VERSION = "1.0";

use strict;
use base 'Client::Admin';
use Data::Account;
use Data::SiteAccount;
use Utils::Time;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($self)

Create a new Client::Admin::Account object

=cut
sub new
{
    my ($class, $self) = @_;

    # Return the new Client::Admin::Account object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create($values)

Create an account

=cut
sub create
{
    my ($self, $values) = @_;
    my $username = $values->{username} or die "no account username";

    # Check that the account has not already been added

    Data::Account->connect();
    my $account = Data::Account->select('username = ? and reseller_id = ?', $username, $self->{reseller_id});
    die "account already exists with username $username" if $account->{account_id};

    # Create a new account from the values, but use defaults

    $account = Data::Account->new(%{$values});
    $account->{reseller_id} = $self->{reseller_id};
    $account->{start_date} ||= Utils::Time->get_date();
    $account->{status} ||= 'L';

    # Insert the new account

    $account->insert();
    $account = Data::Account->row($account->{account_id}); # get missing fields
    Data::Account->disconnect();

    # Return the new account ID

    return { status => 'ok', id => $account->{account_id}, account => $account };
}

=item select($values)

Select an account

=cut
sub select
{
    my ($self, $values) = @_;

    # Get a matching account

    Data::Account->connect();
    my $account = $self->get_account($values);
    Data::Account->disconnect();

    return { status => 'ok', account => $account };
}

=item update($values)

Update an account

=cut
sub update
{
    my ($self, $values) = @_;

    # Get a matching account

    Data::Account->connect();
    my $account = $self->get_account($values);

    # Update the account

    foreach my $key (keys %{$values})
    {
        $account->{$key} = $values->{$key};
    }
    $account->update();
    Data::Account->disconnect();

    return { status => 'ok', account => $account };
}

=item delete($values)

Delete an account

=cut
sub delete
{
    my ($self, $values) = @_;

    # Get a matching account

    Data::Account->connect();
    my $account = $self->get_account($values);

    # Delete related SiteAccount objects

    Data::SiteAccount->connect();
    my $query = 'account_id = ?';
    my @site_accounts = ();
    for (my $site_account = Data::SiteAccount->select($query, $values->{id});
            $site_account->{site_account_id};
            $site_account = Data::SiteAccount->next($query))
    {
        push @site_accounts, $site_account;
    }

    foreach my $site_account (@site_accounts)
    {
        $site_account->delete();
    }
    Data::SiteAccount->disconnect();

    # Delete the object

    $account->delete();
    Data::Account->disconnect();

    return { status => 'ok' };
}

=item get_account($values)

Get an account matching an "id" or "username" value, belonging to this reseller

=cut
sub get_account
{
    my ($self, $values) =  @_;
    my $account_id = $values->{id} || 0;
    my $username = $values->{username};
    die "need an account id or username" unless $account_id or $username;

    # Get the matching account

    my $account = $account_id ? Data::Account->row($account_id)
                              : Data::Account->select('username = ? and reseller_id = ?', $username, $self->{reseller_id});
    die "no matching account" unless $account->{account_id};

    # Check the reseller ID for permission

    die "no permission" if $account->{reseller_id} != $self->{reseller_id};

    # Return the account

    return $account;
}

}1;

=back

=head1 DEPENDENCIES

Data::Account, Data::SiteAccount, Utils::Time

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
