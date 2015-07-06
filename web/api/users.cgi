#!/usr/bin/env perl

use strict;

BEGIN {
    $ENV{HOME} ||= '/usr/local/deploy/cloud/projects';
    $ENV{SERVER_HOME} ||= $ENV{HOME} . '/sitestats-server';
    $ENV{CONFIG_DIR}="$ENV{SERVER_HOME}/config";
}

use lib "$ENV{SERVER_HOME}/perl/lib";
use Utils::Env; Utils::Env->setup();
use CGI qw/:cgi -debug/;
use Data::APIToken;
use Data::SiteAccount;
use Client::Users;

# Return an error message to the user

sub error
{
    my $message = shift;
    print "Content-type: text/plain\n\nERROR: $message\n";
    exit;
}

# Get the query parameters

my $cgi = new CGI;
my %params = $cgi->Vars;
my $format = lc($params{format}) || 'xml';
my $site_id = $params{site}+0 or error "no 'site' query parameter";
my $channel = $params{channel};
my $token_text = $params{token} or error "no 'token' query parameter";
my $request = $params{request} || '';
my $callback = $params{callback} || '';

# Store the remote host address

$ENV{HTTP_REMOTE_ADDR} = $cgi->remote_host();

# Wrap the code in an eval to catch errors

eval {

# Connect to the database

Data::APIToken->connect();
Data::SiteAccount->connect();

# Select the API token

my $token = Data::APIToken->select('token_text = ?', $token_text);
my $account_id = $token->{account_id} or error "no token found with ID '$token_text'";

# Check the token call

my $error = $token->call();
error "sorry, cannot call token '$token_text': $error" if $error;

# Get the site account

my $site_account = Data::SiteAccount->select('site_id = ? and account_id = ?', $site_id, $account_id);
$site_account->{can_read} eq 'yes' or error "token '$token_text' does not have permission to read reports for site id '$site_id'";

# Get the report

my $users = Client::Users->new($site_id);
my $output = $users->generate( channel => $channel,
                               format  => $format,
                               request => $request );

# Disconnect from the database

Data::APIToken->disconnect();
Data::SiteAccount->disconnect();

# Finally, write the channels

$output = "$callback($output)" if $callback && $format eq 'json';
$format = 'javascript' if $format eq 'json';
print "Content-type: text/$format\n\n$output";

}; # End of the eval block
error $@ if $@;

__END__

=head1 DEPENDENCIES

Data::APIToken, Data::SiteAccount, Client::Users

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
