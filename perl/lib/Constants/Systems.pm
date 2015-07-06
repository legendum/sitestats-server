#!/usr/bin/env perl

=head1 NAME

Constants::Systems - Contains all the operating systems and browser constants

=head1 VERSION

This document refers to version 1.0 of Constants::Systems, released Jul 07, 2015

=head1 DESCRIPTION

Constants::Systems contains all the operating systems and browser constants

=head2 Properties

=over 4

None

=back

=cut
package Constants::Systems;
$VERSION = "1.0";

use strict;

# System definitions

use constant WINDOWS => [
    [ME             => 'WinME'],
    [XP             => 'WinXP'],
    [98             => 'Win98'],
    [95             => 'Win95'],
    ['NT 5.0'       => 'Win00'],
    ['NT 5.1'       => 'WinXP'],
    ['NT 6.0'       => 'Vista'],
    ['NT 6.1'       => 'Win7'],
    [NT             => 'WinNT'],
    ['Windows 3.1'  => 'Win31'],
    [Win16          => 'Win16'],
    [Win32          => 'Win32'],
    [Win            => 'Win'],
];

use constant OTHERS => [
    [Wii    => 'Wii'],
    [iPhone => 'iPhone'],
    [Mac    => 'Mac'],
    [X11    => 'Unix'],
    [WebTV  => 'WebTV'],
    [SEGA   => 'Sega'],
];

use constant BROWSERS => [
    ['Keynote\-Perspective (.).(.)' => 'KP'],
    ['MSIECrawler'                  => 'IEC'],
    ['MSIE (.).(.)'                 => 'IE'],
    ['Firefox\/(.).(.)'             => 'FF'],
    ['Version\/(.).(.).\d Safari'   => 'SA'],
    ['Opera\/(.)'                   => 'OP'],
    ['Chrome\/(.).(.)'              => 'CH'],
    ['iPhone'                       => 'IPHN'],
    ['iPod'                         => 'IPOD'],
    ['Galeon\/(.).(.)'              => 'GA'],
    ['Konqueror\/(.).(.)'           => 'KO'],
    ['Googlebot\/(.)'               => 'GGL'],
    ['msnbot\/(.)'                  => 'MSN'],
    ['Sony'                         => 'SONY'],
    ['Slurp'                        => 'YHOO'],
    ['geniebot'                     => 'GENI'],
    ['Netscape\/(.)'                => 'NN'],
    ['Mozilla\/(.)'                 => 'MOZ'],
    ['bot'                          => 'BOT'],
];

# Web spider browsers

use constant SPIDERS => {
    Goog => 1, # Google
    Gull => 1, # Northern Light
    Info => 1, # Infoseek
    Lyco => 1, # Lycos
    Scoo => 1, # AltaVista
    Slur => 1, # Inktomi
    Ultr => 1, # Infoseek
    WebC => 1, # Web Crawler
    KP50 => 1, # Keynote Perspective 5
    KP60 => 1, # Keynote Perspective 6
    YHOO => 1, # Yahoo! Web Crawler
    MSN1 => 1, # MSN Bot 1
    BOT  => 1, # Any other bot
};

=back

=head1 DEPENDENCIES

None

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
