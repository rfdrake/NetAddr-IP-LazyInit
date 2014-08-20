use Test::More;
use NetAddr::IP::LazyInit;

# $Id: v4-split-bulk.t,v 1.1.1.1 2006/08/14 15:36:06 lem Exp $

my @addr = ( [ '10.0.0.0', 20, 32, 4096 ],
	     [ '10.0.0.0', 22, 32, 1024 ],
	     [ '10.0.0.0', 22, 24, 4 ],
	     [ '10.0.0.0', 22, 23, 2 ],
	     [ '10.0.0.0', 24, 32, 256 ],
	     [ '10.0.0.0', 19, 32, 8192 ],
	     [ '10.0.0.0', 24, 24, 1 ],
	     [ '10.0.0.0', 31, 32, 2 ]
	    );

plan tests => (scalar @addr);

for my $a (@addr) {
    my $ip = new NetAddr::IP::LazyInit $a->[0], $a->[1];
    my $r = $ip->splitref($a->[2]);

    is(@$r, $a->[3]);
}
