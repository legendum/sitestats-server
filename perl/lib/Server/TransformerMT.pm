#!/usr/bin/env perl

=head1 NAME

Server::TransformerMT - Tranform web activity files then load into data servers
                        This version is threaded using Perl compiled-in support

=head1 VERSION

This document refers to version 3.0 of Server::TransformerMT released Jul 07, 2015

=head1 DESCRIPTION

Server::TransformerMT transforms web activity files then loads into data servers
This subclass of Server::Transformer uses Perl threads for all hostname lookups.

=head2 Properties

=over 4

None

=back

=cut
package Server::TransformerMT;
$VERSION = "3.0";

use strict; use threads;
use Thread::Queue;
use Thread::Semaphore;
use IO::Socket;
use base 'Server::Transformer';
{
    # Class static properties

    use constant MAX_QUEUED_LINES => 100; # lines
    use constant MAX_THREAD_COUNT =>  20; # threads
    use constant DEQUEUE_WAIT_SECS =>  4; # secs

    # Global variables

    my $_Queue = Thread::Queue->new;

=head2 Class Methods

=over 4

=item new($source_dir)

Create a new Server::Transformer object

=cut
sub new
{
    my ($class, $source_dir) = @_;

    # Create a new Server::TransformerMT object

    my $self = $class->SUPER::new($source_dir);
    bless $self, $class;

    # Create semaphores for multi-threaded synchronization

    $self->{geoip_semaphore} = new Thread::Semaphore;

    # Start some threads to lookup hostnames, parse and load data

    for (my $thread = 0; $thread < MAX_THREAD_COUNT; $thread++)
    {
        threads->create(\&line_parser_thread, $self);
    }

    return $self;
}

=item line_parser_thread()

A line parser thread does the following:
1) Adds the hostname to a queued input line by doing a lookup on the IP address
2) Loads the data into a data server

=cut
sub line_parser_thread
{
    my ($self) = @_;

    while (my $line = $_Queue->dequeue())
    {
        eval
        {
            # Get the host IP if the line has complete visit data (with [fl]ash)

            if ($line =~ /\|fl=/ && $line =~ /\|ip=([\d\.]+)/)
            {
                my $host_ip = $1;

                # Lookup the host

                my $host = '';
                my $addr = inet_aton($host_ip);
                $host = (gethostbyaddr($addr, 2))[0] || '' if $addr;

                # Add the host to the line

                $line = "ho=$host$line";
            }

            # Parse the line and load it into a data server

            $self->parse($line);
        };
        $self->{log_file}->error("Parse error: $@") if $@;
    }
}

=back

=head2 Object Methods

=over 4

=item found_file($directory, $filename)

Read a web activity file

=cut
sub found_file
{
    my ($self, $directory, $filename) = @_;

    # Don't read more lines if we have too many pending

    my $queued = $_Queue->pending();
    if ($queued >= MAX_QUEUED_LINES)
    {
        $self->{log_file}->warn("$queued lines pending");
        for (my $i = 1; $i < 10; $i++)
        {
            sleep DEQUEUE_WAIT_SECS if $queued >= MAX_QUEUED_LINES * $i;
        }
    }

    # Read the web activity file

    $self->{log_file}->info("Reading $filename");
    my $fh = FileHandle->new("$directory/$filename", 'r');
    while (my $line = $fh->getline())
    {
        if ($line =~ s/^event:/\|/)
        {
            # Add the line to the queue of lines to be parsed and loaded

            $_Queue->enqueue($line);
        }
    }

    # Delete the web activity file

    unlink "$directory/$filename";
}

=item end_files($directory)

All extracted files have been read

=cut
sub end_files
{
    my ($self, $directory) = @_;

    # Start new threads if any of them died

    my $threads = scalar threads->list;
    while ($threads++ < MAX_THREAD_COUNT)
    {
        $self->{log_file}->alert("Starting thread");
        threads->create(\&line_parser_thread, $self);
    }

    # Disconnect and log the parsing results

    $self->SUPER::end_files($directory);
}

}1;

=back

=head1 DEPENDENCIES

Thread::Queue, Thread::Semaphore, IO::Socket, Server::Transformer

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
