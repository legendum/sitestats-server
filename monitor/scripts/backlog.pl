#!/usr/bin/env perl

=head1 NAME

backlog - Check that the data files are not backlogged

=head1 DESCRIPTION

This program checks that there are not too many new data files in the
"/data/extractor" directory. This is a symptom of the "transformer.pl"
process running too slowly, because host names are not being resolved.

=cut

use strict;
use warnings;
use constant TOO_MANY_FILES_WAITING => 100;

my $return_code = 0;

my $dir = "$ENV{SERVER_HOME}/data/extractor";
opendir (DIR, $dir);
my $files = grep /\d+$/, readdir(DIR);
closedir DIR;

if ($files > TOO_MANY_FILES_WAITING)
{
    # Create an error message

	my $message = "Backlog was $files data files";

    # Remove large files

    system "find $dir -type f -size +50k | xargs rm -f";
    system "$ENV{SERVER_HOME}/bin/xserver -restart";

    # Recount the files

    opendir (DIR, $dir);
    $files = grep /\d+$/, readdir(DIR);
    closedir DIR;

	# Return an error

	print STDERR "$message - now it's $files data files\n";
	$return_code = 1;
}

exit $return_code;
__END__

=head1 DEPENDENCIES

None

=head1 AUTHOR

Kevin Hutchinson (kevin.hutchinson@legendum.com)

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
