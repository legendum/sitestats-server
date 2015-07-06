#!/usr/bin/env perl

=head1 NAME

Client::Channels - Write web site channels as XML (default), CSV, HTML or JSON

=head1 VERSION

This document refers to version 1.2 of Client::Channels, released Jul 07, 2015

=head1 DESCRIPTION

Client::Channels writes web site channels as XML (default), CSV, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Channels;
$VERSION = "1.2";

use strict;
use base 'Client::API';
use Data::SiteChannel;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Client::Channels object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new(
        channels => [],
    );
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate()

Generate a list of site channels in the chosen format

=cut
sub generate
{
    my ($self) = @_;

    # Get channel details

    my $site = $self->{site};
    my $channels = {  site => {
                        id => $site->{site_id},
                        url => $site->{url},
                        channels => {
                            channel => $self->get_channels($site->{site_id})
                        }
                      }
                    };

    # Add the request stats

    $channels->{stats} ||= $self->api_stats();

    # Return the channels reports

    return $self->format_reports($channels);
}

=item get_channels($site_id)

Return all the channels for a site

=cut
sub get_channels
{
    my ($self, $site_id) = @_;

    Data::SiteChannel->connect();

    # Get all the channels for the site, but don't sort them with SQL

    my @channels = ();
    my $query = 'site_id = ?';
    for (my $site_channel = Data::SiteChannel->select($query, $site_id);
            $site_channel->{site_channel_id};
            $site_channel = Data::SiteChannel->next($query))
    {
        push @channels, { id => $site_channel->{channel_id},
                          parent => $site_channel->{parent_id},
                          name => $site_channel->{name},
                          urls => $site_channel->{urls},
                        };
    }

    Data::SiteChannel->disconnect();

    # Sort the channels by their channel_id and parent_id, so they are ordered

    my $order = sub { my $ch = shift;
                      $ch->{parent} ? $ch->{parent}*1000 + $ch->{id}
                                    : $ch->{id}*1000; };
    my @sorted = sort {$order->($a) <=> $order->($b)} @channels;

    # Return the sorted channel list

    return \@sorted;
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
