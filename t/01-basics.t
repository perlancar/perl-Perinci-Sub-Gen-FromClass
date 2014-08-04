#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Perinci::Sub::Gen::FromClass qw(gen_func_from_class);
use Test::More 0.98;

my $res = gen_func_from_class(
    class   => 'Foo::Moo',
    type    => 'Moo',
    method  => 'meth1',

    summary => 'A summary',
    description => 'A description',

    install => 0,
);

is($res->[0], 200, "status");
is_deeply($res->[2]{meta}, {
    v => 1.1,
    summary => 'A summary',
    description => 'A description',
    args => {
        attr1 => { req=>1 },
        attr2 => { req=>0 },
    },
    result_naked => 1,
}, "meta");

DONE_TESTING:
done_testing;
