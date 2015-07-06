#!/usr/bin/env perl -w

=head1 NAME

Client::Sitester::Lookups::X2::Country looks up web country names

=head1 VERSION

This document refers to version 1.0 of Client::Sitester::Lookups::X2::Country, released Jul 07, 2015

=head1 DESCRIPTION

Client::Sitester::Lookups::X2::Country looks up web country names

=head2 Properties

=over 4

None

=back

=cut
package Client::Sitester::Lookups::X2::Country;
$VERSION = "1.0";

use strict;
use base 'Client::Sitester::Lookups';
{
    my %_Lookup = (
        aa=>"aa",
        ad=>"ad",
        ae=>"ae",
        af=>"af",
        ag=>"ag",
        ai=>"ai",
        al=>"al",
        am=>"am",
        an=>"an",
        ao=>"ao",
        aq=>"aq",
        ar=>"ar",
        as=>"as",
        at=>"at",
        au=>"au",
        aw=>"aw",
        az=>"az",
        ba=>"ba",
        bb=>"bb",
        bd=>"bd",
        be=>"be",
        bf=>"bf",
        bg=>"bg",
        bh=>"bh",
        bi=>"bi",
        bj=>"bj",
        bm=>"bm",
        bn=>"bn",
        bo=>"bo",
        br=>"br",
        bs=>"bs",
        bt=>"bt",
        bu=>"bu",
        bv=>"bv",
        bw=>"bw",
        by=>"by",
        bz=>"bz",
        ca=>"ca",
        cc=>"cc",
        cd=>"cd",
        cf=>"cf",
        ch=>"ch",
        ci=>"ci",
        ck=>"ck",
        cl=>"cl",
        cm=>"cm",
        cn=>"cn",
        co=>"co",
        cr=>"cr",
        cu=>"cu",
        cv=>"cv",
        cx=>"cx",
        cy=>"cy",
        cz=>"cz",
        de=>"de",
        dj=>"dj",
        dk=>"dk",
        dm=>"dm",
        do=>"do",
        dz=>"dz",
        ec=>"ec",
        ee=>"ee",
        eg=>"eg",
        eh=>"eh",
        er=>"er",
        es=>"es",
        et=>"et",
        fi=>"fi",
        fj=>"fj",
        fk=>"fk",
        fm=>"fm",
        fo=>"fo",
        fr=>"fr",
        ga=>"ga",
        en=>"gb",
        gb=>"gb",
        gd=>"gd",
        ge=>"ge",
        gf=>"gf",
        gh=>"gh",
        gi=>"gi",
        gl=>"gl",
        gm=>"gm",
        gn=>"gn",
        gp=>"gp",
        gq=>"gq",
        gr=>"gr",
        gs=>"gs",
        gt=>"gt",
        gu=>"gu",
        gw=>"gw",
        gy=>"gy",
        hk=>"hk",
        hm=>"hm",
        hn=>"hn",
        hr=>"hr",
        ht=>"ht",
        hu=>"hu",
        id=>"id",
        ie=>"ie",
        il=>"il",
        in=>"in",
        io=>"io",
        iq=>"iq",
        ir=>"ir",
        is=>"is",
        it=>"it",
        jm=>"jm",
        jo=>"jo",
        jp=>"jp",
        ke=>"ke",
        kg=>"kg",
        kh=>"kh",
        ki=>"ki",
        km=>"km",
        kn=>"kn",
        kp=>"kp",
        kr=>"kr",
        kw=>"kw",
        ky=>"ky",
        kz=>"kz",
        la=>"la",
        lb=>"lb",
        lc=>"lc",
        li=>"li",
        lk=>"lk",
        lr=>"lr",
        ls=>"ls",
        lt=>"lt",
        lu=>"lu",
        lv=>"lv",
        ly=>"ly",
        ma=>"ma",
        mc=>"mc",
        md=>"md",
        me=>"me",
        mg=>"mg",
        mh=>"mh",
        mk=>"mk",
        ml=>"ml",
        mm=>"mm",
        mn=>"mn",
        mo=>"mo",
        mp=>"mp",
        mq=>"mq",
        mr=>"mr",
        ms=>"ms",
        mt=>"mt",
        mu=>"mu",
        mv=>"mv",
        mw=>"mw",
        mx=>"mx",
        my=>"my",
        mz=>"mz",
        na=>"na",
        nc=>"nc",
        ne=>"ne",
        nf=>"nf",
        ng=>"ng",
        ni=>"ni",
        nl=>"nl",
        no=>"no",
        np=>"np",
        nr=>"nr",
        nt=>"nt",
        nu=>"nu",
        nz=>"nz",
        om=>"om",
        pa=>"pa",
        pe=>"pe",
        pf=>"pf",
        pg=>"pg",
        ph=>"ph",
        pk=>"pk",
        pl=>"pl",
        pm=>"pm",
        pn=>"pn",
        pr=>"pr",
        ps=>"ps",
        pt=>"pt",
        pw=>"pw",
        py=>"py",
        qa=>"qa",
        re=>"re",
        ro=>"ro",
        ru=>"ru",
        rw=>"rw",
        sa=>"sa",
        sb=>"sb",
        sc=>"sc",
        sd=>"sd",
        se=>"se",
        sg=>"sg",
        sh=>"sh",
        si=>"si",
        sj=>"sj",
        sk=>"sk",
        sl=>"sl",
        sm=>"sm",
        sn=>"sn",
        so=>"so",
        sp=>"sp",
        sr=>"sr",
        st=>"st",
        sv=>"sv",
        sy=>"sy",
        sz=>"sz",
        tc=>"tc",
        td=>"td",
        tf=>"tf",
        tg=>"tg",
        th=>"th",
        tj=>"tj",
        tk=>"tk",
        tm=>"tm",
        tn=>"tn",
        to=>"to",
        tp=>"tp",
        tr=>"tr",
        tt=>"tt",
        tv=>"tv",
        tw=>"tw",
        tz=>"tz",
        ua=>"ua",
        ug=>"ug",
        uk=>"gb",
        um=>"um",
        us=>"us",
        uy=>"uy",
        uz=>"uz",
        va=>"va",
        vc=>"vc",
        ve=>"ve",
        vg=>"vg",
        vi=>"vi",
        vn=>"vn",
        vu=>"vu",
        wf=>"wf",
        ws=>"ws",
        ye=>"ye",
        yt=>"yt",
        yu=>"yu",
        za=>"za",
        zm=>"zm",
        zr=>"zr",
        zw=>"zw",
    );

=head2 Class Methods

=over 4

=item new([$regex])

Create a new Client::Sitester::Lookups::X2::Country object with optional regex

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
