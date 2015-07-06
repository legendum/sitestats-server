#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Cache - Cache Sitester report data and web user traffic data

=head1 VERSION

This document refers to version 1.1 of Client::Sitester::Cache, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Cache caches Sitester report data and web user traffic data

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Cache;
$VERSION = "1.1";

use strict;
use base 'Client::API::Cache';
use Constants::General;
use FileHandle;
{
    my $_SEPARATOR = '|';

=head2 Class Methods

=over 4

=item new($filename, $end_date, $time_zone, [$time])

Create a new Client::Sitester::Cache object with a filename

=cut
sub new
{
    my ($class, $filename, $end_date, $time_zone, $time) = @_;
    $ENV{CACHE_DIR} = "$ENV{DATA_DIR}/sitester";
    my $self = $class->SUPER::new($filename, $end_date, $time_zone, $time);
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item write_keys_and_values($data_list)

Write keys and values to the cache file from an arrayref

=cut
sub write_keys_and_values
{
    my ($self, $data_list) = @_;

    my $fh = FileHandle->new($self->busy_path(), 'w');
    die "no filehandle" unless $fh;
    foreach my $pair (@{$data_list})
    {
        my $field = $self->xml_attr($pair->{field});
        my $value = $self->xml_attr($pair->{value});
        my $title = $self->xml_attr($pair->{title});
        $fh->print("$field$_SEPARATOR$value$_SEPARATOR$title\n");
    }
    $fh->flush();
    $fh->close();

    rename $self->busy_path(), $self->{path};
    chmod 0666, $self->{path};
}

=item read_keys_and_values($data_list, $include, $exclude)

Read keys and values from the cache file into an arrayref

=cut
sub read_keys_and_values
{
    my ($self, $data_list, $include, $exclude) = @_;

    my $fh = FileHandle->new($self->{path}, 'r');
    die "no filehandle" unless $fh;
    my $total = 0;
    while (my $line = $fh->getline())
    {
        chomp $line; # remove trailing newline
        my ($field, $value, $title) = split /\|/, $line;
        next if $include && $field !~ /$include/;
        next if $exclude && $field =~ /$exclude/;
        my $data = {field => $field, value => $value};
        $data->{title} = $title if $title;
        unshift @{$data_list}, $data;
        $total += $value if $value =~ /^\d+$/;
    }
    $fh->close();

    return $total;
}

=item xml_attr($text)

Parse some text so it can be included as an XML attribute

=cut
sub xml_attr
{
    my ($self, $text) = @_;
    my $replace = '\\' . $_SEPARATOR;
    $text =~ s/$replace//gs;
    $text =~ s/\r?\n//gs;
    $text =~ s/[]//g; # TODO: Filter more control characters here
    return $text;
}

=item write_traffic($traffic)

Write traffic to the cache file from an arrayref
Note that this code has been optimized for a particular set of visit keys

=cut
sub write_traffic
{
    my ($self, $traffic) = @_;

    my $fh = FileHandle->new($self->{path}, 'w');
    die "no filehandle" unless $fh;
    foreach my $v (@{$traffic})
    {
        $fh->print("$v->{ui}|$v->{vi}|$v->{ip}|$v->{ho}|$v->{os}|$v->{ua}|$v->{tz}|$v->{la}|$v->{co}|$v->{ci}|$v->{cb}|$v->{sr}|$v->{re}|$v->{se}|$v->{ch}|$v->{sq}\n");
    }
    $fh->flush();
    $fh->close();
}

=item read_traffic($traffic)

Read traffic data from the cache file into an araryref
Note that this code has been optimized for a particular set of visit keys

=cut
sub read_traffic
{
    my ($self, $traffic) = @_;

    my $fh = FileHandle->new($self->{path}, 'r');
    die "no filehandle" unless $fh;
    while (my $line = $fh->getline())
    {
        chomp $line; # remove trailing newline
        my ($ui, $vi, $ip, $ho, $os, $ua, $tz, $la, $co, $ci, $cb, $sr, $re, $se, $ch, @sq) = split /\|/, $line;
        unshift @{$traffic}, {
            ui => $ui, # user ID
            vi => $vi, # visit ID
            ip => $ip, # host ip
            ho => $ho, # host name
            os => $os, # op sys
            ua => $ua, # user agent
            tz => $tz, # user agent
            la => $la, # language
            co => $co, # country
            ci => $ci, # city
            cb => $cb, # color bigs
            sr => $sr, # screen resolution
            re => $re, # referrer
            se => $se, # search term
            ch => $ch, # channels of pages
            sq => join('|', @sq) # sequence of pages
        };
    }
    $fh->close();
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, FileHandle

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
