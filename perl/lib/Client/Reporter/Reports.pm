#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Reports - Write detailed web traffic reports to Reports table

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Reports, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Reports writes detailed web traffic reports to Reports table

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Reports;
$VERSION = "1.0";

use strict;
use Client::Reporter::DayFile;
use Client::Reporter::Reports::Demographics;
use Client::Reporter::Reports::Referrer;
use Data::SiteConfig;
use Data::SiteStats;
use Constants::Reports;
{
    # Class static properties

    use constant DEFAULT_LIMIT  => 200;

=head2 Class Methods

=over 4

=item new($reporter)

Create a new Client::Reporter::Stats object

=cut
sub new
{
    my ($class, $reporter) = @_;
    die "no reporter" unless $reporter;

    my $self = {
        site_id  => $reporter->{site_id},
        site     => $reporter->{site},
        date     => $reporter->{date},
        channels => $reporter->{channels},
        config   => $reporter->{config},
        data     => [],
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($day_file)

Generate detailed reports by reading the day file of visit data

=cut
sub generate
{
    my ($self, $day_file) = @_;

    # Make a list of reports to process

    my @reports = (
        Client::Reporter::Reports::Demographics->new($self),
        Client::Reporter::Reports::Referrer->new($self),
    );

    # Process one report at a time

    foreach my $report (@reports)
    {
        # Reset the report data

        $self->{data} = [];

        # Report each visit in the day

        $day_file->open();
        while (my $visit_data = $day_file->next_visit())
        {
            $report->visit($visit_data);
        }
        $day_file->close();

        # Finally write the reports

        $self->write()
    }
}

=item report($hash_ref, $field, $visit_data)

Report a field in a hash of field data against a hash of visit data

=cut
sub report
{
    my ($self, $report_id, $field, $visit_data) = @_;
    my $hash_ref = $self->{data}[$report_id] ||= {};
    my $is_bounce = $visit_data->{pv} == 1;
    my $is_suspect = $is_bounce && $visit_data->{dn} eq 0;

    $hash_ref->{$field}[Constants::Reports::PART_FIRST_TIMES]{$visit_data->{ui}} = 1 if $visit_data->{ui} eq $visit_data->{vi};
    $hash_ref->{$field}[Constants::Reports::PART_USERS]{$visit_data->{ui}} = 1;
    $hash_ref->{$field}[Constants::Reports::PART_VISITS]++;
    $hash_ref->{$field}[Constants::Reports::PART_HITS] += $visit_data->{pv};
    #$hash_ref->{$field}[Constants::Reports::PART_MAILS] += $visit_data->{mv};
    $hash_ref->{$field}[Constants::Reports::PART_BOUNCES]++ if $is_bounce;
    $hash_ref->{$field}[Constants::Reports::PART_SUSPECT]++ if $is_suspect;
    $hash_ref->{$field}[Constants::Reports::PART_DURATION] += $visit_data->{dn};
    $hash_ref->{$field}[Constants::Reports::PART_CAMPAIGNS]++ if $visit_data->{ca};

    return $self; # to daisy-chain calls to this method
}

=item write()

Write reports

=cut
sub write
{
    my ($self) = @_;
    my $site = $self->{site} or die "no site";

    Data::SiteStats->connect(host => $site->data_server()->{host});
    for (my $report_id = 0; $report_id < Constants::Reports::MAX_REPORTS; $report_id++)
    {
        if (my $hash_ref = $self->{data}->[$report_id])
        {
            $self->write_channel_report(0, $report_id, $hash_ref);
        }
    }
    Data::SiteStats->disconnect();
}

=item write_channel_report($channel_id, $report_id, $hash_ref)

Write a report to the database for a channel

=cut
sub write_channel_report
{
    my ($self, $channel_id, $report_id, $hash_ref) = @_;
    my $site = $self->{site} or die "no site";
    my $date = $self->{date} or die "no date";
    die "need report id" unless $report_id;

    my $database = $site->database();
    Data::SiteStats->sql("delete from $database.Reports where the_date = ? and channel_id = ? and report_id = ?", $date, $channel_id, $report_id);

    # Write the stats

    my $sql = "insert into $database.Reports (the_date, channel_id, report_id, field, first_times, users, visits, hits, mails, bounces, suspect, duration, campaigns, conversions, campaign_convs, campaign_goals, goals, cost, revenue) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    my $count = 0;
    my $limit = Data::SiteConfig->find($self->{config}, 'limit', $channel_id, $report_id) || DEFAULT_LIMIT;
    foreach my $field (sort {$hash_ref->{$b}[Constants::Reports::PART_HITS]
                        <=>  $hash_ref->{$a}[Constants::Reports::PART_HITS]}
                       keys %{$hash_ref})
    {
        my $values = $hash_ref->{$field};
        if ($count++ <= $limit)
        {
            next if $field =~ /\\/;
            $values->[Constants::Reports::PART_FIRST_TIMES] = scalar keys %{$values->[Constants::Reports::PART_FIRST_TIMES]};
            $values->[Constants::Reports::PART_USERS] = scalar keys %{$values->[Constants::Reports::PART_USERS]};
            $values->[Constants::Reports::PART_MAX] += 0; # for the array length
            Data::SiteStats->sql($sql, $date, $channel_id, $report_id, $field, @{$values});
        }
    }
}

}1;

=back

=head1 DEPENDENCIES

Client::Reporter::DayFile, Client::Reporter::Reports::Demographics, Client::Reporter::Reports::Referrer, Data::SiteConfig, Data::SiteStats, Constants::Reports

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
