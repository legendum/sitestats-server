#!/usr/bin/env perl

=head1 NAME

Client::Sitester::ReportFilters - A module to create report filters when needed

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::ReportFilters, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::ReportFilters creates report filters when they are needed, for
example when a "page visits" report is being displayed for a content channel.

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::ReportFilters;
$VERSION = "1.0";

use strict;

use Constants::Reports;
use Data::SiteChannel;
{

=head2 Class Methods

=over 4

=item new($report_id, $channel_id)

Create a new Client::Sitester::ReportFilters object for a particular report ID
and optionally a channel ID

=cut
sub new
{
    my ($class, $report_id, $channel_id) = @_;
    die "no report ID" unless $report_id;

    my $self = {
        report_id   => $report_id,
        channel_id  => $channel_id || 0,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item apply_to($reports)

Apply some report filters to a "reports" object by modifying its "include" and
"exclude" properties if necessary.

=cut
sub apply_to
{
    my ($self, $reports) = @_;

    return $self->apply_to_page_visits($reports)
        if $self->{report_id} == Constants::Reports::PAGE_VISITS
        && $self->{channel_id};
}

=item apply_to_page_visits($reports)

Apply some report filters to a page visits "reports" object by modifying its
"include" property so that it matches particular page names inside the channel.

=cut
sub apply_to_page_visits
{
    my ($self, $reports) = @_;

    # Get a the site's channels

    Data::SiteChannel->connect();
    my $channels = Data::SiteChannel->get($reports->{site}{site_id});
    Data::SiteChannel->disconnect();

    # Create a regex from the channel and its children

    my $channel = $channels->[$self->{channel_id}];
    my @urls = split /[\r\n]+/, $channel->{urls};
    foreach my $channel_id (@{$channel->{children}})
    {
        $channel = $channels->[$channel_id];
        push @urls, split /[\r\n]+/, $channel->{urls};
    }
    my $regex = '^(' . join('|', @urls) . ')';

    # Update the "include" field on the "reports" object

    $reports->{include} = $regex;
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports, Data:SiteChannel

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
