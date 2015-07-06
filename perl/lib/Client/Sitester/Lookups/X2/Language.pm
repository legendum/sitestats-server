#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::X2::Language looks up language names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::X2::Language, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::X2::Language looks up language names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::X2::Language;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
        aa=>"aa",
        ab=>"ab",
        ae=>"ae",
        af=>"af",
        ak=>"ak",
        am=>"am",
        an=>"an",
        ar=>"ar",
        as=>"as",
        av=>"av",
        ay=>"ay",
        az=>"az",
        ba=>"ba",
        be=>"be",
        bg=>"bg",
        bh=>"bh",
        bi=>"bi",
        bm=>"bm",
        bn=>"bn",
        bo=>"bo",
        br=>"br",
        bs=>"bs",
        ca=>"ca",
        ce=>"ce",
        ch=>"ch",
        co=>"co",
        cr=>"cr",
        cs=>"cs",
        cu=>"cu",
        cv=>"cv",
        cy=>"cy",
        da=>"da",
        de=>"de",
        dv=>"dv",
        dz=>"dz",
        ee=>"ee",
        el=>"el",
        en=>"en",
        eo=>"eo",
        es=>"es",
        et=>"et",
        eu=>"eu",
        fa=>"fa",
        ff=>"ff",
        fi=>"fi",
        fj=>"fj",
        fo=>"fo",
        fr=>"fr",
        fy=>"fy",
        ga=>"ga",
        gd=>"gd",
        gl=>"gl",
        gn=>"gn",
        gu=>"gu",
        gv=>"gv",
        ha=>"ha",
        he=>"he",
        hi=>"hi",
        ho=>"ho",
        hr=>"hr",
        ht=>"ht",
        hu=>"hu",
        hy=>"hy",
        hz=>"hz",
        ia=>"ia",
        id=>"id",
        ie=>"ie",
        ig=>"ig",
        ii=>"ii",
        ik=>"ik",
        io=>"io",
        is=>"is",
        it=>"it",
        iu=>"iu",
        ja=>"ja",
        jv=>"jv",
        ka=>"ka",
        kg=>"kg",
        ki=>"ki",
        kj=>"kj",
        kk=>"kk",
        kl=>"kl",
        km=>"km",
        kn=>"kn",
        ko=>"ko",
        kr=>"kr",
        ks=>"ks",
        ku=>"ku",
        kv=>"kv",
        kw=>"kw",
        ky=>"ky",
        la=>"la",
        lb=>"lb",
        lg=>"lg",
        li=>"li",
        ln=>"ln",
        lo=>"lo",
        lt=>"lt",
        lu=>"lu",
        lv=>"lv",
        mg=>"mg",
        mh=>"mh",
        mi=>"mi",
        mk=>"mk",
        ml=>"ml",
        mn=>"mn",
        mo=>"mo",
        mr=>"mr",
        ms=>"ms",
        mt=>"mt",
        my=>"my",
        na=>"na",
        nb=>"nb",
        nd=>"nd",
        ne=>"ne",
        ng=>"ng",
        nl=>"nl",
        nn=>"nn",
        no=>"no",
        nr=>"nr",
        nv=>"nv",
        ny=>"ny",
        oc=>"oc",
        oj=>"oj",
        om=>"om",
        or=>"or",
        os=>"os",
        pa=>"pa",
        pi=>"pi",
        pl=>"pl",
        ps=>"ps",
        pt=>"pt",
        qu=>"qu",
        rm=>"rm",
        rn=>"rn",
        ro=>"ro",
        ru=>"ru",
        rw=>"rw",
        sa=>"sa",
        sc=>"sc",
        sd=>"sd",
        se=>"se",
        sg=>"sg",
        sh=>"sh",
        si=>"si",
        sk=>"sk",
        sl=>"sl",
        sm=>"sm",
        sn=>"sn",
        so=>"so",
        sq=>"sq",
        sr=>"sr",
        ss=>"ss",
        st=>"st",
        su=>"su",
        sv=>"sv",
        sw=>"sw",
        ta=>"ta",
        te=>"te",
        tg=>"tg",
        th=>"th",
        ti=>"ti",
        tk=>"tk",
        tl=>"tl",
        tn=>"tn",
        to=>"to",
        tr=>"tr",
        ts=>"ts",
        tt=>"tt",
        tw=>"tw",
        ty=>"ty",
        ug=>"ug",
        uk=>"uk",
        ur=>"ur",
        us=>"us",
        uz=>"uz",
        wa=>"wa",
        ve=>"ve",
        vi=>"vi",
        vo=>"vo",
        wo=>"wo",
        xh=>"xh",
        yi=>"yi",
        yo=>"yo",
        za=>"za",
        zh=>"zh",
        zu=>"zu",
    );

=head2 Class Methods

=over 4

=item new([$regex])

Create a new Client::Sitester::Lookups::X2::Language object with optional regex

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
