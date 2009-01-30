package Script::SXC::Test::Library::Core::Reserved;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( dump );

sub T590_reserved_symbols: Tests {
    my $self = shift;

    # dot
    throws_ok { $self->run('(let ((x 23) (y 12)) (list x .))') } 'Script::SXC::Exception::ParseError',
        'dot symbol in variable definition throws parse error';
    like $@, qr/dot/i, 'error message contains "dot"';
    like $@, qr/reserved/i, 'error message contains "reserved"';

    throws_ok { $self->run('(let ((x 23) (. 12)) (list x))') } 'Script::SXC::Exception::ParseError',
        'dot symbol in variable access throws parse error';
    like $@, qr/dot/i, 'error message contains "dot"';
    like $@, qr/reserved/i, 'error message contains "reserved"';
}

1;
