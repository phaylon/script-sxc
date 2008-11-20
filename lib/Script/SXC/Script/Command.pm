package Script::SXC::Script::Command;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object Bool );

use aliased 'Script::SXC::Reader',                   'ReaderClass';
use aliased 'Script::SXC::Compiler',                 'CompilerClass';
use aliased 'Script::SXC::Script::Message',          'InfoMessage';
use aliased 'Script::SXC::Script::Message::Warning', 'WarningMessage';

use namespace::clean -except => 'meta';

extends 'MooseX::App::Cmd::Command';

has _reader => (
    is          => 'rw',
    isa         => ReaderClass,
    required    => 1,
    builder     => '_build_default_reader',
    lazy        => 1,
    handles     => {
        'build_stream' => 'build_stream',
    },
);

has _compiler => (
    is          => 'rw',
    isa         => CompilerClass,
    required    => 1,
    builder     => '_build_default_compiler',
    lazy        => 1,
    handles     => {
        'compile_tree'    => 'compile_tree',
        'top_environment' => 'top_environment',
    },
);

has optimize_tailcalls => (
    is              => 'rw',
    isa             => Bool,
    default         => 0,
    documentation   => 'activate tailcall optimization where possible',
);

method _build_default_reader { ReaderClass->new }

method _build_default_compiler { CompilerClass->new(optimize_tailcalls => $self->optimize_tailcalls) }

method print_info (Str $message, Bool :$no_prefix?, CodeRef :$filter) { 
    InfoMessage->new(
        text => $message, 
      ( $no_prefix ? (prefix => undef) : () ),
        filter => $filter,
    )->print;
}

method print_warning (Str $warning) { WarningMessage->new(text => $warning)->print }

1;
