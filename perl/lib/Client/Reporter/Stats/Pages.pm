#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Stats::Pages - generate reports about web pages

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats::Pages, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats::Pages generates reports about web pages

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats::Pages;
$VERSION = "1.0";

use strict;
use base 'Client::Reporter::Stats::Report';
use Data::Page;
use Client::Reporter::Event;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Stats::Pages object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    # Connect to the site page table to add missing pages

    my $site = $reporter->{site} or die "no site";
    Data::Page->connect(host => $site->data_server()->{host}, database => $site->database());
    my $url_trim = Data::SiteConfig->find($reporter->{config}, 'url_trim') || '\?';
    my $site_search = Data::SiteConfig->find($reporter->{config}, 'site_search') || '';

    # Get the start time to calculate the hour-of-day hits

    my $self = {
        stats       => $reporter->{stats},
        pages       => undef,
        channels    => $reporter->{channels},
        reporter    => $reporter, # for the start time
        url_trim    => $url_trim, # for browsing pages
        site_search => $site_search, # for site search
    };

    # Return the new pages report object

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

    my $count = 1;
    my $last_page;
    my $time = $visit_data->{tm};
    my $start_time = $self->{reporter}{start_time};
    my $referrer = $visit_data->{re};
    my $visit_path = $referrer || 'direct';
    $visit_path =~ s/\/.*//; # strip the page
    my $visit_pages = 0;
    my $visit_duration = 0;
    while (my $event = $visit_data->{"e$count"})
    {
        my ($channel_id, $type_id, $duration, $name, $refer_id, $class) = Client::Reporter::Event->parse($event);
        my $channel = $stats->[$channel_id] ||= [];
        $duration = 0 if $duration < 0; # safeguard
        $count++;

        # Handle non-page event types

        if ($type_id != Constants::Events::TYPE_PAGE)
        {
            if ($type_id == Constants::Events::TYPE_EXIT)
            {
                # Be sure to count the visit, even if it's just an exit

                $visit->[Constants::Reports::CHANNEL]{$channel_id} += 0;
            }
            elsif ($type_id == Constants::Events::TYPE_PING)
            {
                $channel->[Constants::Reports::TRAFFIC]{duration} += $duration;
                $channel->[Constants::Reports::PAGE_DURATION]{$name} += $duration;
            }
            elsif ($type_id == Constants::Events::TYPE_FILE)
            {
                $channel->[Constants::Reports::TRAFFIC]{files}++;
                $channel->[Constants::Reports::FILE]{$name}++;
            }
            elsif ($type_id == Constants::Events::TYPE_LINK)
            {
                $channel->[Constants::Reports::TRAFFIC]{links}++;
                $channel->[Constants::Reports::LINK]{$name}++;
            }
            elsif ($type_id == Constants::Events::TYPE_MAIL)
            {
                $name =~ s#/.*##; # remove address
                $channel->[Constants::Reports::TRAFFIC]{mails}++;
                $channel->[Constants::Reports::MAIL]{$name}++;
            }
            next;
        }

        # Measure the traffic duration

        $channel->[Constants::Reports::TRAFFIC]{duration} += $duration;

        # Count the event in the channel and its parents

        $visit->[Constants::Reports::CHANNEL]{$channel_id}++ if $channel_id;
        my $parents = $self->{channels}[$channel_id]{parents};
        map {$visit->[Constants::Reports::CHANNEL]{$_}++} @{$parents};

        # Count visit measures

        $visit->[Constants::Reports::ENTRY_PAGE]{$name} = 1 if $count == 2;
        $visit->[Constants::Reports::PAGE_VISITS]{$name} = 1;
        $self->site_search($visit, $name) if $self->{site_search};

        # Update the page views and directory views reports

        $channel->[Constants::Reports::PAGE]{$name}++;
        $channel->[Constants::Reports::PAGE_DURATION]{$name} += $duration;
        $channel->[Constants::Reports::PAGE_NAVIGATION]{$last_page.'->'.$name}++ if $last_page;
        $channel->[Constants::Reports::REFERRER_HITS]{$referrer.'->'.$name}++ if $referrer;
        my $directory = ($name =~ m#^(.+)/# ? $1 : '/');
        $channel->[Constants::Reports::DIRECTORY]{$directory}++;
        my $hour = int(($time - $start_time) / 3600);
        $hour = 25 if $hour < 0 || $hour > 23; # Ed Norton's 25th hour exception
        $visit->[Constants::Reports::HOUR_OF_DAY_VISITS]{$hour} = 1 if $count == 2;
        $channel->[Constants::Reports::HOUR_OF_DAY_HITS]{$hour}++;

        # Move the time along to the next page

        $time += $duration;
        $visit_path .= "->$name";

        # Remember the last page, and keep visit stats

        $last_page = $name;
        $visit_pages++;
        $visit_duration += $duration;

        # Ensure the page is included in the page hash

        my $trim = $self->{url_trim}; # query strings
        eval { $name =~ s/$trim.*$//; }; # to remove
        $self->{pages}{$name} ||= 0; # no page ID yet
    }

    # If only one page was visited it's a bounce page

    $visit->[Constants::Reports::BOUNCE_PAGE]{$last_page} = 1 if $count == 2 && $last_page;

    # Save visit data for other reporters who need it

    my $max = Constants::General::VISIT_DURATION;
    $visit_duration = $max if $visit_duration > $max;
    $visit->[Constants::Reports::THIS_VISIT_DURATION] = $visit_duration;
    $visit->[Constants::Reports::THIS_VISIT_PAGES] = $visit_pages;
    $visit->[Constants::Reports::THIS_VISIT_PATH] = $visit_path;

    # Measure visit stats about the pages visited

    $visit->[Constants::Reports::EXIT_PAGE]{$last_page} = 1 if $last_page;
    my $duration_in_mins = int($visit_duration / 60 + 0.5);
    $visit->[Constants::Reports::VISIT_DURATION]{$duration_in_mins} = 1;
    $visit->[Constants::Reports::VISIT_PAGES]{$visit_pages} = 1;
    $visit->[Constants::Reports::REFERRER_PATH]{$visit_path} = 1;

    # Don't filter

    return 0;
}

=item start()

Start the report

=cut
sub start
{
    my ($self) = @_;
    $self->{pages} = Data::Page->get_pages($self->{reporter}{page_titles},
                                           $self->{url_trim});
}

=item finish()

Finish the report

=cut
sub finish
{
    my ($self) = @_;

    # Add missing pages to the page table

    Data::Page->add_pages($self->{pages},                   # URLs to add
                          $self->{reporter}{page_titles},   # titles to match
                          $self->{url_trim});               # URL trimming

    # Disconnect from the site page table

    Data::Page->disconnect();
}

=item site_search($visit, $page)

Measure any search inside the web site

=cut
sub site_search
{
    my ($self, $visit, $page) = @_;
    my $pos = rindex $page, $self->{site_search};
    if ($pos > -1)
    {
        $pos += length $self->{site_search};
        my $search = substr $page, $pos;
        $visit->[Constants::Reports::SITE_SEARCH_PHRASE]{$search} = 1;
        foreach my $word (split /\s+/, $search)
        {
            $visit->[Constants::Reports::SITE_SEARCH_WORD]{lc($word)}++ if length $word;
        }
    }
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Constants::Reports, Constants::Events, Data::Page, Client::Reporter::Event

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
