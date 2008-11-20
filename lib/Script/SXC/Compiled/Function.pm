package Script::SXC::Compiled::Function;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object Bool );

use aliased 'Script::SXC::Compiled::Goto', 'CompiledGoto';

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::Scope';
with    'Script::SXC::TypeHinting';

has signature => (
    is              => 'rw',
    isa             => 'Script::SXC::Signature',
    required        => 1,
);

method build_default_typehint { 'code' }

override all_expressions => method {
    my @exprs = super;
    return @exprs;
};

override wrap_in_scope_frame => method (Str $body) {
    
    # wrap in 'sub' frame instead
    return "sub { $body }";
};

__PACKAGE__->meta->make_immutable;

1;
