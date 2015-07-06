#!/usr/bin/env perl

=head1 NAME

Data::Account - Manages customer accounts

=head1 VERSION

This document refers to version 1.0 of Data::Account, released Jul 07, 2015

=head1 DESCRIPTION

Data::Account manages the details for all customer accounts.
Be sure to call the class static method connect() before using Data::Account
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item reseller_id

The account's reseller

=item parent_id

The account's parent

=item status

The accounts status

=item start_date

The date the account was first signed up

=item end_date

The end date for the account's subscription

=item realname

The account holder's real name

=item username

The account holder's user name

=item password

The account holder's password

=item email

The account holder's email address

=item referrer

How the account holder came to know about the service

=item comments

Any comments about the account

=back

=cut
package Data::Account;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
{
    # Class static properties

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
    $class->fields(qw(account_id reseller_id parent_id status start_date end_date realname username password email referrer comments));

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

=back

=head2 Object Methods

=over 4

=item None

=cut

}1;

=back

=head1 DEPENDENCIES

Data::Object

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
