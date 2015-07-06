#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Stats::Spiders - generate reports about web spiders

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats::Spiders, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats::Spiders generates reports about web spiders

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats::Spiders;
$VERSION = "1.0";

use strict;
use base 'Client::Reporter::Stats::Report';
use Utils::Transforms;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Stats::Spiders object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    my $self = {
        stats       => $reporter->{stats},
        transforms  => Utils::Transforms->new(),
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item report($visit_data, $visit)

Report the visit

=cut
sub report
{
    my ($self, $visit_data, $visit) = @_;
    my $stats = $self->{stats};

    # It's a spider if it requested the "spider" page or the browser matches

    my $browser = $visit_data->{ua};
    my $first_page = $visit_data->{e1} || '';
    if ($first_page =~ /spider$/ || $self->{transforms}->is_spider($browser))
    {
        $stats->[0][Constants::Reports::TRAFFIC]{spider_visits}++;
        $stats->[0][Constants::Reports::SPIDER]{$browser}++;
        return 1; # filter this visit
    }

    # Don't filter

    return 0;
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports, Utils::Transforms

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
