#!/usr/bin/env perl

=head1 NAME

Data::SiteAccount - Manages customer account links to site reporting

=head1 VERSION

This document refers to version 1.0 of Data::SiteAccount, released Jul 07, 2015

=head1 DESCRIPTION

Data::SiteAccount manages all customer account links to site reporting.
Be sure to call the class static method connect() before using Data::SiteAccount
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item site_id

The site being linked

=item channel_id

The channel being linked

=item account_id

The acount being linked

=item can_read

Whether the account may read the site reports

=item can_write

Whether the account may change the site settings

=item get_reports

A comma-separated list of report ID's to email

=item get_periods

A comma-separated list of periods (week,month) to email

=item status

The status of the site account link

=back

=cut
package Data::SiteAccount;
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
    $class->fields(qw(site_account_id site_id channel_id account_id can_read can_write get_reports get_periods status));

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
