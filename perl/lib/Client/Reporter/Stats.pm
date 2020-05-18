#!/usr/bin/env perl

=head1 NAME

Client::Reporter::Stats - Read and write web traffic reports from/to Stats table

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::Stats, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::Stats reads and writes web traffic reports from/to Stats table

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::Stats;
$VERSION = "1.0";

use strict;
use Data::Site;
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
        stats    => $reporter->{stats},
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item write()

Write stats reports for all the site channels

=cut
sub write
{
    my ($self) = @_;
    my $site = $self->{site} or die "no site";

    # Sum the channel durations, links, mails and hourly hits

    my $postorder_channels = Data::SiteChannel->postorder($self->{channels});
    foreach my $channel (@{$postorder_channels})
    {
        my $channel_id = $channel->{channel_id} or next;
        my $parent_id = $channel->{parent_id};
        my $channel_stats = $self->{stats}[$channel_id];
        my $parent_stats = $self->{stats}[$parent_id];
        $parent_stats->[Constants::Reports::TRAFFIC]{duration} += $channel_stats->[Constants::Reports::TRAFFIC]{duration} || 0;
        $parent_stats->[Constants::Reports::TRAFFIC]{links} += $channel_stats->[Constants::Reports::TRAFFIC]{links} || 0;
        $parent_stats->[Constants::Reports::TRAFFIC]{mails} += $channel_stats->[Constants::Reports::TRAFFIC]{mails} || 0;

        for (my $hour = 0; $hour < 24; $hour++)
        {
            $parent_stats->[Constants::Reports::HOUR_OF_DAY_HITS]{$hour} += $channel_stats->[Constants::Reports::HOUR_OF_DAY_HITS]{$hour} || 0;
        }
    }

    # Close any old connections

    Data::Site->disconnect();
    Data::SiteStats->disconnect();

    # Connect to the site's data server and the master data server

    Data::Site->connect(host => $site->data_server()->{host});
    Data::SiteStats->connect(); # to the master server

    # For each site channel...

    foreach my $channel (@{$postorder_channels})
    {
        my $channel_id = $channel->{channel_id};
        my $reports = $self->{stats}[$channel_id];

        # Get a unique user count

        my $users = scalar keys %{$reports->[Constants::Reports::USER]};
        $reports->[Constants::Reports::TRAFFIC]{users} = $users;

        # Write the daily traffic

        Data::SiteStats->traffic( $self->{site_id},
                                  $channel_id,
                                  $self->{date},
                                  'day',
                                  $reports->[Constants::Reports::TRAFFIC] );

        # Calculate average page durations and load times

        map { $reports->[Constants::Reports::PAGE_DURATION]{$_} /= ($_ =~ /mail:(.+)/ ?
                                        $reports->[Constants::Reports::MAIL]{$1} || 1 :
                                        $reports->[Constants::Reports::PAGE]{$_} || 1) }
                                        keys %{$reports->[Constants::Reports::PAGE_DURATION]};

        map { $reports->[Constants::Reports::PAGE_LOAD_TIME]{$_} /= ($reports->[Constants::Reports::PAGE]{$_} || 1) }
                                        keys %{$reports->[Constants::Reports::PAGE_LOAD_TIME]};

        # For each report...

        for (my $report_id = Constants::Reports::MIN_REPORTS; $report_id <= Constants::Reports::MAX_REPORTS; $report_id++)
        {
            next if $report_id == Constants::Reports::USER; # don't write all user ids
            my $hash_ref = $reports->[$report_id] or next;

            # Write the channel report

            my $hash_ref_for_keys = $report_id == Constants::Reports::PAGE_DURATION ?
                                    $reports->[Constants::Reports::PAGE] :
                                    $hash_ref;
            $self->write_channel_report($channel_id, $report_id, $hash_ref, $hash_ref_for_keys)
        }
    }

    # Disconnect from the data servers

    Data::Site->disconnect();
    Data::SiteStats->disconnect();
}

=item write_channel_report($channel_id, $report_id, $hash_ref, $hash_ref_for_keys)

Write a stats report to the database for a channel

=cut
sub write_channel_report
{
    my ($self, $channel_id, $report_id, $hash_ref, $hash_ref_for_keys) = @_;
    $hash_ref_for_keys ||= $hash_ref;
    my $site = $self->{site} or die "no site";
    my $date = $self->{date} or die "no date";
    die "need report id" unless $report_id;

    my $database = $site->database();
    Data::Site->sql("delete from $database.Stats where the_date = ? and channel_id = ? and report_id = ?", $date, $channel_id, $report_id);

    # Write the stats

    my $sql = "insert into $database.Stats (the_date, channel_id, report_id, field, value) values (?, ?, ?, ?, ?)";
    my $count = 0;
    my $limit = Data::SiteConfig->find($self->{config}, 'limit', $channel_id, $report_id) || DEFAULT_LIMIT;
    my %others = ();
    foreach my $field (sort {$hash_ref->{$b} <=> $hash_ref->{$a}} keys %{$hash_ref_for_keys})
    {
        my $value = $hash_ref->{$field};
        if ($limit && $count++ <= $limit)
        {
            $field =~ s/\\(x\w{2})/&#$1;/g; # turn "\xAB" into HTML "&$xAB;"
            $field = substr($field, 0, 255); # enforce the max field length
            Data::Site->sql($sql, $date, $channel_id, $report_id, $field, int($value));
        }
        else
        {
            delete $hash_ref->{$field}; # for $hash_ref_for_keys
            if ($report_id == Constants::Reports::HOST)
            {
                $others{lc("other.$1")} += $value
                    if $field =~ /(\w+)$/;
            }
            elsif ($report_id != Constants::Reports::PAGE_DURATION && $report_id != Constants::Reports::PAGE_LOAD_TIME)
            {
                $others{others} += $value;
            }
        }
    }

    # Write the "others"

    while (my ($field, $value) = each(%others))
    {
        Data::Site->sql($sql, $date, $channel_id, $report_id, $field, $value);
    }
}

}1;

=back

=head1 DEPENDENCIES

Data::Site, Data::SiteStats, Constants::Reports

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
