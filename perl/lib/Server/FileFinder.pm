#!/usr/bin/env perl

=head1 NAME

Server::FileFinder - Find files in a directory that match a pattern

=head1 VERSION

This document refers to version 1.2 of Server::FileFinder, released Jul 07, 2015

=head1 DESCRIPTION

Server::FileFinder finds files in directory that match a pattern.

=head2 Properties

=over 4

None

=back

=cut
package Server::FileFinder;
$VERSION = "1.2";

use strict;
{
    # Class static properties

    my $_PAUSE_SECS = 5; # How long to wait between directory scans

=head2 Class Methods

=over 4

=item new($directory, $pattern)

Create a new Server::FileFinder object that will search a directory for files
matching a pattern, such as *.txt for example.

=cut
sub new
{
    my ($class, $directory, $pattern) = @_;
    die "$directory is not a directory" unless -d $directory;

    my $self = {
        directory => $directory,
        pattern   => $pattern || '',
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item find_files($pause)

Find files in the directory that match the Server::FileFinder's pattern. Search
the directory for matching files every few seconds by default. Use a negative
value if you don't want an infinite polling loop, e.g. find_files(-1) to return.

=cut
sub find_files
{
    my ($self, $pause) = @_;
    $pause ||= $_PAUSE_SECS;

    # Search the directory for matching files

    my $directory = $self->{directory};
    while (1)
    {
        opendir (DIR, $directory);
        my @filenames = sort grep /$self->{pattern}/, readdir(DIR);
        closedir DIR;

        # Tell our subclass that we have found the files

        $self->begin_files($directory);
        my $total = length @filenames;
        my $count = 1;
        foreach my $filename (@filenames)
        {
            $self->found_file($directory, $filename, $count, $total);
            $count++;
        }
        $self->end_files($directory);

        last if $pause <= 0;
        sleep $pause;
    }
}

=item begin_files($directory)

This method may be overridden by subclasses

=cut
sub begin_files
{
    my ($self, $directory) = @_;
}

=item found_file($directory, $filename)

This method must be overridden by subclasses

=cut
sub found_file
{
    my ($self, $directory, $filename) = @_;

    die "found_file() called in superclass - should be overridden by subclass";
}

=item end_files($directory)

This method may be overridden by subclasses

=cut
sub end_files
{
    my ($self, $directory) = @_;
}

}1;

=back

=head1 DEPENDENCIES

None

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
