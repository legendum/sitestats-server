#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Stats::Commerce - generate reports about web site commerce

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats::Commerce, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats::Commerce generates reports about web site commerce

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats::Commerce;
$VERSION = "1.0";

use strict;
use base 'Client::Reporter::Stats::Report';
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Stats::Commerce object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    my $self = {
        reporter        => $reporter, # for find_first_campaign_page()
        campaign        => $reporter->{campaign} || 'campaign',
        campaign_pages  => $reporter->{site}{campaign_pages} || '',
        commerce_pages  => $reporter->{site}{commerce_pages} || '',
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

    # Find the first page in the visit

    my $first_page = Client::Reporter::Event->find_first_page($visit_data);
    return '' unless $first_page;

    # Report any campaign

    my $campaign_page = $1 if $first_page =~ /^([^?]*)/;
    if ($first_page =~ /$self->{campaign}=/ || ($campaign_page && "$self->{campaign_pages}," =~ /\b\Q$campaign_page\E,/)) # Note the commas!
    {
        # Excellent, we have a campaign entry page

        $campaign_page = $first_page;
        $visit->[Constants::Reports::CAMPAIGN]{$visit_data->{ca}} = 1;
        $visit->[Constants::Reports::CAMPAIGN_ENTRY_PAGE]{$campaign_page} = 1;
        $visit->[Constants::Reports::TRAFFIC]{campaign_visits} = 1;
    }
    else
    {
        # No, this visit wasn't from any campaign

        $campaign_page = '';
    }

    # Report any commerce

    my $visit_path = $visit->[Constants::Reports::THIS_VISIT_PATH];
    my @commerce_pages = split /[,\s]+/, $self->{commerce_pages};
    foreach my $commerce_page (@commerce_pages)
    {
        my $commerce_page_regex = quotemeta $commerce_page;
        next unless $visit_path =~ /$commerce_page_regex/;

        # We have commerce!

        $visit->[Constants::Reports::TRAFFIC]{commerce_visits} = 1;

        # Search for the user's first campaign click

        $campaign_page ||= $self->{reporter}->find_first_campaign_page($visit_data->{ui});

        # Measure commerce from a campaign

        if ($campaign_page)
        {
            $visit->[Constants::Reports::TRAFFIC]{campaign_commerce} = 1;
            my $search = $visit_data->{se};
            $visit->[Constants::Reports::CAMPAIGN_COMMERCE]{"$campaign_page $search->$commerce_page"} = 1;
        }

        # Measure commerce entry page and path

        $visit->[Constants::Reports::COMMERCE_ENTRY_PAGE]{"$first_page->$commerce_page"} = 1;
        $visit->[Constants::Reports::COMMERCE_PATH]{$visit_path} = 1;

        # Measure commerce referrals

        if (my $referrer = $visit_data->{re})
        {
            $referrer =~ s#/.*$##;
            $visit->[Constants::Reports::COMMERCE_REFERRER]{"$referrer->$commerce_page"} = 1;

            # Measure commerce search phrases

            if (my $search = $visit_data->{se})
            {
                $visit->[Constants::Reports::COMMERCE_PHRASE]{$search} = 1;
                $visit->[Constants::Reports::COMMERCE_ENGINE_PHRASE]{"$referrer $search"} = 1;

                # Measure commerce search words

                foreach my $word (split /\s+/, $search)
                {
                    $visit->[Constants::Reports::COMMERCE_WORD]{lc($word)} = 1;
                }
            } # if search
        } # if referrer
    } # for commerce

    # Don't filter

    return 0;
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
