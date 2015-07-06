#!/usr/bin/env perl

=head1 NAME

Data::GridJob - Manages grid jobs to be run by the Server::GridEngine

=head1 VERSION

This document refers to version 1.0 of Data::GridJob, released Jul 07, 2015

=head1 DESCRIPTION

Data::GridJob manages the details for grid jobs to be run by Server::GridEngine.
Be sure to call the class static method connect() before using Data::GridJob
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item grid_job_id

The grid job ID

=item priority

The job priority

=item command

The command to run

=item result

The command result

=item submit_time

The time the job was submitted

=item start_time

The time the job was started

=item finish_time

The time the job was finished

=item comp_server

The server hosting the data

=item job_server

The server running the job

=item status

The status of the job

=back

=cut
package Data::GridJob;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
use Constants::General;
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
    $class->fields(qw(grid_job_id priority command result submit_time start_time finish_time comp_server job_server status));

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

=item submit(command => $command, priority => $priority, comp_server => $comp_server)

Submit a new grid job

=cut
sub submit
{
    my ($class, %args) = @_;

    # Default the job details

    $args{command} or die "no job command provided";
    $args{priority} ||= Constants::General::DEFAULT_JOB_PRIORITY;
    $args{submit_time} ||= time();
    $args{status} ||= 'A';

    # Submit the new grid job

    Data::GridJob->connect();
    my $grid_job = Data::GridJob->new(%args);
    $grid_job->insert();
    Data::GridJob->disconnect();

    return $grid_job;
}

=back

=head2 Object Methods

=over 4

=item None

=cut

}1;

=back

=head1 DEPENDENCIES

Data::Object, Constants::General

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
