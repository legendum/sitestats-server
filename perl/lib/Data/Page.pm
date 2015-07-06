#!/usr/bin/env perl

=head1 NAME

Data::Page - Caches web page details (e.g. titles) for monitored web sites

=head1 VERSION

This document refers to version 1.1 of Data::Page, released Jul 07, 2015

=head1 DESCRIPTION

Data::Page caches web page details (e.g. titles) for monitored web sites.
Be sure to call the class static method connect() before using Data::Page
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item page_id

The page being cached

=item url

The full page URL with protocol and domain

=item url_thumb

A URL to a thumbnail image of the web page

=item last_seen

The last time this page was seen (timestamp)

=item days_seen

The number of days this page has been seen

=item failures

The number of times we failed to read the page

=item title

The page title (from its HTML)

=item keywords

The page keywords (from its HTML meta tags)

=item description

The page description (from its HTML meta tags)

=item content

The page content (as HTML)

=back

=cut
package Data::Page;
$VERSION = "1.1";

use strict;
use base 'Data::Object';
use Encode;
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
    my ($class, %arg) = @_;
    return $_Connection if $_Connection;

    $_Connection = $class->SUPER::connect(%arg);
    $class->fields(qw(page_id url url_thumb days_seen failures title keywords description content));

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

=item get_pages()

Get a cache of web page IDs, keyed on URLs (see the "add_pages()" method below)

=cut
sub get_pages
{
    my ($class, $page_titles, $url_trim) = @_;
    $page_titles ||= {};

    # If we're trimming URLs then apply this to the hashref of page titles

    my $trimmed_page_titles = $class->trimmed_pages($page_titles, $url_trim);

    # Create a hashref of page URLs mapping to page ID numbers, +ve and -ve

    my $query = Data::Page->sql("select page_id, url, title from Page");
    my %pages = ();
    while (my $page = $query->fetchrow_hashref())
    {
        my $url = $page->{url};
        my $title = $page->{title} || '';
        my $title_today = $trimmed_page_titles->{$url} || $title;
        my $page_id = $page->{page_id};

        # Use positive IDs for pages with current titles, negative for the rest

        $pages{$url} = ($title eq '' || $title ne $title_today) ? 0 - $page_id
                                                                : 0 + $page_id;
    }

    return \%pages;
}

=item add_pages($pages, [$page_titles], [$url_trim])

Add any unbrowsed web page URLs to the database so they can be browsed later

=cut
sub add_pages
{
    my ($class, $pages, $page_titles, $url_trim) = @_;
    $page_titles ||= {};

    # If we're trimming URLs then apply this to the hashref of page titles

    my $trimmed_page_titles = $class->trimmed_pages($page_titles, $url_trim);

    # Add all pages that don't already have an assigned page ID

    while (my ($url, $page_id) = each %{$pages})
    {
        next if $page_id > 0; # it's an existing page with a current title
        my $title = $trimmed_page_titles->{$url} || '';

        if ($page_id == 0) # it's a new page we never saw before
        {
            Data::Page->new( url => $url, title => $title, days_seen => 0, failures => 0 )->insert();
        }
        elsif ($page_id < 0) # it's a page that needs its title updating
        {
            my $page = Data::Page->row(0 - $page_id);
            next unless $page->{page_id};
            if ($page->{title} ne $title)
            {
                $page->{title} = $title;
                $page->update();
            }
        }
    }
}

=item trimmed_pages($page_titles, [$url_trim])

Trim page URLs and return a new hashref of trimmed URLs mapping to page titles

=cut
sub trimmed_pages
{
    my ($class, $page_titles, $url_trim) = @_;
    return $page_titles unless $url_trim;

    my $trimmed_page_titles = {};
    while (my ($url, $title) = each %{$page_titles})
    {
        eval { $url =~ s/$url_trim.*$//; };
        $title =~ s/\\[rnt]/ /g; # to remove whitespace
        $trimmed_page_titles->{$url} ||= $title;
    }
    return $trimmed_page_titles;
}

=item dedupe_pages()

Deduplicate pages by scanning through all the URLs and removing duplicates

=cut
sub dedupe_pages
{
    my ($class) = @_;

    # Find pages with duplicate URLs

    my $query = '1=1 order by url';
    my $pages = 0;
    my $last_url = '';
    my @duplicates = ();
    for (my $page = $class->select($query);
            $page->{page_id};
            $page = $class->next($query))
    {
        $pages++;
        push @duplicates, $page->{page_id} if $last_url eq $page->{url};
        $last_url = $page->{url};
    }

    # Delete duplicate pages

    my $dupes = 0;
    foreach my $duplicate (@duplicates)
    {
        $dupes++;
        my $page = $class->row($duplicate);
        $page->delete();
    }

    return ($pages, $dupes);
}

=back

=head2 Object Methods

=over 4

=item url()

Return the URL as decoded UTF8 text

=cut
sub url
{
    my ($self) = @_;

    return decode('utf8', $self->{url});
}

}1;

=back

=head1 DEPENDENCIES

Data::Object, Encode

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
