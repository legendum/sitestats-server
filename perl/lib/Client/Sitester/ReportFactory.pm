#!/usr/bin/env perl

=head1 NAME

Client::Sitester::ReportFactory - A factory to make Sitester report objects

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::ReportFactory, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::ReportFactory makes Sitester report objects of a chosen type

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::ReportFactory;
$VERSION = "1.0";

use strict;

use Constants::Reports;
use Client::Sitester::Reports;
{
    my $_Default_language = 'EN';
    my @_Order_by_key_reports = (Constants::Reports::TIME_ZONE, Constants::Reports::VISIT_DURATION, Constants::Reports::VISIT_PAGES);

=head2 Class Methods

=over 4

=item new($report_id)

Create a new Client::Sitester::ReportFactory object for a particular report ID

=cut
sub new
{
    my ($class, $report_id, $language) = @_;
    $language ||= $_Default_language;

    my $self = {
        report_id => $report_id,
        language  => $language,
    };

    bless $self, $class;
}

=item match($report_id, $match_id1, [$match_id2]...)

Return whether the report ID matches any of the report IDs in the list to match

=cut
sub match
{
    my ($class, $report_id, @match_ids) = @_;
    die "no report IDs to match!" unless @match_ids;

    # Check each match ID in the list

    foreach my $match_id (@match_ids)
    {
        return 1 if $report_id == $match_id;
    }

    return 0; # no match found
}

=back

=head2 Object Methods

=over 4

=item create($type, %args)

Create a new Client::Sitester::Reports subclass object, e.g. "Users" or "Stats"

=cut
sub create
{
    my ($self, $type, %args) = @_;
    my $report_id = $self->{report_id};
    $args{lookups} = $self->get_lookup($report_id);
    $args{order} = 'keys' if $self->match($report_id, @_Order_by_key_reports);

    # Return the first and last user and visit IDs for web site channels

    if ($self->match($report_id, Constants::Reports::RANGE))
    {
        require Client::Sitester::Reports::Range;
        return Client::Sitester::Reports::Range->new(%args);
    }

    # Always generate recency and frequency reports from raw visit data

    if ($self->match($report_id, Constants::Reports::RECENCY, Constants::Reports::FREQUENCY))
    {
        require Client::Sitester::Reports::Visits;
        return Client::Sitester::Reports::Visits->new(%args);
    }

    # Cover the general case of a stats report without a user list

    if ($type eq 'Stats')
    {
        require Client::Sitester::Reports::Stats;
        return Client::Sitester::Reports::Stats->new(%args);
    }

    # From now on, all reports are for groups of user IDs

    if ($self->match($report_id, Constants::Reports::TRAFFIC))
    {
        require Client::Sitester::Reports::Users::Traffic;
        return Client::Sitester::Reports::Users::Traffic->new(%args);
    }

    if ($self->match($report_id, Constants::Reports::REFERRER_PAGE, Constants::Reports::REFERRER_SITE, Constants::Reports::REFERRER_SEARCH))
    {
        require Client::Sitester::Reports::Users::Referrer;
        return Client::Sitester::Reports::Users::Referrer->new(%args);
    }

    if ($self->match($report_id, Constants::Reports::SEARCH_WORD, Constants::Reports::SEARCH_PHRASE))
    {
        require Client::Sitester::Reports::Users::Search;
        return Client::Sitester::Reports::Users::Search->new(%args);
    }

    if ($self->match($report_id, Constants::Reports::LOCATION))
    {
        require Client::Sitester::Reports::Users::Location;
        return Client::Sitester::Reports::Users::Location->new(%args);
    }

    if ($self->match($report_id, Constants::Reports::VISIT_DURATION, Constants::Reports::VISIT_PAGES, Constants::Reports::BOUNCE_PAGE, Constants::Reports::ENTRY_PAGE, Constants::Reports::EXIT_PAGE))
    {
        require Client::Sitester::Reports::Users::Visit;
        return Client::Sitester::Reports::Users::Visit->new(%args);
    }

    if ($self->match($report_id, Constants::Reports::PAGE, Constants::Reports::DIRECTORY, Constants::Reports::PAGE_DURATION, Constants::Reports::PAGE_NAVIGATION, Constants::Reports::PAGE_VISITS, Constants::Reports::MAIL, Constants::Reports::FILE, Constants::Reports::LINK, Constants::Reports::SITE_SEARCH_PHRASE, Constants::Reports::SITE_SEARCH_WORD))
    {
        require Client::Sitester::Reports::Users::Page;
        return Client::Sitester::Reports::Users::Page->new(%args);
    }

    # Finally, use the default user report for other report IDs

    require Client::Sitester::Reports::Users;
    return Client::Sitester::Reports::Users->new(%args);
}

=item get_lookup($report_id)

Create a new Client::Sitester::Reports::Lookups subclass object, e.g. "Browser"

=cut
sub get_lookup
{
    my ($self, $report_id) = @_;
    my $module = '';
    my $regex = '';

    # Browsers

    if ($self->match($report_id, Constants::Reports::BROWSER))
    {
        $module = 'Browser';
    }

    # Operating systems

    elsif ($self->match($report_id, Constants::Reports::OP_SYS))
    {
        $module = 'OpSys';
    }

    # Countries and locations

    elsif ($self->match($report_id, Constants::Reports::COUNTRY, Constants::Reports::LOCATION))
    {
        # Use a regex to say where to find the county code in the field

        if ($self->match($report_id, Constants::Reports::LOCATION))
        {
            $regex = '(\w{2})$'; # country code is final 2 characters in field
        }

        $module = 'Country';
    }

    # Languages (Phase 2, issue 2)

    elsif ($self->match($report_id, Constants::Reports::LANGUAGE))
    {
        $module = 'Language';
    }

    # If we've chosen a lookup Perl module, then require it and instantiate it

    if ($module)
    {
        # Make a new lookup object and return it

        my $lookup;
        my $la = $self->{language};
        eval "require Client::Sitester::Lookups::${la}::${module};";
        eval "\$lookup = Client::Sitester::Lookups::${la}::${module}->new(\$regex);";
        return $lookup;
    }
    else
    {
        # By default, return an undefined lookup object

        return undef;
    }
}

}1;

=back

=head1 DEPENDENCIES

Constants::Reports, Client::Sitester::Reports and its subclasses

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
