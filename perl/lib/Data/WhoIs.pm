#!/usr/bin/env perl

=head1 NAME

Data::WhoIs - Caches domain name "whois" details (e.g. name, address, email, phone)

=head1 VERSION

This document refers to version 1.0 of Data::WhoIs, released Jul 07, 2015

=head1 DESCRIPTION

Data::WhoIs caches domain name "whois" details e.g. name, address, email, phone.
Be sure to call the class static method connect() before using Data::WhoIs
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item who_is_id

The ID of the domain name being cached

=item domain

The domain name being cached

=item url_thumb

A URL to a thumbnail image of the domain's home page

=item details

The domain name's "whois" details

=item status

The domain name's status ([A]ctive, [I]nternet Service Provider, [S]uspended)

=back

=cut
package Data::WhoIs;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
use Encode;
{
    # Class static properties

    use constant STATUS_ACTIVE  => 'A';
    use constant STATUS_ISP     => 'I';
    use constant TRUE           => 1;

    my %_Domain_parts = (
        co  => TRUE,
        com => TRUE,
        net => TRUE,
        org => TRUE,
        gov => TRUE,
        int => TRUE,
    );

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
    $class->fields(qw(who_is_id domain url_thumb details status));

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

=item lookup($host)

Lookup a host name

=cut
sub lookup
{
    my ($class, $host) = @_;
    die "bad host $host" unless $host =~ /^\w[\w\.-]+\w$/;
    return {} if $class->is_ISP($host);
    my $domain = $class->domain($host);

    # Return any matching whois object

    my $who_is = $class->select("domain = ?", $domain);
    return $who_is if $who_is->{who_is_id};

    # Make a new whois object, unless it's an ISP

    $who_is = $class->new(domain => $domain);
    $who_is->{details} = `/usr/bin/whois $domain`;
    $who_is->{details} =~ s/\s+$//gm; # remove trailing white space
    $who_is->{status} = STATUS_ACTIVE;
    $who_is->update();
    
    return $who_is;
}

=item is_ISP($host)

Is this host name from an ISP?

=cut
sub is_ISP
{
    my ($class, $host) = @_;

    # ISP hostnames have many parts

    my @parts = split /\./, $host;
    return TRUE if @parts > 4;

    # ISP hostnames have big numbers in the first parts

    return $parts[0] =~ /\d\d+/ || $parts[1] =~ /\d\d+/;
}

=item domain($host)

Get the domain part of a host name

=cut
sub domain
{
    my ($class, $host) = @_;

    # Split the host name into its parts

    my @parts = split /\./, lc($host);
    return join '.', @parts[-3..-1] if @parts > 2 && $_Domain_parts{$parts[-2]};
    return join '.', @parts[-2..-1];
}

=back

=head2 Object Methods

=over 4

=item name()

Get the domain registrant's name from the "whois" details

=cut
sub name
{
    my ($self) = @_;
    my $name = '';
    $name = $1 if $self->{details} =~ /Admin.*:\n\s*(.+)/im;
    $name = $1 if $name eq '' && $self->{details} =~ /Registrant.*:\n\s*(.+)/im;
    $name =~ s/\s\s+.*$//;
    $name = "$2 $1" if $name =~ /(\w+), (\w+)/;
    return $name;
}

=item address()

Get the domain registrant's address from the "whois" details

=cut
sub address
{
    my ($self) = @_;
    my $address = '';
    $address = $1 if $self->{details} =~ /Registrant's address:\n(.+\n.+\n.+\n.+)/im;
    $address = $1 if $address eq '' && $self->{details} =~ /Registrant.*:\n(.+\n.+\n.+\n.+)/im;
    $address =~ s/\s\s+/, /gm;
    $address =~ s/^[,\s]+//;
    return $address;
}

=item phone()

Get the domain registrant's phone from the "whois" details

=cut
sub phone
{
    my ($self) = @_;
    my $phone = '';
    $phone = $1 if $self->{details} =~ /\n\s+([()\d+][()\d\.\s+-]{10,20})/im;
    chomp $phone;
    return $phone;
}

=item email()

Get the domain registrant's email from the "whois" details

=cut
sub email
{
    my ($self) = @_;
    my $email = '';
    $email = lc($1) if $self->{details} =~ /([\w\.-]+@[\w\.-]+)/im;
    return $email;
}

}1;

=back

=head1 DEPENDENCIES

Data::Object, "/usr/bin/whois" executable program

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
