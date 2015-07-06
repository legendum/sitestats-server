#!/usr/bin/env perl

=head1 NAME

Utils::Time - Time and date utility functions

=head1 VERSION

This document refers to version 1.0 of Utils::Time, released Jul 07, 2015

=head1 DESCRIPTION

Utils::Time contains a variety of useful time and date utility functions.

=head2 Properties

=over 4

None

=back

=cut
package Utils::Time;
$VERSION = "1.0";

use strict;
use POSIX;
use Time::Local;
{
    # Class static properties

    # Parts of gmtime() array

    use constant SECS  => 0;
    use constant MINS  => 1;
    use constant HOUR  => 2;
    use constant MDAY  => 3;
    use constant MONTH => 4;
    use constant YEAR  => 5;
    use constant WDAY  => 6;
    use constant YDAY  => 7;

    # Multiples of time units

    use constant MIN_SECS  => 60;
    use constant HOUR_SECS => 3600;
    use constant DAY_SECS  => 86400;
    use constant WEEK_DAYS => 7;

    # get_day_of_week() gives

    use constant SUNDAY => 0;
    use constant MONDAY => 1;
    use constant TUESDAY => 2;
    use constant WEDNESDAY => 3;
    use constant THURSDAY => 4;
    use constant FRIDAY => 5;
    use constant SATURDAY => 6;

    my @_Months = qw(January February March April May June July August September October November December);
    my %_Lookup = (jan=>1, feb=>2, mar=>3, apr=>4, may=>5, jun=>6, jul=>7, aug=>8, sep=>9, oct=>10, nov=>11, dec=>12);

=head2 Class Methods

=over 4

=item get_time($date, $hh_mm_ss, $time_zone)

Get the epoch time from a date (YYYYMMDD), time (HH:MM:SS) and time zone

=cut
sub get_time
{
    my ($class, $date, $hh_mm_ss, $time_zone) = @_;
    die "no date (YYYYMMDD)" unless $date;
    die "no time (HH:MM:SS)" unless $hh_mm_ss;
    $time_zone ||= 0;
    my ($year, $month, $mday) = ($1, $2, $3) if $date =~ /(....)(..)(..)/;
    my ($hour, $mins, $secs)  = ($1, $2, $3) if $hh_mm_ss =~ /(..):(..):(..)/;

    my $time = timegm(0, 0, 0, $mday, $month-1, $year-1900);
    $time += HOUR_SECS * ($hour - $time_zone) + MIN_SECS * $mins + $secs;

    return $time;
}

=item get_time_range($date, $time_zone)

Get the epoch time range from a date (YYYYMMDD) and time zone

=cut
sub get_time_range
{
    my ($class, $date, $time_zone) = @_;
    die "no date (YYYYMMDD)" unless $date;
    $time_zone ||= 0;
    my ($year, $month, $mday) = ($1, $2, $3) if $date =~ /(....)(..)(..)/;

    my $time = timegm(0, 0, 0, $mday, $month-1, $year-1900);
    my $start_time = $time - HOUR_SECS * $time_zone;
    my $end_time = $start_time + DAY_SECS;

    return ($start_time, $end_time);
}

=item get_start_and_end_times($start_date, $end_date, $time_zone)

Get the start and end times for a start date and end date, given a time zone

=cut
sub get_start_and_end_times
{
    my ($class, $start_date, $end_date, $time_zone) = @_;
    $time_zone ||= 0;
    my ($start_time, $blank1) = $class->get_time_range($start_date, $time_zone);
    my ($blank2, $end_time) = $class->get_time_range($end_date, $time_zone);
    return ($start_time, $end_time);
}

=item get_date($time, $time_zone)

Get the date (YYYYMMDD) for an epoch time and time zone

=cut
sub get_date
{
    my ($class, $time, $time_zone) = @_;
    $time ||= time();
    $time_zone ||= 0;

    # Add the time zone and return the data as YYYYMMDD

    $time += HOUR_SECS * $time_zone;
    my ($mday, $month, $year) = (gmtime($time))[MDAY, MONTH, YEAR];
    return sprintf("%04d%02d%02d", $year + 1900, $month + 1, $mday);
}

=item get_date_time($time, $time_zone)

Get the date and time (YYYYMMDD HH:MM:SS) for an epoch time and time zone

=cut
sub get_date_time
{
    my ($class, $time, $time_zone) = @_;
    $time ||= time();
    $time_zone ||= 0;

    # Add the time zone and return the data as YYYYMMDD

    $time += HOUR_SECS * $time_zone;
    my ($mday, $month, $year, $hour, $mins, $secs) = (gmtime($time))[MDAY, MONTH, YEAR, HOUR, MINS, SECS];
    return sprintf("%04d%02d%02d %02d:%02d:%02d", $year + 1900, $month + 1, $mday, $hour, $mins, $secs);
}

=item get_days_ago($date)

Get the number of days ago for a date

=cut
sub get_days_ago
{
    my ($class, $date) = @_;
    die "no date" unless $date;

    my $todays_date = $class->get_date();
    my ($today_start, $today_end) = $class->get_time_range($todays_date);
    my $date_start = $class->get_time($date, '00:00:00');
    return ($today_start - $date_start) / DAY_SECS;
}

=item get_date_range($period, $days_ago, $time_zone, [$time])

Get the date range and name for a period (week or month) a number of days ago

=cut
sub get_date_range
{
    my ($class, $period, $days_ago, $time_zone, $time) = @_;
    die 'bad period' unless $period eq 'week' or $period eq 'month';
    $days_ago  ||= 1;
    $time_zone ||= 0;
    $time ||= time(); # for testing
    $time -= $days_ago*DAY_SECS;
    $time += $time_zone*HOUR_SECS;

    my $start_date;
    my $end_date;
    my $period_name;
    if ($period eq 'week')
    {
        my ($year, $month, $mday) = (gmtime($time - 6*DAY_SECS))[YEAR, MONTH, MDAY];
        $start_date = sprintf("%04d%02d%02d", $year+1900, $month+1, $mday);
        ($year, $month, $mday) = (gmtime($time))[YEAR, MONTH, MDAY];
        $end_date = sprintf("%04d%02d%02d", $year+1900, $month+1, $mday);
        $period_name = 'Weekly';
    }
    elsif ($period eq 'month')
    {
        my ($year, $month, $mday) = (gmtime($time))[YEAR, MONTH, MDAY];
        $end_date = sprintf("%04d%02d%02d", $year+1900, $month+1, $mday);
        $start_date = substr($end_date, 0, 6) . '01';
        $period_name = $_Months[$month];
    }

    return ($start_date, $end_date, $period_name);
}

=item get_month_name($mm)

Get the month name for a month number (e.g. month number 1 is January)

=cut
sub get_month_name
{
    my ($class, $mm) = @_;
    die "bad month number $mm" unless $mm >= 1 && $mm <= 12;
    return $_Months[$mm-1];
}

=item get_month_number($month)

Get the month number for a month name (e.g. January is month number 1)

=cut
sub get_month_number
{
    my ($class, $month) = @_;
    die "bad month name $month" unless $month =~ /^\w+$/;
    my $mon = substr(lc($month), 0, 3);
    return $_Lookup{$mon};
}

=item get_part_of_day($time_zone, [$time])

Get the part of the day that has passed already as a decimal number

=cut
sub get_part_of_day
{
    my ($class, $time_zone, $time) = @_;
    $time ||= time(); # for testing
    my $date = $class->get_date($time, $time_zone);
    my ($start_time, $end_time) = $class->get_time_range($date, $time_zone);
    return sprintf("%04.4f", ($time - $start_time) / DAY_SECS);
}

=item get_day_of_week($yyyymmdd)

Get the day of the week from a date in YYYYMMDD format

=cut
sub get_day_of_week
{
    my ($class, $date) = @_;
    my $time = $class->get_time($date, '00:00:00');
    return (gmtime($time))[WDAY];
}

=item get_day_of_year($yyyymmdd)

Get the day of the year from a date in YYYYMMDD format

=cut
sub get_day_of_year
{
    my ($class, $date) = @_;
    my $time = $class->get_time($date, '00:00:00');
    return (gmtime($time))[YDAY];
}

=item get_week_of_year($yyyymmdd)

Get the week of the year from a date in YYYYMMDD format

=cut
sub get_week_of_year
{
    my ($class, $date) = @_;
    my $time = $class->get_time($date, '00:00:00');
    return POSIX::strftime("%V", gmtime($time));
}

=item normalize_date($date, [$time_zone])

Normalize a date that's a small number of "days ago"

=cut
sub normalize_date
{
    my ($class, $date, $time_zone) = @_;
    $date ||= 0;
    $date =~ s/-//g; # to remove any dashes in "2010-01-23"
    if ($date < 20000000)
    {
        $time_zone += 0;
        $date = $class->get_date(time() - $date * DAY_SECS, $time_zone);
    }
    return $date;
}

}1;

=back

=head1 DEPENDENCIES

Time::Local

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
