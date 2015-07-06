#!/usr/bin/env perl

=head1 NAME

Client::API - Provide common API client functionality in a single perl module

=head1 VERSION

This document refers to version 1.0 of Client::API, released Jul 07, 2015

=head1 DESCRIPTION

Client::API provides common API client functionality in a single perl module.

=head2 Properties

=over 4

None

=back

=cut
package Client::API;
$VERSION = "1.0";

use strict;
use CGI qw/:cgi -debug/;
use Constants::General;
use Data::APIToken;
use Data::SiteAccount;
use Data::Site;
use XML::Simple;
use JSON;
{
    # Class static properties

    # None

=head2 Class Methods

=over 4

=item new([%args])

Create a new Client::API object

=cut
sub new
{
    my ($class, %args) = @_;

    # Make a CGI object and read its parameters

    my $cgi = new CGI;
    my $params = $cgi->Vars;

    # Make an API object and assign to it the CGI and params

    my $self = \%args || {};
    $self->{cgi} = $cgi;
    $self->{params} = $params;

    # Set the remote host IP address in the env

    $ENV{HTTP_REMOTE_ADDR} = $cgi->remote_host();

    # Return a new API object

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item call_token($token_text)

Call the user's token to check we have permission to use the API

=cut
sub call_token
{
    my ($self, $token_text) = @_;
    $token_text ||= $self->param('token');
    $self->error('no "token" parameter') unless $token_text;

    # Find a token with ID matching the token text

    Data::APIToken->connect();
    my $token = Data::APIToken->select('token_text = ?', $token_text);
    my $account_id = $token->{account_id} or $self->error("no token found with ID \"$token_text\"");

    # Call the token, noting any error message

    my $error = $token->call();
    $self->error("sorry, cannot call token \"$token_text\": $error") if $error;

    # Check the site account for read permission

    if (my $site = $self->set_site())
    {
        my $site_id = $site->{site_id};
        Data::SiteAccount->connect();
        my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
        $site_account->{can_read} eq 'yes' or $self->error("token \"$token_text\" does not have permission to read reports for site ID $site_id");
    }

    return $account_id; # in case the client needs to use it
}

=item set_site($site_id)

Set the site for subsequent API calls

=cut
sub set_site
{
    my ($self, $site_id) = @_;
    return if $self->{site};

    # Get the site ID parameter

    $site_id ||= $self->param('site') + 0;
    $site_id ||= $self->param('site_id') + 0;
    return unless $site_id;

    # Get the site details (e.g. data server and time zone)

    Data::Site->connect();
    my $site = Data::Site->row($site_id);
    Data::Site->disconnect();
    $site->{site_id} or $self->error("no site with ID $site_id");
    $site->{status} ne Constants::General::STATUS_SUSPENDED or $self->error("site with ID $site_id is suspended");

    # Finally set the site

    $self->{site} = $site;
    return $site;
}

=item site()

Get the site

=cut
sub site
{
    my ($self) = @_;
    return $self->{site};
}

=item param($name, $default)

Get a CGI parameter

=cut
sub param
{
    my ($self, $name, $default) = @_;
    return $self->{params}{$name} || $default || '';
}

=item param_lc($name, $default)

Get a CGI parameter as a lowercase string

=cut
sub param_lc
{
    my ($self, $name, $default) = @_;
    return lc $self->param($name, $default);
}

=item error($message)

Display an error message on a web page

=cut
sub error
{
    my ($self, $message) = @_;
    $message = "<api><error>$message</error></api>" if $self->format() eq 'xml';
    $self->display("$message\n");
    exit;
}

=item display($output)

Display some output in a format

=cut
sub display
{
    my ($self, $output) = @_;

    # Get the display format

    my $format = $self->param('format', 'xml');
    $format = 'xml' if $format eq 'map';
    $format = 'javascript' if $format eq 'json';

    # Get any JavaScript callback function

    if ($format eq 'javascript')
    {
        my $callback = $self->param('callback');
        $output = "$callback($output)" if $callback;
    }

    # Finally display the output in the format

    print "Content-type: text/$format\n\n$output";

    # Disconnect from the database

    Data::APIToken->disconnect();
    Data::SiteAccount->disconnect();
    Data::Site->disconnect();
}

=item user_clause($users, $table)

Get an SQL user clause for a site, depending on any user list provided

=cut
sub user_clause
{
    my ($self_or_class, $users, $table) = @_;
    return '' unless $users =~ /^[\d\s,]+$/;
    $table = $table ? "$table." : '';
    my $field = $table . 'user_id';
    return " and $field in ($users)";
}

=item visit_clause($visits, $table)

Get an SQL visit clause for a site, depending on any visit list provided

=cut
sub visit_clause
{
    my ($self_or_class, $visits, $table) = @_;
    return '' unless $visits =~ /^[\d\s,]+$/;
    $table = $table ? "$table." : '';
    my $field = $table . 'visit_id';
    return " and $field in ($visits)";
}

=item host_clause($site, $hosts, $table)

Get an SQL host clause for a site, depending on any host list provided

=cut
sub host_clause
{
    my ($self_or_class, $site, $hosts, $table) = @_;
    return '' unless $hosts =~ /^[\w\-\.\s,]*$/;

    # Handle the case where a list of host IPs and names is not provided

    if (!$hosts) # no hosts, so just get the site's filter clause
    {
        return $site->filter_clause($table);
    }
    elsif ($hosts eq 'all') # all hosts, so don't filter anything
    {
        return '';
    }
    elsif ($hosts eq 'excluded') # get the site's excluded clause
    {
        my $sql = $site->filter_clause($table);
        return ' and not (true' . $sql . ')';
    }

    # Otherwise handle the normal case where a list of hosts is provided

    $table = $table ? "$table." : '';
    my @hosts = split /[,\s]+/, $hosts;
    my @ip_hosts = ();
    my @name_hosts = ();
    foreach my $host (@hosts)
    {
        if ($host =~ /\d$/) # ends with a digit, so it's an IP address
        {
            push @ip_hosts, "'$host'";
        }
        else # it doesn't end with a digit, so it's a host domain name.
        {
            push @name_hosts, "'$host'";
        }
    }

    # Return SQL to select rows where the host IP or host name matches

    my $ip_sql = '';
    $ip_sql = $table . 'host_ip in (' . join(',', @ip_hosts) . ')'
                                                                if @ip_hosts;
    my $name_sql = '';
    $name_sql = $table . 'host in (' . join(',', @name_hosts) . ')'
                                                                if @name_hosts;
    my @sql_clauses = ();
    push @sql_clauses, $ip_sql if $ip_sql;
    push @sql_clauses, $name_sql if $name_sql;
    my $sql = ' and (' . join(' or ', @sql_clauses) . ')';
    return $sql;
}


=item api_stats()

Return a hashref with API stats including the request, remote IP and timestamp

=cut
sub api_stats
{
    my ($self) = @_;
    return { request     => $self->param('request'),
             remote_addr => $ENV{HTTP_REMOTE_ADDR},
             timestamp   => time() };
}

=item format()

Return the format (e.g. "xml") that's used to format the reports (see below)

=cut
sub format
{
    my ($self) = @_;
    return $self->param('format', 'xml');
}

=item format_reports($reports, $format)

Format the reports according to the format parameter

=cut
sub format_reports
{
    my ($self, $reports, $format) = @_;
    die "no reports!?" unless $reports;
    $format ||= $self->format();

    my $output;
    $output = $self->xml_reports($reports) if $format eq 'xml';
    $output = $self->csv_reports($reports) if $format eq 'csv';
    $output = $self->html_reports($reports) if $format eq 'html';
    $output = $self->json_reports($reports) if $format eq 'json';
    return $output;
}

=item xml_reports($reports)

Return a traffic path data structure formatted as XML

=cut
sub xml_reports
{
    my ($self, $reports) = @_;
    my $xml = new XML::Simple(RootName => 'api');
    my $out = $xml->XMLout($reports);
    $out =~ s/[^\x9\xA\xD\x20-\xD7FF\xE000-\xFFFD]//g; # no illegal XML chars!
    return '<?xml version="1.0" encoding="UTF-8"?>' . "\n\n$out";
}

=item csv_reports($reports)

Return a traffic path data structure formatted as CSV

=cut
sub csv_reports
{
    my ($self, $reports) = @_;
    my $csv = '';

    my $data = $reports->{site}{path}{data};
    foreach my $datum (@{$data})
    {
        # TODO
        my $field = $datum->{field}; $field =~ s/"/""/g;
        my $value = $datum->{value}; $value =~ s/"/""/g;
        $csv .= "\"$field\",\"$value\"\n";
    }

    return $csv;
}

=item html_reports($reports)

Return a traffic path data structure formatted as HTML

=cut
sub html_reports
{
    my ($self, $reports) = @_;
    my $html = '';

    # Append the table header

    $html .= "<table>\n";

    # Convert the report data to HTML

    my $data = $reports->{site}{path}{data};
    foreach my $datum (@{$data})
    {
        # TODO
        my $field = $datum->{field}; $field =~ s/&/&amp;/g;
        my $value = $datum->{value}; $value =~ s/&/&amp;/g;
        $html .= "<tr><td>$field</td><td>$value</td></tr>\n";
    }

    # Append the table footer

    $html .= "</table>\n";

    # Return the report output formatted as an HTML table

    return $html;
}

=item json_reports($reports)

Return a traffic path data structure formatted as JSON

=cut
sub json_reports
{
    my ($self, $reports) = @_;
    my $json = new JSON;
    return $json->encode($reports);
}

}1;

=back

=head1 DEPENDENCIES

CGI, Constants::General, Data::APIToken, Data::SiteAccount, Data::Site, XML::Simple, JSON

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
