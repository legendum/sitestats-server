#!/usr/bin/env perl -w

use strict;

use Test::More tests => 12;
use Utils::Time;

is(Utils::Time->get_time('20080526', '00:00:00', 6), 1211738400, 'Midnight on 26/05/2008 in Mexico is epoch time 1211738400');
is((Utils::Time->get_time_range('20080526', 6))[0], 1211738400, '26/05/2008 in Mexico begins at epoch time 1211738400');
is((Utils::Time->get_time_range('20080526', 6))[1], 1211824800, '26/05/2008 in Mexico ends at epoch time 1211824800');
is(Utils::Time->get_date(1211738400, 6), 20080526, 'Epoch time 1211738400 in Mexico is 26/05/2008');
is(Utils::Time->get_date_time(1211738400, 6), '20080526 00:00:00', 'Epoch time 1211738400 in Mexico is 26/05/2008 at midnight');
is((Utils::Time->get_date_range('week', 1, 6, 1211738400))[0], '20080519', 'The week begins in Mexico on 20080519');
is((Utils::Time->get_date_range('week', 1, 6, 1211738400))[1], '20080525', 'The week ends in Mexico on 20080525');
is(Utils::Time->get_month_name(1), 'January', 'Month 1 is January');
is(Utils::Time->get_month_number('January'), 1, 'January is month 1');
is(Utils::Time->get_part_of_day(6, 1211738400), '0.0000', 'Epoch time 1211738400 is the beginning of the day in Mexico');
is(Utils::Time->get_day_of_week('20080526'), 1, '26/05/2008 is the 2nd day of the week');
is(Utils::Time->get_day_of_year('20080526'), 146, '26/05/2008 is the 146th day of the year');

__END__
