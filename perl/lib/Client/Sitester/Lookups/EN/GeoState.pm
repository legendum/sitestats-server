#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::EN::GeoState looks up USA and Canadian state names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::EN::GeoState, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::EN::GeoState looks up USA and Canadian state names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::EN::GeoState;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (

        # USA

        'al'=>'Alabama',
        'ak'=>'Alaska',
        'as'=>'American Samoa',
        'az'=>'Arizona',
        'ar'=>'Arkansas',
        'ca'=>'California',
        'co'=>'Colorado',
        'ct'=>'Connecticut',
        'de'=>'Delaware',
        'dc'=>'District Of Columbia',
        'fm'=>'Federated States Of Micronesia',
        'fl'=>'Florida',
        'ga'=>'Georgia',
        'gu'=>'Guam',
        'hi'=>'Hawaii',
        'id'=>'Idaho',
        'il'=>'Illinois',
        'in'=>'Indiana',
        'ia'=>'Iowa',
        'ks'=>'Kansas',
        'ky'=>'Kentucky',
        'la'=>'Louisiana',
        'me'=>'Maine',
        'mh'=>'Marshall Islands',
        'md'=>'Maryland',
        'ma'=>'Massachusetts',
        'mi'=>'Michigan',
        'mn'=>'Minnesota',
        'ms'=>'Mississippi',
        'mo'=>'Missouri',
        'mt'=>'Montana',
        'ne'=>'Nebraska',
        'nv'=>'Nevada',
        'nh'=>'New Hampshire',
        'nj'=>'New Jersey',
        'nm'=>'New Mexico',
        'ny'=>'New York',
        'nc'=>'North Carolina',
        'nd'=>'North Dakota',
        'mp'=>'Northern Mariana Islands',
        'oh'=>'Ohio',
        'ok'=>'Oklahoma',
        'or'=>'Oregon',
        'pw'=>'Palau',
        'pa'=>'Pennsylvania',
        'pr'=>'Puerto Rico',
        'ri'=>'Rhode Island',
        'sc'=>'South Carolina',
        'sd'=>'South Dakota',
        'tn'=>'Tennessee',
        'tx'=>'Texas',
        'ut'=>'Utah',
        'vt'=>'Vermont',
        'vi'=>'Virgin Islands',
        'va'=>'Virginia',
        'wa'=>'Washington',
        'wv'=>'West Virginia',
        'wi'=>'Wisconsin',
        'wy'=>'Wyoming',

        # Canada

        'ab'=>'Alberta',
        'bc'=>'British Columbia',
        'mb'=>'Manitoba',
        'nb'=>'New Brunswick',
        'nf'=>'Newfoundland',
        'ns'=>'Nova Scotia',
        'nt'=>'Northwest Territories',
        'on'=>'Ontario',
        'pe'=>'Prince Edward Island',
        'qc'=>'Quebec',
        'sk'=>'Saskatchewan',
        'yt'=>'Yukon',
    );

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Lookups::EN::GeoState object

=cut
sub new
{
    my ($class) = @_;
    my $self = $class->SUPER::new(\%_Lookup);
    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

None

=cut
sub dummy
{
    my ($self) = @_;
}

}1;

=back

=head1 DEPENDENCIES

Client::Sitester::Lookups

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
