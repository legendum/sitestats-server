#!/usr/bin/env perl

=head1 NAME

Client::Admin - Perform admin actions and return results as XML by default

=head1 VERSION

This document refers to version 1.0 of Client::Admin, released Jul 07, 2015

=head1 DESCRIPTION

Client::Admin performs admin actions and returns results as XML by default.

=head2 Properties

=over 4

None

=back

=cut
package Client::Admin;
$VERSION = "1.0";

use strict;
use base 'Client::API';
use Data::Reseller;
use Data::SiteAccount;
{
    # Class static properties

    use constant CAN_WRITE => 'can_write';
    use constant CAN_READ => 'can_read';

=head2 Class Methods

=over 4

=item factory($account_id, $entity)

Create a new Client::Admin subclassed object for a particular entity e.g. 'Site'

=cut
sub factory
{
    my ($class, $account_id, $entity) = @_;
    die "need an account id" unless $account_id =~ /^\d+$/;
    die "need an entity" unless $entity =~ /^\w+$/;

    # Get any reseller details

    Data::Reseller->connect();
    my $reseller = Data::Reseller->select('account_id = ?', $account_id);
    Data::Reseller->disconnect();

    # Get a list of sites the user edit

    my $site_accounts = $class->get_site_accounts($account_id);

    # Make a new Client::Admin object

    my $self = $class->SUPER::new(
        reseller_id     => $reseller->{reseller_id} || 0,
        account_id      => $account_id,
        site_accounts   => $site_accounts,
        entity          => $entity,
    );

    # Subclass the object for the entity

    eval "require Client::Admin::$entity;"; die $@ if $@;
    eval "\$self = Client::Admin::$entity->new(\$self);";
    die $@ if $@;
    return $self;
}

=item get_site_accounts($account_id)

Return a hash of site accounts for an account ID
The hash key is the site_id or site_id/channel_id if there's a channel ID

=cut
sub get_site_accounts
{
    my ($class, $account_id) = @_;

    my $site_accounts = {};
    Data::SiteAccount->connect();
    my $query = 'account_id = ?';
    for (my $site_account = Data::SiteAccount->select($query, $account_id);
            $site_account->{site_account_id};
            $site_account = Data::SiteAccount->next($query))
    {
        my $site_id = $site_account->{site_id};
        my $channel_id = $site_account->{channel_id};
        $site_id .= '/' . $channel_id if $channel_id;
        $site_accounts->{$site_id} = $site_account;
    }
    Data::SiteAccount->disconnect();

    return $site_accounts;
}

=back

=head2 Object Methods

=over 4

=item perform(action => $action, entity => $entity, $values => $values, [format => $format])

Perform an admin action on an entity with particular values,
and return the results in a particular format, e.g. XML.

=cut
sub perform
{
    my ($self, %args) = @_;
    my $action  = lc $args{action} or die "no action specified";
    my $values  = $args{values} or die "no values specified";

    # Decode the values passed in JSON format

    $values = JSON->new()->jsonToObj($values);

    # Get the result of the action

    my $api = { admin => {
                    action  => $action,
                    entity  => $self->{entity},
                    values  => $values,
                    result  => { error => 'unknown entity or action' },
                },
              };

    # Check that the action is a legal method call

    eval {
        $api->{admin}{result} = $self->$action($values);
    } if $action =~ /^(create|select|update|delete)$/;

    # Report errors by extracting the messag, file and line number

    if ($@)
    {
        my $error = $@; chomp $error;
        my ($file, $line) = ($1, $2) if $error =~ s/ at (\/[\w\/\.]+) line (\d+).*$//;
        $api->{admin}{result} = { error => $error, file => $file, line => $line } if $@;
    }

    # Add the request stats

    $api->{stats} ||= $self->api_stats();

    # Return the admin reports

    return $self->format_reports($api);
}

=item check_permission($permission, $site_id, [$channel_id])

Return whether or not this account can read or write site configs.
Use $permission values of 'can_read' or 'can_write' to run checks.

=cut
sub check_permission
{
    my ($self, $permission, $site_id, $channel_id) = @_;
    my $key = $site_id;

    # First check to see if we have reseller write permissions

    Data::Site->connect();
    my $site = Data::Site->row($site_id);
    Data::Site->disconnect();
    return 1 if $site->{reseller_id} == $self->{reseller_id};

    # Second check to see if we have site-wide write permissions

    my $site_account = $self->{site_accounts}{$key} || {};
    return 1 if $site_account->{$permission} eq 'yes';

    # Third check to see if we have channel write permissions

    if ($channel_id)
    {
        $key .= "/$channel_id";
        $site_account = $self->{site_accounts}{$key} || {};
        return 1 if $site_account->{$permission} eq 'yes';
    }

    # No write permissions

    return 0;
}

}1;

=back

=head1 DEPENDENCIES

Data::Reseller, Data::SiteAccount, Data::Site, XML::Simple, JSON

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
