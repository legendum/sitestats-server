#!/usr/bin/env perl

=head1 NAME

monitor.pl - Run test scripts to check that the system is working OK

=head1 DESCRIPTION

This program runs all test scripts in directory ~/monitor/scripts.
The tests should be small scripts that exit with value 0 upon success
and other codes upon failure. Any output to standard error is logged.

If any tests fail, a list of failed tests and an error log are both
emailed to all email addresses listed in the notify.txt file. If the
same tests fail again with the same error messages, then no email is
generated, since there is no point delivering identical emails.

This program should be run hourly to perform routine system tests.

=cut

use strict;

use Test;
use Sys::Hostname;

# Get the date

my $date_string = localtime();

# Get a list of test scripts

my $path = "$ENV{SERVER_HOME}/monitor";
my $script_path = "$path/scripts";
opendir (DIR, $script_path);
my @scripts = sort grep /^[^\.]/, readdir(DIR);
closedir DIR;

# Open logs for standard output and errors

my $log_path = "$path/logs";
my $stdout = "$log_path/stdout.txt";
my $stderr_new = "$log_path/stderr.new";
my $stderr = "$log_path/stderr.txt";
open (STDOUT, ">$stdout");
open (STDERR, ">$stderr_new");
print STDOUT "Tests started at " . localtime() . "\n";

# Run the monitor scripts

plan tests => scalar @scripts, onfail => \&fail;
foreach my $script (@scripts)
{
    my $cmd = "$script_path/$script";
    next unless -f $cmd;
    my $return_code = system($cmd) >> 8;
    ok($return_code, 0, $script);
}

# Close the logs

print STDOUT "Tests finished at " . localtime() . "\n";
close STDOUT;
close STDERR;

# END OF MAIN CODE

# Send a success message if an empty error file has been left over

if (-z $stderr_new && -f $stderr)
{
    unlink $stderr;
    my $subject = "Tests succeeded on " . hostname();
    my $message = "$subject on $date_string";
    notify($subject, $message);
}

# Upon failure, notify all email addresses in the notification list

sub fail
{
    my ($failures) = @_;
    return unless different_errors();

    # List the failed tests

    my $subject = "Tests failed on " . hostname();
    my $message = "$subject on $date_string\n\n";
    foreach my $failure (@{$failures})
    {
        $message .= "- $failure->{diagnostic}\n";
    }

    # Append the error log

    $message .= "\nError log:\n\n";
    open (LOG, $stderr);
    $message .= $_ while <LOG>;
    close LOG;

    # Append the test log

    $message .= "\nTest log:\n\n";
    open (LOG, $stdout);
    $message .= $_ while <LOG>;
    close LOG;

    # Notify all email addresses

    notify($subject, $message);
}

# Send emails to all addresses in the notification list

sub notify
{
    my ($subject, $message) = @_;
    open (EMAILS, "$path/notify.txt");
    my $email;
    while ($email = <EMAILS>)
    {
        next if $email =~ /^#/;     # ignore if commented out
        next unless $email =~ /\@/; # ignore unless valid address

        chomp $email;
        open (MAIL, "|mail -s '$subject' $email");
        print MAIL $message;
        close MAIL;
    }
    close EMAILS;
}

# Return whether two error files are different, replacing the old with the new

sub different_errors
{
    my $different = 0;
    if (-f $stderr)
    {
        open (DIFF, "diff $stderr_new $stderr|");
        my @diff = <DIFF>;
        close DIFF;
        $different = @diff > 0;
    }
    else
    {
        $different = 1;
    }

    rename $stderr_new, $stderr if $different;
    return $different;
}

1;
__END__

=head1 DEPENDENCIES

Test, Sys::Hostname

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
