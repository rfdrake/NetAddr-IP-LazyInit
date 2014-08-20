# t/old-store.t - test backwards compatible Storable interaction

use Test::More;

my $tests = 7;

plan tests => $tests;

SKIP:
{
    skip "Failed to use Storable, module not found", $tests
	unless eval { require Storable && use_ok("Storable", 'freeze', 'thaw')};

    skip "Failed to use NetAddr::IP::LazyInit", $tests
	unless use_ok("NetAddr::IP::LazyInit", ':old_storable');

    my $oip = new NetAddr::IP::LazyInit "localhost";
    my $nip;

    isa_ok($oip, 'NetAddr::IP::LazyInit', 'Correct return type');

    my $serialized;

    eval { $serialized = freeze($oip) };
    unless (ok(!$@, "Freezing"))
    {
	diag $@;
    }

#    diag "Result is '$serialized'";

    eval { $nip = thaw($serialized) };
    unless (ok(!$@, "Thawing"))
    {
	diag $@;
    }

    isa_ok($nip, 'NetAddr::IP::LazyInit', 'Recovered correct type');
    is("$nip", "$oip", "New object eq original object");
}
