#!/usr/bin/env perl

=head1 NAME

Server::Browser - Browse web pages and store details such as titles and text

=head1 VERSION

This document refers to version 1.1 of Server::Browser, released Jul 07, 2015

=head1 DESCRIPTION

Server::Browser browses web pages and stores details such as titles and text

=head2 Properties

=over 4

None

=back

=cut
package Server::Browser;
$VERSION = "1.1";

use strict;
use Constants::General;
use Data::Site;
use Data::Page;
use Utils::LogFile;
use Utils::LoadAvg;
use IO::Socket;
use LWP::UserAgent;
{
    # Class static properties

    use constant ALARM_SECS =>  10;
    use constant PAUSE_SECS =>   5;
    use constant MAX_LIMIT  => 500;
    use constant MIN_LIMIT  => 100;
    use constant MAX_FAILS  =>  10;
    use constant WAIT_DAYS  =>  20;

=head2 Class Methods

=over 4

=item new()

Create a new Server::Browser object

=cut
sub new
{
    my ($class) = @_;

    my $host = $1 if "$ENV{HOSTNAME} default 0" =~ /(\d+)/;
    my $self = {
        browser  => LWP::UserAgent->new,
        log_file => Utils::LogFile->new("$ENV{LOGS_DIR}/browser"),
        load_avg => Utils::LoadAvg->new("$ENV{MAX_LOAD_AVG}"),
    };
    $self->{browser}->timeout(ALARM_SECS);
    $self->{browser}->env_proxy;
    $self->{log_file}->alert("Created");

    bless $self, $class;
}

=item url_encode($url)

Return an encoded URL

=cut
sub url_encode
{
    my ($class, $url) = @_;
    my $uri = URI->new($url);
    return $uri->as_string();
}

=back

=head2 Object Methods

=over 4

=item browse(@site_ids)

Browse some web pages and store their details in the Pages database table

=cut
sub browse
{
    my ($self, @site_ids) = @_;
    my $limit = @site_ids ? MAX_LIMIT : MIN_LIMIT; # max limit if sites chosen
    @site_ids = $self->get_site_ids() unless @site_ids; # all sites by default
    my @sites = $self->get_sites(@site_ids);

    foreach my $site (@sites)
    {
        my $count = $limit;

        # Connect to the site's database

        eval { Data::Page->connect(host => $site->data_server()->{host}, database => $site->database()) };
        if ($@)
        {
            $self->{log_file}->error($@);
            next;
        }

        # Browse the site's web pages

        my $query = 'last_seen < ? and failures < ? limit ?';
        my $today = $self->{log_file}{date};
        for (my $page = Data::Page->select($query, $today, MAX_FAILS, $limit);
                $page->{page_id};
                $page = Data::Page->next($query))
        {
            # Update web pages infrequently (use plain SQL for speed)

            $page->{days_seen}++;
            $page->sql("update Page set days_seen = days_seen + 1 where page_id = ?", $page->{page_id});
            next if $page->{days_seen} > 1 # first read is a special case
                 && ($site->{site_id} + $page->{days_seen}) % WAIT_DAYS;

            # Update page text & attributes

            my $url = $self->full_url($site->{url}, $page->{url});
            my $html = $self->get_html($url) or $page->{failures}++;
            my $text = $self->get_text($html);
            my $attrs = $self->parse_html($html);
            $self->save_page($page, $text, $attrs);

            # Don't spider overly

            last unless $count--;
            sleep PAUSE_SECS;
            sleep PAUSE_SECS while $self->{load_avg}->too_high();
        }

        # Disconnect from the site's database

        Data::Page->disconnect();
    }
}

=item get_site_ids()

Get a list of site databases hosted on this server - see hack for 64-bit servers

=cut
sub get_site_ids
{
    my ($self) = @_;

    Data::Site->connect();

    my @site_ids = ();
    my $host_ip = inet_ntoa(inet_aton($ENV{HOSTNAME})); # get the data server ip
    my $query = "(comp_server like '$ENV{HOSTNAME}%' or comp_server like '$host_ip%') and status in ('L', 'T') order by site_id desc"; # new sites first
    for (my $site = Data::Site->select($query);
            $site->{site_id};
            $site = Data::Site->next($query))
    {
        push @site_ids, $site->{site_id};
    }
        
    Data::Site->disconnect();

    return @site_ids;
}

=item get_sites(@site_ids)

Get a hash of site details

=cut
sub get_sites
{
    my ($self, @site_ids) = @_;
    my @sites = ();

    Data::Site->connect();
    foreach my $site_id (@site_ids)
    {
        my $site = Data::Site->row($site_id);
        push @sites, $site;   
    }
    Data::Site->disconnect();

    return @sites;
}

=item full_url($domain, $path)

Return a full URL including protocol, domain and path

=cut
sub full_url
{
    my ($self, $domain, $path) = @_;
    $path = '' if $path eq Constants::General::HOME_PAGE;

    # Try the best case first - a full path

    my @parts = split(/\./, $path);
    return $path if $parts[0] =~ m#://#;

    # Partial path, so prepend the domain

    @parts = split(/\./, $domain);
    $domain = "www.$domain" unless @parts > 2;
    $domain = "http://$domain" unless $parts[0] =~ m#://#;
    return "$domain/$path";
}

=item get_html($url)

Get a web page as HTML

=cut
sub get_html
{
    my ($self, $url) = @_;
    return '' unless $url =~ /^http/;

    my $response = $self->{browser}->get($url);
    if ($response->is_success)
    {
        $self->{log_file}->info("Read $url");
        return $response->content;
    }
    else
    {
        $self->{log_file}->error("Cannot read $url " . $response->status_line);
        return '';
    }
}

=item get_text($html)

Get a web page as text

=cut
sub get_text
{
    my ($self, $html) = @_;

    my $text = '';
    $text = $1 if $html =~ /<body[^>]*>(.*)<\/body>/is;
    $text =~ s/<script[^>]*>.*?<\/script>//gis;
    $text =~ s/<style>.*?<\/style>//gis;
    $text =~ s/<[^>]+>/ /gs;
    $text =~ s/&nbsp;/ /gs;
    $text =~ s/\s+/ /gs;

    return $text;
}

=item parse_html($html)

Parse a web page into title, keywords, description, etc...

=cut
sub parse_html
{
    my ($self, $html) = @_;
    my %attrs = ();

    $attrs{title} = $1 if $html =~ m#<title>\s*(.*\S)\s*</title>#is;
    $attrs{keywords} = $1 if $html =~ m#<meta\s+name="keywords"\s+content="([^"]+)#i;
    $attrs{description} = $1 if $html =~ m#<meta\s+name="description"\s+content="([^"]+)#i;

    return \%attrs;
}

=item save_page($page, $text, $attrs)

Save the web page text and attributes like title, keywords, description, etc...

=cut
sub save_page
{
    my ($self, $page, $text, $attrs) = @_;

    $page->{content}     = $text;
    $page->{title}       ||= $attrs->{title}     || ''; # may already be set?
    $page->{keywords}    = $attrs->{keywords}    || '';
    $page->{description} = $attrs->{description} || '';
    $page->update();
}

=item DESTROY

Log the death of the object

=cut
sub DESTROY
{
    my ($self) = @_;
    $self->{log_file}->alert("Destroyed");
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Data::Site, Data::Page, Utils::LogFile, Utils::LoadAvg, IO::Socket, LWP::UserAgent

=head1 AUTHOR

Kevin Hutchinson (kevin.hutchinson@legendum.com)

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
