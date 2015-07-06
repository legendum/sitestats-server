#!/usr/bin/env perl

=head1 NAME

Utils::LogFile - Manage log files

=head1 VERSION

This document refers to version 1.3 of Utils::LogFile, released Jul 07, 2015

=head1 DESCRIPTION

Utils::LogFile manages log files.

=head2 Properties

=over 4

=item path

The path to a logging directory

=item level

The level of logging to write

=back

=cut
package Utils::LogFile;
$VERSION = "1.3";

use strict;
use FileHandle;
{
    use constant LOG_FILE_PERMS => 0660;

    # Logging levels are defined as class static methods:

    sub DEBUG {1};
    sub INFO {2};
    sub WARN {3};
    sub ERROR {4};
    sub ALERT {5};

=head2 Class Methods

=over 4

=item new($path [, $level])

Open a log file at a logging level

=cut
sub new
{
    my ($class, $path, $level) = @_;
    die "$path is not a valid path" unless -d $path;

    my $self = {
        path  => $path,
        level => $level || $ENV{LOGGING_LEVEL} || INFO,
        date  => 0,
        same  => 0,     # count the same lines
        prev  => '',    # keep the previous line
        fh    => undef,
    };

    bless $self, $class;
}

=item datetime()

Get the date and time

=cut
sub datetime
{
    my ($unused) = @_;

    my ($sec, $min, $hour, $day, $month, $year) = gmtime();
    my $date = sprintf("%04d%02d%02d", $year+1900, $month+1, $day);
    my $time = sprintf("%02d:%02d:%02d", $hour, $min, $sec);

    return ($date, $time);
}

=item level($level)

Get the level

=cut
sub level
{
    my ($unused, $level) = @_;
    die "no level" unless defined($level);

    return (qw(zero DEBUG INFO WARN ERROR ALERT))[$level];
}

=back

=head2 Object Methods

=over 4

=item write($line [, $level])

Write a line at an optional level (default is INFO)

=cut
sub write
{
    my ($self, $line, $level) = @_;
    return unless $line;

    # Check the log level

    $level ||= INFO;
    return unless $level >= $self->{level};

    # Get the date and time and open the log

    my ($date, $time) = $self->datetime();
    $level = $self->level($level);
    $self->open($date);

    # Write a log line unless it's the same

    $line = "$time [$$] $level $line\n";
    if ($line eq $self->{prev})
    {
        $self->{same}++; # don't repeat the same line
    }
    else # different so write it to the log
    {
        if ($self->{same} > 0) # say how many repeats
        {
            $self->{fh}->print("Last line repeated $self->{same} times\n") if $self->{fh};
            $self->{same} = 0;
        }
        $self->{fh}->print($line) if $self->{fh};
        $self->{prev} = $line;
    }
}

=item debug(@args)

Write a debug line

=cut
sub debug
{
    my ($self, @args) = @_;
    $self->write(join('', @args), DEBUG);
}

=item info(@args)

Write an info line

=cut
sub info
{
    my ($self, @args) = @_;
    $self->write(join('', @args), INFO);
}

=item warn(@args)

Write a warn line

=cut
sub warn
{
    my ($self, @args) = @_;
    $self->write(join('', @args), WARN);
}

=item error(@args)

Write an error line

=cut
sub error
{
    my ($self, @args) = @_;
    $self->write(join('', @args), ERROR);
}

=item alert(@args)

Write an alert line

=cut
sub alert
{
    my ($self, @args) = @_;
    $self->write(join('', @args), ALERT);
}

=item open($date)

Open a log file

=cut
sub open
{
    my ($self, $date) = @_;
    die "no date" unless $date;
    return if $self->{date} eq $date;

    $self->{fh}->close() if $self->{fh};
    $self->{fh} = FileHandle->new("$self->{path}/$date.txt", 'a', LOG_FILE_PERMS);
    $self->{fh}->autoflush(1);
    $self->{date} = $date;
}

=item close()

Close a log file

=cut
sub close
{
    my ($self) = @_;
    $self->{fh}->close() if $self->{fh};
    $self->{fh} = undef;
}

=item grep($pattern)

Grep a log file

=cut
sub grep
{
    my ($self, $pattern) = @_;
    die "no pattern" unless $pattern;

    my $fh = FileHandle->new("$self->{path}/$self->{date}.txt", 'r');
    my @lines = grep /$pattern/, $fh->getlines();
    $fh->close();

    return @lines;
}

=item DESTROY()

Close a log file

=cut
sub DESTROY
{
    my ($self) = @_;
    $self->close();
}

}1;

=back

=head1 DEPENDENCIES

FileHandle

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
