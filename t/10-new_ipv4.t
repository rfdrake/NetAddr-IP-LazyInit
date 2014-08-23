use Test::More;
use strict;
use warnings;
use lib './lib';

use NetAddr::IP::LazyInit;

my $ip = NetAddr::IP::LazyInit->new_ipv4( '10.10.10.5' );
my $ipmask = NetAddr::IP::LazyInit->new_ipv4_mask( '10.10.10.5', '255.255.255.0' );

is($ipmask->mask, '255.255.255.0', 'netmask');
is($ipmask->addr, '10.10.10.5', 'address for ipmask');
is($ip->addr, '10.10.10.5', 'address for ip');

done_testing();
