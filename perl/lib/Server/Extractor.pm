#!/usr/bin/env perl

=head1 NAME

Server::Extractor - read web server log files and add channel IDs from page URLs

=head1 VERSION

This document refers to version 1.2 of Server::Extractor, released Jul 07, 2015

=head1 DESCRIPTION

Server::Extractor reads web server log files and adds channel IDs from page URLs

=head2 Properties

=over 4

None

=back

=cut
package File::Tail;
sub getline
{
    my $self = shift;
    return $self->read();
}

package Server::Extractor;
$VERSION = "1.2";

use strict;
use base 'Server::FileFinder';
use Constants::General;
use Data::Site;
use Data::SiteChannel;
use Data::SiteConfig;
use FileHandle;
use File::Tail;
use Utils::LogFile;
use Encode;
{
    # Class static properties

    use constant TAIL_SECS => 1;    # How often to check the tailed file
    use constant WRITE_SECS => 5;   # How often to write the output file
    use constant RESET_SECS => 10;  # How often to look for a new file
    use constant FILE_RECON => 20;  # Reconnect every few written files
    use constant FILE_DURN => 1800; # 30 mins (see /etc/apache2/apache2.conf)
    use constant SEG_START => 200;  # start of "segment" channels

=head2 Class Methods

=over 4

=item new($source_dir, $sink_dir)

Create a new Extractor object

=cut
sub new
{
    my ($class, $source_dir, $sink_dir) = @_;
    $source_dir ||= "$ENV{DATA_DIR}/apache";
    $sink_dir ||= "$ENV{DATA_DIR}/extractor";
    die "$source_dir is not a directory" unless -d $source_dir;
    die "$sink_dir is not a directory" unless -d $sink_dir;

    my $self = $class->SUPER::new($source_dir, '\.\d+$');
    $self->{last_time} = 0;
    $self->{files} = 0;
    $self->{sites} = {};
    $self->{configs} = {};
    $self->{sink_dir} = $sink_dir;
    $self->{log_file} = Utils::LogFile->new("$ENV{LOGS_DIR}/extractor");
    $self->{log_file}->alert("Created");

    bless $self, $class;
}

=back

=head2 Object Methods

=item begin_files($source_dir)

Connect to the master database

=cut
sub begin_files
{
    my ($self, $source_dir) = @_;

    Data::Site->connect();
    Data::SiteChannel->connect();
    Data::SiteConfig->connect();
    $self->{sites} = undef;
    $self->{configs} = undef;
}

=item found_file($directory, $filename)

Read a web server log file

=cut
sub found_file
{
    my ($self, $directory, $filename) = @_;
    my $now = time();

    # Don't begin from the first file in the Apache files directory

    $self->{last_time} ||= $now - FILE_DURN;

    # Return if the file is old and it's not being "tailed"

    my ($name, $time) = ($1, $2) if $filename =~ /^(.*)\.(\d+)$/;
    my $is_tail = $time > $now - FILE_DURN; # Only "tail" the most recent file
    return if $time <= $self->{last_time} && !$is_tail;
    $self->{log_file}->alert("Reading $filename");
    my $last_filename = $filename;

    # Parse the web server log file

    my $name_changes = sub { return "$directory/$name." . (int(time() / FILE_DURN) * FILE_DURN) };
    my $fh_i = $is_tail ? File::Tail->new(name => "$directory/$filename",
                                          name_changes => $name_changes,
                                          maxinterval => TAIL_SECS,
                                          resetafter => RESET_SECS) :
                          FileHandle->new("$directory/$filename", 'r');
    my $sink_dir = $self->{sink_dir};
    my $fh_o = FileHandle->new("$sink_dir/extractor", 'w');
    my $parsed_lines = 0;
    my $read_lines = 0;
    my $file_lines = 0;
    my $start_time = $now;

    # Use an "eval" block in case the File::Tail module barfs at inactivity

    eval
    {
        while (my $line = $fh_i->getline())
        {
            # Only parse event lines

            if ($line =~ s/^event://)
            {
                if (my $parsed_line = $self->parse($line))
                {
                    $fh_o->print("event:$parsed_line\n");
                    $parsed_lines++;
                }
                $read_lines++;
                $file_lines++;
            }

            # If we're tailing, then write every few seconds

            my $now = time();
            if ($is_tail && $now > $start_time + WRITE_SECS)
            {
                # Save the file and reset the counters

                $self->{log_file}->debug("Parsed $parsed_lines of $read_lines Apache event lines");
                $fh_o->close();
                rename "$sink_dir/extractor", "$sink_dir/$name.$now";
                $fh_o = FileHandle->new("$sink_dir/extractor", 'w');
                $parsed_lines = $read_lines = 0;
                $start_time = $now;

                # Log the current file if it's changed

                $filename = "$name." . (int($now / FILE_DURN) * FILE_DURN);
                if ($filename ne $last_filename)
                {
                    $self->{log_file}->info("File contained $file_lines Apache event lines");
                    $file_lines = 0;
                    $self->{log_file}->alert("Reading $filename");
                    $last_filename = $filename;
                }

                # Reconnect to the database every few files

                $self->reconnect();
            }
        }
    };

    # Log any error from the File::Tail module

    $self->{log_file}->error($@) if $@;

    # The loop only exits if we're reading a regular file, not using File::Tail

    $self->{log_file}->debug("Parsed $parsed_lines of $read_lines Apache event lines");

    # Close and rename the output file

    $fh_o->close();
    rename "$sink_dir/extractor", "$sink_dir/$filename";

    # Remember the last time so we don't reread the same Apache log file

    $self->{last_time} = $time;
}

=item reconnect()

Reconnect to the database after writing a number of files

=cut
sub reconnect
{
    my ($self, $source_dir) = @_;

    $self->{files}++;
    if ($self->{files} % FILE_RECON == 0)
    {
        $self->{log_file}->info("Reconnecting to database after writing $self->{files} files");
        $self->end_files();
        $self->begin_files();
    }
}

=item end_files($source_dir)

Disconnect from the master database

=cut
sub end_files
{
    my ($self, $source_dir) = @_;

    Data::Site->disconnect();
    Data::SiteChannel->disconnect();
    Data::SiteConfig->disconnect();
}

=item parse($line)

Parse a web server log file line

=cut
sub parse
{
    my ($self, $line) = @_;

    # Encode the line of data with the default encoding

    chomp $line;
    $line =~ s/\\x([a-fA-F0-9]{2})/pack("C",hex($1))/eg;
    $line = encode(Constants::General::DEFAULT_ENCODING, $line);
    $line =~ s/%([a-fA-F0-9]{2})/pack("C",hex($1))/eg;

    # Extract the field/value pairs and get the site ID

    my %fields;
    map {$fields{$1} = $2 if /^(\w{2})=(.*)/} (split /\|/, $line);
    my $site_id = $fields{si};

    # Check that the web site exists & is not suspended

    my $site = $self->{sites}{$site_id} ||= Data::Site->row($site_id);
    return '' if !$site->{status} or $site->{status} eq 'S' or $site->{product_code} eq 'A'; # Alerts
    my $config = $self->{configs}{$site_id} ||= Data::SiteConfig->get($site_id);
    my $campaign = Data::SiteConfig->find($config, 'campaign') || 'campaign';
    my $webfilter = Data::SiteConfig->find($config, 'webfilter');
    my $webreplace = Data::SiteConfig->find($config, 'webreplace');
    my $ip2country = lc Data::SiteConfig->find($config, 'ip2country') eq 'yes';

    eval
    {
        # Remove domain from local pages and apply any page filter

        my $event_type = $fields{et} || '';
        if ($event_type =~ /^(page|exit|file)$/)
        {
            my $event_name = $fields{en} || '';
            $event_name =~ s#(https?://)(www\.)?$site->{url}/?##i;
            $event_name =~ s#$webfilter#$webreplace#g if $webfilter;
            $event_name ||= Constants::General::HOME_PAGE;
            $fields{en} = $event_name;

            # Append a channel ID to the site ID (unless it's set)

            if ($site_id !~ m#/#)
            {
                my $event_desc = $fields{ed} || '';
                my $channel_id = $self->page2channel($site_id, $event_name, $event_desc);
                $site_id .= "/$channel_id" if $channel_id;
                $fields{si} = $site_id;
            }

            # Extract any campaign from the event name

            if (!$fields{ca} && $event_name =~ /$campaign=([^&]+)/)
            {
                $fields{ca} = $1;
            }
        }

        # Strip self-referrals when the visit is starting (i.e. has user agent)

        $fields{re} ||= '';
        $fields{re} = '' if $fields{re} =~ /$site->{url}/i && $fields{ua};

        # Remove the site's domain from page-to-page referrals

        $fields{re} =~ s#^(https?://)?(www\.)?$site->{url}/?##i;

        # Add the data server for the site

        $fields{ds} = $site->{data_server}
            or die "No data server for site $site_id";

        # Add a field to indicate daylight saving time

        $fields{tz} = $site->is_daylight_saving();

        # Add a field to indicate to only use the IP to detect the Country

        $fields{ic} = $ip2country;
    };

    # Log any errors so they can be picked up by the system monitor

    $self->{log_file}->error($@) if $@;

    # Return the modified web server log line

    $line = '';
    while (my ($key, $value) = each %fields)
    {
        $line .= "$key=$value|";
    }
    chop $line and return $line;
}

=item page2channel($site_id, $page_url, $page_title)

Translate a page into a channel ID number for a web site

=cut
sub page2channel
{
    my ($self, $site_id, $page_url, $page_title) = @_;

    # Find the first channel that matches the page

    $self->{sites}{$site_id}{channels} ||= $self->channels($site_id);
    foreach my $channel (@{$self->{sites}{$site_id}{channels}})
    {
        return $channel->{channel_id} if $channel->is_page_match($page_url, $page_title);
    }

    # No channel matches this page

    return 0;
}

=item channels($site_id)

Get a list of channels for a web site

=cut
sub channels
{
    my ($self, $site_id) = @_;

    my $sql = 'site_id = ? order by parent_id desc';
    my @channels = ();
    for (my $channel = Data::SiteChannel->select($sql, $site_id);
        $channel->{site_channel_id};
        $channel = Data::SiteChannel->next($sql))
    {
        push @channels, $channel if $channel->{channel_id} < SEG_START;
    }

    return \@channels;
}

=item DESTROY

Log the death of the object

=cut
sub DESTROY
{
    my ($self) = @_;
    $self->{log_file}->alert("Destroyed");
}

}1;

=back

=head1 DEPENDENCIES

Constants::General, Data::Site, Data::SiteChannel, Data::SiteConfig, Server::FileFinder, FileHandle, File::Tail, Utils::LogFile, Encode

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
