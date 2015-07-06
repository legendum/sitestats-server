#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Reports::Users::Referrer - Make referrer reports for user IDs

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Reports::Users::Referrer, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports::Users::Referrer makes referrer reports for user IDs

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports::Users::Referrer;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Reports::Users';

use Constants::Reports;
{
=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Reports::Users::Referrer subclass object

=cut
sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item traffic_stats($channel_id, $report_id, $traffic)

Turn web traffic into a stats report

=cut
sub traffic_stats
{
    my ($self, $channel_id, $report_id, $traffic) = @_;

    return $self->referrer_page($channel_id, $traffic)
        if $report_id == Constants::Reports::REFERRER_PAGE;

    return $self->referrer_site($traffic)
        if $report_id == Constants::Reports::REFERRER_SITE;

    return $self->referrer_search($traffic)
        if $report_id == Constants::Reports::REFERRER_SEARCH;
}

=item referrer_page($channel_id, $traffic)

Generate a web page referrer report from web traffic data

=cut
sub referrer_page
{
    my ($self, $channel_id, $traffic) = @_;
    my %pages = ();
    foreach my $visit (@{$traffic})
    {
        next if $channel_id && $visit->{ch} !~ /$channel_id/;

        my $referrer = $visit->{re};
        $referrer = '' if $referrer =~ m#^\w+/#; # filter out internal referrals
        $pages{$referrer}++ if $referrer;
    }

    return \%pages;
}

=item referrer_site($traffic)

Generate a web site referrer report from web traffic data

=cut
sub referrer_site
{
    my ($self, $traffic) = @_;
    my %sites = ();
    foreach my $visit (@{$traffic})
    {
        my $referrer = $visit->{re};
        $referrer = '' if $referrer =~ m#^\w+/#; # filter out internal referrals
        $referrer =~ s#/.*$##; # strip the path from the end of the site domain
        $sites{$referrer}++ if $referrer;
    }

    return \%sites;
}

=item referrer_search($traffic)

Generate a search engine referrer report from web traffic data

=cut
sub referrer_search
{
    my ($self, $traffic) = @_;
    my %search_sites = ();
    foreach my $visit (@{$traffic})
    {
        next unless $visit->{se}; # check that there was a search phrase
        my $referrer = $visit->{re};
        $referrer = '' if $referrer =~ m#^\w+/#; # filter out internal referrals
        $referrer =~ s#/.*$##; # strip the path and query from the search URL
        $search_sites{$referrer}++ if $referrer;
    }

    return \%search_sites;
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports, Client::Sitester::Reports::Users

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
