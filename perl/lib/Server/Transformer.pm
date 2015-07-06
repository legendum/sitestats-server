#!/usr/bin/env perl

=head1 NAME

Server::Transformer - Tranform web activity files to load data into data servers

=head1 VERSION

This document refers to version 2.0 of Server::Transformer released Jul 07, 2015

=head1 DESCRIPTION

Server::Transformer transforms web activity files to load data into data servers

=head2 Properties

=over 4

None

=back

=cut
package Server::Transformer;
$VERSION = "2.0";

use strict;
use base 'Server::FileFinder';
use FileHandle;
use Utils::Transforms;
use IO::Socket;
use Utils::Config;
use Server::DataServer;
use Utils::LogFile;
{
    # Class static properties

    use constant CLEAN_FREQUENCY => 1000; # lines
    use constant TOO_LONG_TO_WAIT => 2; # seconds

=head2 Class Methods

=over 4

=item new($source_dir)

Create a new Server::Transformer object

=cut
sub new
{
    my ($class, $source_dir) = @_;
    $source_dir ||= "$ENV{DATA_DIR}/extractor";
    die "$source_dir is not a directory" unless -d $source_dir;

    my $self = $class->SUPER::new($source_dir, '\.\d+$');
    $self->{counter}      = 0;
    $self->{transforms}   = Utils::Transforms->new();
    $self->{data_servers} = {};
    $self->{log_file}     = Utils::LogFile->new("$ENV{LOGS_DIR}/transformer");
    $self->{log_file}->alert("Created");

    bless $self, $class;
}

=back

=head2 Object Methods

=over 4

=item begin_files($directory)

Reset out logging counters

=cut
sub begin_files
{
    my ($self, $directory) = @_;
    $self->{parsed} = 0;
    $self->{stored} = 0;
    $self->{events} = 0;
    $self->{visits} = 0;
}

=item found_file($directory, $filename)

Read a web activity file

=cut
sub found_file
{
    my ($self, $directory, $filename) = @_;

    $self->{log_file}->info("Reading $filename");

    # Read the web activity file

    my $fh = FileHandle->new("$directory/$filename", 'r');
    while (my $line = $fh->getline())
    {
        eval
        {
            if ($line =~ s/^event:/\|/)
            {
                # Parse the line to store it in a database on a data server

                $line = $self->hostname_lookup($line) if $line =~ /\|fl=/;
                $self->parse($line);
            }
        };
        $self->{log_file}->error("Parse error: $@") if $@;
    }

    # Delete the web activity file

    unlink "$directory/$filename";
}

=item end_files($directory)

All extracted files have been read

=cut
sub end_files
{
    my ($self, $directory) = @_;

    # Disconnect from all the connected data servers

    foreach my $ds (values %{$self->{data_servers}})
    {
        $ds->disconnect();
    }
    $self->{data_servers} = {};

    # Log the number of lines parsed and stored

    $self->{log_file}->debug("Parsed $self->{parsed} lines and stored $self->{stored} rows ($self->{events} events and $self->{visits} visits)") if $self->{parsed};
}

=item hostname_lookup($line)

Lookup the host IP to get the hostname and add it to the line as a "ho" field

=cut
sub hostname_lookup
{
    my ($self, $line) = @_;

    if ($line =~ /\|ip=([\d\.]+)/)
    {
        my $host_ip = $1;
        my $host = '';
        if (my $secs = $ENV{HOSTNAME_SECS})
        {
            eval
            {
                local $SIG{ALRM} = sub { die "timeout"; };
                alarm($secs);
                my $addr = inet_aton($host_ip);
                $host = (gethostbyaddr($addr, 2))[0] || '' if $addr;

                # Add the host to the line and reset the alarm

                $line = "ho=$host$line";
                alarm(0);
            };
            alarm(0);
        }
    }

    return $line;
}

=item parse($line)

Parse a line of web activity data and store it in a data server

=cut
sub parse
{
    my ($self, $line) = @_;

    # Clean the transform lookup hashes to reduce memory usage

    $self->{transforms}->clean() unless $self->{counter}++ % CLEAN_FREQUENCY;

    # Prepare the data string

    chomp $line;
    $line =~ tr/+/ /;       # translate any URL spaces found
    $line =~ s/(\\x|%)([a-fA-F0-9]{2})/pack("C",hex($2))/eg;
    $line =~ s/[\r\n]/ /g;  # remove any newline chars found

    # Get the line as a hash

    my %fields;
    map {$fields{$1} = $2 if /^(\w{2})=(.*)/} (split /\|/, $line);

    # Get connection details

    my $data_server = $fields{ds} or return; # Can't load data without a server
    my $site_id     = $fields{si} or return; # Can't load data without a site;
    my $channel_id  = 0; $channel_id = $1 if $site_id =~ s#/(\d+)##;
    my $database    = "stats$site_id"; # TODO: Replace with $site->database()

    # Get the various fields

    my $host_ip = $fields{ip};
    my $host = $fields{ho} || ''; # Field populated by a hostname lookup
    my $time = $fields{tm};
    my $type = $fields{et} || '';
    my $name = $fields{en} || '';
    my $class = $fields{ec} || '';
    my $msecs = $fields{lt} || 0;
    if (!$type)
    {
        $type = $1 if $name =~ /^(\w+):(.*)/; # Get type from name
        $name = $2 if $self->{transforms}->event_type_id($type);
    }
    my $visit_id    = $fields{vi};
    my $user_id     = $fields{ui};
    my $global_id   = $fields{gi};
    my $cookies     = $fields{co};
    my $flash       = $fields{fl};
    my $java        = $fields{ja};
    my $javascript  = $fields{js};
    my $language    = $fields{la};
    my $tz_offset   = $fields{tz}; # 1 for daylight saving time, 0 otherwise
    my $clock_time  = $fields{ct}; # browser clock time formatted as HH:MM:SS
    my $color_bits  = $fields{cb};
    my $resolution  = $fields{sr}; # width x height, for example "1280x800"
    my $user_agent  = $fields{ua};
    my $campaign    = $fields{ca} || '';
    my $refer_id    = $fields{ri} || '';
    my $referrer    = $fields{re} || ''; $referrer =~ s#^https?://##;
    my $description = $fields{ed} || '';
    my $ip2country  = $fields{ic} || 0;

    # Get the real visit ID from the host IP unless cookies are accepted

    my $real_visit_id = ($cookies eq 'yes' ? $visit_id : $self->{transforms}->host2id($site_id, $host_ip, $time, $visit_id));

    if ($type eq 'user')
    {
        my $data = $self->{transforms}->user_data($name);
        foreach my $field (keys %{$data})
        {
            my $value = $data->{$field} || '';

            # Send any user data to the data server

            my $attrs = {
                user_id => $user_id,
                visit_id => $real_visit_id,
                global_id => $global_id,
                field => $field,
                value => $value,
            };
            $self->sql($data_server,
                       $self->get_insert_statement($database, 'User', $attrs),
                       values %{$attrs});
        }
    }
    else
    {
        # Convert the type to ID

        my $type_id = $self->{transforms}->event_type_id($type) || 0;

        # Send the event to the data server

        my $attrs = {
            channel_id => $channel_id,
            type_id => $type_id,
            user_id => $user_id,
            visit_id => $real_visit_id,
            time => $time,
            name => $self->truncate('name', $name),
        };
        $attrs->{class} = $class if $class;
        $attrs->{msecs} = $msecs if $msecs;
        $attrs->{refer_id} = $refer_id if $refer_id;
        $attrs->{referrer} = $self->truncate('referrer', $referrer)
                             if $referrer;
        $attrs->{description} = $self->truncate('description', $description)
                                if $description;
        $self->sql($data_server,
                   $self->get_insert_statement($database, 'Event', $attrs),
                   values %{$attrs}); $self->{events}++;
    }

    # Only visits have Flash data so return if we don't have it

    $self->{parsed}++;
    return unless $flash;
    $flash =~ s/\.//; # remove "." from "10.0"
    $flash = $self->truncate('flash', $flash);

    # Store the visit

    if ($real_visit_id == $visit_id)
    {
        $host_ip =~ s/,.*//;

        # Get the browser and op sys

        my ($browser, $op_sys) = $self->{transforms}->computer($user_agent);

        # Get the country, language and time zone

        my $hour = ($clock_time =~ /^(\d+):/ ? $1 : 0) - $tz_offset;
        my $geo = { language => $language };
        eval
        {
            $self->{geoip_semaphore}->down() if $self->{geoip_semaphore};
            $geo = $self->{transforms}->geo($host_ip, $language, $hour, $time, $ip2country);
            $self->{geoip_semaphore}->up() if $self->{geoip_semaphore};
        };
        $self->{log_file}->error("GeoIP error: $@") if $@;

        # Get the referrer and any search phrase

        my $search;
        ($referrer, $search) = $self->{transforms}->referrer($referrer, $language);

        # Send the visit to the data server

        my $attrs = {
            visit_id => $real_visit_id,
            user_id => $user_id,
            global_id => $global_id,
            time => $time,
            cookies => 'yes',
            flash => $flash,
            java => $java,
            javascript => $javascript,
            user_agent => $self->truncate('user_agent', $user_agent),
            browser => $self->truncate('browser', $browser),
            city => $geo->{city},
            region => $geo->{region},
            country => $geo->{country},
            language => $geo->{language},
            netspeed => $geo->{netspeed},
            latitude => $geo->{latitude},
            longitude => $geo->{longitude},
            color_bits => $color_bits,
            resolution => $resolution,
            op_sys => $self->truncate('op_sys', $op_sys),
            host_ip => $host_ip,
            host => $host,
            campaign => $self->truncate('campaign', $campaign),
            referrer => $self->truncate('referrer', $referrer),
            search => $self->truncate('search', $search),
        };
        $attrs->{time_zone} = $geo->{time_zone} if $clock_time;
        $self->sql($data_server,
                   $self->get_insert_statement($database, 'Visit', $attrs),
                   values %{$attrs}); $self->{visits}++;
    }
    elsif ($self->{transforms}->is_new_cookie_refuser($real_visit_id))
    {
        $self->sql($data_server, "update stats$site_id.Visit set cookies = 'no' where visit_id = ?", $real_visit_id);
    }
}

=item truncate($field, $value)

Truncate a field value if it is longer than the maximum field length

=cut
sub truncate
{
    my ($self, $field, $value) = @_;
    my $lengths = $self->{field_lengths} ||= Utils::Config->load('field_lengths') or die 'no "field_lengths" config file';
    my $length = $lengths->{$field} or return $value; # if no maximum length
    return length($value) > $length ? substr($value, 0, $length) : $value;
}

=item sql($data_server_list, $sql, @args)

Run some SQL on a dataserver, with optional arguments

=cut
sub sql
{
    my ($self, $data_server_list, $sql, @args) = @_;

    foreach my $data_server (split /[,\s]+/, $data_server_list)
    {
        my $secs = $ENV{SQL_LOAD_SECS} || 0;
        my $start_time = time();
        eval
        {
            # Commented out on 12 Jan 2010 by Kevin Hutchinson

            #local $SIG{ALRM} = sub { die "timeout"; };
            #alarm($secs);
            my $ds = $self->{data_servers}{$data_server} ||= Server::DataServer->new($data_server, { timeout => $secs } );
            $ds->sql($sql, @args);
            #alarm(0);
        };
        #alarm(0);
        delete $self->{data_servers}{$data_server} if $@ && $@ =~ /server has gone away/ || $@ =~ /link failure/;
        $self->{log_file}->error("$data_server: $@\nSQL: $sql\nData: " . join(', ', @args)) if $@;
        $secs = time() - $start_time;
        $self->{log_file}->warn("$data_server took $secs seconds to process SQL: $sql") if $secs >= TOO_LONG_TO_WAIT;
        $self->{stored}++ unless $@ or $sql =~ /^update /i;
    }
}

=item get_insert_statement($database, $table, $hash_ref)

Get an SQL insert statement for a field/value hash on a database table

=cut
sub get_insert_statement
{
    my ($self, $database, $table, $hash_ref) = @_;

    my $fields = join ",", keys %{$hash_ref};
    my $values = join ",", ('?') x (scalar keys %{$hash_ref});
    my $sql = "insert into $database.$table ($fields) values ($values)";
    return $sql;
}

=item DESTROY

Close data server connections and log the death of the object

=cut
sub DESTROY
{
    my ($self) = @_;

    # Disconnect from all the connected data servers

    foreach my $ds (values %{$self->{data_servers}})
    {
        $ds->disconnect();
    }

    # Write a message to the log

    $self->{log_file}->alert("Destroyed");
}

}1;

=back

=head1 DEPENDENCIES

Server::FileFinder, FileHandle, Utils::Transforms, IO::Socket, Utils::Config, Server::DataServer, Utils::LogFile

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
