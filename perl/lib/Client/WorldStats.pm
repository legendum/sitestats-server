#!/usr/bin/env perl 

=head1 NAME

Client::WorldStats - Generate web traffic reports about global web visitors

=head1 VERSION

This document refers to version 1.0 of Client::WorldStats, released Jul 07, 2015

=head1 DESCRIPTION

Client::WorldStats generates web traffic reports about global web visitors.

=head2 Properties

=over 4

None

=back

=cut
package Client::WorldStats;
$VERSION = "1.0";

use strict;
use base 'Server::FileFinder';
use Constants::Reports;
use FileHandle;
use Utils::Transforms;
use Utils::Country;
use Utils::Time;
use Data::Site;
use Data::SiteConfig;
use Utils::LogFile;
{
    # Class static properties

    use constant WORLD                  => 1;
    use constant DEFAULT_LIMIT          => 500;

    # Report ID numbers

    use constant REPORT_LIST => (
        Constants::Reports::TRAFFIC,
        Constants::Reports::BROWSER,
        Constants::Reports::COUNTRY,
        Constants::Reports::LANGUAGE,
        Constants::Reports::TIME_ZONE,
        Constants::Reports::COLOR_BITS,
        Constants::Reports::RESOLUTION,
        Constants::Reports::OP_SYS,
        Constants::Reports::REFERRER_SEARCH,
        Constants::Reports::HOUR_OF_DAY_VISITS,
        Constants::Reports::SPIDER,
        Constants::Reports::LOCATION,
    );

=head2 Class Methods

=over 4

=item new($source_dir)

Create a new Client::WorldStats object to generate reports for global web visitors

=cut
sub new
{
    my ($class, $source_dir) = @_;
    $source_dir ||= "$ENV{DATA_DIR}/apache";
    die "need a directory to read stats files" unless -d $source_dir;

    # Get the world site data details

    Data::Site->connect();
    Data::SiteConfig->connect();
    my $site = Data::Site->row(WORLD);
    my $config = Data::SiteConfig->get(WORLD);
    Data::Site->disconnect();
    Data::SiteConfig->disconnect();

    # Create a Client::WorldStats data object

    my $self = $class->SUPER::new($source_dir, '\.\d+$');
    $self->{date} = 0;
    $self->{site} = $site;
    $self->{config} = $config;
    $self->{transforms} = Utils::Transforms->new();
    $self->{log_file} = Utils::LogFile->new("$ENV{LOGS_DIR}/worldstats");
    $self->{log_file}->alert("Created");

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($date)

Generate daily reports about global web visitors

=cut
sub generate
{
    my ($self, $date) = @_;

    # Use today's date by default

    $date ||= 0;
    if ($date < 20000000)
    {
        my $time = time() - 86400 * $date; # $date is a number of days
        $date = Utils::Time->get_date($time, $self->{site}->{time_zone})
    }
    $self->{date} = $date;


    # Read and write world stats

    $self->read_world_data();
    $self->write_world_data();
}

=item read_world_data()

Read global web visitor data from the raw Apache log files (in custom format)

=cut
sub read_world_data
{
    my ($self) = @_;

    # Get the time range and database

    my ($start_time, $end_time) = Utils::Time->get_time_range($self->{date}, $self->{site}->{time_zone});

    $self->{start_time} = $start_time;
    $self->{end_time} = $end_time;
    $self->{stats} = [];
    $self->find_files(-1); # return
}

=item write_world_data()

Write global web visitor data into the special "stats1" WorldStats database

=cut
sub write_world_data
{
    my ($self) = @_;
    my $site = $self->{site} or die "no site";

    # Connect to the data server

    Data::Site->connect(host => $site->data_server()->{host});

    # Write the world stats data

    for (my $country_id = 0; $country_id < 255; $country_id++)
    {
        my $country = $self->{stats}[$country_id] or next;

        foreach my $report_id (REPORT_LIST)
        {
            my $data = $country->[$report_id];
            $self->write_country_data($country_id, $report_id, $data);
        }

        my ($code, $name) = Utils::Country->for_id($country_id);
        my $visits = $country->[Constants::Reports::TRAFFIC]{visits};
        $self->{log_file}->info("$code $name had $visits visits");
    }

    # Disconnect from the data srever

    Data::Site->disconnect();
}

=item write_country_data($country_id, $report_id, $hash_ref)

Write a stats report to the world stats database for a country

=cut
sub write_country_data
{
    my ($self, $country_id, $report_id, $hash_ref) = @_;
    my $database = "stats" . WORLD;
    my $date = $self->{date} or die "no date";
    die "need report id and date" unless $report_id && $date;

    Data::Site->sql("delete from $database.Stats where the_date = ? and channel_id = ? and report_id = ? and web_server = ?", $date, $country_id, $report_id, $ENV{HOSTNAME});

    # Write the stats

    my $sql = "insert into $database.Stats (the_date, channel_id, report_id, field, value, web_server) values (?, ?, ?, ?, ?, ?)";
    my $count = 0;
    my $limit = Data::SiteConfig->find($self->{config}, 'limit', $country_id, $report_id) || DEFAULT_LIMIT;
    my %others = ();
    foreach my $field (sort {$hash_ref->{$b} <=> $hash_ref->{$a}} keys %{$hash_ref})
    {
        my $value = $hash_ref->{$field};
        if ($count++ <= $limit)
        {
            next if $field =~ /\\/;
            Data::Site->sql($sql, $date, $country_id, $report_id, $field, int($value), $ENV{HOSTNAME});
        }
        else
        {
            $others{others} += $value;
        }
    }

    # Write the "others"

    while (my ($field, $value) = each(%others))
    {
        Data::Site->sql($sql, $date, $country_id, $report_id, $field, $value, $ENV{HOSTNAME});
    }
}

=item found_file($directory, $filename)

Parse an Apache log file to extract world stats data

=cut
sub found_file
{
    my ($self, $directory, $filename) = @_;

    # Does the file contain data about the date?

    my $time = $1 if $filename =~ /\.(\d+)$/;
    return if $time < $self->{start_time} || $time > $self->{end_time};

    # Read the file

    my $fh = FileHandle->new("$directory/$filename", 'r');
    while (my $line = $fh->getline())
    {
        if ($line =~ s/^event://)
        {
            $self->input($line);
        }
    }
}

=item input($line)

Parse a line of Apache log file data into world stats data

=cut
sub input
{
    my ($self, $line) = @_;

    # Read the line as a hash

    my %fields;
    map {$fields{$1} = $2 if /^(\w{2})=(.*)/} (split /\|/, $line);

    # Only measure visits, not page views

    return unless $fields{ua};

    # Extract the world stats

    my ($browser, $op_sys) = $self->{transforms}->computer($fields{ua}, $fields{os});
    my $java = $fields{ja} || '';
    my $javascript = $fields{js} || '';
    my $clock_time = $fields{ct} || '';
    my $color_bits = $fields{cb} || '';
    my $resolution = $fields{sr} || '';
    my $host_ip = $fields{ip};
    my $language = $fields{la} || '';
    my $hour = ($clock_time =~ /^(\d+):/ ? $1 : 0);
    my $time = $fields{tm}; # event time for time zones
    my $geo = $self->{transforms}->geo($host_ip, $language, $hour, $time);
    my $country = $geo->{country} || '';
    my $city = $geo->{city} || '';
    my $is_spider = $self->{transforms}->is_spider($browser);
    my $location = "$city, $country";

    # Update the world stats

    my $country_id = Utils::Country->id($country) || 0;
    my $stats = $self->{stats}[$country_id] ||= [];
    $stats->[Constants::Reports::BROWSER]{$browser}++ if $browser;
    if ($is_spider)
    {
        $stats->[Constants::Reports::SPIDER]{$browser}++;
        $stats->[Constants::Reports::TRAFFIC]{spider_visits}++;
        return; # don't measure spiders
    }
    $stats->[Constants::Reports::COUNTRY]{$country}++ if $country;
    $stats->[Constants::Reports::LANGUAGE]{$language}++ if $language;
    $stats->[Constants::Reports::TIME_ZONE]{$geo->{time_zone}}++ if $geo->{time_zone};
    $stats->[Constants::Reports::COLOR_BITS]{$color_bits}++ if $color_bits;
    $stats->[Constants::Reports::RESOLUTION]{$resolution}++ if $resolution;
    $stats->[Constants::Reports::OP_SYS]{$op_sys}++ if $op_sys;
    $fields{re} =~ s#^\w+://##;
    my ($referrer, $search) = $self->{transforms}->referrer($fields{re}, $geo->{language});
    $stats->[Constants::Reports::REFERRER_SEARCH]{$referrer}++ if $search;
    $stats->[Constants::Reports::HOUR_OF_DAY_VISITS]{$hour}++ if $hour;
    $stats->[Constants::Reports::LOCATION]{$location}++ if $location;
    $stats->[Constants::Reports::TRAFFIC]{referrer_visits}++ if $referrer;
    $stats->[Constants::Reports::TRAFFIC]{search_visits}++ if $search;
    $stats->[Constants::Reports::TRAFFIC]{visits}++;
    $stats->[Constants::Reports::TRAFFIC]{java}++ if $java eq 'yes';
    $stats->[Constants::Reports::TRAFFIC]{javascript}++ if $javascript eq 'yes';
}

=item DESTROY

Log the death of the object

=cut
sub DESTROY
{
    my ($self) = @_;
    $self->{log_file}->alert("Destroyed");
}

}1;

=back

=head1 DEPENDENCIES

Server::FileFinder, Constants::Reports, FileHandle, Utils::Transforms, Utils::Country, Utils::Time, Data::Site, Data::SiteConfig, Utils::LogFile

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
