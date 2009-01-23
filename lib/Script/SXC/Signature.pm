package Script::SXC::Signature;
use Moose;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw( Str Object ArrayRef );

use Script::SXC::lazyload
    'Script::SXC::Exception::ParseError',
    'Script::SXC::Signature::Parameter',
    ['Script::SXC::Compiled::Value',             'CompiledValue'        ],
    ['Script::SXC::Compiled::Validation::Count', 'CompiledArgCountCheck'];

use constant ListClass     => 'Script::SXC::Tree::List';
use constant VariableClass => 'Script::SXC::Compiler::Environment::Variable';

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

has named_parameters => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Object],
    required    => 1,
    default     => sub { [] },
    lazy        => 1,
    provides    => {
        'count'     => 'named_parameter_count',
    },
);

method all_parameters {
    return @{ $self->fixed_parameters },
           @{ $self->named_parameters },
           $self->rest_parameter // ();
}

method required_parameter_count {
    return scalar grep { not $_->is_optional } @{ $self->fixed_parameters }, @{ $self->named_parameters };
}

method compile_validations (Object $compiler!, Object $env!) {
    my @validations;

    # calculate argument count boundaries
    my $min = $self->required_parameter_count;
    my $max = $self->rest_parameter ? undef : $self->fixed_parameter_count + ($self->named_parameter_count * 2);

    # argument count
    push @validations, CompiledArgCountCheck->new(min => $min)
        if $min;
    push @validations, CompiledArgCountCheck->new(max => $max)
        if defined $max;

    # general validations
    push @validations, map { @{ $_->compile_validations($compiler, $env) } } $self->all_parameters;
}

method D___compile_validations (Object $compiler!, Object $env!) {
    return [ 
        ( $self->fixed_parameter_count ? CompiledArgCountCheck->new(min => $self->fixed_parameter_count) : () ),
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

method _is_rest_indicator ($class: $item) {
    $item->isa('Script::SXC::Tree::Dot') or $item->isa('Script::SXC::Tree::Keyword') and $item->value eq 'rest';
}

method _is_optional_indicator ($class: $item) {
    $item->isa('Script::SXC::Tree::Keyword') and $item->value eq 'optional';
}

method _is_named_indicator ($class: $item) {
    $item->isa('Script::SXC::Tree::Keyword') and $item->value eq 'named';
}

method new_from_tree ($class: Object $item!, Object $compiler!, Object $env!) {

    # grab-all when symbol is given
    if ($item->isa('Script::SXC::Tree::Symbol') or $item->isa(VariableClass)) {
        return $class->new(rest_parameter => Parameter->new_from_tree($item, $compiler, $env));
    }

    # otherwise it has to be a list
    $item->throw_parse_error(invalid_signature_specification => 'Signature specification must be symbol or list')
        unless $item->isa('Script::SXC::Tree::List');

    # grab the lists contents
    my @sig_parts = @{ $item->contents };

    # walk the items and collect parameters
    my (@fixed_params, $rest, $is_optional, $is_named);
  SIGPART:
    while (my $sig_part = shift @sig_parts) {

        # if the optional flag is set, the following parameters will be optional
        if ($class->_is_optional_indicator($sig_part)) {

            $is_optional = 1;
            next SIGPART;
        }

        # if the named flag is set, the following parameters will be named
        if ($class->_is_named_indicator($sig_part)) {

            $is_named = 1;
            next SIGPART;
        }

        # if we encounter a dot, we found the rest specification
        if ($class->_is_rest_indicator($sig_part)) {

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
