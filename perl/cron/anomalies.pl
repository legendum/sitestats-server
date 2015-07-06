#!/usr/bin/env perl

use strict;

use constant HITS_LIMIT => 10; # page views
use constant MAIL_SENDER => 'Site Stats Support <support@sitestats.com>';

use lib "$ENV{SERVER_HOME}/perl/lib";
use Data::Account;
use Data::SiteAccount;
use Data::Site;
use Data::SiteStats;
use Data::Reseller;
use Utils::Time;
use MIME::Lite;

my $days_ago = shift || 1;
my $week_start = Utils::Time->get_date(time() - ($days_ago + Utils::Time::WEEK_DAYS) * Utils::Time::DAY_SECS);
my $week_end = Utils::Time->get_date(time() - $days_ago * Utils::Time::DAY_SECS);

# Get all the reseller contact details

my %resellers = ();
Data::Reseller->connect();
for (my $reseller = Data::Reseller->select();
        $reseller->{reseller_id};
        $reseller = Data::Reseller->next())
{
    my $reseller_id = $reseller->{reseller_id};
    $resellers{$reseller_id} = $reseller;
}
Data::Reseller->disconnect();

# Get a list of sites whose reports are computed by this server

my $comp_server = $ENV{HOSTNAME};
my $query = "comp_server = ? and status in ('T', 'L')";
my @sites = ();
Data::Site->connect();
for (my $site = Data::Site->select($query, $comp_server);
        $site->{site_id};
        $site = Data::Site->next($query))
{
    push @sites, $site;
}
Data::Site->disconnect();

# Check the web traffic for any anomalies

Data::Account->connect();
Data::SiteAccount->connect();
Data::SiteStats->connect();
foreach my $site (@sites)
{
    # Check the web site's traffic

    my $query = "site_id = ? and the_date between $week_start and $week_end and period = 'day' order by the_date";
    my @hit_parade = ();
    for (my $site_stats = Data::SiteStats->select($query, $site->{site_id});
            $site_stats->{site_stats_id};
            $site_stats = Data::SiteStats->next($query))
    {
        push @hit_parade, $site_stats->{hits};
    }

    my $week_ago = $hit_parade[0];
    my $yesterday = $hit_parade[-1];
    my $day_before = $hit_parade[-2];
    if ($week_ago > HITS_LIMIT && ($yesterday + $day_before) < HITS_LIMIT)
    {
        # Get the site's account details

        my $site_account = Data::SiteAccount->select('site_id = ?', $site->{site_id});
        my $account = Data::Account->select('account_id = ?', $site_account->{account_id});

        # Compose a message to the reseller

        my $reseller = $resellers{$site->{reseller_id}};
        my $subject = "Site $site->{url} has no traffic";
        my $message = <<End_Of_Message;
Dear $reseller->{contact}

Regarding your $reseller->{brand} service:
Site $site->{url} (ID $site->{site_id}) had no traffic during the past 2 days.
User $account->{realname} <$account->{email}> is the primary contact.

Possible reasons for this are:
1) The web tracking HTML code might have been removed from their web pages
2) Their web traffic database might have suffered from some data corruption
3) Their web site domain name might have become unavailable or redirected
4) Their web site might have received no traffic during the past 2 days

Please reply to this email with details if you require some customer support.

Kind regards

Kevin Hutchinson
Site Stats Manager
End_Of_Message

        # Send the message

        print "Mailing $reseller->{email}: $subject\n";
        my $mail = MIME::Lite->new( From => MAIL_SENDER,
                                    Cc => MAIL_SENDER,
                                    To => $reseller->{email},
                                    Subject => $subject,
                                    Data => $message );
        $mail->send();
    }
}
Data::Account->disconnect();
Data::SiteAccount->disconnect();
Data::SiteStats->disconnect();

__END__

=head1 DEPENDENCIES

Data::Account, Data::SiteAccount, Data::Site, Data::SiteStats, Data::Reseller, Utils::Time, MIME::Lite

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
