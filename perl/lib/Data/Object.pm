#!/usr/bin/env perl

=head1 NAME

Data::Object - Store Perl objects in a MySql (or Oracle) database

=head1 VERSION

This document refers to version 1.2 of Data::Object, released Jul 07, 2015.
Download Data::Object.pm from http://www.legendum.com/perl/Data::Object.pm

=head1 SYNOPSIS

First create a table Foo in a MySql database Bar:

    create table Foo
    (
        id        INTEGER UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name        VARCHAR(255) NOT NULL,
        email        VARCHAR(255),
        telephone    VARCHAR(255),
        timestamp    TIMESTAMP
    );

Then create a Perl program to access table Foo in database Bar as objects:

    package Foo;
    @ISA = qw(Data::Object);
    use Data::Object;

    package main;
    Foo->connect(database=>'Bar', user=>'fred', password=>'bloggs');
    Foo->fields( qw(id name email telephone) );
    my $foo = Foo->new(name=>'kev', email=>'kev@frontierworld.com');
    $foo->insert();
    $foo->{telephone} = '+44 207 359 0985';
    $foo->update();
    $foo = Foo->select('name=?', 'kev');
    print $foo->{name} . ' has email address ' . $foo->{email} . '\n';
    $foo->delete();
    Foo->disconnect();

=head1 DESCRIPTION

Data::Object stores objects in a database. It should be inherited by a class
wishing to persist its objects in the database. The inheriting class should
correspond to a table of the same name (case-sensitive) in the database. This
table must have an auto_increment column as its primary key.

Data::Object provides database connectivity via connect() and disconnect(),
object creation via methods new(), select() and next(), and object/database
syncronisation via methods insert(), update() and delete().

Data::Object does not check whether objects were modified in the database while
they were being modified in your Perl program. Nor does it support any locking
mechanisms. Basically it's designed to be fast, simple, easy and predictable.

To use Data::Object with an Oracle database, set the ORACLE_HOME database
environment variable. When using Oracle on Sun Solaris, you should also set the
LD_PRELOAD to "/lib/libthread.so.1" to enable thread support. When you connect,
you should add "driver=>'Oracle'" to the argument list. When setting and getting
object field values, use the Data::Object AUTOLOAD method because Oracle fields
have uppercase names. For example, to set blah to be 2, use "$obj->blah(2)".

=cut
package Data::Object;
$VERSION = "1.2";

