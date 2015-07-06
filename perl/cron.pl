#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();

use Utils::Config;
use Utils::LogFile;

use constant TRUE   => 1;
use constant FALSE  => 0;

# Get the time right now

our ($SECS, $MINS, $HOURS, $DAY_OF_MONTH, $MONTH, $YEAR, $DAY_OF_WEEK, $DAY_OF_YEAR) = gmtime();
$YEAR += 1900;  # Turn year "110" into year "2010"
$DAY_OF_WEEK++; # Sunday is 1, Monday is 2, etc...

# Get the directory holding the cron jobs as Perl programs

my $cron_dir = "$ENV{CRON_DIR}";
die "no cron directory at $cron_dir" unless -d $cron_dir;

# Open the log file

my $log_file = Utils::LogFile->new("$ENV{LOGS_DIR}/cron");

# Parse the cron file

my $cron = Utils::Config->load('cron');
while (my ($prog, $data) = each %{$cron})
{
    $prog .= '.pl'; # they are Perl progs

    # Check the host, time and executable

    next unless this_host($data->{host});
    next unless its_time($data->{when});
    my $path = "$cron_dir/$prog";
    my $args = parse_args($data->{args});
    next unless -x $path;

    # Run the program and log its output

    $log_file->alert("Running $prog$args");
    $log_file->debug("Description: " . $data->{desc}) if $data->{desc};
    open (PROG,  "$path$args|");
    while (my $stdout = <PROG>)
    {
        chomp $stdout;
        $log_file->info($stdout)
    }
    close PROG;
    $log_file->alert("Finished $prog$args");
}

# Return a value as a simple scalar or a scalar comma list

sub scalarize
{
    my $value = shift;
    return ref($value) eq 'ARRAY' ? join ',', @{$value} : $value;
}

# Return whether we can find a string inside a value (list)

sub can_find
{
    my ($it, $value) = @_;
    return TRUE if $value eq 'all';
    return ",$value," =~ /,$it,/;
}

# Check to see if this host should be running the cron job

sub this_host
{
    my $host = shift or return TRUE;
    return can_find($ENV{HOSTNAME}, scalarize($host));
}

# Check to see if it's the right time to run the cron job

sub its_time
{
    my $when = shift or return TRUE;
    while (my ($measure, $value) = each %{$when})
    {
        next if ref $value eq 'SCALAR' && $value eq 'all';
        $measure = uc $measure;
        no strict;
        my $now = $$measure;
        use strict;
        return FALSE unless can_find($now, scalarize($value));
    }
    return TRUE;
}

# Parse any arguments to be passed into the cron job

sub parse_args
{
    my $args = shift;
    return '' unless $args;

    my $line = '';
    while (my ($arg, $value) = each %{$args})
    {
        $line .= " -$arg=" . scalarize($value);
    }
    return $line;
}

__END__

=head1 DEPENDENCIES

Utils::Config, Utils::LogFile

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
