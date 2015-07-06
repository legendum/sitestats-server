#!/usr/bin/env perl

=head1 NAME

Client::Reporter::DataFinder - Find specific data in a web site's stats database

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::DataFinder, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::DataFinder finds specific data in a web site's stats database.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::DataFinder;
$VERSION = "1.0";

use strict;
use Constants::Events;
{

=head2 Class Methods

=over 4

=item new($site)

Create a new Client::Reporter::DataFinder object for a particular site object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    my $self = {
        site        => $reporter->{site},
        campaign    => $reporter->{campaign} || 'campaign',
        dbh         => undef,
        query       => undef,
        event_table => 'Event',
        visit_table => 'Visit',
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item find_first_campaign_page($user_id)

Get the first campaign page visited by a user ID

=cut
sub find_first_campaign_page
{
    my ($self, $user_id) = @_;

    # Get the site details

    my $site = $self->{site};
    return '' if !$site->{status} || $site->{status} eq 'S';

    # Connect to the site's data server (if necessary)

    $self->{dbh} ||= $site->data_server()->connect();

    # Filter out any local traffic

    my $filter_clause = $site->filter_clause();

    # Create a data server query (if necessary)

    my $database = $site->database();
    my $query = $self->{query} ||= $self->{dbh}->prepare("select E.*, V.*, E.visit_id from $database.$self->{event_table} E join $database.$self->{visit_table} V on V.visit_id = E.visit_id where V.user_id = ? $filter_clause order by E.visit_id, E.time");

    # Read through the traffic to find a first campaign page

    $query->execute($user_id);
    while (my $row = $query->fetchrow_hashref())
    {
        next unless $row->{type_id} == Constants::Events::TYPE_PAGE;
        my $page = $row->{name};
        my $campaign_page = $1 if $page =~ /^([^?]*)/;

        return $page if $page =~ /$self->{campaign}=/ || ($campaign_page && "$site->{campaign_pages}," =~ /\b\Q$campaign_page\E,/);
    }

    # No campaign page was found

    return '';
}

=item disconnect()

Disconnect the data finder by finishing all the queries

=cut
sub disconnect
{
    my ($self) = @_;

    my $query = $self->{query} or return; # if no query to finish

    $query->finish();
}

}1;

=back

=head1 DEPENDENCIES

Constants::Events, Data::SiteStats

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
