#!/usr/bin/env perl

=head1 NAME

Client::Accounts - Write web site accounts as XML (default), CSV, HTML or JSON

=head1 VERSION

This document refers to version 1.0 of Client::Accounts, released Jul 07, 2015

=head1 DESCRIPTION

Client::Accounts writes web site accounts as XML (default), CSV, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Accounts;
$VERSION = "1.0";

use strict;
use base 'Client::API';
use Data::SiteAccount;
use Data::SiteChannel;
use Data::Account;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Accounts object for a site ID

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{channels} = [];
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate()

Generate a list of site accounts in the chosen format

=cut
sub generate
{
    my ($self) = @_;

    # Get account details

    my $site = $self->{site};
    $site->{accounts} = { account => $self->get_accounts($site->{site_id}) };
    $site->{id} = $site->{site_id}; delete $site->{site_id};
    my $accounts = { site => $site };

    # Add the request stats

    $accounts->{stats} ||= $self->api_stats();

    # Return the accounts reports

    return $self->format_reports($accounts);
}

=item get_accounts($site_id)

Return all the accounts for a site

=cut
sub get_accounts
{
    my ($self, $site_id) = @_;

    Data::SiteAccount->connect();
    Data::SiteChannel->connect();
    Data::Account->connect();

    # Get all the accounts for the site

    my @accounts = ();
    my $channels = [];
    my $last_account;
    my $last_account_id = 0;
    my $query = 'site_id = ? order by account_id, channel_id';
    for (my $site_account = Data::SiteAccount->select($query, $site_id);
            $site_account->{site_account_id};
            $site_account = Data::SiteAccount->next($query))
    {
        # If we're at a new account then save access details

        if ($last_account_id != $site_account->{account_id})
        {
            push @accounts, { id => $last_account->{account_id},
                              realname => $last_account->{realname},
                              username => $last_account->{username},
                              email => $last_account->{email},
                              phone => $last_account->{phone},
                              status => $last_account->{status},
                              channels => { channel => $channels },
                            } if $last_account_id;

            $channels = [];
            $last_account = Data::Account->row($site_account->{account_id});
            $last_account_id = $site_account->{account_id};
        }

        # Get details about the channel so we know which one it is

        my $channel = $self->get_channel($site_id, $site_account->{channel_id});

        # Remember the channels that the account can access

        push @{$channels}, { id => $site_account->{channel_id},
                             name => $channel->{name},
                             urls => $channel->{urls},
                             parent_id => $channel->{parent_id},
                             can_read => $site_account->{can_read},
                             can_write => $site_account->{can_write},
                             get_reports => $site_account->{get_reports},
                             get_periods => $site_account->{get_periods},
                           };
    }

    # Don't foret the last one

    push @accounts, { id => $last_account->{account_id},
                      realname => $last_account->{realname},
                      username => $last_account->{username},
                      email => $last_account->{email},
                      phone => $last_account->{phone},
                      status => $last_account->{status},
                      channels => { channel => $channels },
                    } if $last_account_id;

    Data::SiteAccount->disconnect();
    Data::SiteChannel->disconnect();
    Data::Account->disconnect();

    # Return the account list

    return \@accounts;
}

=item get_channel($site_id, $channel_id)

Return details about a site channel

=cut
sub get_channel
{
    my ($self, $site_id, $channel_id) = @_;

    my $query = 'site_id = ? and channel_id = ?';
    return $self->{channels}[$channel_id] ||= Data::SiteChannel->select($query, $site_id, $channel_id);
}

}1;

=back

=head1 DEPENDENCIES

Data::SiteAccount, Data::SiteChannel, Data::Account

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
