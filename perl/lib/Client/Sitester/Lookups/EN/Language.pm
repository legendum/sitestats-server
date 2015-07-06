#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::EN::Language looks up language names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::EN::Language, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::EN::Language looks up language names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::EN::Language;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
		'ab'=>'Abkhazian',
		'ae'=>'Avestan',
		'af'=>'Afrikaans',
		'ak'=>'Akan',
		'am'=>'Amharic',
		'an'=>'Aragonese',
		'ar'=>'Arabic',
		'as'=>'Assamese',
        'au'=>'English (Australian)',
		'av'=>'Avaric',
		'ay'=>'Aymara',
		'az'=>'Azerbaijani',
		'ba'=>'Bashkir',
		'be'=>'Belarusian',
		'bg'=>'Bulgarian',
		'bh'=>'Bihari',
		'bi'=>'Bislama',
		'bm'=>'Bambara',
		'bn'=>'Bengali',
		'bo'=>'Tibetan',
		'br'=>'Breton',
		'bs'=>'Bosnian',
		'ca'=>'Catalan; Valencian',
		'ce'=>'Chechen',
		'ch'=>'Chamorro',
		'co'=>'Corsican',
		'cr'=>'Cree',
		'cs'=>'Czech',
		'cu'=>'Slavic',
		'cv'=>'Chuvash',
		'cy'=>'Welsh',
		'da'=>'Danish',
		'de'=>'German',
		'dv'=>'Divehi',
		'dz'=>'Dzongkha',
		'ee'=>'Ewe',
		'el'=>'Greek (modern)',
		'en'=>'English',
		'eo'=>'Esperanto',
		'es'=>'Spanish',
		'et'=>'Estonian',
		'eu'=>'Basque',
		'fa'=>'Persian',
		'ff'=>'Fulah',
		'fi'=>'Finnish',
		'fj'=>'Fijian',
		'fo'=>'Faroese',
		'fr'=>'French',
		'fy'=>'Western Frisian',
		'ga'=>'Irish',
		'gd'=>'Gaelic; Scottish Gaelic',
		'gl'=>'Galician',
		'gn'=>'Guarani',
		'gu'=>'Gujarati',
		'gv'=>'Manx',
		'ha'=>'Hausa',
		'he'=>'Hebrew',
		'hi'=>'Hindi',
		'ho'=>'Hiri Motu',
		'hr'=>'Croatian',
		'ht'=>'Haitian',
		'hu'=>'Hungarian',
		'hy'=>'Armenian',
		'hz'=>'Herero',
		'ia'=>'Interlingua',
		'id'=>'Indonesian',
		'ie'=>'Interlingue',
		'ig'=>'Igbo',
		'ii'=>'Sichuan Yi',
		'ik'=>'Inupiaq',
		'io'=>'Ido',
		'is'=>'Icelandic',
		'it'=>'Italian',
		'iu'=>'Inuktitut',
		'ja'=>'Japanese',
		'jv'=>'Javanese',
		'ka'=>'Georgian',
		'kg'=>'Kongo',
		'ki'=>'Kikuyu',
		'kj'=>'Kwanyama',
		'kk'=>'Kazakh',
		'kl'=>'Kalaallisut (Greenlandic)',
		'km'=>'Khmer',
		'kn'=>'Kannada',
		'ko'=>'Korean',
		'kr'=>'Kanuri',
		'ks'=>'Kashmiri',
		'ku'=>'Kurdish',
		'kv'=>'Komi',
		'kw'=>'Cornish',
		'ky'=>'Kyrgyz',
		'la'=>'Latin',
		'lb'=>'Luxembourgish',
		'lg'=>'Ganda',
		'li'=>'Limburgish',
		'ln'=>'Lingala',
		'lo'=>'Lao',
		'lt'=>'Lithuanian',
		'lu'=>'Luba-Katanga',
		'lv'=>'Latvian',
		'mg'=>'Malagasy',
		'mh'=>'Marshallese',
		'mi'=>'Maori',
		'mk'=>'Macedonian',
		'ml'=>'Malayalam',
		'mn'=>'Mongolian',
		'mo'=>'Moldavian',
		'mr'=>'Marathi',
		'ms'=>'Malay',
		'mt'=>'Maltese',
		'my'=>'Burmese',
		'na'=>'Nauru',
		'nb'=>'Bokmå (Norwegia)',
		'nd'=>'Ndebele',
		'ne'=>'Nepali',
		'ng'=>'Ndonga',
		'nl'=>'Dutch (Flemish)',
		'nn'=>'Norwegian (Nynorsk)',
		'no'=>'Norwegian',
		'nr'=>'Ndebele',
		'nv'=>'Navajo',
		'ny'=>'Chichewa',
		'oc'=>'Occitan',
		'oj'=>'Ojibwa',
		'om'=>'Oromo',
		'or'=>'Oriya',
		'os'=>'Ossetian',
		'pa'=>'Punjabi',
		'pi'=>'Pali',
		'pl'=>'Polish',
		'ps'=>'Pashto',
		'pt'=>'Portuguese',
		'qu'=>'Quechua',
		'rm'=>'Romansh',
		'rn'=>'Rundi',
		'ro'=>'Romanian',
		'ru'=>'Russian',
		'rw'=>'Kinyarwanda',
		'sa'=>'Sanskrit',
		'sc'=>'Sardinian',
		'sd'=>'Sindhi',
		'se'=>'Sami',
		'sg'=>'Sango',
		'si'=>'Sinhalese',
		'sk'=>'Slovak',
		'sl'=>'Slovenian',
		'sm'=>'Samoan',
		'sn'=>'Shona',
		'so'=>'Somali',
		'sq'=>'Albanian',
		'sr'=>'Serbian',
		'ss'=>'Swati',
		'st'=>'Sotho',
		'su'=>'Sundanese',
		'sv'=>'Swedish',
		'sw'=>'Swahili',
		'ta'=>'Tamil',
		'te'=>'Telugu',
		'tg'=>'Tajik',
		'th'=>'Thai',
		'ti'=>'Tigrinya',
		'tk'=>'Turkmen',
		'tl'=>'Tagalog',
		'tn'=>'Tswana',
		'to'=>'Tonga',
		'tr'=>'Turkish',
		'ts'=>'Tsonga',
		'tt'=>'Tatar',
		'tw'=>'Twi',
		'ty'=>'Tahitian',
		'ug'=>'Uyghur',
		'uk'=>'Ukrainian',
		'ur'=>'Urdu',
        'us'=>'English (American)',
		'uz'=>'Uzbek',
		've'=>'Venda',
		'vi'=>'Vietnamese',
		'vo'=>'Volapük',
		'wa'=>'Walloon',
		'wo'=>'Wolof',
		'xh'=>'Xhosa',
		'yi'=>'Yiddish',
		'yo'=>'Yoruba',
		'za'=>'Zhuang',
		'zh'=>'Chinese',
		'zu'=>'Zulu',
    );

=head2 Class Methods

=over 4

=item new([$regex])

Create a new Client::Sitester::Lookups::EN::Language object with optional regex

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
