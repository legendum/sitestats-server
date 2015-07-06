#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use Data::GridJob;

my $grid_job_id = shift || 0;
my $command = join ' ', @ARGV;
die "usage: $0 GRID_JOB_ID command" unless $grid_job_id > 0;
die "usage: $0 grid_job_id COMMAND" unless $command;

# Run the job to get the result

my $result = '';
my $status = '';
my $stderr = "/tmp/gridjob.$$";
eval {
    open (JOB, "$command 2>$stderr|");
    $result .= $_ while <JOB>;
    close JOB;
};

# Check for errors from the job

if (-s $stderr)
{
    open (ERROR, $stderr);
    $result .= $_ while <ERROR>;
    close ERROR;

    $status = 'E'; # ERROR
}
else
{
    $status = 'S'; # STOPPED
}
unlink $stderr;
chomp $result;

# Update the grid job's details

Data::GridJob->connect();
my $grid_job = Data::GridJob->row($grid_job_id);
$grid_job->{finish_time} = time();
$grid_job->{result} = $result;
$grid_job->{status} = $status;
$grid_job->update();
Data::GridJob->disconnect();

__END__

=head1 DEPENDENCIES

Data::GridJob

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
