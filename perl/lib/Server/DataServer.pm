#!/usr/bin/env perl

=head1 NAME

Server::DataServer - Provides access to data servers

=head1 VERSION

This document refers to version 1.1 of Server::DataServer, released Jul 07, 2015

=head1 DESCRIPTION

Server::DataServer provides access to data servers. It connects only when it
needs to execute an SQL statement, unless "connect()" is explicitly called
beforehand. The "connect()" function allows config names or hostnames to be
used to create connections, thus offering some flexibility. The default driver
is "mysql" but "ODBC" or "Sybase" may also be used to connect to MS SQL Server
databases. If you connect to MS SQL databases using "Sybase" as your DBD driver,
be sure to use "freetds" and write entries in the "/etc/freetds/freetds.config"
file like this:

[server1]
    host = server1.host1.org
    port = 1433
    tds version = 7.0

(the tabs are important)

=head2 Properties

=over 4

None

=back

=cut
package Server::DataServer;
$VERSION = "1.1";

use strict;
use DBI;
use Encode;
use Utils::Config;
{
    # Class constants

    use constant DEFAULT_BATCH_SIZE => 20; # for commits to MS SQL servers

    # Class static properties

    my $_Parsers = {
        mysql   => 'parse_for_mysql',
        odbc    => 'parse_for_odbc',
        sybase  => 'parse_for_sybase',
    };

=head2 Class Methods

=over 4

=item new($name_or_host)

Create a new Server::DataServer object using a config name or hostname

=cut
sub new
{
    my ($class, $name_or_host, $options) = @_;

    $options ||= {};
    my $data_config = Utils::Config->load('data_servers') or die 'no "data_servers.yaml" config file';
    my $config = $data_config->{$name_or_host} || {};
    my $self = {
        dbh         => undef,
        queries     => {},
        name        => $name_or_host,
        host        => $config->{host} || $name_or_host,
        timeout     => $config->{timeout} || $options->{timeout} || 0,
        driver      => $config->{driver},
        server      => $config->{server},
        username    => $config->{username},
        password    => $config->{password},
        database    => $config->{database},
        encoding    => $config->{encoding},
        ins_delayed => Utils::Config->is_true($config->{insert_delayed}),
        auto_commit => Utils::Config->is_true($config->{auto_commit}),
        batch_size  => $config->{batch_size} || DEFAULT_BATCH_SIZE,
        batch_count => 0,
    };

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item connect([$hostname])

Connect to a data server host, preferring config details over the hostname 

=cut
sub connect
{
    my ($self, $hostname) = @_;

    # Get this data server's config details

    my $host = $self->{host} || $hostname;
    my $driver = lc $self->{driver} || 'mysql';
    my $server = $self->{server} || undef;
    my $username = $self->{username} || $ENV{DB_USER};
    my $password = $self->{password} || $ENV{DB_PASSWORD};
    my $database = $self->{database} || $ENV{DB_DATABASE};
    my $auto_commit = $self->{auto_commit} || 0; 

    # Disconnect if we're already connected

    $self->disconnect() if $self->{dbh};

    # Create a new connection to MySQL or Sybase

    my $dbi = 'DBI:';
    $dbi .= "mysql:$database:$host" if $driver eq 'mysql';
    $dbi .= "Sybase:server=$server" if $driver eq 'sybase';
    $dbi .= "ODBC:$server" if $driver eq 'odbc';
    $self->{dbh} = DBI->connect($dbi,
                                $username,
                                $password,
                                { PrintError => 0,    # warn()
                                  RaiseError => 1,    # die()
                                  AutoCommit => $auto_commit,
                                });

    # Set a timeout for long lasting queries to stop the system from stalling

    $self->{dbh}{odbc_query_timeout} = $self->{timeout}
               if $driver eq 'odbc' && $self->{timeout};

    return $self->{dbh};
}

=item disconnect()

Disconnect from the connected data server

=cut
sub disconnect
{
    my ($self) = @_;

    # Commit any executed queries
 
    $self->{dbh}->commit() if $self->{dbh} && !$self->{auto_commit};

    # Finish the data server queries

    foreach my $query (values %{$self->{queries}})
    {
        $query->finish() if $query;
    }

    # Disconnect from the data server

    $self->{dbh}->disconnect() if $self->{dbh};
    $self->{dbh} = undef;
}

=item sql($sql, [@args])

Run SQL on the data server, with optional arguments

=cut
sub sql
{
    my ($self, $sql, @args) = @_;

    # Encode arguments if necessary

    @args = map { encode($self->{encoding}, $_) } @args if $self->{encoding};

    # Get the data server connection

    $self->connect() unless $self->{dbh};
    my $dbh = $self->{dbh} or die "no connection";
    my $driver = lc $self->{driver};

    # Prepare the data server query

    my $parser = $_Parsers->{$driver} or die "no SQL parser!";
    $sql = $self->$parser($sql, @args);
    my $query = $self->{queries}{$sql} ||= $dbh->prepare($sql);

    # Run the data server query

    $driver eq 'sybase' ? $query->execute() : $query->execute(@args);
    $dbh->commit() unless $self->{auto_commit}
                       or $self->{batch_count}++ % $self->{batch_size};
    delete $self->{queries}{$sql} if $driver eq 'sybase';
    return $query;
}

=item sql_cmd($sql)

Run SQL on the data server via the command line, *without* optional arguments

=cut
sub sql_cmd
{
    my ($self, $sql) = @_;
    my $user = $self->{username};
    my $pass = $self->{password};
    my $host = $self->{host};
    open (MYSQL, "|/usr/bin/mysql -u$user -p$pass -h$host");
    print MYSQL "$sql;\n";
    close MYSQL;
}

=item parse_for_mysql($sql)

Parse some SQL to use "insert delayed" if it is configured

=cut
sub parse_for_mysql
{
    my ($self, $sql) = @_;
    $sql =~ s/insert /insert delayed / if $self->{ins_delayed};
    return $sql;
}

=item parse_for_sybase($sql, [@args])

Parse some SQL to replace placeholders with the actual arguments

=cut
sub parse_for_sybase
{
    my ($self, $sql, @args) = @_;
    my $args = '';
    foreach my $arg (@args)
    {
        $args .= ',' if $args;
        $arg =~ s/'/''/g;
        $args .= "'$arg'";
    }
    $sql =~ s/\([\?,\s]+\)/($args)/;
    $sql =~ s/(from|into|update) (stats\d+)\./$1 $2.dbo./;
    return $sql;
}

=item parse_for_odbc($sql)

Parse some SQL for ODBC

=cut
sub parse_for_odbc
{
    my ($self, $sql) = @_;
    $sql =~ s/(from|into|update) (stats\d+)\./$1 $2.dbo./;
    return $sql;
}

=item DESTROY

Disconnect when the object is destroyed

=cut
sub DESTROY
{
    my ($self) = @_;
    $self->disconnect();
}

}1;

=back

=head1 DEPENDENCIES

DBI, Encode, Utils::Config

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