use strict;
use Carp;
use DBI;
{
    # Class static references to hashes keyed by class/table name

    my $_Connections = {};  # Database connections, keyed by class
    my $_Drivers = {};      # Database drivers, keyed by class
    my $_Cache = {};        # Database connection cache, keyed by database

    my $_IdField = {};      # Primary key for uniquely identifying objects
    my $_Fields  = {};      # Fields to be syncronised with the database
    my $_Queries = {};      # User-defined queries for select() and next()

    my $_Selects = {};      # Standard select queries for row()
    my $_Inserts = {};      # Standard insert queries for insert()/update()
    my $_Updates = {};      # Standard update queries for update()
    my $_Deletes = {};      # Standard delete queries for delete()

    # Error messages

    my $_ERROR_FIELDS = "call class static method fields() first";

=head2 Class Methods

=over 4

=item connect(driver=>'mysql', host=>'localhost', database=>'dbname', user=>'username', password=>'pass', print_error=>0, raise_error=>1, fields=>[qw(id_field fields1 field2 field3)])

Connect to the database with optional connection details, and return the DBI
connection. The database driver always defaults to "mysql" unless environment
variable $DRIVER has been set. The database, user and password will default
to environment variables $DATABASE, $USER and $PASSWORD. If a field list is
not supplied, then a separate call to fields() must be made after connecting.

=cut
sub connect
{
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    # Get the connection details

    my $driver      = $args{driver}      || $ENV{DRIVER} || 'mysql';
    my $server      = $args{server}      || $ENV{SERVER} || 'unknown';
    my $host        = $args{host}        || $ENV{HOST}   || 'localhost';
    my $database    = $args{database}    || $ENV{DB_DATABASE};
    my $user        = $args{user}        || $ENV{DB_USER};
    my $password    = $args{password}    || $ENV{DB_PASSWORD};
    my $print_error = $args{print_error} || $ENV{PRINT_ERROR} || 0;
    my $raise_error = $args{raise_error} || $ENV{RAISE_ERROR} || 1;

    # Connect to the database using cached connections

    my $dbi = "DBI:$driver:";
    $dbi .= "$database:$host" if $driver =~ /mysql/i;
    $dbi .= "server=$server" if $driver =~ /sybase/i;
    $dbi .= "host=$host;sid=$database" if $driver =~ /oracle/i;

    my $uid = "$dbi:$user";
    $_Cache->{$uid} ||= DBI->connect( $dbi,
                                      $user,
                                      $password,
                                      { PrintError => $print_error, # warn()
                                        RaiseError => $raise_error, # die()
                                      } );

    $_Connections->{$class} = $_Cache->{$uid};
    $_Drivers->{$class} = $driver;

    # Create standard queries for the database fields

    $class->fields(@{ $args{fields} }) if $args{fields};

    # Return the database connection

    return $_Connections->{$class}
            or croak("cannot connect to database: $DBI::errstr");
}

=item disconnect()

Disconnect from the database cleanly. You must call disconnect() before calling
connect() for a second time, otherwise connect() will merely return a handle to
the current database connection.

=cut
sub disconnect
{
    my ($self) = @_;
    my $class = ref($self) || $self;
    return unless $_Connections->{$class};

    # Finish user-defined queries

    foreach my $query (keys %{ $_Queries->{$class} })
    {
        $_Queries->{$class}->{$query}->finish();
    }
    delete $_Queries->{$class};

    # Finish standard queries

    $_Selects->{$class}->finish();
    $_Deletes->{$class}->finish();
    $_Inserts->{$class}->finish();
    $_Updates->{$class}->finish();

    # Close the database connection and disconnect if it's the last one

    delete $_Connections->{$class};

    my $connected = 0;
    foreach my $class (keys %{$_Connections})
    {
        $connected++ if $_Connections->{$class};
    }

    if (!$connected)
    {
        foreach my $uid (keys %{$_Cache})
        {
            $_Cache->{$uid}->disconnect() if $_Cache->{$uid};
            delete $_Cache->{$uid};
        }
    }
}

=item fields('id_field', 'field1', 'field2', ...)

Setup a list of fields to keep in sync with the database. The first field
should be the "id" field followed by the fields that you want to keep
syncronised with the database. Call fields() immediately after calling
connect() if you didn't provide a field list when you called connect().
Use an id field name of "null" if there is no auto increment id field.

=cut
sub fields
{
    my ($self, @fields) = @_;
    my $class = ref($self) || $self;
    @fields = map { uc($_) } @fields if $_Drivers->{$class} =~ /oracle/i;

    my $id_field = shift @fields;
    $_IdField->{$class} = $id_field;
    $_Fields->{$class} = [@fields];

    my $dbh = $_Connections->{$class} || $class->connect();
    my $table = $class; $table = $1 if $table =~ /::(\w+)$/;

    # Prepare standard queries

    $_Selects->{$class} = $dbh->prepare("select * from $table where $id_field = ?");
    $_Deletes->{$class} = $dbh->prepare("delete from $table where $id_field = ?");

    my $field_list = "";
    my $value_list = "";
    my $update_list = "";
    foreach my $field (@fields)
    {
        $field_list .= ", " if $field_list;
        $field_list .= $field;

        $value_list .= ", " if $value_list;
        $value_list .= "?";

        $update_list .= ", " if $update_list;
        $update_list .= "$field = ?";
    }

    $_Inserts->{$class} = $dbh->prepare("insert into $table ($field_list) values ($value_list)");
    $_Updates->{$class} = $dbh->prepare("update $table set $update_list where $id_field = ?");
}

=item <fieldname>('value')

Get/set an object's field value in a driver independent manner.

=cut
sub AUTOLOAD
{
    my ($self, $value) = @_;
    my $class = ref($self);

    no strict;
    my $field = $1 if $AUTOLOAD =~ /::(\w+)$/;
    use strict;
    return if $field eq "DESTROY";

    $field = uc($field) if $_Drivers->{$class} =~ /oracle/i;
    $self->{$field} = $value if defined($value);
    return $self->{$field};
}

=item new(field1=>'value1', field2=>'value2', ...)

Create a new object, setting any field values that were passed. This call does
not store the new object in the database - you should call insert() or update().

=cut
sub new
{
    my ($self, %args) = @_;
    my $class = ref($self) || $self;
    bless { %args }, $class;
}

=item row(id)

Get a table row as an object, by requesting a specific id. This is very useful
when one table has a relationship with another table, implemented via foreign
keys, and you wish to get the related object.

=cut
sub row
{
    my ($self, $id) = @_;
    my $class = ref($self) || $self;
    $_Fields->{$class} or croak($_ERROR_FIELDS);

    # Get an object with a specific id from the database

    $_Selects->{$class}->execute($id);
    $self = $_Selects->{$class}->fetchrow_hashref() || {};

    bless $self, $class;
}

=item sql('select * from table where field=?', 'value')

Create and execute a parameterised SQL statement. The format of the conditions
and arguments is similar to "printf", in that a "?" is used as a placeholder
for a corresponding argument. For example, if you use three question marks, you
should provide three arguments to instantiate them. Returns the query created.

=cut
sub sql
{
    my ($self, $sql, @args) = @_;
    my $class = ref($self) || $self;
    $_Fields->{$class} or croak($_ERROR_FIELDS);

    # Create a user-defined query unless it's cached

    my $dbh = $_Connections->{$class};
    $_Queries->{$class}->{$sql} ||= $dbh->prepare($sql);

    # Execute the query

    my $query = $_Queries->{$class}->{$sql};
    $query->execute(@args);

    return $query;
}

=item select('field=?', 'value')

Select the first object matching some conditions. The format of the conditions
and arguments is similar to "printf", in that a "?" is used as a placeholder
for a corresponding argument. For example, if you use three question marks, you
should provide three arguments to instantiate them. Use next() to iterate.

=cut
sub select
{
    my ($self, $conditions, @args) = @_;
    my $class = ref($self) || $self;
    $_Fields->{$class} or croak($_ERROR_FIELDS);
    $conditions ||= "1=1";

    # Create a new object by executing the query

    my $table = $class; $table = $1 if $table =~ /::(\w+)$/;
    my $query = $class->sql("select * from $table where $conditions", @args);
    $self = $query->fetchrow_hashref() || {};

    bless $self, $class;
}

=item next('field=?')

Select the next object matching some conditions. The conditions must exactly
match those originally provided in a select() call. When next() cannot return
the next object, it returns an empty object. A typical use for select() and
next() is in a for loop like this:

    my $obj;
    for ( $obj = Class->select("field=?",value);
          $obj->{id_field};
          $obj = Class->next("field=?"))
    {
        # Do something with $obj
    }

=cut
sub next
{
    my ($self, $conditions) = @_;
    my $class = ref($self) || $self;
    $_Fields->{$class} or croak($_ERROR_FIELDS);
    $conditions ||= "1=1";

    # Get the next object from a user-defined query

    my $table = $class; $table = $1 if $table =~ /::(\w+)$/;
    my $sql = "select * from $table where $conditions";
    my $query = $_Queries->{$class}->{$sql}
        or croak("select query not definied for $class: $conditions");

    $self = $query->fetchrow_hashref() || {};

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item insert()

Insert an object into the database and give the object a new id.

=cut
sub insert
{
    my ($self) = @_;
    my $class = ref($self);
    my $id_field = $_IdField->{$class};
    $self->{$id_field} = undef;
    $self->update();
}

=item update()

Update an object in the database, or insert it if the object has no id.

=cut
sub update
{
    my ($self) = @_;
    my $class = ref($self);
    $_Fields->{$class} or croak($_ERROR_FIELDS);

    # Get any object properties that are field values

    my @args = ();
    foreach my $field (@{ $_Fields->{$class} })
    {
        push @args, $self->{$field};
    }

    my $id_field = $_IdField->{$class};
    if ($self->{$id_field})
    {
        # Update the object in the database

        push @args, $self->{$id_field};
        $_Updates->{$class}->execute(@args);
    }
    else
    {
        # Insert the object into the database

        $_Inserts->{$class}->execute(@args);
        $self->{$id_field} = $_Inserts->{$class}->{mysql_insertid};
    }
}

=item delete()

Delete an object from the database.

=cut
sub delete
{
    my ($self) = @_;
    my $class = ref($self);
    my $id_field = $_IdField->{$class};
    return unless $self->{$id_field};
    $_Fields->{$class} or croak($_ERROR_FIELDS);

    # Delete an object from the database and give it an undefined id

    $_Deletes->{$class}->execute($self->{$id_field});
    $self->{$id_field} = undef;
}

=item matching($where_clause)

Return a lis of objects that match a "where clause"

=cut
sub matching
{
    my ($self, $clause) = @_;
    my $class = ref($self) || $self;
    my @objects;
    $class->connect();
    my $id_field = $_IdField->{$class};
    for (my $object = $class->select($clause);
            $object->{$id_field};
            $object = $class->next($clause))
    {
        push @objects, $object;
    }
    $class->disconnect();
    return @objects;
}

}1;

=back

=head1 DEPENDENCIES

DBI

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
