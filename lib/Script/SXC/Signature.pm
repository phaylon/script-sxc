package Script::SXC::Signature;
use Moose;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw( Str Object ArrayRef );

use aliased 'Script::SXC::Exception::ParseError';
use aliased 'Script::SXC::Signature::Parameter';
use aliased 'Script::SXC::Compiled::Value',             'CompiledValue';
use aliased 'Script::SXC::Compiled::Validation::Count', 'CompiledArgCountCheck';

use namespace::clean -except => 'meta';

has fixed_parameters => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Object],
    required    => 1,
    default     => sub { [] },
    lazy        => 1,
    provides    => {
        'count'     => 'fixed_parameter_count',
    },
);

has rest_parameter => (
    is          => 'rw',
    isa         => Object,
    handles     => {
        'rest_parameter_name'   => 'name',
        'rest_parameter_symbol' => 'symbol',
    },
);

method compile_validations (Object $compiler!, Object $env!) {
    return [ 
        CompiledArgCountCheck->new(min => $self->fixed_parameter_count),
        ( $self->rest_parameter ? () : CompiledArgCountCheck->new(max => $self->fixed_parameter_count) ),
        ( map { @{ $_->compile_validations($compiler, $env) } } @{ $self->fixed_parameters } ),
        ( $self->rest_parameter
          ? @{ $self->rest_parameter->compile_validations($compiler, $env, rest_container => 1) }
          : () 
        ),
    ];
}

method as_definition_map {
    my $arg_index = 0;

    # return an arrayref with (str)name/(compiled)expr pairs
    return [ 

        # fixed parameters
        ( map { [
            $_->symbol, 
            CompiledValue->new(content => sprintf('$_[%d]', $arg_index++)),
        ] } @{ $self->fixed_parameters } ),

        # a rest parameter, if present
        ( $self->rest_parameter ? [
            $self->rest_parameter_symbol, 
            CompiledValue->new(content => sprintf('[@_[%d .. $#_]]', $arg_index)),
        ] : () ),
    ];
};

method new_from_tree ($class: Object $item!, Object $compiler!, Object $env!) {

    # grab-all when symbol is given
    if ($item->isa('Script::SXC::Tree::Symbol') or $item->isa('Script::SXC::Compiler::Environment::Variable::Internal')) {
        return $class->new(rest_parameter => Parameter->new_from_tree($item, $compiler, $env));
    }

    # otherwise it has to be a list
    $item->throw_parse_error(invalid_signature_specification => 'Signature specification must be symbol or list')
        unless $item->isa('Script::SXC::Tree::List');

    # grab the lists contents
    my @sig_parts = @{ $item->contents };

    # walk the items and collect parameters
    my (@fixed_params, $rest);
  SIGPART:
    while (my $sig_part = shift @sig_parts) {

        # if we encounter a dot, we found the rest specification
        if ($sig_part->isa('Script::SXC::Tree::Dot')) {

            # bark if there are too many rest parameters
            $item->throw_parse_error(invalid_signature => 'Too many rest parameters specified')
                if @sig_parts > 1;

            # bark if there is no rest parameter
            $item->throw_parse_error(invalid_signature => 'Expected rest parameter specification')
                if @sig_parts < 1;

            # store rest and end cycle
            $rest = Parameter->new_from_tree(shift(@sig_parts), $compiler, $env);

            # not needed, since list now empty, but it documents in-flow rather nicely
            last SIGPART;       
        }

        # this is a fixed parameter
        push @fixed_params, Parameter->new_from_tree($sig_part, $compiler, $env);
    }

    # construct object from found parameters
    my $self = $class->new(fixed_parameters => \@fixed_params);
    $self->rest_parameter($rest) if $rest;

    # construction finished
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
