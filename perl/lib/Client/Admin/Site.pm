#!/usr/bin/env perl

=head1 NAME

Client::Admin::Site - Perform admin actions on sites

=head1 VERSION

This document refers to version 1.0 of Client::Admin::Site, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin::Site performs admin actions on sites

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin::Site;
$VERSION = "1.0";

use strict;
use base 'Client::Admin';
use Data::Site;
use Data::SiteAccount;
use Utils::Time;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($self)

Create a new Client::Admin::Site object

=cut
sub new
{
    my ($class, $self) = @_;

    # Return the new Client::Admin::Site object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create($values)

Create a site

=cut
sub create
{
    my ($self, $values) = @_;
    my $url = $values->{url} or die "no site url";

    # Check that the site has not already been added

    Data::Site->connect();
    my $site = Data::Site->select('url = ?', $url);
    die "site already exists with url $url" if $site->{site_id};

    # Create a new site from the values, but use defaults

    $site = Data::Site->new(%{$values});
    $site->{reseller_id} = $self->{reseller_id};
    $site->{start_date} ||= Utils::Time->get_date();
    $site->{daylight_saving} ||= 'N';
    $site->{time_zone} ||= 0;
    $site->{status} ||= 'L';

    # Insert the new site

    $site->insert();
    $site = Data::Site->row($site->{site_id}); # to get any missing fields
    Data::Site->disconnect();

    # Return the new site ID

    return { status => 'ok', id => $site->{site_id}, site => $site };
}

=item select($values)

Select a site

=cut
sub select
{
    my ($self, $values) = @_;

    # Get a matching site

    Data::Site->connect();
    my $site = $self->get_site($values);
    Data::Site->disconnect();

    return { status => 'ok', site => $site };
}

=item update($values)

Update a site

=cut
sub update
{
    my ($self, $values) = @_;

    # Get a matching site

    Data::Site->connect();
    my $site = $self->get_site($values);

    # Update the site

    foreach my $key (keys %{$values})
    {
        $site->{$key} = $values->{$key};
    }
    $site->update();
    Data::Site->disconnect();

    return { status => 'ok', site => $site };
}

=item delete($values)

Delete a site

=cut
sub delete
{
    my ($self, $values) = @_;

    # Get a matching site

    Data::Site->connect();
    my $site = $self->get_site($values);

    # Delete related SiteAccount objects

    Data::SiteAccount->connect();
    my $query = 'site_id = ?';
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

    $site->delete();
    Data::Site->disconnect();

    return { status => 'ok' };
}

=item get_site($values)

Get a site matching an "id" or "url" value, and belonging to this reseller

=cut
sub get_site
{
    my ($self, $values) =  @_;
    my $site_id = $values->{id} || 0;
    my $url = $values->{url};
    die "need a site id or url" unless $site_id or $url;

    # Get the matching site

    my $site = $site_id ? Data::Site->row($site_id)
                        : Data::Site->select('url = ?', $url);
    die "no matching site" unless $site->{site_id};

    # Check the reseller ID for permission

    die "no permission" if $site->{reseller_id} != $self->{reseller_id};

    # Return the site

    return $site;
}

}1;

=back

=head1 DEPENDENCIES

Data::Site, Data::SiteAccount, Utils::Time

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
