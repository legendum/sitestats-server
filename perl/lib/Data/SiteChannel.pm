#!/usr/bin/env perl

=head1 NAME

Data::SiteChannel - Manages web site content channels

=head1 VERSION

This document refers to version 1.0 of Data::SiteChannel, released Jul 07, 2015

=head1 DESCRIPTION

Data::SiteChannel manages the details for all web site content channels.
Be sure to call the class static method connect() before using Data::SiteChannel
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item site_id

The channel's site

=item channel_id

The channel ID number

=item parent_id

The channel parent's ID number (default is zero)

=item name

The channel name

=item urls

A text list of URLs included in this channel

=item titles

A text list of titles included in this channel

=back

=cut
package Data::SiteChannel;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
{
    # Class static properties

    use constant PARENT_LIMIT => 5;

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
    $class->fields(qw(site_channel_id site_id channel_id parent_id name urls titles));

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

=item get($site_id)

Return an array of channels for a site, where position equals channel_id
 
=cut
sub get
{
    my ($class, $site_id) = @_;
    die "no site" unless $site_id;

    # Create a virtual channel for the whole site

    my $site_channels = [];
    $site_channels->[0] = { channel_id  => 0,
                            parent_id   => 0,
                            parents     => [0] };

    # Get a list of channels

    my $max_channel_id = 0;
    my $query = 'site_id = ?';
    for (my $site_channel = $class->select($query, $site_id);
        $site_channel->{channel_id};
        $site_channel = $class->next($query))
    {
        my $channel_id = $site_channel->{channel_id};
        $site_channels->[$channel_id] = $site_channel;

        $max_channel_id = $channel_id if $channel_id > $max_channel_id;
    }

    # Add child and parent lists to each channel

    for (my $channel_id = 1; $channel_id <= $max_channel_id; $channel_id++)
    {
        my $channel = $site_channels->[$channel_id] or next;
        my $parent_id = $channel->{parent_id} || 0;
        my $parent = $site_channels->[$parent_id] ||= {channel_id => $parent_id};

        # Add the channel to the parent's child list

        my $children = $parent->{children} ||= []; # child list
        push @{$children}, $channel_id;

        # Add a list of the channel's parents

        my $parents = $channel->{parents} ||= []; # parent list
        my $count = 0;
        while ($parent = $site_channels->[$parent_id])
        {
            my $channel_id = $parent->{channel_id};
            push @{$parents}, $channel_id;
            last if $channel_id == 0 || $count++ > PARENT_LIMIT;
            
            $parent_id = $parent->{parent_id};
        }
    }
    
    return $site_channels;
}

=item postorder($channels, $channel_id)

Return a list of children for a channel, in postorder
 
=cut
sub postorder
{
    my ($class, $channels, $channel_id) = @_;
    $channel_id ||= 0; # whole site
    my $channel = $channels->[$channel_id];

    my @children = ();
    foreach my $child_id (@{$channel->{children}})
    {
        push @children, @{$class->postorder($channels, $child_id)};
    }
    push @children, $channel;

    return \@children;
}

=back

=head2 Object Methods

=over 4

=item is_page_match($page_url, $page_title)

Return whether or not a page is matched by the channel's URL list

=cut
sub is_page_match
{
    my ($self, $page_url, $page_title) = @_;
    return 0 unless $self->{urls} || $self->{titles};

    # Try to match the page with a URL pattern

    my @urls = split /\r?\n/, $self->{urls};
    foreach my $url (@urls)
    {
        return 1 if $url && $page_url =~ /^$url/i;
    }

    # Try to match the title with a title pattern

    if ($page_title)
    {
        $page_title =~ s/%20/ /g; # decode spaces to match
        my @titles = split /\r?\n/, $self->{titles};
        foreach my $title (@titles)
        {
            return 1 if $title && $page_title =~ /^$title/i;
        }
    }

    return 0; # no match
}

}1;

=back

=head1 DEPENDENCIES

Data::Object

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
