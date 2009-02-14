package Script::SXC::Test::Library::Core::Packages;
use 5.010;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump       qw( pp );
use Sub::Information;
use Class::Unload;

sub T100_define_package: Tests {
    my $self = shift;

    is $self->run('(define-package Foo::Bar::A)'), 'Foo::Bar::A', 'define-package has correct return value';
    ok exists($INC{'Foo/Bar/A.pm'}), 'define-package created %INC entry';

    throws_ok { $self->run('(define-package :Foo)') } 'Script::SXC::Exception::ParseError',
        'trying to use a keyword instead of a string or symbol as package name throws parse error';
    like $@, qr/define-package/, 'error message contains "define-package"';
    like $@, qr/string/i, 'error message contains "string"';
    like $@, qr/symbol/i, 'error message contains "symbol"';
}

sub T105_define_package_version: Tests {
    my $self = shift;

    is $self->run('(define V 1.01) (define-package Foo::Bar::B (version V))'), 'Foo::Bar::B',
        'correct return value with version';
    is Foo::Bar::B->VERSION, 1.01, 'define-package created correct version in package';

    is $self->run('(define-package Foo::Bar::C (version "1.02"))'), 'Foo::Bar::C', 
        'correct return value with string version';
    is Foo::Bar::C->VERSION, 1.02, 'define-package created correct string version in package';
}

my $PackageCounter = 1;

sub T110_define_package_exports: Tests {
    my $self = shift;

    $self->run(q#
        (define foo 23)
        (define (bar n) (* n n))
        (define-package Foo::Bar::D
          (exports 'foo 'bar))
    #);

    my $package = 'Foo::Bar::D::Consumer' . $PackageCounter++;
    diag "creating test package $package";
    eval qq#
        package ${package};
        Foo::Bar::D->import(qw( foo bar ));
    #;

    is ref(my $foo = $package->can('foo')), 'CODE', 'constant value was exported';
    is ref(my $bar = $package->can('bar')), 'CODE', 'function value was exported';

    given (inspect $foo) {
        is $_->name, 'foo', 'constant subroutine name is correct';
        is $_->package, 'Foo::Bar::D', 'constant subroutine package is correct';
    };

    given (inspect $bar) {
        is $_->name, 'bar', 'function name is correct';
        is $_->package, 'Foo::Bar::D', 'function package is correct';
    }

    is $foo->(), 23, 'constant value is correct';
    is $bar->(3), 9, 'function return value is correct';

    is prototype($foo), '', 'constant value export has () prototype';
    is prototype($bar), undef, 'function export has empty prototype';

    throws_ok { $self->run('(define-package Foo::Bar::E (exports 23))') } 'Script::SXC::Exception',
        'trying to export something else than a symbol throws exception';
    like $@, qr/export/i, 'error message contains "export"';
    like $@, qr/symbol/i, 'error message contains "symbol"';

    throws_ok { $self->run('(define-package Foo::Bar::F (exports `xyz))') } 'Script::SXC::Exception',
        'trying to export an unknown symbol throws exception';
    like $@, qr/export/i, 'error message contains "export"';
    like $@, qr/xyz/, 'error message contains invalid symbol name';
}

sub T200_require: Tests {
    my $self    = shift;
    my $package = 'Script::SXC::Test::Package';
    
    dies_ok { $package->is_loaded } 'package not yet loaded';
    lives_ok { $self->run('(define foo "Script::SXC::Test::Package") (require foo)') } 'runtime require does not die';
    ok $package->is_loaded, 'package is loaded after runtime require';
    Class::Unload->unload($package);
}

1;
