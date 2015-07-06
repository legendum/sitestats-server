#!/usr/bin/env perl

=head1 NAME

Client::API::Cache - Read and write API data to a cache

=head1 VERSION

This document refers to version 1.0 of Client::API::Cache, released Jul 07, 2015

=head1 DESCRIPTION

Client::API::Cache reads and writes API data to a cache.

Here's how to use the API::Cache:

my $cache = Client::API::Cache->new($filename, $end_date, $site->{time_zone});
if ($cache->is_empty_or_stale())
{
    if ($cache->is_busy()) # being written by another process
    {
        sleep 1 while $cache->is_still_busy();
        return $cache->read();
    }

    my $data = $self->get_some_data();
    return $cache->write($data);
}
else # the cache isn't empty or stale
{
    return $cache->read();
}

...and that's about it!

=head2 Properties

=over 4

None

=back

=cut
package Client::API::Cache;
$VERSION = "1.0";

use strict;
use Constants::General;
use Utils::Time;
use FileHandle;
{
    # Class static properties and constants

    use constant STAT_MOD_TIME => 9;

=head2 Class Methods

=over 4

=item new($filename, $end_date, $time_zone, [$time])

Create a new Client::API::Cache object with a filename

=cut
sub new
{
    my ($class, $filename, $end_date, $time_zone, $time) = @_;
    die "no filename" unless $filename;
    die "no data dir" unless $ENV{DATA_DIR};

    # Compare today with the end date to see if the cache is stale

    $end_date = Utils::Time->normalize_date($end_date, $time_zone);
    $time_zone ||= 0;
    $time ||= time(); # for testing
    my $today = Utils::Time->get_date($time, $time_zone);
    my $is_today = ($end_date == $today);
    $filename .= '.part' if $is_today;

    # Create a subdirectory if necessary

    my $path = $ENV{CACHE_DIR} || "$ENV{DATA_DIR}/api";
    $path .= '/' unless $path =~ /\/$/;
    my @parts = split /\./, $filename;
    $path .= $parts[0] . '/' if $parts[0] ne $filename;
    unless (-d $path) {
        mkdir $path;
        chmod 0777, $path;
    }
    $path .= $filename;

    # Create the API::Cache object

    my $self = {
        path     => $path,
        is_today => $is_today,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item busy_path()

Return the path to the cache file while we're busy writing to it

=cut
sub busy_path
{
    my ($self) = @_;
    return $self->{path} . '.busy';
}

=item is_busy()

Return true if the cache file is being written by another process

=cut
sub is_busy
{
    my ($self) = @_;

    # Return true if it's busy now

    my $path = $self->busy_path();
    my $secs = time() - (stat($path))[STAT_MOD_TIME];
    return 1 if -f $path && $secs < Constants::General::CACHE_BUSY_WAIT_SECS;

    # Return false if we prepared the file

    my $fh = FileHandle->new($path, 'w');
    $fh->flush();
    $fh->close();
    return 0;
}

=item is_still_busy()

Return true if the cache file is still being written by another process

=cut
sub is_still_busy
{
    my ($self) = @_;

    # Return true if it's still busy

    my $path = $self->busy_path();
    return -f $path ? 1 : 0;
}

=item is_empty()

Return true if the cache file doesn't exist or it's empty

=cut
sub is_empty
{
    my ($self) = @_;
    my $path = $self->{path};
    return ! -f $path || -z $path || $ENV{DEBUG};
}

=item is_stale()

Return true if the cache file is stale because the end date is today
and the file was not recently modified.

=cut
sub is_stale
{
    my ($self) = @_;
    
    my $path = $self->{path};
    my $secs = time() - (stat($path))[STAT_MOD_TIME];
    return $self->{is_today} && $secs > Constants::General::CACHE_DURATION;
}

=item is_empty_or_stale()

Return true if the cache file is empty or stale.

=cut
sub is_empty_or_stale
{
    my ($self) = @_;
    return $self->is_empty() || $self->is_stale();
}

=item write($data)

Write data to the cache file

=cut
sub write
{
    my ($self, $data) = @_;

    # Open the cache file to write the data

    my $fh = FileHandle->new($self->busy_path(), 'w');
    die "no filehandle" unless $fh;

    # Write the data into the cache file

    $fh->print($data);
    $fh->flush();
    $fh->close();
    rename $self->busy_path(), $self->{path};
    return $data;
}

=item read()

Read data from the cache file

=cut
sub read
{
    my ($self) = @_;

    # Open the cache file to read the data

    my $fh = FileHandle->new($self->{path}, 'r');
    die "no filehandle" unless $fh;

    # Read and return the data in the cache

    my $data = join "\n", $fh->getlines();
    $fh->close();
    return $data;
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, FileHandle, Utils::Time

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
