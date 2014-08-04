package Perinci::Sub::Gen::FromClass;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Monkey::Patch::Action qw(patch_package);
use Perinci::Sub::Gen;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(gen_func_from_class);

our %SPEC;

$SPEC{gen_func_from_class} = {
    v => 1.1,
    summary => 'Generate function from a class',
    description => <<'_',

`gen_func_from_class` will create a function and Rinci metadata from a
{Mo,Moo,Moose,Mouse} class. Given a class like this:

    package MyClass;
    use Moo;
    has attr1 => (is => 'ro', required=>1);
    has attr2 => (is => 'rw');
    sub meth1 { ... }
    sub meth2 { ... }
    1;

will create a function that does something like this (it will basically
instantiate a class, set its attributes, and call a method):

    MyClass->new(attr1=>..., attr2=>...)->meth1;

along with Rinci metadata like this:

    {
        v => 1.1,
        args => {
            attr1 => { req=>1, schema=>'any' },
            attr2 => { schema=>'any' },
        },
    }

It works by wrapping the `has` function provided by Mo* to get the list of
attributes. The attributes will become the generated function's arguments.

_
    args => {
        %Perinci::Sub::Gen::common_args,
        class => {
            summary => 'Class name, will be loaded with require() unless when '.
                '`load` is false',
            req => 1,
        },
        method => {
            summary => 'Method of class to call',
            req => 1,
            # XXX guess if not specified?
        },
        load => {
            summary => 'Whether to load the class',
            schema => 'bool',
            default => 1,
            req => 1,
        },
        method_args => {
            schema => 'array*',
        },
    },
    result => {
        summary => 'A hash containing generated function, metadata',
        schema => 'hash*',
    },
};
sub gen_func_from_class {
    my %args = @_;

    my $class  = $args{class} or return [400, "Please specify 'class'"];
    $class =~ /\A\w+(::\w+)*\z/ or
        return [400, "Invalid value for 'class', please use Foo::Bar ".
                    "syntax only"];
    my $method = $args{method} or return [400, "Please specify 'method'"];
    if ($arsg{load} // 1) {
        my $classp = $class;
        $classp =~ s!::!/!g; $classp .= ".pm";
        require $classp;
    }
    my $install = $args{install} // 1;
    my $fqname = $args{name};
    return [400, "Please specify 'name'"] unless $fqname || !$install;
    my @caller = caller();
    if ($fqname =~ /(.+)::(.+)/) {
        $package = $1;
        $uqname  = $2;
    } else {
        $package = $args{package} // $caller[0];
        $uqname  = $fqname;
        $fqname  = "$package\::$uqname";
    }

    my $handle;
    my %func_args;
    push @handles, patch_package(
        $class, 'has', 'wrap', sub {
            my $ctx = shift;
            my ($name, %clauses) = @_;
            $func_args{$name} = {
                req => $clauses{required} ? 1:0,
                # XXX schema
            };
            $ctx->{orig}->(@_);
        });

    my $meta = {
        v => 1.1,
        (summary => $args{summary}) x !!$args{summary},
        (description => $args{description}) x !!$args{description},
        args => \%func_args,
        result_naked => 1,
    };

    my $func = sub {
        no strict 'refs';
        my %func_args = @_;
        my $obj = $class->new(%func_args);
        my @meth_args;
        if ($args{method_args}) {
            @meth_args = @{ $args{method_args} };
        }
        $obj->$method->(@meth_args);
    };

    if ($install) {
        no strict 'refs';
        no warnings;
        #$log->tracef("Installing function as %s ...", $fqname);
        *{ $fqname } = $func;
        ${$package . "::SPEC"}{$uqname} = $func_meta;
    }

    return [200, "OK", {meta=>$meta, func=>$func}];
}

1;
# ABSTRACT: Generate function (and its Rinci metadata) from a class

=head1 SYNOPSIS

Given a Mo/Moo/Mouse/Moose class:

    package MyClass;
    use Moo;
    has attr1 => (is => 'ro', required=>1);
    has attr2 => (is => 'rw');
    sub do_this { ... }
    sub do_that { ... }
    1;

you can generate a function for it:

    use Perinci::Sub::Gen::FromClass qw(gen_func_from_class);
    gen_func_from_class(
        name   => 'do_this',

        class  => 'MyClass',
        method => 'do_this',
        method_args => [3, 4, 5], # optional
    );

then if you call this function:

    do_this(attr1=>1, attr2=>2);

it will do something like (instantiate class and call a method):

    MyClass->new(attr1=>1, attr2=>2)->do_this(3, 4, 5);


=head1 DESCRIPTION

Sometimes some module annoyingly only provides OO interface like:

 my $obj = Foo->new(arg1=>1, arg2=>2);
 $obj->some_action;

when it could very well just be:

 some_action(arg1=>1, arg2=>2);

This module helps you create that function from a class.


=head1 TODO

Get attributes from superclass (by trapping the C<extends> keyword or perhaps
look at C<@ISA> directly).

Translate C<isa> option in C<has> into argument schema.


=head1 SEE ALSO

L<Rinci>

=cut
