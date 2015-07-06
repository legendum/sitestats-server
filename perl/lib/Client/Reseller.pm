#!/usr/bin/env perl

=head1 NAME

Client::Reseller - Write reseller web site as XML (default), CSV, HTML or JSON

=head1 VERSION

This document refers to version 1.0 of Client::Reseller, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reseller writes reseller web sites as XML (default), CSV, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reseller;
$VERSION = "1.0";

use strict;
use base 'Client::API';
use Data::Reseller;
use Data::Site;
use Data::SiteStats;
use XML::Simple;
use JSON;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($account_id)

Create a new Client::Reseller object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($account_id)

Generate a list of reseller sites in the chosen format

=cut
sub generate
{
    my ($self, $account_id) = @_;

    # Get the reseller details

    my $reseller = $self->get_reseller($account_id);

    # Get reseller site details

    my $sites = { reseller => {
                  id => $reseller->{reseller_id},
                  account_id => $reseller->{account_id},
                  contact => $reseller->{contact},
                  company => $reseller->{company},
                  street1 => $reseller->{street1},
                  street2 => $reseller->{street2},
                  city => $reseller->{city},
                  country => $reseller->{country},
                  zip_code => $reseller->{zip_code},
                  tel_number => $reseller->{tel_number},
                  fax_number => $reseller->{fax_number},
                  vat_number => $reseller->{vat_number},
                  url => $reseller->{url},
                  email => $reseller->{email},
                  brand => $reseller->{brand},
                  sites => {
                    site => $self->get_sites($reseller->{reseller_id}),
                    },
                  },
                };

    # Add the request stats

    $sites->{stats} ||= $self->api_stats();

    # Return the reseller sites report

    return $self->format_reports($sites);
}

=item get_reseller($account_id)

Return a reseller with an account ID

=cut
sub get_reseller
{
    my ($self, $account_id) = @_;
    die "need the id of the reseller's account" unless $account_id;

    # Get the reseller details

    Data::Reseller->connect();
    my $reseller = Data::Reseller->select('account_id = ?', $account_id);
    Data::Reseller->disconnect();
    $reseller->{reseller_id} or die "no reseller with account ID $account_id";
    return $reseller;
}

=item get_sites($reseller_id)

Return all the sites for a reseller

=cut
sub get_sites
{
    my ($self, $reseller_id) = @_;

    Data::Site->connect();
    Data::SiteStats->connect();

    # Get all the sites for the reseller

    my @sites = ();
    my $query = 'reseller_id = ?';
    for (my $site = Data::Site->select($query, $reseller_id);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        my $projection = $self->get_projection($site->{site_id});
        my $last_month = $self->get_last_month($site->{site_id});
        my $first_used = $self->get_first_used($site->{site_id});
        $site->{id} = $site->{site_id}; delete $site->{site_id};
        $site->{projection} = $projection;
        $site->{last_month} = $last_month;
        $site->{first_used} = $first_used;
        push @sites, $site;
    }

    Data::SiteStats->disconnect();
    Data::Site->disconnect();

    # Return the site list

    return \@sites;
}

=item get_projection($site_id)

Return a web traffic projection for a particular site ID

=cut
sub get_projection
{
    my ($self, $site_id) = @_;

    # Get the past week of web traffic for the site

    my $hits = 0;
    my $sql = "site_id = ? and channel_id = 0 and period = 'day' order by the_date desc limit 7";
    for (my $site_stats = Data::SiteStats->select($sql, $site_id);
            $site_stats->{site_stats_id};
            $site_stats = Data::SiteStats->next($sql))
    {
        $hits += $site_stats->{hits};
    }

    # Return a projection for 30 days of web traffic

    return int($hits / 7 * 30);
}

=item get_last_month($site_id)

Return last month's page view count for a particular site ID

=cut
sub get_last_month
{
    my ($self, $site_id) = @_;

    my $sql = "site_id = ? and channel_id = 0 and period = 'month' order by the_date desc limit 1";
    my $site_stats = Data::SiteStats->select($sql, $site_id);
    return $site_stats->{hits};
}

=item get_first_used($site_id)

Return the first date that this site ID had some web traffic data

=cut
sub get_first_used
{
    my ($self, $site_id) = @_;

    my $sql = "site_id = ? and channel_id = 0 and period = 'day' and hits > 0 order by the_date limit 1";
    my $site_stats = Data::SiteStats->select($sql, $site_id);
    return $site_stats->{the_date} || ''; # blank when unused
}

}1;

=back

=head1 DEPENDENCIES

Data::Reseller, Data::SiteStats

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
