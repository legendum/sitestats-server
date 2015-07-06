#!/usr/bin/env perl

=head1 NAME

Data::APIToken - Manage the properties of all customer API tokens

=head1 VERSION

This document refers to version 1.0 of Data::APIToken, released Jul 07, 2015

=head1 DESCRIPTION

Data::APIToken manages the properties of all customer API tokens.
Be sure to call the class static method connect() before using Data::APIToken 
objects and disconnect() once you've finished.

=head2 Properties

=over 4

=item account_id

The API token's linked account (required)

=item token_text

The API token's text identifier (required)

=item call_count

The number of calls made to the API

=item call_limit

The number of calls allowed to the API

=item start_date

The date the API token becomes active

=item end_date

The end date for the API token's access

=item status

The API token status ([A]ctive or [S]uspended)

=back

=cut
package Data::APIToken;
$VERSION = "1.0";

use strict;
use base 'Data::Object';
use Utils::Time;
use Digest::MD5 qw(md5_hex);
use XML::Simple;
use JSON;
{
    # Class static properties

    use constant CALL_LIMIT => 1_000_000;
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
    $class->fields(qw(api_token_id account_id token_text call_count call_limit start_date end_date status));

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

=item call

Count the call to the API token, and return an error if we cannot call the token

=cut
sub call
{
    my ($self) = @_;
    my $date = Utils::Time->get_date();
    my $start_date = $self->{start_date} || ''; $start_date =~ s/-//g;
    my $end_date = $self->{end_date} || ''; $end_date =~ s/-//g;

    # Check the status, start date and end date

    return "suspended" if $self->{status} eq 'S';
    return "too young" if $start_date && $start_date > $date;
    return "too old" if $end_date && $end_date < $date;

    # Check the call count

    $self->{call_count}++;
    return "too many calls" if $self->{call_limit} && $self->{call_count} > $self->{call_limit};
    $self->update();
    return ''; # ok
}

=item create($account_id)

Create a new token for an account and give it default properties

=cut
sub create
{
    my ($self, $account_id) = @_;

    $self->{account_id} = $account_id or die "no account ID";
    $self->{token_text} = md5_hex($account_id . time());
    $self->{call_count} = 0;
    $self->{call_limit} ||= CALL_LIMIT;
    $self->{start_date} ||= Utils::Time->get_date();
    $self->{status} ||= 'A';

    $self->update();
}

=item generate

Generate a customer API token in CSV, XML, HTML or JSON format

=cut
sub generate
{
    my ($self, %args) = @_;
    my $format = $args{format} || 'html';
    my $request = $args{request} || '';

    my $token = {
        text    => $self->{token_text},
        calls   => $self->{call_count},
        limit   => $self->{call_limit},
        starts  => $self->{start_date},
        expires => $self->{end_date},
        status  => $self->{status}
    };

    my $api = {
        token => $token,
        stats => { request     => $request,
                   remote_addr => $ENV{HTTP_REMOTE_ADDR},
                   timestamp   => time() }
    };

    if ($format eq 'xml')
    {
        my $xml = new XML::Simple(RootName => 'api');
        return $xml->XMLout($api);
    }
    elsif ($format eq 'csv')
    {
        my $csv = '';
        while (my ($title, $value) = each %{$api->{token}})
        {
            $csv .= "\"$title\",\"$value\"\n";
        }
        return $csv;
    }
    elsif ($format eq 'html')
    {
        my $html = "<table>\n";
        while (my ($title, $value) = each %{$api->{token}})
        {
            $html .= "<tr><td>$title</td><td>$value</td></tr>\n";
        }
        $html .= "</table>\n";
        return $html;
    }
    elsif ($format eq 'json')
    {
        my $json = new JSON;
        return $json->encode($api);
    }
}

}1;

=back

=head1 DEPENDENCIES

Data::Object, Utils::Time, Digest::MD5, XML::Simple, JSON

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
