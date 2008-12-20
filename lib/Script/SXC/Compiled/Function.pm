package Script::SXC::Compiled::Function;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object Bool ArrayRef );

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Goto', 'CompiledGoto'];

use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::Scope';
with    'Script::SXC::TypeHinting';

has signature => (
    is              => 'rw',
    isa             => 'Script::SXC::Signature',
    required        => 1,
#    handles         => {
#        'signature_validation_statements' => 'validation_statements',
#    },
);

has validations => (
    is              => 'rw',
    isa             => ArrayRef[Object],
    required        => 1,
    default         => sub { [] },
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

override build_post_definition_statements => method {
#    use Data::Dump qw(dump); warn dump $self;
    return @{ $self->validations };
};

__PACKAGE__->meta->make_immutable;

1;
