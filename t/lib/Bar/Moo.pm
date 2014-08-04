package Bar::Moo;

use Moo;
extends 'Foo::Moo';

has attr3 => (is=>'rw');

sub meth2 { 2002 }
sub meth3 { 2003 }

1;
