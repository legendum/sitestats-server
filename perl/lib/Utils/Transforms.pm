#!/usr/bin/env perl

=head1 NAME

Utils::Transforms - Tranform web activity data into meaningful measurements

=head1 VERSION

This document refers to version 1.1 of Utils::Transforms, released Jul 07, 2015

=head1 DESCRIPTION

Utils::Transforms transforms web activity data into meaningful measurements.

=head2 Properties

=over 4

None

=back

=cut
package Utils::Transforms;
$VERSION = "1.1";

use strict;
use Constants::General;
use Constants::Systems;
use Constants::Events;
use Utils::GeoIP;
use Encode;
use Encode::Guess;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Utils::Transforms object

=cut
sub new
{
    my ($class) = @_;

    my $self = {
        host_ids => {},
        host_times => {},
        no_cookies => {},
        geo_ip => Utils::GeoIP->new(),
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item event_type_id($type)

Return the event type id number for an event type

=cut
sub event_type_id
{
    my ($self, $type) = @_;
    return (Constants::Events::TYPE_IDS)->{$type};
}

=item host2id($site_id, $host_ip, $event_time, $visit_id)

Return the visit id number for a host IP using a site
This method will prevent the miscounting of visit IDs

=cut
sub host2id
{
    my ($self, $site_id, $host_ip, $event_time, $visit_id) = @_;
    $visit_id ||= $self->time2id($event_time);
    return $visit_id unless $host_ip;

    my $host_ids = $self->{host_ids};
    my $host_times = $self->{host_times};
    my $key = "$site_id|$host_ip";
    my $host_id = $host_ids->{$key} || 0;
    my $last_time = $host_times->{$key} || 0;
    if ($event_time - $last_time > Constants::General::VISIT_DURATION)
    {
        $host_times->{$key} = $event_time;
        return $host_ids->{$key} = $visit_id; # new visit
    }
    else
    {
        $host_times->{$key} = $event_time;
        return $host_ids->{$key} ||= $visit_id; # current visit
    }
}

=item time2id($time)

Return the id number for a time by simply appending "000000" to the time

=cut
sub time2id
{
    my ($self, $time) = @_;
    return "${time}000000";
}

=item is_new_cookie_refuser($visit_id)

Return whether an id belongs to a new cookie refuser

=cut
sub is_new_cookie_refuser
{
    my ($self, $visit_id) = @_;

    my $no_cookies = $self->{no_cookies};
    return 0 if defined($no_cookies->{$visit_id});
    $no_cookies->{$visit_id} = 1;
}

=item clean([$time])

Clean our lookup hashes of any entries older than an hour

=cut
sub clean
{
    my ($self, $time) = @_;
    $time ||= time(); # for testing
    my $host_ids = $self->{host_ids};
    my $host_times = $self->{host_times};
    my $no_cookies = $self->{no_cookies};

    # Sort the keys by time

    my @keys = sort {$host_times->{$a} <=> $host_times->{$b}} keys %{$host_times};
    foreach my $key (@keys)
    {
        # Don't delete younger than an hour

        my $last_time = $host_times->{$key};
        last if $time - $last_time < Constants::General::VISIT_DURATION * 2;

        # Delete entries from the hashes

        my $visit_id = $host_ids->{$key};
        delete $host_ids->{$key};
        delete $host_times->{$key};
        delete $no_cookies->{$visit_id};
    }
}

=item is_spider($user_agent)

Return whether the user agent is a spider

=cut
sub is_spider
{
    my ($class, $user_agent) = @_;
    $user_agent = substr($user_agent, 0, 4);
    return (Constants::Systems::SPIDERS)->{$user_agent} || 0;
}

=item computer($user_agent)

Determine the browser and operating system of the web user agent

=cut
sub computer
{
    my ($self, $user_agent) = @_;

    # Get the operating system from the user agent

    my $array_ref = ($user_agent =~ /Win/ ? Constants::Systems::WINDOWS
                                          : Constants::Systems::OTHERS);

    my $op_sys = $self->match($user_agent, $array_ref) || $user_agent;

    my $browser = $self->match($user_agent, Constants::Systems::BROWSERS)
                                                       || $user_agent;
    return ($browser, $op_sys);
}

=item match($string, $array_ref)

Match a string against patterns in an array of patterns and values

=cut
sub match
{
    my ($self, $string, $array_ref) = @_;

    foreach my $pair (@{$array_ref})
    {
        my ($re, $id) = @{$pair};
        if ($string =~ /$re/)
        {
            $id .= $1 if defined($1);
            $id .= $2 if defined($2);
            return $id;
        }
    }

    return ''; # no match
}

=item geo($host_ip, $language, $hour, $event_time, $ip2country)

Get geographical data about a web user. The "ip2country" flah is used to say
whether only the IP address should be used to detect the country of the visit.
If this is not set then the browser language is used to imply the country code.

=cut
sub geo
{
    my ($self, $host_ip, $language, $hour, $event_time, $ip2country) = @_;
    $language ||= 'us';
    $hour ||= 0;

    # Get the time zone

    my $event_hour = (gmtime($event_time))[2];
    my $time_zone = $hour - $event_hour;
    $time_zone -= 24 if $time_zone > 12;
    $time_zone += 24 if $time_zone <= -12;

    # Get the language

    $language = lc($language);
    if ($language =~ /us$/)
    {
        $language = 'en';
    }
    else
    {
        $language = $2 if $language =~ /^(\w{2}-)?(\w{2})/; # preferred language
        $language = 'en' if $language eq 'gb';
        $language = 'es' if $language eq 'mx';
    }

    # Get geographical data for the IP address

    my $geo = $self->{geo_ip}->lookup($host_ip);
    $geo->{time_zone} = $time_zone;
    $geo->{language} = $language;
    $geo->{region} = lc($geo->{region});
    my $country = lc($geo->{country});
    $country = $language if !$country && !$ip2country && $language && $language ne 'en';
    $country = 'uk' if $country eq 'gb';
    $geo->{country} = $country;
    $geo->{latitude} = int($geo->{latitude} * 10000) if $geo->{latitude};
    $geo->{longitude} = int($geo->{longitude} * 10000) if $geo->{longitude};

    return $geo;
}

=item referrer($referrer)

Get the referring page and any search phrase

=cut
sub referrer
{
    my ($self, $referrer, $language) = @_;

    # Extract any search words

    my $search = '';
    if ($referrer =~ /[\?&](p|q|qt|MT|qry|query|search|search_word|key|Keywords)=([^&]*)/)
    {
        $search = $2;
        if ($language eq 'ja')
        {
            $search =~ s/%u([a-fA-F0-9]{4})/pack("U",hex($1))/eg;
            my $decoder = guess_encoding($search, qw/euc-jp shiftjis 7bit-jis/);
            eval { $search = $decoder->decode($search) } if ref($decoder);
        }
        else
        {
            $search = lc($search);  # lower case words
            $search =~ s/([\xC0-\xDF])([\x80-\xBF])/chr(ord($1)<<6&0xC0|ord($2)&0x3F)/eg;
            my $decoder = guess_encoding($search, qw/latin1/);
            eval { $search = $decoder->decode($search) } if ref($decoder);
        }

        $referrer =~ s#/.*##;       # remove search page when search engine
    }
    $referrer =~ s#/$##;            # remove any trailing slash

    return ($referrer, $search);
}

=item user_data($data)

Parse a user data string into a hash

=cut
sub user_data
{
    my ($self, $data) = @_;
    my %hash = ();
    my @terms = split /\],/, "$data,";
    foreach my $term (@terms)
    {
        my ($field, $value) = split /=\[/, $term;
        $hash{$field} = $value;
    }
    return \%hash;
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Constants::Systems, Constants::Events, Utils::GeoIP, Encode, Encode::Guess

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
