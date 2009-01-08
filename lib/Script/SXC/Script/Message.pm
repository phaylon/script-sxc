package Script::SXC::Script::Message;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::CurriedHandles;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Object Maybe Undef CodeRef );
use IO::Handle;

use signatures;
use namespace::clean -except => 'meta';

has text => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has prefix => (
    is          => 'rw',
    isa         => Maybe[Str],
    builder     => 'default_prefix',
);

has filter => (
    is          => 'rw',
    isa         => Maybe[CodeRef],
);

has handle => (
    metaclass       => 'MooseX::CurriedHandles',
    is              => 'rw',
    isa             => 'IO::Handle',
    required        => 1,
    builder         => 'default_handle',
    curried_handles => {
        'print' => { 
            'print' => [
                sub ($self) { 
                    return sprintf "# %s%s\n", 
                      ( $self->prefix ? sprintf('%s: ', $self->prefix) : '' ), 
                      ( $self->filter
                        ? join("\n", map { $self->filter->($self, $_) } split /\n/, $self->text)
                        : $self->text );
                },
            ],
        },
    },
);

method default_prefix { 'Info' }

method default_handle { *STDOUT{IO} }

1;
