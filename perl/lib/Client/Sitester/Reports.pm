#!/usr/bin/env perl

=head1 NAME

Client::Sitester::Reports - Generate, cache and return Sitester report data

=head1 VERSION

This document refers to version 1.1 of Client::Sitester::Reports, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Reports generates, caches and returns Sitester report data

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Reports;
$VERSION = "1.1";

use strict;
use Constants::General;
use Constants::Reports;
use Client::Sitester::ReportFilters; # to filter me
use Client::Sitester::Cache; # to cache report data
use Data::Page; # to add page titles to report data
use Data::SiteConfig; # to read site config details
use Data::SiteChannel; # to add SQL channel clauses
use Digest::MD5 qw(md5_hex); # for cache signatures
{
    # Don't let the reports get too long

    my $_DEFAULT_LIMIT = 500;
    my $_DEFAULT_ORDER = 'values';

    # Distinct reports (i.e. those reports measured for a single channel only)

    my %_Is_distinct = (
        Constants::Reports::PAGE => 1,
        Constants::Reports::DIRECTORY => 1,
        Constants::Reports::PAGE_NAVIGATION => 1,
        Constants::Reports::PAGE_DURATION => 1,
        Constants::Reports::REFERRER_HITS => 1,
        Constants::Reports::MAIL => 1,
        Constants::Reports::LINK => 1,
        Constants::Reports::FILE => 1,
    );

    # Reports with page titles

    my %_Has_page_titles = (
        Constants::Reports::PAGE => 1,
        Constants::Reports::BOUNCE_PAGE => 1,
        Constants::Reports::ENTRY_PAGE => 1,
        Constants::Reports::EXIT_PAGE => 1,
        Constants::Reports::PAGE_VISITS => 1,
        Constants::Reports::PAGE_DURATION => 1,
        Constants::Reports::PAGE_NAVIGATION => 1,
        Constants::Reports::COMMERCE_ENTRY_PAGE => 1,
        Constants::Reports::CAMPAIGN_ENTRY_PAGE => 1,
    );

    # Reports with measurement units other the default 

    my $_DEFAULT_UNITS = 'visits';
    my %_Report_units = (
        Constants::Reports::TRAFFIC => 'various',
        Constants::Reports::RANGE => 'date/time',
        Constants::Reports::RECENCY => 'users',
        Constants::Reports::FREQUENCY => 'users',
        Constants::Reports::PAGE => 'views',
        Constants::Reports::DIRECTORY => 'views',
        Constants::Reports::PAGE_NAVIGATION => 'clicks',
        Constants::Reports::PAGE_DURATION => 'seconds',
        Constants::Reports::REFERRER_HITS => 'views',
        Constants::Reports::MAIL => 'views',
        Constants::Reports::LINK => 'clicks',
        Constants::Reports::SITE_SEARCH_PHRASE => 'searches',
        Constants::Reports::SITE_SEARCH_WORD => 'searches',
    );

    # Cache filters (subs that take a hashref as a single argument)

    my %_Cache_filters = (
        Constants::Reports::FILE =>
            sub { my ($self, $stats) = @_;
                my $filtered = {};
                foreach my $key (keys %{$stats})
                {
                    # Filter locally saved web pages from the report
                    next if $key =~ m#^///#;

                    # Copy the stats array
                    $filtered->{$key} = $stats->{$key};
                }
                return $filtered;
            },

        Constants::Reports::VISIT_DURATION =>
            sub { my ($self, $stats) = @_;
                my $filtered = {};
                foreach my $key (keys %{$stats})
                {
                    my $filter_key = (int($key) > 30 ? '30' : $key);

                    # Copy the stats array
                    $filtered->{$filter_key} ||= 0;
                    $filtered->{$filter_key} += $stats->{$key};
                }
                return $filtered;
            },
    );

=head2 Class Methods

=over 4

=item new(site => $site, data => $data, [hosts => $hosts], [users => $users], [visits => $visits], [include => $include], [exclude => $exclude])

Create a new Client::Sitester::Reports object with an optional user ID list

=cut
sub new
{
    my ($class, %args) = @_;
    my $site = $args{site} or die "no site";
    my $data = $args{data} or die "no data";
    my $limit = $args{limit} || $_DEFAULT_LIMIT;
    my $order = $args{order} || $_DEFAULT_ORDER;
    my $hosts = $args{hosts}; # optional list of host IPs
    my $users = $args{users}; # optional list of user IDs
    my $visits = $args{visits}; # optional list of visit IDs
    my $key_map = $args{key_map}; # optional hash of fields
    my $include = $args{include}; # optional include filter
    my $exclude = $args{exclude}; # optional exclude filter
    my $lookups = $args{lookups}; # optional lookups object

    # Get site config details

    Data::SiteConfig->connect();
    my $config = Data::SiteConfig->get($site->{site_id});
    Data::SiteConfig->disconnect();

    my $self = {
        data    => $data, # this gets returned
        site    => $site,
        limit   => $limit,
        order   => $order,
        hosts   => $hosts,
        users   => $users,
        visits  => $visits,
        config  => $config,
        key_map => $key_map,
        include => $include,
        exclude => $exclude,
        lookups => $lookups,
        logging => [], # to debug slow reports
    };

    bless $self, $class;
}

=item report_id($name)

Return the report ID for a report name, e.g. "traffic" -> 1, "browser" -> 2

=cut
sub report_id
{
    my ($class, $name) = @_;
    return eval 'Constants::Reports::' . uc $name;
}

=item is_distinct($report_id)

Return whether a report ID is distinct for a channel or sums over all channels

=cut
sub is_distinct
{
    my ($class, $report_id) = @_;
    return $_Is_distinct{$report_id};
}

=back

=head2 Object Methods

=over 4

=item get_report($channel_id, $report_id, $start_date, $end_date)

Get a report for a particular channel between a start and end date

=cut
sub get_report
{
    my ($self, $channel_id, $report_id, $start_date, $end_date) = @_;

    # Cache the report

    my $cache = $self->cache_report($channel_id, $report_id, $start_date, $end_date);

    # Apply any report filters

    my $filter = Client::Sitester::ReportFilters->new($report_id, $channel_id);
    $filter->apply_to($self); # modifies our "include" and "exclude" fields

    # ...then return the cached report by reading it into our data arrayref

    return $cache->read_keys_and_values($self->{data}, $self->{include}, $self->{exclude});

    # Note that the return value is the report total
}

=item cache_report($channel_id, $report_id, $start_date, $end_date)

Cache a stats report by saving the data to a cache file and returning the cache

=cut
sub cache_report
{
    my ($self, $channel_id, $report_id, $start_date, $end_date) = @_;

    # Create a cache object to manage a cached data file for this report

    my $filename = $self->filename($self->{site}{site_id}, $channel_id, $report_id, $start_date, $end_date);
    my $cache = Client::Sitester::Cache->new($filename, $end_date, $self->{site}{time_zone});

    if ($cache->is_empty_or_stale())
    {
        # Log details about the cached report

        $self->log('Cache file is empty or stale');

        # Wait if the cache is being written by another request 

        if ($cache->is_busy())
        {
            do {
                $self->log('Cache file is busy being written');
                sleep 1;
            } while ($cache->is_still_busy());
            return $cache;
        }

        # Update the cached data file if it's empty (over-ride "get_stats()")

        my $stats = $self->get_stats($channel_id, $report_id, $start_date, $end_date);
        $self->write_cache($cache, $stats, $report_id);
        $self->log('A new cache file was written');
    }
    else
    {
        $self->log('Cache file available for use');
    }

    return $cache;
}

=item write_cache($cache, $stats, $report_id)

Write stats to a cache after filtering, sorting and adding page titles

=cut
sub write_cache
{
    my ($self, $cache, $stats, $report_id) = @_;
    my $filter = $_Cache_filters{$report_id};
    $stats = $filter->($self, $stats) if $filter;
    my $data_list = $self->sort_stats($stats);
    $self->add_titles($data_list, $report_id) if $self->has_titles($report_id);
    $cache->write_keys_and_values($data_list);
}

=item sort_stats($stats)

Turn a key/value hash into an ordered stats report, according to the report ID

=cut
sub sort_stats
{
    my ($self, $stats) = @_;
    my $lookups = $self->{lookups};

    # Sort the results, with a limit (time zones are an exception)

    my @fields = $self->{order} =~ /keys/ ?
                     sort {$a+0 <=> $b+0} keys %{$stats} :
                     sort {$stats->{$b} <=> $stats->{$a}} keys %{$stats};
    my @data = ();
    my $others = 0;
    my $rownum = 0;
    foreach my $field (@fields)
    {
        my $value = $stats->{$field};
        $field = $lookups->lookup($field) || 'others' if $lookups;

        if ($field eq 'others' || $rownum > $self->{limit})
        {
            $others += $value;
        }
        else
        {
            unshift @data, { field => "$field", value => "$value" };
        }
        $rownum++;
    }
    unshift @data, { field => "others", value => "$others" } if $others;

    # Return the sorted stats report data

    return \@data;
}

=item has_titles($report_id)

Return whether or not a report has page titles

=cut
sub has_titles
{
    my ($self, $report_id) = @_;

    return $_Has_page_titles{$report_id};
}

=item add_titles($data_list, $report_id)

Add page title attributes to a list of report data

=cut
sub add_titles
{
    my ($self, $data_list, $report_id) = @_;
    my $site = $self->{site} or die "no site";

    # First, cache the page titles in a hash for fast lookups

    my $dbh = Data::Page->connect(host => $site->data_server()->{host});
    my $database = $site->database();
    my $query = $dbh->prepare("select url, title from $database.Page where title is not null");
    $query->execute();
    my %titles = ();
    my $chr0 = chr 0;
    my $chr31 = chr 31;
    while (my $page = $query->fetchrow_hashref())
    {
        # Strip out page title white space

        my $title = $page->{title};
        $title =~ s/^[\r\n\s]+//gs;
        $title =~ s/[\r\n\s]+$//gs;

        # Remove any remaining illegal low chracters in the range 0 to 31

        $title =~ s/[$chr0-$chr31]//g;

        # Associate the page title with the page URL

        my $url = $page->{url} || Constants::General::HOME_PAGE;
        $titles{$url} = $title;
    }
    Data::Page->disconnect();

    # By default, remove the query string, but this is configurable

    my $trim = Data::SiteConfig->find($self->{config}, 'url_trim') || '\?';

    # Then, add the page titles by looking up the URLs in the hash

    if ($report_id == Constants::Reports::PAGE_NAVIGATION)
    {
        foreach my $data (@{$data_list})
        {
            my ($url1, $url2) = split /->/, $data->{field};
            $url1 =~ s/$trim.*$//; $url2 =~ s/$trim.*$//;
            my $title1 = $titles{$url1} ? $titles{$url1} : 'unknown';
            my $title2 = $titles{$url2} ? $titles{$url2} : 'unknown';
            $data->{title} = "[$title1]->[$title2]";
        }
    }
    else
    {
        foreach my $data (@{$data_list})
        {
            my $url = $data->{field};
            $url =~ s/$trim.*$//;
            $data->{title} = $titles{$url} ? $titles{$url} : 'unknown';
        }
    }
}

=item channels_clause($channel_id, [$report_id])

Get an SQL channels clause for a site channel, including the channel's children.
This clause may be applied to any table that includes a "channel_id" int field.

=cut
sub channels_clause
{
    my ($self, $channel_id, $report_id) = @_;
    my $site = $self->{site} or die "no site";
    $channel_id ||= 0;
    return " and channel_id = $channel_id" # for reports that are aggregated
                           if $report_id && !$self->is_distinct($report_id);
    return ' and channel_id = 0' unless $channel_id || $report_id; # optimize
    return '' unless $channel_id; # don't return a clause for the whole site

    # For reports that hold distinct data (e.g. page) we need to aggregate
    # all the child channels of this parent channel to include all the data.

    Data::SiteChannel->connect();
    my $channels = Data::SiteChannel->get($site->{site_id});
    my $ordered = Data::SiteChannel->postorder($channels, $channel_id);
    my @list = map { $_->{channel_id} } @{$ordered};
    my $channel_list = join ',', @list;
    my $channel_clause = " and channel_id in ($channel_list)";
    Data::SiteChannel->disconnect();

    return $channel_clause;
}

=item user_clause($table)

Get an SQL user clause for a site, depending on any user list provided

=cut
sub user_clause
{
    my ($self, $table) = @_;
    return '' unless $self->{users} =~ /^[\d\s,]+$/;

    $table = $table ? "$table." : '';
    my $field = $table . 'user_id';
    return " and $field in ($self->{users})";
}

=item visit_clause($table)

Get an SQL visit clause for a site, depending on any visit list provided

=cut
sub visit_clause
{
    my ($self, $table) = @_;
    return '' unless $self->{visits} =~ /^[\d\s,]+$/;

    $table = $table ? "$table." : '';
    my $field = $table . 'visit_id';
    return " and $field in ($self->{visits})";
}

=item host_clause($table)

Get an SQL host clause for a site, depending on any host list provided

=cut
sub host_clause
{
    my ($self, $table) = @_;
    return '' unless $self->{hosts} =~ /^[\w\-\.\s,]*$/;
    my $hosts = $self->{hosts};

    # Handle the case where a list of host IPs and names is not provided

    if (!$hosts) # no hosts, so just get the site's filter clause
    {
        return $self->{site}->filter_clause($table);
    }
    elsif ($hosts eq 'all') # all hosts, so don't filter anything
    {
        return '';
    }
    elsif ($hosts eq 'excluded') # get the site's excluded clause
    {
        my $sql = $self->{site}->filter_clause($table);
        return ' and not (true' . $sql . ')';
    }

    # Otherwise handle the normal case where a list of hosts is provided

    $table = $table ? "$table." : '';
    my @hosts = split /[,\s]+/, $hosts;
    my @ip_hosts = ();
    my @name_hosts = ();
    foreach my $host (@hosts)
    {
        if ($host =~ /\d$/) # ends with a digit, so it's an IP address
        {
            push @ip_hosts, "'$host'";
        }
        else # it doesn't end with a digit, so it's a host domain name.
        {
            push @name_hosts, "'$host'";
        }
    }

    # Return SQL to select rows where the host IP or host name matches

    my $ip_sql = '';
    $ip_sql = $table . 'host_ip in (' . join(',', @ip_hosts) . ')'
                                                                if @ip_hosts;
    my $name_sql = '';
    $name_sql = $table . 'host in (' . join(',', @name_hosts) . ')'
                                                                if @name_hosts;
    my @sql_clauses = ();
    push @sql_clauses, $ip_sql if $ip_sql;
    push @sql_clauses, $name_sql if $name_sql;
    my $sql = ' and (' . join(' or ', @sql_clauses) . ')';
    return $sql;
}

=item units($report_id)

Return the measurement units for this report

=cut
sub units
{
    my ($self, $report_id) = @_;
    return $_Report_units{$report_id} || $_DEFAULT_UNITS;
}

=item signature()

Return a unique MD5 hex signature for the particular list of user and visit IDs

=cut
sub signature
{
    my ($self) = @_;
    return '' unless $self->{hosts} || $self->{users} || $self->{visits};
    my @hosts = map {"h$_"} split /[,\s]+/, $self->{hosts};
    my @users = map {"u$_"} split /[,\s]+/, $self->{users};
    my @visits = map {"v$_"} split /[,\s]+/, $self->{visits};
    $self->{signature} ||= md5_hex(join ',', sort(@hosts, @users, @visits));
    return $self->{signature};
}

=item language()

Return the language of this report, if it has a referenced "Lookups" object

=cut
sub language
{
    my ($self) = @_;
    my $lookups = $self->{lookups} or return ''; # no language
    return $lookups->language(); # return the lookups language
}

=item filename($site_id, $channel_id, $report_id, $start_date, $end_date)

Return the filename for the cache file used to save the report data

=cut
sub filename
{
    my ($self, $site_id, $channel_id, $report_id, $start_date, $end_date) = @_;

    my $filename = "$site_id.$channel_id.$report_id.$start_date.$end_date";

    my $signature = $self->signature();
    $filename .= ".$signature" if $signature;

    my $language = $self->language();
    $filename .= ".$language" if $language;

    $filename .= '.keys' if $self->{key_map};

    return $filename;
}

=item log($line)

Log a line of information about the report generation

=cut
sub log
{
    my ($self, $line) = @_;
    my ($sec, $min, $hour, $day, $month, $year) = gmtime();
    my $time = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
    push @{$self->{logging}}, "$time $line";
}

=item get_logging()

Get an array ref of log lines for this report

=cut
sub get_logging
{
    my ($self) = @_;
    return $self->{logging};
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Constants::Reports, Client::Sitester::ReportFilters, Client::Sitester::Cache, Data::Page, Data::SiteChannel, Digest::MD5

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
