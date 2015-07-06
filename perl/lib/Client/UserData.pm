#!/usr/bin/env perl 

=head1 NAME

Client::UserData - Insert "whois" data about web visitors into User data tables

=head1 VERSION

This document refers to version 1.0 of Client::UserData, released Jul 07, 2015

=head1 DESCRIPTION

Client::UserData inserts "whois" data about web visitors into User data tables.

=head2 Properties

=over 4

None

=back

=cut
package Client::UserData;
$VERSION = "1.0";

use strict;
use Data::Site;
use Data::SiteConfig;
use Data::WhoIs;
use Utils::Time;
use Utils::LogFile;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($site_id)

Create a new Client::UserData object to generate visit data for web users

=cut
sub new
{
    my ($class, $site_id) = @_;
    die "need the id of the site being reported" unless $site_id;

    my $self = {
        site_id     => $site_id,
        config      => [],
        visits      => [],
        date        => 0,
        site        => undef,
        dbh         => undef,
        optimize    => undef,
        visit_table => 'Visit',
        log_file    => Utils::LogFile->new("$ENV{LOGS_DIR}/userdata"),
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate($date)

Generate daily user data from raw web activity stored as visits

=cut
sub generate
{
    my ($self, $date) = @_;

    # Connect to the master database

    $self->{dbh} = Data::Site->connect();
    $self->{dbh}->do("set autocommit=0"); # for InnoDB
    Data::SiteConfig->connect();
    Data::WhoIs->connect();

    # Get the site details

    my $site_id = $self->{site_id};
    my $site = Data::Site->row($site_id);
    return if !$site->{status} || $site->{status} eq 'S';
    my $config = Data::SiteConfig->get($site_id);
    $self->{site} = $site;
    $self->{visits} = [];
    $self->{config} = $config;

    # Use today's date by default

    $date ||= 0;
    if ($date < 20000000)
    {
        my $time = time() - 86400 * $date; # $date is a number of days
        $date = Utils::Time->get_date($time, $site->{time_zone})
    }
    $self->{date} = $date;

    # Get the optimizer setting

    $self->{optimize} = lc Data::SiteConfig->find($config, 'optimize') eq 'yes';

    # Use rollover database tables

    my $rollover = lc Data::SiteConfig->find($config, 'rollover') eq 'yes';
    my $year_month = substr($date, 0, 6);
    my $today = Utils::Time->get_date();
    if ($rollover && $year_month != substr($today, 0, 6))
    {
        $self->{visit_table} .= $year_month;
    }

    # Collate daily site stats for the main data server

    Data::Site->disconnect();
    $self->{dbh} = Data::Site->connect(host => $site->data_server()->{host});
    eval
    {
        $self->read_visit_data();
        $self->write_user_data();
    };
    $self->{log_file}->error("Site $site_id error: $@") if $@;

    # Disconnect from the database

    Data::Site->disconnect();
    Data::SiteConfig->disconnect();
    Data::WhoIs->disconnect();
}

=item read_visit_data()

Read web visit details

=cut
sub read_visit_data
{
    my ($self) = @_;
    my $site = $self->{site} or die "no site";

    # Get the time range and database

    my ($start_time, $end_time) = Utils::Time->get_time_range($self->{date}, $site->{time_zone});
    my $database = "stats" . $self->{site_id};
    my $query = $self->{dbh}->prepare("select V.visit_id, V.user_id, V.global_id, V.host from $database.$self->{visit_table} V where V.visit_id between ? and ? order by V.visit_id", {'mysql_use_result' => $self->{optimize}});
    $query->execute("${start_time}000000", "${end_time}999999");
    while (my $visit = $query->fetchrow_hashref())
    {
        push @{$self->{visits}}, $visit if $visit->{host};
    }
}

=item write_user_data()

Write web user data

=cut
sub write_user_data
{
    my ($self) = @_;
    my $site_id = $self->{site_id};
    my $database = "stats" . $site_id;

    # Delete old web user records

    my $first_visit = @{$self->{visits}}[0];
    my $last_visit = @{$self->{visits}}[-1];
    Data::Site->sql("delete from $database.User where visit_id between ? and ? and field like 'whois_%'", $first_visit->{visit_id}, $last_visit->{visit_id});

    # Write new web user records

    my $sql = "insert into $database.User (visit_id, user_id, global_id, field, value) values (?, ?, ?, ?, ?)";
    foreach my $visit (@{$self->{visits}})
    {
        # Perform a "whois" lookup on the visit host

        my $who_is = Data::WhoIs->lookup($visit->{host});
        next unless $who_is->{who_is_id};

        # Insert "whois" details for the web user

        my $name = $who_is->name;
        Data::Site->sql($sql, $visit->{visit_id}, $visit->{user_id}, $visit->{global_id}, 'whois_name', $name) if $name;
        my $address = $who_is->address;
        Data::Site->sql($sql, $visit->{visit_id}, $visit->{user_id}, $visit->{global_id}, 'whois_address', $address) if $address;
        my $phone = $who_is->phone;
        Data::Site->sql($sql, $visit->{visit_id}, $visit->{user_id}, $visit->{global_id}, 'whois_phone', $phone) if $phone;
        my $email = $who_is->email;
        Data::Site->sql($sql, $visit->{visit_id}, $visit->{user_id}, $visit->{global_id}, 'whois_email', $email) if $email;
    }
}

}1;

=back

=head1 DEPENDENCIES

Data::Site, Data::SiteConfig, Data::WhoIs, Utils::Time, Utils::LogFile

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
