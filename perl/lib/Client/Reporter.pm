#!/usr/bin/env perl

=head1 NAME

Client::Reporter - Generate daily reports from raw web traffic activity data
                   As a side-effect, create a day of Traffic data for a site

=head1 VERSION

This document refers to version 2.1 of Client::Reporter, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter generates daily reports from raw web traffic activity data,
and as a side-effect, creates a day of Traffic data for a site - very useful!

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter;
$VERSION = "2.1";

use strict;
use Constants::General;
use Constants::Reports;
use Client::Reporter::DayFile;
use Client::Reporter::DataFinder;
use Client::Reporter::Reports;
use Client::Reporter::Stats;
use Client::Reporter::Stats::Spiders;
use Client::Reporter::Stats::Pages;
use Client::Reporter::Stats::Visits;
use Client::Reporter::Stats::Commerce;
use Client::Reporter::Traffic;
use Data::Site;
use Data::SiteChannel;
use Data::SiteConfig;
use Utils::Time;
use Utils::LogFile;
{
=head2 Class Methods

=over 4

=item new($site_id)

Create a new Client::Reporter object

=cut
sub new
{
    my ($class, $site_id) = @_;
    die "need the id of the site being reported" unless $site_id;

    my $self = {
        site_id         => $site_id,
        channels        => [],
        config          => [],
        stats           => [],
        stats_reports   => {},
        site            => undef,
        campaign        => undef,
        optimize        => undef,
        rollover        => undef,
        start_time      => undef,
        data_finder     => undef,
        page_titles     => undef,
        log_file        => Utils::LogFile->new("$ENV{LOGS_DIR}/reporter"),
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($date)

Generate daily stats reports from raw web activity stored as visits and events

=cut
sub generate
{
    my ($self, $date) = @_;

    # Connect to the master database

    Data::Site->connect();
    Data::SiteChannel->connect();
    Data::SiteConfig->connect();

    # Get the site details

    my $site_id = $self->{site_id} or die "no site_id";
    my $site = Data::Site->row($site_id);
    return $site if !$site->{status} || $site->{status} eq 'S';
    if ($site->{report_time} < time()) # update timestamp
    {
        $site->{report_time} = time();
        $site->update();
    }
    my $channels = Data::SiteChannel->get($site_id);
    my $config = Data::SiteConfig->get($site_id);
    $self->{site} = $site;
    $self->{channels} = $channels;
    $self->{config} = $config;

    # Disconnect from the database

    Data::Site->disconnect();
    Data::SiteChannel->disconnect();
    Data::SiteConfig->disconnect();

    # Use today's date by default

    $date ||= 0;
    if ($date < 20000000)
    {
        my $time = time() - 86400 * $date; # $date is a number of days
        $date = Utils::Time->get_date($time, $site->{time_zone})
    }
    $self->{date} = $date;

    # Get the campaign query string and optimizer settings

    $self->{campaign} = Data::SiteConfig->find($config, 'campaign') || 'campaign';
    $self->{rollover} = lc Data::SiteConfig->find($config, 'rollover') eq 'yes';
    $self->{optimize} = lc Data::SiteConfig->find($config, 'optimize') eq 'yes';

    # Create an ordered list of report generators (THE ORDER IS IMPORTANT)

    $self->{stats_reports} = [
        Client::Reporter::Stats::Spiders->new($self), # check for spiders 1st
        Client::Reporter::Stats::Pages->new($self),   # to filter them out,
        Client::Reporter::Stats::Commerce->new($self),# commerce before visits
        Client::Reporter::Stats::Visits->new($self),  # to check all referrers
    ];

    # Generate a day of web traffic reports

    eval {
        my $traffic = Client::Reporter::Traffic->new($self);
        my $day_file = Client::Reporter::DayFile->new($site);
        my $start_time = $day_file->generate(date     => $date,
                                             rollover => $self->{rollover},
                                             optimize => $self->{optimize},
                                             recreate => 0);
        $self->{start_time} = $start_time or die "Site $site_id has no start time";
        $self->{page_titles} = $day_file->get_page_titles(); # for page reports

        # Start the reports

        foreach my $stats_report (@{$self->{stats_reports}})
        {
            $stats_report->start();
        }

        # Read the stats reports, and write traffic data

        $traffic->connect();
        $traffic->delete($start_time);

        $day_file->open();
        while (my $visit_data = $day_file->next_visit())
        {
            $traffic->insert($visit_data);
            $self->visit_stats($visit_data);
        }
        $day_file->close();

        $traffic->disconnect();

        # Finish the reports

        foreach my $stats_report (@{$self->{stats_reports}})
        {
            $stats_report->finish();
        }

        # Disconnect the data finder

        $self->disconnect_data_finder();

        # Write the stats reports

        $self->write_stats();

        # Generate detailed reports for pro and commerce users

        my $product_code = $self->{site}{product_code};
        if ($product_code eq Constants::General::PRODUCT_CODE_PRO ||
            $product_code eq Constants::General::PRODUCT_CODE_COMMERCE)
        {
            Client::Reporter::Reports->new($self)->generate($day_file);
        }
    };
    $self->{log_file}->error("Site $site_id error: $@") if $@;

    # Return the site with its updated timestamp

    return $site;
}

=item visit_stats($visit_data)

Process all reports for the visit, then collate the values in visited channels

=cut
sub visit_stats
{
    my ($self, $visit_data) = @_;
    my $stats = $self->{stats} or die "no stats";
    my $visit = [];
    return if $visit_data->{if}; # "if" means "is filtered"

    # Get visit stats by running all the reporters

    foreach my $stats_report (@{$self->{stats_reports}})
    {
        # Use a true return value to filter the visit

        last if $stats_report->report($visit_data, $visit);
    }

    # Update all the channel stats with the visit

    while (my ($channel_id, $hits) = each %{$visit->[Constants::Reports::CHANNEL]})
    {
        my $channel = $stats->[$channel_id] ||= [];

        for (my $report_id = Constants::Reports::MIN_REPORTS; $report_id <= Constants::Reports::MAX_REPORTS; $report_id++)
        {
            while (my ($field, $value) = each %{$visit->[$report_id]})
            {
                $channel->[$report_id]{$field} += $value;
            }
        }

        $channel->[Constants::Reports::TRAFFIC]{visits}++;
        $channel->[Constants::Reports::TRAFFIC]{hits} += $hits;
    }
}

=item write_stats()

Write web traffic report stats to the site's Stats table

=cut
sub write_stats
{
    my ($self) = @_;

    Client::Reporter::Stats->new($self)->write();
    $self->{stats} = []; # to reclaim some memory
}

=item find_first_campaign_page($user_id)

Find and return the first campaign page visited by a user ID

=cut
sub find_first_campaign_page
{
    my ($self, $user_id) = @_;

    my $data_finder = $self->{data_finder} ||= Client::Reporter::DataFinder->new($self);
    return $data_finder->find_first_campaign_page($user_id);
}

=item disconnect_data_finder()

Disconnect the data finder

=cut
sub disconnect_data_finder
{
    my ($self) = @_;

    my $data_finder = $self->{data_finder} or return; # if no data finder

    $data_finder->disconnect();
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Constants::Reports, Client::Reporter::DayFile, Client::Reporter::DataFinder, Client::Reporter::Reports, Client::Reporter::Stats, Client::Reporter::Traffic, Client::Reporter::Stats::Spiders, Client::Reporter::Stats::Pages, Client::Reporter::Stats::Visits, Client::Reporter::Stats::Commerce, Data::Site, Data::SiteChannel, Data::SiteConfig, Utils::Time, Utils::LogFile

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
