#!/usr/bin/env perl

=head1 NAME

Client::Sitester - Write web site reports as XML (default), CSV, HTML or JSON

=head1 VERSION

This document refers to version 1.2 of Client::Sitester, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester writes web site reports as XML (default), CSV, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester;
$VERSION = "1.3";

use strict;
use base 'Client::API';
use Constants::General;
use Constants::Reports;
use Client::Sitester::ReportFactory;
use Client::Reporter;
use Data::SiteChannel;
use Utils::Time;
use Utils::LogFile;
{
    use constant MAX_DAYS   => 31;

    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Client::Sitester object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new(
        date            => 0,
        reports         => 0,
        channels        => 0,
        channel_names   => {},
        date_requested  => undef,
        log_file        => Utils::LogFile->new("$ENV{LOGS_DIR}/sitester"),
    );
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item refresh()

Refresh today's reports if they are stale

=cut
sub refresh
{
    my ($self) = @_;
    return if $self->{site}{report_time} > time() - Constants::General::CACHE_DURATION;
    $self->{site} = Client::Reporter->new($self->{site}{site_id})->generate();
}

=item generate(start_date => $start_date, end_date => $end_date, channel => $channel_id, hosts => $hosts, users => $users, visits => $visits, name => $name, include => $include, exclude => $exclude, language => $language, group_by => $group_by, log_info => $message)

Generate daily stats reports from web site activity statistics

=cut
sub generate
{
    my ($self, %args) = @_;
    my $start_date = $args{start_date} || 0; # default to today
    my $end_date = $args{end_date} || 0; # default to today
    my $name = $args{name} or die "no report name";
    my $limit = $args{limit} || 0; # optional row limit
    my $hosts = $args{hosts}; # optional list of host IPs
    my $users = $args{users}; # optional list of user IDs
    my $visits = $args{visits}; # optional list of visit IDs
    my $channel_id = $args{channel} || 0;
    my $include = $args{include};
    my $exclude = $args{exclude};
    my $language = $args{language};
    my $group_by = $args{group_by};
    my $log_info = $args{log_info};

    # Log the request
 
    my $site = $self->site() or die "no site";
    my $request_time = time();
    my $details = ($channel_id ? " for channel $channel_id" : '');
    $details .= " group by $group_by" if $group_by;
    $details .= " for " . $self->count_list($hosts) . " hosts" if $hosts;
    $details .= " for " . $self->count_list($users) . " users" if $users;
    $details .= " for " . $self->count_list($visits) . " visits" if $visits;
    $self->{log_file}->info($log_info) if $log_info;
    $self->{log_file}->info("Received $site->{url} request for $name report from $start_date to $end_date$details");

    # Normalize the dates

    $start_date = Utils::Time->normalize_date($start_date, $site->{time_zone});
    $end_date = Utils::Time->normalize_date($end_date, $site->{time_zone});

    # Refresh the reports if necessary

    my $today = Utils::Time->get_date(time(), $site->{time_zone});
    $self->refresh() if $end_date >= $today;

    # Prepare empty report data

    my $reports = {};

    # Get a channel list (if used)

    my @channel_ids = $self->get_all_channel_ids($site->{site_id});
    @channel_ids = split /,/, $channel_id if $channel_id ne 'all';
    foreach my $channel_id (@channel_ids)
    {
        # Split any comma-separated list of names

        foreach my $report_name (split /,\s*/, $name)
        {
            # Split the date range into weeks or months if required

            my @dates = $self->get_dates($start_date, $end_date, $group_by);
            foreach my $date (@dates)
            {
                my ($period_start, $period_end, $period_name) = @{$date};
                $self->get_report(  reports => $reports,
                                    channel_id => $channel_id,
                                    start_date => $period_start,
                                    end_date => $period_end,
                                    period => $period_name,
                                    name => $report_name,
                                    limit => $limit,
                                    hosts => $hosts,
                                    users => $users,
                                    visits => $visits,
                                    include => $include,
                                    exclude => $exclude,
                                    language => $language );
            }
        } # reports
    } # channel list

    # Format the reports

    my $output = $self->format_reports($reports);

    # Log the response
 
    my $request_secs = time() - $request_time;
    my $format = $self->format();
    $self->{log_file}->info("Sending $site->{url} response as $format after $request_secs seconds");

    # Return the reports

    return $output;
}

=item count_list($list)

Return the number of items in a list like "1,2,3,4"

=cut
sub count_list
{
    my ($self, $list) = @_;
    return 0 unless $list;
    my @items = split /,\s*/, $list;
    return scalar @items;
}

=item get_all_channel_ids($site_id)

Return all the channel IDs for a site

=cut
sub get_all_channel_ids
{
    my ($self, $site_id) = @_;

    Data::SiteChannel->connect();

    my @channel_ids = ();
    my $query = 'site_id = ?';
    for (my $site_channel = Data::SiteChannel->select($query, $site_id);
            $site_channel->{site_channel_id};
            $site_channel = Data::SiteChannel->next($query))
    {
        my $channel_id = $site_channel->{channel_id};
        push @channel_ids, $channel_id;
        $self->{channel_names}{$channel_id} = $site_channel->{name};
    }

    Data::SiteChannel->disconnect();

    return @channel_ids;
}

=item get_channel($reports, $site_id, $channel_id)

Return channel data hash for a web site channel ID

=cut
sub get_channel
{
    my ($self, $reports, $site_id, $channel_id) = @_;

    # Return the current channel if it has the right channel ID

    if ($self->{channels} > 0)
    {
        my $current = $reports->{site}{channel}[$self->{channels}-1];
        return $current if $current && $current->{id} == $channel_id;
    }

    # Get the channel name if we were given an ID

    my $channel_name = '';
    $channel_name = $self->{channel_names}{$channel_id} || '' if $channel_id;

    # Create a new channel with an ID and name

    my $channel = $reports->{site}{channel}[$self->{channels}++] = { id => $channel_id, name => $channel_name };
    $self->{reports} = 0;
    return $channel;
}

=item get_key_map($channel, $report_id)

Return a key map to dictate which field keys should be populated.
This was added so that "page_duration,page" report keys match up.

=cut
sub get_key_map
{
    my ($self, $channel, $report_id) = @_;
    return undef unless $self->{reports} > 0;

    # If the last report was page duration and this is page views,
    # or the last report was page views and this is page duration,
    # then make a hash of field keys from the page duration report

    my $key_map = undef;
    my $last_report = $channel->{report}[$self->{reports} - 1];
    if (($last_report->{id} == Constants::Reports::PAGE_DURATION
        && $report_id == Constants::Reports::PAGE)
    ||  ($last_report->{id} == Constants::Reports::PAGE
        && $report_id == Constants::Reports::PAGE_DURATION))
    {
        $key_map = {};
        foreach my $row (@{$last_report->{data}})
        {
            $key_map->{$row->{field}} = 1;
        }
    }

    return $key_map;
}

=item get_dates($start_date, $end_date, $group_by)

Return an array of start/date/period triples according to the start/end dates
and the group_by parameter, which may be "day", "week" or "month".

=cut
sub get_dates
{
    my ($self, $start_date, $end_date, $group_by) = @_;
    my @dates = ();

    # Split the start and end dates into periods according to the group_by

    if ($group_by eq 'day')
    {
        my ($period_start, $period_end, $period_name);
        my $days = 0; # count the days to prevent server overload
        my $time = Utils::Time->get_time($start_date, '00:00:00');
        $period_start = $period_end = Utils::Time->get_date($time);
        do {
            $period_name = $period_start;
            push @dates, [$period_start, $period_end, $period_name];
            $time += Utils::Time::DAY_SECS;
            $period_start = $period_end = Utils::Time->get_date($time);
        } while ($period_end <= $end_date && $days++ < MAX_DAYS);
    }
    elsif ($group_by eq 'week')
    {
        my ($period_start, $period_end, $period_name);
        my $time = Utils::Time->get_time($start_date, '00:00:00');
        my $wday = Utils::Time->get_day_of_week($start_date);
        $time -= ($wday-1) * Utils::Time::DAY_SECS; # Start on a Monday;
        do {
            $period_start = Utils::Time->get_date($time);
            $period_end = Utils::Time->get_date($time + 6 * Utils::Time::DAY_SECS);
            my $year = substr($period_start, 0, 4);
            my $week = Utils::Time->get_week_of_year($period_start);
            $period_name = sprintf("%04d%02d", $year, $week);
            $period_start = $start_date if $period_start < $start_date;
            $period_end = $end_date if $period_end > $end_date;
            push @dates, [$period_start, $period_end, $period_name];
            $time += 7 * Utils::Time::DAY_SECS; # Add a week
        } while ($period_end < $end_date);
    }
    elsif ($group_by =~ /^(month|quarter|third|half|year)$/)
    {
        my %periods = ('month'=>1, 'quarter'=>3, 'third'=>4, 'half'=>6, 'year'=>12);
        my $months = $periods{$group_by};
        my ($year, $month) = ($1, $2) if $start_date =~ /(\d{4})(\d{2})/;
        my $period = int(($month - 1) / $months);
        my ($period_start, $period_end, $period_name);
        do {
            $period_start = sprintf("%04d%02d01", $year, $period*$months + 1);
            $period_name = substr($period_start, 0, 6) if $group_by eq 'month';
            $period_name = "${year}Q" . ($period+1) if $group_by eq 'quarter';
            $period_name = "${year}T" . ($period+1) if $group_by eq 'third';
            $period_name = "${year}H" . ($period+1) if $group_by eq 'half';
            $period_name = $year if $group_by eq 'year';
            $period++;
            if ($period >= 12/$months)
            {
                $period = 0;
                $year++;
            }
            $period_end = sprintf("%04d%02d01", $year, $period*$months + 1);
            $period_end = Utils::Time->get_date(Utils::Time->get_time($period_end, '00:00:00') - Utils::Time::DAY_SECS);
            $period_start = $start_date if $period_start < $start_date;
            $period_end = $end_date if $period_end > $end_date;
            push @dates, [$period_start, $period_end, $period_name];
        } while ($period_end < $end_date);
    }
    else
    {
        # By default, return the start and end dates, with no period

        push @dates, [$start_date, $end_date, ''];
    }

    return @dates;
}

=item get_report(%args)

Return report data for a web site channel on a particular date

=cut
sub get_report
{
    my ($self, %args) = @_;
    my $site = $self->{site} or die "no site";
    my $reports = $args{reports} or die "no reports";
    my $channel_id = $args{channel_id} || 0;
    my $start_date = $args{start_date} || 0;
    my $end_date = $args{end_date} || 0;
    my $period = $args{period} || '';
    my $name = $args{name} or die "no report name";
    my $limit = $args{limit} || 0; # optional row limit
    my $hosts = $args{hosts} || ''; # optional host list
    my $users = $args{users} || ''; # optional user list
    my $visits = $args{visits} || ''; # optional visit list
    my $include = $args{include} || ''; # optional field name filter
    my $exclude = $args{exclude} || ''; # optional field name filter
    my $language = $args{language} || ''; # optional language

    # Get the Unix epoch time and seconds into the day to compute forecasts

    my $time = Utils::Time->get_time($start_date, '00:00:00', $site->{time_zone});
    my $secs = time() - $time;
    
    # Create the Perl data structure

    $reports->{site} ||= { id => $site->{site_id}, url => $site->{url}, time_zone => $site->{time_zone} };
    my $channel = $self->get_channel($reports, $site->{site_id}, $channel_id);

    # Store the report's ID name and date details

    $name = lc($name);
    my $report_id = Client::Sitester::Reports->report_id($name) or die "report '$name' not known";
    my $key_map = $self->get_key_map($channel, $report_id);
    my $report = $channel->{report}[$self->{reports}++] = { id => $report_id, name => $name, start_date => $start_date, end_date => $end_date, period => $period, time => $time, secs => $secs, data => [] };

    # Read report data from the Sitester cache

    %args = (data => $report->{data}, # this is filled by get_report() below
             site => $site,
             limit => $limit,
             hosts => $hosts,
             users => $users,
             visits => $visits,
             key_map => $key_map,
             include => $include,
             exclude => $exclude);
    my $type = ($hosts || $users || $visits) ? 'Users' : 'Stats';
    my $factory = Client::Sitester::ReportFactory->new($report_id, $language);
    my $report_object = $factory->create($type, %args);

    $report->{units} = 'unknown';
    $report->{total} = 0;
    eval {
        $report->{units} = $report_object->units($report_id);
        $report->{total} = $report_object->get_report($channel_id, $report_id, $start_date, $end_date);
    };
    $self->{log_file}->error($@) if $@;

    # Return the reports as a hash-ref data structure with request stats

    $reports->{stats} ||= $self->api_stats();

    # Optionally add any debug info to the hash-ref

    $reports->{debug} = $ENV{DEBUG} if $ENV{DEBUG};

    # Log details about the report generation speed

    my $details = join "\n", @{ $report_object->get_logging() };
    $self->{log_file}->debug("Report generation details:\n$details");
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Constants::Reports, Client::Sitester::ReportFactory, Client::Reporter, Data::SiteChannel, Utils::Time, Utils::LogFile

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
