#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::EN::Country looks up web country names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::EN::Country, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::EN::Country looks up web country names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::EN::Country;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
        'ad'=>'Andorra',
        'ae'=>'United Arab Emirates',
        'af'=>'Afghanistan',
        'ag'=>'Antigua and Barbuda',
        'ai'=>'Anguilla',
        'al'=>'Albania',
        'am'=>'Armenia',
        'an'=>'Netherlands Antilles',
        'ao'=>'Angola',
        'AP'=>'Asia/Pacific',
        'aq'=>'Antarctica',
        'ar'=>'Argentina',
        'as'=>'American Samoa',
        'at'=>'Austria',
        'au'=>'Australia',
        'aw'=>'Aruba',
        'az'=>'Azerbaijan',
        'ba'=>'Bosnia and Herzegovina',
        'bb'=>'Barbados',
        'bd'=>'Bangladesh',
        'be'=>'Belgium',
        'bf'=>'Burkina Faso',
        'bg'=>'Bulgaria',
        'bh'=>'Bahrain',
        'bi'=>'Burundi',
        'bj'=>'Benin',
        'bm'=>'Bermuda',
        'bn'=>'Brunei Darussalam',
        'bo'=>'Bolivia',
        'br'=>'Brazil',
        'bs'=>'Bahamas',
        'bt'=>'Bhutan',
        'bv'=>'Bouvet Island',
        'bw'=>'Botswana',
        'by'=>'Belarus',
        'bz'=>'Belize',
        'ca'=>'Canada',
        'cc'=>'Cocos (Keeling) Islands',
        'cf'=>'Central African Republic',
        'cg'=>'Congo',
        'ch'=>'Switzerland',
        'ci'=>'Cote D\'Ivoire (Ivory Coast)',
        'ck'=>'Cook Islands',
        'cl'=>'Chile',
        'cm'=>'Cameroon',
        'cn'=>'China',
        'co'=>'Colombia',
        'cr'=>'Costa Rica',
        'cs'=>'Czechoslovakia (former)',
        'cu'=>'Cuba',
        'cv'=>'Cape Verde',
        'cx'=>'Christmas Island',
        'cy'=>'Cyprus',
        'cz'=>'Czech Republic',
        'de'=>'Germany',
        'dj'=>'Djibouti',
        'dk'=>'Denmark',
        'dm'=>'Dominica',
        'do'=>'Dominican Republic',
        'dz'=>'Algeria',
        'ec'=>'Ecuador',
        'ee'=>'Estonia',
        'eg'=>'Egypt',
        'eh'=>'Western Sahara',
        'el'=>'El Salvador',
        'en'=>'English',
        'er'=>'Eritrea',
        'es'=>'Spain',
        'et'=>'Ethiopia',
        'eu'=>'Europe',
        'fi'=>'Finland',
        'fj'=>'Fiji',
        'fk'=>'Falkland Islands (Malvinas)',
        'fm'=>'Micronesia',
        'fo'=>'Faroe Islands',
        'fr'=>'France',
        'fx'=>'France, Metropolitan',
        'ga'=>'Gabon',
        'gb'=>'Great Britain',
        'gd'=>'Grenada',
        'ge'=>'Georgia',
        'gf'=>'French Guiana',
        'gh'=>'Ghana',
        'gi'=>'Gibraltar',
        'gl'=>'Greenland',
        'gm'=>'Gambia',
        'gn'=>'Guinea',
        'gp'=>'Guadeloupe',
        'gq'=>'Equatorial Guinea',
        'gr'=>'Greece',
        'gs'=>'S. Georgia and S. Sandwich Isls.',
        'gt'=>'Guatemala',
        'gu'=>'Guam',
        'gw'=>'Guinea-Bissau',
        'gy'=>'Guyana',
        'he'=>'Israel (Hebrew)',
        'hk'=>'Hong Kong',
        'hm'=>'Heard and McDonald Islands',
        'hn'=>'Honduras',
        'hr'=>'Croatia (Hrvatska)',
        'ht'=>'Haiti',
        'hu'=>'Hungary',
        'id'=>'Indonesia',
        'ie'=>'Ireland',
        'il'=>'Israel',
        'in'=>'India',
        'io'=>'British Indian Ocean Territory',
        'iq'=>'Iraq',
        'ir'=>'Iran',
        'is'=>'Iceland',
        'it'=>'Italy',
        'ja'=>'Japan',
        'jm'=>'Jamaica',
        'jo'=>'Jordan',
        'jp'=>'Japan',
        'ke'=>'Kenya',
        'kg'=>'Kyrgyzstan',
        'kh'=>'Cambodia',
        'ki'=>'Kiribati',
        'ko'=>'Korea',
        'km'=>'Comoros',
        'kn'=>'Saint Kitts and Nevis',
        'kp'=>'Korea (North)',
        'kr'=>'Korea (South)',
        'kw'=>'Kuwait',
        'ky'=>'Cayman Islands',
        'kz'=>'Kazakhstan',
        'la'=>'Laos',
        'lb'=>'Lebanon',
        'lc'=>'Saint Lucia',
        'li'=>'Liechtenstein',
        'lk'=>'Sri Lanka',
        'lr'=>'Liberia',
        'ls'=>'Lesotho',
        'lt'=>'Lithuania',
        'lu'=>'Luxembourg',
        'lv'=>'Latvia',
        'ly'=>'Libya',
        'ma'=>'Morocco',
        'mc'=>'Monaco',
        'md'=>'Moldova',
        'mg'=>'Madagascar',
        'mh'=>'Marshall Islands',
        'mk'=>'Macedonia',
        'ml'=>'Mali',
        'mm'=>'Myanmar',
        'mn'=>'Mongolia',
        'mo'=>'Macau',
        'mp'=>'Northern Mariana Islands',
        'mq'=>'Martinique',
        'mr'=>'Mauritania',
        'ms'=>'Montserrat',
        'mt'=>'Malta',
        'mu'=>'Mauritius',
        'mv'=>'Maldives',
        'mw'=>'Malawi',
        'mx'=>'Mexico',
        'my'=>'Malaysia',
        'mz'=>'Mozambique',
        'na'=>'Namibia',
        'nc'=>'New Caledonia',
        'ne'=>'Niger',
        'nf'=>'Norfolk Island',
        'ng'=>'Nigeria',
        'ni'=>'Nicaragua',
        'nl'=>'Netherlands',
        'no'=>'Norway',
        'np'=>'Nepal',
        'nr'=>'Nauru',
        'ns'=>'Nova Scotia',
        'nt'=>'Neutral Zone',
        'nu'=>'Niue',
        'nz'=>'New Zealand (Aotearoa)',
        'om'=>'Oman',
        'pa'=>'Panama',
        'pe'=>'Peru',
        'pf'=>'French Polynesia',
        'pg'=>'Papua New Guinea',
        'ph'=>'Philippines',
        'pk'=>'Pakistan',
        'pl'=>'Poland',
        'pm'=>'St. Pierre and Miquelon',
        'pn'=>'Pitcairn',
        'pr'=>'Puerto Rico',
        'pt'=>'Portugal',
        'pw'=>'Palau',
        'py'=>'Paraguay',
        'qa'=>'Qatar',
        're'=>'Reunion',
        'ro'=>'Romania',
        'ru'=>'Russian Federation',
        'rw'=>'Rwanda',
        'sa'=>'Saudi Arabia',
        'sb'=>'Solomon Islands',
        'sc'=>'Seychelles',
        'sd'=>'Sudan',
        'se'=>'Sweden',
        'sg'=>'Singapore',
        'sh'=>'St. Helena',
        'si'=>'Slovenia',
        'sj'=>'Svalbard and Jan Mayen Islands',
        'sk'=>'Slovak Republic',
        'sl'=>'Slovenia',
        'sm'=>'San Marino',
        'sn'=>'Senegal',
        'so'=>'Somalia',
        'sr'=>'Suriname',
        'st'=>'Sao Tome and Principe',
        'su'=>'USSR (former)',
        'sv'=>'Sweden', # used to be El Salvador
        'sy'=>'Syria',
        'sz'=>'Swaziland',
        'tc'=>'Turks and Caicos Islands',
        'td'=>'Chad',
        'tf'=>'French Southern Territories',
        'tg'=>'Togo',
        'th'=>'Thailand',
        'tj'=>'Tajikistan',
        'tk'=>'Tokelau',
        'tm'=>'Turkmenistan',
        'tn'=>'Tunisia',
        'to'=>'Tonga',
        'tp'=>'East Timor',
        'tr'=>'Turkey',
        'tt'=>'Trinidad and Tobago',
        'tv'=>'Tuvalu',
        'tw'=>'Taiwan',
        'tz'=>'Tanzania',
        'ua'=>'Ukraine',
        'ug'=>'Uganda',
        'uk'=>'United Kingdom',
        'um'=>'US Minor Outlying Islands',
        'ur'=>'Uruguay',
        'us'=>'United States',
        'uy'=>'Uruguay',
        'uz'=>'Uzbekistan',
        'va'=>'Vatican City (Holy See)',
        'vc'=>'Saint Vincent and the Grenadines',
        've'=>'Venezuela',
        'vg'=>'Virgin Islands (British)',
        'vi'=>'Virgin Islands (U.S.)',
        'vn'=>'Viet Nam',
        'vu'=>'Vanuatu',
        'wf'=>'Wallis and Futuna Islands',
        'ws'=>'Samoa',
        'ye'=>'Yemen',
        'yt'=>'Mayotte',
        'yu'=>'Yugoslavia',
        'za'=>'South Africa',
        'zm'=>'Zambia',
        'zr'=>'Zaire',
        'zw'=>'Zimbabwe',
    );

=head2 Class Methods

=over 4

=item new([$regex])

Create a new Client::Sitester::Lookups::EN::Country object with optional regex

=cut
sub new
{
    my ($class, $regex) = @_;
    my $self = $class->SUPER::new(\%_Lookup, $regex);
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
