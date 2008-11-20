package Script::SXC::Signature;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Str Object ArrayRef );

use aliased 'Script::SXC::Exception::ParseError';
use aliased 'Script::SXC::Signature::Parameter';
use aliased 'Script::SXC::Compiled::Value',       'CompiledValue';

use namespace::clean -except => 'meta';

has fixed_parameters => (
    is          => 'rw',
    isa         => ArrayRef[Object],
    required    => 1,
    default     => sub { [] },
    lazy        => 1,
);

has rest_parameter => (
    is          => 'rw',
    isa         => Object,
    handles     => {
        'rest_parameter_name'   => 'name',
    },
);

method as_definition_map {

    # return an arrayref with (str)name/(compiled)expr pairs
    return [ 

        # fixed parameters
        ( map { [$_->name, CompiledValue->new(content => 'shift(@_)')] } @{ $self->fixed_parameters } ),

        # a rest parameter, if present
        ( $self->rest_parameter ? [$self->rest_parameter_name, CompiledValue->new(content => '[@_]')] : () ),
    ];
};

method new_from_tree ($class: Object $item) {

    # grab-all when symbol is given
    if ($item->isa('Script::SXC::Tree::Symbol')) {
        return $class->new(rest_parameter => Parameter->new_from_tree($item));
    }

    # otherwise it has to be a list
    ParseError->throw(
        type                => 'invalid_signature_specification',
        message             => 'Signature specification must be symbol or list',
        source_description  => $item->source_description,
        line_number         => $item->source_line_number,
    ) unless $item->isa('Script::SXC::Tree::List');

    # grab the lists contents
    my @sig_parts = @{ $item->contents };

    # walk the items and collect parameters
    my (@fixed_params, $rest);
  SIGPART:
    while (my $sig_part = shift @sig_parts) {

        # if we encounter a dot, we found the rest specification
        if ($sig_part->isa('Script::SXC::Tree::Dot')) {

            # bark if there are too many rest parameters
            ParseError->throw(
                type                => 'invalid_lambda_signature',
                message             => 'Too many rest parameters specified',
                source_description  => $item->source_description,
                line_number         => $item->source_line_number,
            ) if @sig_parts > 1;

            # bark if there is no rest parameter
            ParseError->throw(
                type                => 'invalid_lambda_signature',
                message             => 'Expected rest parameter specification',
                source_description  => $item->source_description,
                line_number         => $item->source_line_number,
            ) if @sig_parts < 1;

            # store rest and end cycle
            $rest = Parameter->new_from_tree(shift @sig_parts);

            # not needed, since list now empty, but it documents in-flow rather nicely
            last SIGPART;       
        }

        # this is a fixed parameter
        push @fixed_params, Parameter->new_from_tree($sig_part);
    }

    # construct object from found parameters
    my $self = $class->new(fixed_parameters => \@fixed_params);
    $self->rest_parameter($rest) if $rest;

    # construction finished
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
