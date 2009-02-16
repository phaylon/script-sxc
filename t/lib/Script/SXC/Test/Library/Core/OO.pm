package Script::SXC::Test::Library::Core::OO;
use 5.010;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump       qw( pp );
use Class::Inspector;

use constant RuntimeKeyword => 'Script::SXC::Runtime::Keyword';
use constant RuntimeSymbol  => 'Script::SXC::Runtime::Symbol';

sub T100_class_of: Tests {
    my $self = shift;

    is $self->run('(class-of :foo)'), RuntimeKeyword, 'class-of returns correct class for keyword';
    is $self->run("(class-of 'foo)"), RuntimeSymbol, 'class-of returns correct class for symbol';
    is $self->run('(class-of "foo")'), undef, 'class-of returns undefined value on non-object';
}

my $ClassCounter = 1;

sub classname (*) {
    my ($class) = @_;
    return join '', $class, $ClassCounter++;
}

sub filename {
    my ($class) = @_;
    return Class::Inspector->filename($class);
}

sub T200_define_class: Tests {
    my $self = shift;

    my $class = classname Bar::Baz::A;

    is $self->run("(define-class $class)"), $class, 'define-class returns correct class name';
    ok $class->isa('Moose::Object'), 'define-class injected Moose::Object superclass';
    ok exists($INC{ filename $class }), 'define-class created %INC value for class';
}

sub T205_define_class_exports: Tests {
    my $self = shift;

    throws_ok { $self->run('(define x 23) (define-class Bar::Baz::B (exports x))') } 'Script::SXC::Exception::ParseError',
        'define-class throws parse error on exports option';
    like $@, qr/exports/, 'error message contains "exports"';
    is $@->type, 'invalid_class_option', 'parse error has correct type';
}

sub T210_define_class_version: Tests {
    my $self = shift;

    my $class = classname Bar::Baz::C;

    $self->run("(define-class $class (version 0.23))");
    is $class->VERSION, 0.23, 'define-class accepts and uses version option';
}

sub T215_define_class_extends: Tests {
    my $self = shift;

    my $parent = classname Bar::Baz::D::Parent;
    my $child  = classname Bar::Baz::D::Child;

    lives_ok { $self->run("(define-class $parent) (define-class $child (extends '$parent))") }
        'define-class with extends option lives';
    ok $child->isa($parent), 'defined child class inherits from defined parent class';
    ok $child->isa('Moose::Object'), 'child class inherits from Moose::Object';
    ok $parent->isa('Moose::Object'), 'parent class inherits from Moose::Object';
}

sub T220_define_class_method: Tests {
    my $self = shift;

    {   my $class = classname Bar::Baz::E;

        lives_ok { $self->run(qq#
            (define-class $class
              (method foo (n) (++ n))
              (method bar (n) (foo: self (* 2 n))))
        #) } 'define-class with method definitions lives';

        can_ok $class, qw( foo bar );
        is $class->foo(23), 24, 'first method works correctly';
        is $class->bar(23), 47, 'method calling other method works correctly';
    }

    {   my $class = classname Bar::Baz::F;

        lives_ok { $self->run(qq#
            (define-class $class
              (method invocant () self)
              (method all_args ls ls))
        #) } 'empty signature and list signature compile';

        my $obj = $class->new;

        is $obj->invocant, $obj, 'invocant set to correct instance';
        is_deeply $obj->all_args(23), [23], 'argument list is without invocant';
    }
}

1;
