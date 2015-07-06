#!/usr/bin/env perl

=head1 NAME

Client::Sites - Write account web site as XML (default), CSV, HTML or JSON

=head1 VERSION

This document refers to version 1.0 of Client::Sites, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sites writes account web sites as XML (default), CSV, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Sites;
$VERSION = "1.0";

use strict;
use base 'Client::API';
use Data::SiteAccount;
use Data::SiteChannel;
use Data::Account;
use Constants::General;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Client::Sites object for an account ID

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new();
    $self->{site_channels} = {};
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($account_id)

Generate a list of site accounts in the chosen format

=cut
sub generate
{
    my ($self, $account_id) = @_;

    # Get the account details

    my $account = $self->get_account($account_id);

    # Get site details

    my $sites = {  account => {
                   id => $account->{account_id},
                   parent_id => $account->{parent_id},
                   realname => $account->{realname},
                   username => $account->{username},
                   referrer => $account->{referrer},
                   email => $account->{email},
                   phone => $account->{phone},
                   start_date => $account->{start_date},
                   end_date => $account->{end_date},
                   status => $account->{status},
                   sites => {
                       site => $self->get_sites($account->{account_id})
                   }
                 }
               };

    # Add the request stats

    $sites->{stats} ||= $self->api_stats();

    # Return the sites reports

    return $self->format_reports($sites);
}

sub get_account
{
    my ($self, $account_id) = @_;

    # Get the account details

    Data::Account->connect();
    my $account = Data::Account->row($account_id);
    Data::Account->disconnect();
    $account->{account_id} or die "no account with ID $account_id";
    $account->{status} ne Constants::General::STATUS_SUSPENDED or die "account suspended";

    return $account;
}

=item get_sites($account_id)

Return all the sites for an account

=cut
sub get_sites
{
    my ($self, $account_id) = @_;

    Data::SiteAccount->connect();
    Data::SiteChannel->connect();
    Data::Site->connect();

    # Get all the sites for the account

    my @sites = ();
    my $channels = [];
    my $last_site;
    my $last_site_id = 0;
    my $query = 'account_id = ? order by site_id, channel_id';
    for (my $site_account = Data::SiteAccount->select($query, $account_id);
            $site_account->{site_account_id};
            $site_account = Data::SiteAccount->next($query))
    {
        # If we're at a new site then save access details

        if ($last_site_id != $site_account->{site_id})
        {
            push @sites, { id => $last_site->{site_id},
                           url => $last_site->{url},
                           time_zone => $last_site->{time_zone},
                           daylight_saving => $last_site->{daylight_saving},
                           campaign_pages => $last_site->{campaign_pages},
                           commerce_pages => $last_site->{commerce_pages},
                           data_server => $last_site->{data_server},
                           comp_server => $last_site->{comp_server},
                           reseller_id => $last_site->{reseller_id},
                           start_date => $last_site->{start_date},
                           end_date => $last_site->{end_date},
                           status => $last_site->{status},
                           channels => { channel => $channels },
                         } if $last_site_id;

            $channels = [];
            $last_site = Data::Site->row($site_account->{site_id});
            $last_site_id = $site_account->{site_id};
        }

        # Get details about the channel so we know which one it is

        my $channel = $self->get_channel($last_site_id, $site_account->{channel_id});

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

    push @sites, { id => $last_site->{site_id},
                   url => $last_site->{url},
                   time_zone => $last_site->{time_zone},
                   daylight_saving => $last_site->{daylight_saving},
                   campaign_pages => $last_site->{campaign_pages},
                   commerce_pages => $last_site->{commerce_pages},
                   data_server => $last_site->{data_server},
                   comp_server => $last_site->{comp_server},
                   reseller_id => $last_site->{reseller_id},
                   start_date => $last_site->{start_date},
                   end_date => $last_site->{end_date},
                   status => $last_site->{status},
                   channels => { channel => $channels },
                 } if $last_site_id;

    Data::SiteAccount->disconnect();
    Data::SiteChannel->disconnect();
    Data::Site->disconnect();

    # Return the site list

    return \@sites;
}

=item get_channel($site_id, $channel_id)

Return details about a site channel

=cut
sub get_channel
{
    my ($self, $site_id, $channel_id) = @_;

    my $query = 'site_id = ? and channel_id = ?';
    return $self->{site_channels}{$site_id}[$channel_id] ||= Data::SiteChannel->select($query, $site_id, $channel_id);
}

}1;

=back

=head1 DEPENDENCIES

Data::SiteAccount, Data::SiteChannel, Data::Account, Constants::General

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
