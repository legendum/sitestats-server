#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::EN::Browser looks up web browser names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::EN::Browser, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::EN::Browser looks up web browser names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::EN::Browser;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
        'IE90'=>'Internet Explorer 9.0',
        'IE80'=>'Internet Explorer 8.0',
        'IE70'=>'Internet Explorer 7.0',
        'IE65'=>'Internet Explorer 6.5',
        'IE60'=>'Internet Explorer 6.0',
        'IE55'=>'Internet Explorer 5.5',
        'IE52'=>'Internet Explorer 5.2',
        'IE51'=>'Internet Explorer 5.1',
        'IE50'=>'Internet Explorer 5.0',
        'IE45'=>'Internet Explorer 4.5 (Mac)',
        'IE40'=>'Internet Explorer 4.0',
        'IE30'=>'Internet Explorer 3.0',
        'IE20'=>'Internet Explorer 2.0',
        'FF40'=>'Firefox 4.0',
        'FF39'=>'Firefox 3.9',
        'FF38'=>'Firefox 3.8',
        'FF37'=>'Firefox 3.7',
        'FF36'=>'Firefox 3.6',
        'FF35'=>'Firefox 3.5',
        'FF31'=>'Firefox 3.1',
        'FF30'=>'Firefox 3.0',
        'FF20'=>'Firefox 2.0',
        'FF15'=>'Firefox 1.5',
        'FF10'=>'Firefox 1.0',
        'IEC'=>'Internet Explorer Crawler',
        'SA50'=>'Safari 5.0',
        'SA40'=>'Safari 4.0',
        'SA30'=>'Safari 3.0',
        'SAF9'=>'Safari 9',
        'SAF8'=>'Safari 8',
        'SAF7'=>'Safari 7',
        'SAF6'=>'Safari 6',
        'SAF5'=>'Safari 5',
        'SAF4'=>'Safari 4',
        'SAF3'=>'Safari 3',
        'SAF2'=>'Safari 2',
        'SAF1'=>'Safari 1',
        'CH40'=>'Chrome 4.0',
        'CH30'=>'Chrome 3.0',
        'CH20'=>'Chrome 2.0',
        'CH10'=>'Chrome 1.0',
        'MOZ8'=>'Mozilla 8',
        'MOZ7'=>'Mozilla 7',
        'MOZ6'=>'Mozilla 6',
        'MOZ5'=>'Mozilla 5',
        'MOZ4'=>'Mozilla 4',
        'MOZ3'=>'Mozilla 3',
        'MOZ2'=>'Mozilla 2',
        'GA10'=>'Galeon 1.0',
        'GA11'=>'Galeon 1.1',
        'GA12'=>'Galeon 1.2',
        'GA13'=>'Galeon 1.3',
        'GA14'=>'Galeon 1.4',
        'KO20'=>'Konqueror 2.0',
        'KO21'=>'Konqueror 2.1',
        'KO22'=>'Konqueror 2.2',
        'KO23'=>'Konqueror 2.3',
        'KO30'=>'Konqueror 3.0',
        'KO31'=>'Konqueror 3.1',
        'KO32'=>'Konqueror 3.2',
        'KO33'=>'Konqueror 3.3',
        'KO34'=>'Konqueror 3.3',
        'NN8'=>'Netscape Navigator 8',
        'NN7'=>'Netscape Navigator 7',
        'NN6'=>'Netscape Navigator 6',
        'NN5'=>'Netscape Navigator 5',
        'NN4'=>'Netscape Navigator 4',
        'NN3'=>'Netscape Navigator 3',
        'NN2'=>'Netscape Navigator 2',
        'OP9'=>'Opera 9',
        'OP8'=>'Opera 8',
        'OP7'=>'Opera 7',
        'OP6'=>'Opera 6',
        'OP5'=>'Opera 5',
        'IPOD'=>'iPod Touch',
        'IPHN'=>'iPhone',
        'SONY'=>'Sony Ericsson',
        'Sony'=>'Sony Ericsson',
        'MSN1'=>'MSN Bot',
        'YHOO'=>'Yahoo Crawler',
        'Turn'=>'Turnitin Bot',
        'Jaka'=>'Jakarta Spider',
        'Scoo'=>'Altavista',
        'Slur'=>'Inktomi',
        'Wget'=>'GNU Wget crawler',
        'Info'=>'Infoseek',
        'Ultr'=>'Infoseek',
        'WebC'=>'Web Crawler',
        'Lyco'=>'Lycos',
        'Gull'=>'Northern Light',
        'Goog'=>'Google',
        'KP70'=>'Keynote Perspective 7.0',
        'KP60'=>'Keynote Perspective 6.0',
        'KP50'=>'Keynote Perspective 5.0',
    );

=head2 Class Methods

=over 4

=item new(%args)

Create a new Client::Sitester::Lookups::EN::Browser object

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
