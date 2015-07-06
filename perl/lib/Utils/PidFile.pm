#!/usr/bin/env perl

=head1 NAME

Utils::PidFile - Create and remove PID files for daemon processes

=head1 VERSION

This document refers to version 1.0 of Utils::PidFile, released Jul 07, 2015

=head1 DESCRIPTION

Utils::PidFile creates and removes PID files for daemon processes

=head2 Properties

=over 4

None

=back

=cut
package Utils::PidFile;
$VERSION = "1.0";

use strict;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new($pids_dir, [$filename])

Create a new PidFile object

=cut
sub new
{
    my ($class, $pids_dir, $filename) = @_;

    $filename ||= $0; $filename =~ s#.*/##; # cheap man's basename
    my $self = {
        filename => $filename,
        pid      => $$,
        pids_dir => $pids_dir,
    };
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item create()

Create a PID file and return true, or return false if the file already exists

=cut
sub create
{
    my ($self) = @_;

    my $pid_file = "$self->{pids_dir}/$self->{filename}.pid";
    return 0 if $self->valid($pid_file);
    open (PID_FILE, ">$pid_file");
    print PID_FILE "$self->{pid}\n";
    close PID_FILE;
    return 1;
}

=item remove()

Remove a PID file

=cut
sub remove
{
    my ($self) = @_;

    unlink "$self->{pids_dir}/$self->{filename}.pid";
}

=item valid($pid_file)

Check whether a PID file is valid or not

=cut
sub valid
{
    my ($self, $pid_file) = @_;

    if (-f $pid_file)
    {
        # What is the running PID?

        open (PID_FILE, $pid_file);
        my $pid = <PID_FILE>;
        chomp $pid;
        close PID_FILE;

        # Is it really still running?

        open (PS, "/bin/ps -e|");
        my @pid_list = <PS>;
        close PS;
        return 1 if grep /\b$pid\b/, @pid_list;

        # Not running so remove PID file

        unlink $pid_file; # not valid!
    }

    return 0; # no pid file
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
