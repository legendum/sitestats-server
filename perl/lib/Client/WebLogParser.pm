#!/usr/bin/env perl

=head1 NAME

Client::WebLogParser - parse Apache logs into custom files ready for extraction

=head1 VERSION

This document refers to version 1.0 of Client::WebLogParser, released Jul 07, 2015

=head1 DESCRIPTION

Client::WebLogParser parses Apache logs into custom files ready for extraction.

=head2 Properties

=over 4

None

=back

=cut
package Client::WebLogParser;
$VERSION = "1.0";

use strict;
use Data::Site;
use Utils::Time;
use Socket;
{
    # Class static properties

    #Fields: date time c-ip cs-username s-ip s-port cs-method cs-uri-stem cs-uri-query sc-status sc-bytes cs-bytes cs(User-Agent) cs(Referer) 
    my $_Pat_ip_address = qr/(\d{1,3} \.
    \d{1,3} \.
    \d{1,3} \.
    \d{1,3})/x;

    my $_Pat_quoted_field = qr/"((?:(?:(?:(?:   # It can be...
    [^"\\])* |          # ...zero or more characters not quote or backslash...
    (?:\\x[0-9a-fA-F][0-9a-fA-F])* | # ...a backslash quoted hex character...
    (?:\\.*)                         # ...or a backslash escape.
    ))*))"/x;

    my $_Parse_combined = qr/^  # Start at the beginning
    $_Pat_ip_address \s+        # IP address
    (\S+) \s+                   # Ident
    (\S+) \s+                   # Userid
    \[([^\]]*)\] \s+            # Date and time
    $_Pat_quoted_field \s+      # Request
    (\d+) \s+                   # Status
    (\-|[\d]+) \s+              # Length of reply or "-"
    $_Pat_quoted_field \s+      # Referer
    $_Pat_quoted_field          # User agent
    /x;

=head2 Class Methods

=over 4

=item new($site_id)

Create a new Client::WebLogParser object for a particular site ID

=cut
sub new
{
    my ($class, $site_id) = @_;
    Data::Site->connect();
    my $site = Data::Site->row($site_id);
    $site->{site_id} or die "site for ID $site_id not found";
    Data::Site->disconnect();

    my $self = {
        site => $site
    };
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item parse()

Parse a web server log file

=cut
sub parse
{
    my ($self) = @_;

    # Store host details

    my %host_ips = ();
    my %host_ids = ();
    my $sequence = 0;

    # Get the site's ID and URL

    my $site_id = $self->{site}{site_id};
    my $url = $self->{site}{url};
    $url = "http://$url" unless $url =~ /^http/;

    # Parse the log file

    while (<>)
    {
        next unless /$_Parse_combined/;
        my $host_ip = $1;
        my $date = $4;
        my $page = $5;
        my $status = $6;
        my $length = $7;
        my $referrer = $8 || '';
        my $user_agent = $9;
        $page =~ s/^GET\s+//;
        $page =~ s/\s+HTTP.*$//;
        $page = "$url$page" unless $page =~ /^(http|file)/;;
        $referrer = '' if $referrer eq '-';

        # Check the URL

        next if $page =~ /\.(gif|jpg|jpeg|bmp|xpm|css|js)$/i;

        # Get the time from a log date in format "20/Apr/2007:00:12:33 +0100"

        my $time = '';
        if ($date =~ m#(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+)\s+([+-]\d{2})#)
        {
            my ($mday, $mname, $year, $hour, $mins, $secs, $zone) = ($1, $2, $3, $4, $5, $6, $7);
            my $yyyymmdd = sprintf("%04d%02d%02d", $year, Utils::Time->get_month_number($mname), $mday);
            my $hh_mm_ss = sprintf("%02d:%02d:%02d", $hour, $mins, $secs);
            $zone =~ s/([+-])0/$1/; # remove Octal leading zero
            $time = Utils::Time->get_time($yyyymmdd, $hh_mm_ss, $zone);
        }

        # Get the host IP

        $host_ip = '0.0.0.0' if $host_ip eq '-';
        if ($host_ip !~ /^[\d\.]+$/)
        {
            if (!$host_ips{$host_ip})
            {
                my $host = $host_ip;
                my $addr = gethostbyname($host_ip);
                $host_ips{$host} = inet_ntoa($addr) if $addr;
                $host_ips{$host} ||= '0.0.0.0';
            }

            $host_ip = $host_ips{$host_ip};
        }

        # Get the visit ID

        my $visit_id;
        my $append = '';
        if ($visit_id = $host_ids{$host_ip})
        {
            # Great we found it
        }
        else
        {
            $host_ids{$host_ip} = $visit_id = sprintf("%10d%06d", $time, $sequence++);
            $append = "|fl=yes|ua=$user_agent";
        }

        # Write the stats in our custom format

        print "event:si=$site_id|ip=$host_ip|tm=$time|en=$page|vi=$visit_id|re=$referrer$append\n";
    } # end while
}

}1;

=back

=head1 DEPENDENCIES

Data::Site, Utils::Time, Socket

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
