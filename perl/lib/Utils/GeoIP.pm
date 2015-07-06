#!/usr/bin/env perl

=head1 NAME

Utils::GeoIP - Lookup geographical information from hostnames and IP addresses

=head1 VERSION

This document refers to version 1.2 of Utils::GeoIP, released Jul 07, 2015

=head1 DESCRIPTION

Utils::GeoIP looks up geographical information about hostnames and IP addresses.

=head2 Properties

=over 4

=item none

=back

=cut
package Utils::GeoIP;
$VERSION = "1.2";

use strict;
use Constants::General;
use Utils::GeoIP::PurePerl;
use IO::Socket;
use Encode;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new()

Create a new Utils::GeoIP object to get geographical info about IP addresses

=cut
sub new
{
    my ($class) = @_;
    my $path = "$ENV{GEOIP_DIR}/$ENV{GEOIP_CITY_FILE}";
    die "no GeoIP city data file" unless -f $path;

    my $self = {
        cities => Utils::GeoIP::PurePerl->new($path),
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item lookup($host_ip)

Get a Geo IP record for a host IP address

=cut
sub lookup
{
    my ($self, $host_ip) = @_;
    return {} unless $host_ip =~ /^\d+\.\d+\.\d+\.\d+$/;
    my ($country_code, $country_code3, $country_name, $region, $city, $postal_code, $latitude, $longitude, $dma_code, $area_code) = $self->{cities}->get_city_record($host_ip) or return {};

    # Lookup the details

    return {
        host_ip     => $host_ip,
        country     => $country_code || '',
        region      => $region || '',
        city        => encode(Constants::General::DEFAULT_ENCODING, $city) || '',
        postal_code => $postal_code || '',
        longitude   => $longitude || '',
        latitude    => $latitude || '',
        netspeed    => 'unknown', # TODO
    }
}

=item netspeed($host_ip)

Get a Geo IP network speed for a host IP address

=cut
#sub netspeed
#{
#    my ($self, $host_ip) = @_;
#    return unless $self->{netspeed};
#    my $netspeed = $self->{netspeed}->id_by_name($host_ip);
#    return 'unknown' if $netspeed == GEOIP_UNKNOWN_SPEED;
#    return 'dialup' if $netspeed == GEOIP_DIALUP_SPEED;
#    return 'cabledsl' if $netspeed == GEOIP_CABLEDSL_SPEED;
#    return 'corporate' if $netspeed == GEOIP_CORPORATE_SPEED;
#}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Utils::GeoIP::PurePerl, IO::Socket

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
