#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Reports::Referrer - generate reports about web site visits

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Reports::Referrer, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Reports::Referrer generates reports about web site visits

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Reports::Referrer;
$VERSION = "1.0";

use strict;
use Constants::Reports;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reports)

Create a new Client::Reporter::Reports::Referrer object

=cut
sub new
{
    my ($class, $reports) = @_;

    my $self = {
        reports => $reports,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item visit($visit_data)

Measure the visit

=cut
sub visit
{
    my ($self, $visit_data) = @_;
    my $referrer_page = $visit_data->{re} or return;
    my $referrer_site = $1 if $referrer_page =~ m#([^/]*)#;
    my $search_phrase = $visit_data->{se} || '';

    $self->{reports}
    ->report(Constants::Reports::REFERRER_PAGE, $referrer_page, $visit_data)
    ->report(Constants::Reports::REFERRER_SITE, $referrer_site, $visit_data);

    $self->{reports}
    ->report(Constants::Reports::SEARCH_PHRASE, $search_phrase, $visit_data)
    ->report(Constants::Reports::REFERRER_SEARCH, $referrer_site, $visit_data)
    ->report(Constants::Reports::SEARCH_ENGINE_PHRASE, "$referrer_site $search_phrase", $visit_data)
        if $search_phrase;

    if (my @words = split /\s+/, $search_phrase)
    {
        foreach my $word (@words)
        {
            $self->{reports}
            ->report(Constants::Reports::SEARCH_WORD, $word, $visit_data);
        }
    }
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports

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
