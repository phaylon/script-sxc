package Script::SXC::Script::Command;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object Bool );

#use aliased 'Script::SXC::Reader',                   'ReaderClass';
#use aliased 'Script::SXC::Compiler',                 'CompilerClass';
#use aliased 'Script::SXC::Script::Message',          'InfoMessage';
#use aliased 'Script::SXC::Script::Message::Warning', 'WarningMessage';

sub ReaderClass    { 
    Class::MOP::load_class('Script::SXC::Reader'); 
    return 'Script::SXC::Reader';
}
sub CompilerClass  { 
    Class::MOP::load_class('Script::SXC::Compiler'); 
    return 'Script::SXC::Compiler';
}
sub InfoMessage    { 
    Class::MOP::load_class('Script::SXC::Script::Message'); 
    return 'Script::SXC::Script::Message';
}
sub WarningMessage { 
    Class::MOP::load_class('Script::SXC::Script::Message::Warning'); 
    return 'Script::SXC::Script::Message::Warning';
}

use namespace::clean -except => 'meta';

extends 'MooseX::App::Cmd::Command';

has _reader => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    builder     => '_build_default_reader',
    lazy        => 1,
    handles     => {
        'build_stream' => 'build_stream',
    },
);

has _compiler => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    builder     => '_build_default_compiler',
    lazy        => 1,
    handles     => {
        'compile_tree'    => 'compile_tree',
        'top_environment' => 'top_environment',
    },
);

has force_firstclass_procedures => (
    is              => 'rw',
    isa             => Bool,
    default         => 0,
    documentation   => 'force the use of library-loaded firstclass procedures',
);

has optimize_tailcalls => (
    is              => 'rw',
    isa             => Bool,
    default         => 0,
    documentation   => 'activate tailcall optimization where possible',
);

has localize_exceptions => (
    is              => 'rw',
    isa             => Bool,
    default         => 0,
    documentation   => 'trap exceptions at apply level and localize them if necessary',
);


method _build_default_reader { ReaderClass->new }

method _build_default_compiler { 
    return CompilerClass->new(
        optimize_tailcalls          => $self->optimize_tailcalls,
        force_firstclass_procedures => $self->force_firstclass_procedures,
        localize_exceptions         => $self->localize_exceptions,
    );
}

method print_info (Str $message, Bool :$no_prefix?, CodeRef :$filter) { 
    InfoMessage->new(
        text => $message, 
      ( $no_prefix ? (prefix => undef) : () ),
        filter => $filter,
    )->print;
}

method print_warning (Str $warning) { WarningMessage->new(text => $warning)->print }

1;
