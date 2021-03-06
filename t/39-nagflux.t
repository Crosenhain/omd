#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Sys::Hostname;

BEGIN {
    use lib('t');
    require TestUtils;
    import TestUtils;
    use FindBin;
    use lib "$FindBin::Bin/lib/lib/perl5";
}

plan( tests => 39 );

##################################################
# create our test site
my $omd_bin = TestUtils::get_omd_bin();
my $site    = TestUtils::create_test_site() or TestUtils::bail_out_clean("no further testing without site");
my $curl    = '/usr/bin/curl --user root:root';

TestUtils::test_command({ cmd => $omd_bin." config $site set INFLUXDB on" });
TestUtils::test_command({ cmd => $omd_bin." config $site set PNP4NAGIOS off" });
TestUtils::test_command({ cmd => $omd_bin." config $site set NAGFLUX on" });
TestUtils::test_command({ cmd => $omd_bin." config $site set CORE nagios" });
TestUtils::test_command({ cmd => $omd_bin." start $site", like => '/Starting Nagflux\.+OK/' });

print STDERR "Give Nagflux some time to come up...\n";
sleep(70);

my $ranges = "<<END
DATATYPE::SERVICEPERFDATA	TIMET::1441791000	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791001	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;2;10	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791002	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;2;10;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791003	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;2:4;8:10;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791004	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;\@2:4;\@8:10;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791005	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;2:;10:;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791006	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;:2;:10;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1
DATATYPE::SERVICEPERFDATA	TIMET::1441791007	HOSTNAME::xxx	SERVICEDESC::range	SERVICEPERFDATA::a used=4;~:2;10:~;1;4	SERVICECHECKCOMMAND::check_ranges!-w 3: -c 4: -g :46 -l :48 SERVICESTATE::0	SERVICESTATETYPE::1

END
";

#Mock Nagios and write spoolfiles
TestUtils::test_command({ cmd => "/bin/su - $site -c 'cat > var/pnp4nagios/spool/ranges $ranges'"});

#Test if database is up
TestUtils::test_command({ cmd => "/bin/su - $site -c 'lib/nagios/plugins/check_http -t 60 -H localhost -p 8086 -u \"/query\" -P \"q=SHOW%20DATABASES\" -a \"omdadmin:omd\" -s \"nagflux\" '", like => '/HTTP OK:/' });

#Give Nagflux some time to read the spoolfiles
print STDERR "Give Nagflux some time to read files...\n";
sleep(10);

#Search for inserted data
TestUtils::test_command({ cmd => "/bin/su - $site -c 'lib/nagios/plugins/check_http -t 60 -H localhost -p 8086 -u \"/query?db=nagflux&q=SELECT%20COUNT(*)%20FROM%20metrics%20WHERE%20host%3D%27xxx%27%20AND%20service%3D%27range%27%20AND%20performanceLabel%3D%27a%20used%27\" -a \"omdadmin:omd\" -s\"{\\\"results\\\":[{\\\"series\\\":[{\\\"name\\\":\\\"metrics\\\",\\\"columns\\\":[\\\"time\\\",\\\"count_crit\\\",\\\"count_crit-max\\\",\\\"count_crit-min\\\",\\\"count_max\\\",\\\"count_min\\\",\\\"count_value\\\",\\\"count_warn\\\",\\\"count_warn-max\\\",\\\"count_warn-min\\\"],\\\"values\\\":[[\\\"1970-01-01T00:00:00Z\\\",5,2,2,6,6,8,5,2,2]]}]}]}\" '", like => '/HTTP OK:/' });

#Clean up
TestUtils::test_command({ cmd => $omd_bin." stop $site" });
TestUtils::remove_test_site($site);

