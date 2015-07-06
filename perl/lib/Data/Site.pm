#!/usr/bin/env perl

=head1 NAME

Data::Site - Manages customer web site details

=head1 VERSION

This document refers to version 1.0 of Data::Site, released Jul 07, 2015

=head1 DESCRIPTION

Data::Site manages the details for all customer web sites (e.g. url, time zone).
Be sure to call the class static method connect() before using Data::Site
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item reseller_id

The web site reseller

=item url

The web site's URL

=item start_date

The date the site was first signed up

=item end_date

The end date for the site's subscription

=item product_code

The product code purchased - [L]ite, [P]rofessional or [C]ommerce

=item level_code

The level code purchased - [A] to [G]

=item country_code

The web site's country

=item status

The status of the site

=item daylight_saving

Daylight saving time (DST)? [Y]/[N]

=item time_zone

The web site's time zone

=item report_time

The last time a web site report was generated

=item commerce_pages

A list of commerce pages in the web site

=item host_ip_filter

Any host ip filter to apply to the web site's stats

=item host_filter

Any host filter to apply to the web site's stats

=item data_server

The host name of the data server for the site

=item comments

Any comments about the site

=back

=cut
package Data::Site;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
use Server::DataServer;
{
    # Class static properties

    my $_Connection;

=head2 Class Methods

=over 4

=item connect(driver=>'mysql', database=>'dbname', user=>'username', password=>'pass')

Initialise a connection to the database with optional details

=cut
sub connect
{
    my ($class, %args) = @_;
    return $_Connection if $_Connection;

    $args{host} ||= $ENV{MASTER_SERVER};
    eval {
        $_Connection = $class->SUPER::connect(%args);
    }; if ($@) {
        $args{host} = $ENV{BACKUP_SERVER};
        $_Connection = $class->SUPER::connect(%args);
    }
    $class->fields(qw(site_id reseller_id url start_date end_date product_code level_code country_code status daylight_saving time_zone report_time campaign_pages commerce_pages host_ip_filter host_filter comp_server data_server comments));

    return $_Connection;
}

=item disconnect()

Disconnect from the database cleanly

=cut
sub disconnect
{
    my ($class) = @_;
    return unless $_Connection;

    $_Connection = undef;
    $class->SUPER::disconnect();
}

=back

=head2 Object Methods

=over 4

=item filter_clause($table)

Return an SQL host and/or host IP filter clause

=cut
sub filter_clause
{
    my ($self, $table) = @_;
    $table = $table ? "$table." : '';

    my $clause = '';
    $clause .= $self->field_filter($table . 'host', $self->{host_filter});
    $clause .= $self->field_filter($table . 'host_ip', $self->{host_ip_filter});

    return $clause;
}

=item field_filter($field, $filter)

Return an SQL filter for a field

=cut
sub field_filter
{
    my ($self, $field, $filter) = @_;
    return '' unless $filter;

    # Get "in" and "like" clauses from the filter parts

    my @parts = split /,\s*/, $filter;
    my $in_clause = '';
    my $like_clause = '';
    foreach my $part (@parts)
    {
        next unless $part =~ /^[\w\.\-_\*]+$/;
        if ($part =~ s/\*/%/g)
        {
            $like_clause .= " and $field not like '$part'";
        }
        else
        {
            $in_clause .= "," if $in_clause;
            $in_clause .= "'$part'";
        }
    }

    # Put the "in" and "like" clauses together

    my $clause = '';
    $clause .= " and $field not in ($in_clause)" if $in_clause;
    $clause .= $like_clause;
    return $clause;
}

=item is_filtered($host, $host_ip)

Return whether a host/host_ip pair are filtered or not

=cut
sub is_filtered
{
    my ($self, $host, $host_ip) = @_;

    # Do some clever caching for some speed-ups

    my $cache = $self->{filtered_cache} ||= {}; 
    my $cache_key = "$host|$host_ip";
    my $cached = $cache->{$cache_key};
    return $cached if length($cached);

    # Get the host filter and host ip filter

    my $host_filter = $self->{host_filter};
    $host_filter =~ s/\*/\.\*/g; # as a regex
    my $host_ip_filter = $self->{host_ip_filter};
    $host_ip_filter =~ s/\*/\.\*/g; # as a regex

    # Check for host and host ip filtering

    my $is_filtered = 0;
    eval {
        my @host_filters = split /[,\s]+/, $host_filter;
        foreach $host_filter (@host_filters)
        {
            $is_filtered = 1 if $host eq $host_filter
                             or $host =~ /$host_filter/
        }

        my @host_ip_filters = split /[,\s]+/, $host_ip_filter;
        foreach $host_ip_filter (@host_ip_filters)
        {
            $is_filtered = 1 if $host_ip eq $host_ip_filter
                             or $host_ip =~ /$host_ip_filter/;
        }
    };

    # Update the cache to speed-up next time

    $cache->{$cache_key} = $is_filtered;
    return $is_filtered;
}

=item database()

Return the site's database name as "stats12345" where 12345 is the site ID

=cut
sub database
{
    my ($self) = @_;

    return 'stats' . $self->{site_id};
}

=item data_server()

Return the first data server registered for a site

=cut
sub data_server
{
    my ($self) = @_;

    # Return this site's data server if we've already found it earlier

    return $self->{data_server_object} if $self->{data_server_object};

    # Return the first data server in a list of data servers

    my @data_servers = split /[,\s]+/, $self->{data_server};
    $self->{data_server_object} = new Server::DataServer($data_servers[0]);
    return $self->{data_server_object};
}

=item is_daylight_saving()

Return whether this site has daylight saving time set to 'Y' for yes

=cut
sub is_daylight_saving
{
    my ($self) = @_;
    return $self->{daylight_saving} eq 'Y' ? 1 : 0;
}

=item time_zone_dst()

Return the time zone with daylight saving time taken into account

=cut
sub time_zone_dst
{
    my ($self) = @_;
    return $self->{time_zone} + $self->is_daylight_saving();
}

}1;

=back

=head1 DEPENDENCIES

Data::Object

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
