#!/usr/bin/env perl 

=head1 NAME

Client::Navigation - Write web page navigation data as CSV, XML, HTML or JSON

=head1 VERSION

This document refers to version 2.1 of Client::Navigation, released Jul 07, 2015

=head1 DESCRIPTION

Client::Navigation writes web page navigation data as CSV, XML, HTML and JSON.

=head2 Properties

=over 4

None

=back

=cut
package Client::Navigation;
$VERSION = "2.1";

use strict;
use base 'Client::API';
use Client::Reporter;
use Data::Page;
use Utils::Time;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Client::Navigation object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item generate( hosts => $hosts, users => $users, start_date => $start_date, end_date => $end_date, include => $include, exclude => $exclude )

Generate a page report from web site activity data

=cut
sub generate
{
    my ($self, %args) = @_;

    # Prepare an empty page report

    my $reports = {};

    # Get a page report for the particular page

    $self->get_navigation_report( reports => $reports,
                                  hosts => $args{hosts},
                                  users => $args{users},
                                  page => $args{page},
                                  include => $args{include},
                                  exclude => $args{exclude},
                                  start_date => $args{start_date},
                                  end_date => $args{start_date} );

    # Return the page reports

    return $self->format_reports($reports);
}

=item get_navigation_report(%args)

Get a navigation report, optionally for a particular web page

=cut
sub get_navigation_report
{
    my ($self, %args) = @_;
    my $site = $self->site() or die "no site";
    my $reports = $args{reports} or die "no reports";
    my $start_date = $args{start_date};
    my $end_date = $args{end_date};
    my $hosts = $args{hosts};
    my $users = $args{users};
    my $through = $args{page};
    my $include = $args{include};
    my $exclude = $args{exclude};

    # Get the start and end times from normalized dates

    $start_date = Utils::Time->normalize_date($start_date, $site->{time_zone});
    $end_date = Utils::Time->normalize_date($end_date, $site->{time_zone});
    my ($start_time, $end_time) = Utils::Time->get_start_and_end_times($start_date, $end_date, $site->{time_zone});

    # Setup the reports data structure

    $reports->{site} ||= { id => $site->{site_id}, url => $site->{url}, time_zone => $site->{time_zone} };

    # Connect to the site's main data server

    my $data_server = $site->data_server();
    my $dbh = $data_server->connect();
    my $database = 'stats' . $site->{site_id};
    Data::Page->connect(host => $data_server->{host}, database => $database);

    # Get hit, visit and user count report data

    my $host_clause = $self->host_clause($site, $hosts, 'V');
    my $user_clause = $self->user_clause($users, 'E');
    my $sql = "select E.* from $database.Event E, $database.Visit V where E.time between ? and ? and E.type_id = 0 and E.visit_id = V.visit_id $user_clause $host_clause";
    $sql .= $self->user_clause($users);
    $sql .= ' order by visit_id, time';
    my $query = $dbh->prepare($sql);
    $query->execute($start_time, $end_time);
    my %navs = ();
    my %page_cache = ();
    my $last_title = '';
    my $last_url = '';
    my $last_visit_id = 0;
    while (my $row = $query->fetchrow_hashref())
    {
        my $visit_id = $row->{visit_id};
        my ($url, $query) = split /\?/, $row->{name};
        my $page = $page_cache{$url} ||= Data::Page->select('url = ?', $url);
        $url .= "?$query" if $query;
        my $visit_id = $row->{visit_id};
        my $user_id = $row->{user_id};

        if ($visit_id eq $last_visit_id)
        {
            if ($include && ($last_url !~ /$include/ && $url !~ /$include/)
            ||  $exclude && ($last_url =~ /$exclude/ || $url =~ /$exclude/)
            ||  $through && ($last_url ne  $through  && $url ne  $through))
            {
                # Don't measure this click
            }
            else
            {
                my $nav = "$last_url|$url";
                $navs{$nav}{clicks}++;
                $navs{$nav}{visits}{"$visit_id"} ||= 1;
                $navs{$nav}{users}{"$user_id"} ||= 1;
                $navs{$nav}{from_title} = $last_title if $last_title;
                $navs{$nav}{to_title} = $page->{title} if $page->{title};
            }
        }

        $last_title = $page->{title} || '';
        $last_url = $url;
        $last_visit_id = $visit_id;
    }

    # Turn the report data into a nicely formatted tree hierarchy

    my @nav_reports = ();
    while (my ($nav, $report) = each %navs)
    {
        my ($from, $to) = split /\|/, $nav;
        my @visits = keys %{$report->{visits}};
        my @users = keys %{$report->{users}};
        my $nav_report = { from_url => $from,
                           to_url => $to,
                           from_title => $report->{from_title},
                           to_title => $report->{to_title},
                           clicks => $report->{clicks}, 
                           visits => scalar @visits,
                           users => scalar @users, };
                           #visit_list => join(',', @visits),
                           #user_list => join(',', @users), };
        push @nav_reports, $nav_report;
    }

    # Disconnect from the data server

    $data_server->disconnect();
    Data::Page->disconnect();

    # Return the path list in and out

    $reports->{site}{report} = [
        {
            users => $users,
            page => $through,
            include => $include,
            exclude => $exclude,
            start_time => $start_time,
            end_time => $end_time,
            start_date => $start_date,
            end_date => $end_date,
            navigation => \@nav_reports,
            units => 'various',
        },
    ];

    # Return the reports as a hashref data structure with request stats

    $reports->{stats} ||= $self->api_stats();

    # Optionally add any debug info to the hash-ref

    $reports->{debug} = $ENV{DEBUG} if $ENV{DEBUG};
}

}1;

=back

=head1 DEPENDENCIES

Client::Reporter, Utils::Time

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
