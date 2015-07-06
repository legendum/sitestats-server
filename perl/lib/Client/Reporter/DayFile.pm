#!/usr/bin/env perl

=head1 NAME

Client::Reporter::DayFile - Create a file containing web traffic for the day

=head1 VERSION

This document refers to version 1.0 of Client::Reporter::DayFile, released Jul 07, 2015

=head1 DESCRIPTION

Client::Reporter::DayFile creates a file containing web traffic for the day.

=head2 Properties

=over 4

None

=back

=cut
package Client::Reporter::DayFile;
$VERSION = "1.0";

use strict;
use Constants::Events;
use Data::SiteStats;
use Utils::Time;
use FileHandle;
{

=head2 Class Methods

=over 4

=item new($site, [$directory])

Create a new Client::Reporter::DayFile object

=cut
sub new
{
    my ($class, $site, $directory) = @_;
    die "no site" unless $site;
    $directory ||= "$ENV{DATA_DIR}/reporter";

    my $self = {
        site        => $site,
        dbh         => undef,
        directory   => $directory,
        filename    => undef,
        file_handle => undef,
        event_table => 'Event',
        visit_table => 'Visit',
        page_titles => {},
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate(date => $date, [rollover => 1], [optimize => 1])

Generate a file of web traffic data for a date, one visit per line

=cut
sub generate
{
    my ($self, %args) = @_;
    my $date = $args{date} or die "no date";
    my $rollover = $args{rollover} || 0;
    my $optimize = $args{optimize} || 0;

    # Get the site details

    my $site = $self->{site};
    return 0 if !$site->{status} || $site->{status} eq 'S';

    # Use today's date by default

    $date ||= 0;
    if ($date < 20000000)
    {
        my $time = time() - 86400 * $date; # $date is a number of days
        $date = Utils::Time->get_date($time, $site->{time_zone})
    }
    my ($start_time, $end_time) = Utils::Time->get_time_range($date, $site->time_zone_dst()); # apply Daylight Saving Time

    # Set the filename to the site ID and date

    $self->{filename} = $self->{directory} . '/' . $self->{site}{site_id} . '.' . $date;

    # Use rollover database tables

    my $year_month = substr($date, 0, 6);
    my $today = Utils::Time->get_date(time(), $site->{time_zone});
    if ($rollover && $year_month != substr($today, 0, 6))
    {
        $self->{event_table} .= $year_month;
        $self->{visit_table} .= $year_month;
    }

    # Write a file of web traffic data for the day

    $self->write_file($start_time, $end_time, $optimize);
    chmod 0666, $self->{filename}; # so the web server can overwrite

    # Return the start time for hour-of-day reports

    return $start_time;
}

=item write_file($start_time, $end_time, [$optimize])

Read the stats for a web site

=cut
sub write_file
{
    my ($self, $start_time, $end_time, $optimize) = @_;
    my $site = $self->{site} or die "no site";
    $self->{file_handle} = FileHandle->new($self->{filename}, 'w');

    # Get the site's data server

    $self->{dbh} = Data::SiteStats->connect(host => $site->data_server()->{host});

    # Create a data server query

    my $database = $site->database();
    my $query = $self->{dbh}->prepare("select E.*, V.*, E.visit_id, E.time as event_time from $database.$self->{event_table} E, $database.$self->{visit_table} V where E.visit_id = V.visit_id and V.time between ? and ? order by V.visit_id, E.time", {'mysql_use_result' => $optimize});
    $query->execute($start_time, $end_time);
    my $last_visit_id = 0;
    my $last_channel_id = 0;
    my $last_refer_id = 0;
    my $last_type_id = 0;
    my $last_class = undef;
    my $last_page = undef;
    my $first_time = 0;
    my $last_time = 0;
    my $last_row;
    my $count = 0;
    my $pages = 0;
    my $path = '';
    while (my $row = $query->fetchrow_hashref())
    {
        # Set the first values

        $last_visit_id = $row->{visit_id} unless $last_visit_id;
        $last_time = $row->{event_time} unless $last_time;
        $first_time = $row->{event_time} unless $first_time;

        # Write the visit

        if ($last_visit_id != $row->{visit_id})
        {
            $path .= "|e$count=$last_channel_id $last_type_id 0 $last_page $last_refer_id $last_class";
            $last_row->{duration} = $last_time - $first_time;
            $last_row->{page_views} = $pages;
            $self->write_visit($last_row, $path);

            $count = 0;
            $pages = 0;
            $path = '';
            $last_page = undef;
            $first_time = $row->{event_time};
        }

        # Update the path

        my $durn = $row->{event_time} - $last_time;
        $path .= "|e$count=$last_channel_id $last_type_id $durn $last_page $last_refer_id $last_class" if defined $last_page;
        $count++;

        # Remember the last row and values

        $last_visit_id = $row->{visit_id};
        $last_channel_id = $row->{channel_id} || 0;
        $last_refer_id = $row->{refer_id} || 0;
        $last_type_id = $row->{type_id} || Constants::Events::TYPE_PAGE;
        $last_class = $row->{class} || ''; $last_class =~ s/ /%20/g;
        $row->{name} ||= 'Home page';
        $last_page = $row->{name}; $last_page =~ s/ /%20/g;
        $last_time = $row->{event_time};
        $last_row = $row;

        # Remember the page title for the Client::Reporter::Stats::Pages class

        if ($last_type_id == Constants::Events::TYPE_PAGE # If it's a page view
        && $row->{description}                       # and it has a page title
        && $self->{page_titles}{$last_page} eq '')   # and it's a new title...
        {
            my $title = $row->{description}; # all page descriptions are titles
            $title =~ s/\\[rnt]/ /g; # replace any whitespace with a space
            $title =~ s/\\//g; # remove any backslash escapes (e.g. PHP "magic")
            $self->{page_titles}{$last_page} = $title; # save it in the hashref
        }

        # Count the page views

        $pages++ if $last_type_id == Constants::Events::TYPE_PAGE;
    }
    $query->finish();

    # Write the final visit

    if ($last_visit_id)
    {
        $path .= "|e$count=$last_channel_id $last_type_id 0 $last_page $last_refer_id $last_class";
        $last_row->{duration} = $last_time - $first_time;
        $last_row->{page_views} = $pages;
        $self->write_visit($last_row, $path);
    }

    # Disconnect from the database

    Data::SiteStats->disconnect();
}

=item write_visit($visit, $path)

Write a visit to the file

=cut
sub write_visit
{
    my ($self, $v, $path) = @_;

    no warnings;
    my $is_filtered = $self->{site}->is_filtered($v->{host}, $v->{host_ip});
    $self->{file_handle}->print("vi=$v->{visit_id}|ui=$v->{user_id}|gi=$v->{global_id}|tm=$v->{time}|pv=$v->{page_views}|dn=$v->{duration}|if=$is_filtered|ip=$v->{host_ip}|ho=$v->{host}|co=$v->{cookies}|fl=$v->{flash}|ja=$v->{java}|js=$v->{javascript}|ua=$v->{browser}|os=$v->{op_sys}|la=$v->{language}|tz=$v->{time_zone}|gc=$v->{country}|gr=$v->{region}|gt=$v->{city}|go=$v->{longitude}|ga=$v->{latitude}|ns=$v->{netspeed}|cb=$v->{color_bits}|sr=$v->{resolution}|ca=$v->{campaign}|re=$v->{referrer}|se=$v->{search}$path\n");
    use warnings;
}

=item open()

Open the day file

=cut
sub open
{
    my ($self) = @_;
    $self->{file_handle} = FileHandle->new($self->{filename}, 'r');
}

=item close()

Close the day file

=cut
sub close
{
    my ($self) = @_;
    $self->{file_handle}->close();
}

=item next_visit()

Get the next visit

=cut
sub next_visit
{
    my ($self) = @_;
    my $line = $self->{file_handle}->getline() or return;

    # Extract the fields into a hash reference

    my %fields;
    map {$fields{$1} = $2 if /^(\w{2}\d*)=(.*)/} (split /\|/, $line);
    return \%fields;
}

=item get_page_titles()

Get a hashref of page titles, keyed by the page URL

=cut
sub get_page_titles
{
    my ($self) = @_;
    return $self->{page_titles};
}

}1;

=back

=head1 DEPENDENCIES

Constants::Events, Data::SiteStats, Utils::Time, FileHandle

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
