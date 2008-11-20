package Script::SXC::Signature::Parameter;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Bool Str );

use aliased 'Script::SXC::Exception::ParseError';

use namespace::clean -except => 'meta';

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has is_named => (
    is          => 'rw',
    isa         => Bool,
);

method new_from_tree ($class: Object $item) {

    # we have been given just a symbol
    if ($item->isa('Script::SXC::Tree::Symbol')) {

        # we just have the name
        return $class->new(name => $item->value);
    }

    # it must be a list if it's not a symbol
    ParseError->throw(
        type                => 'invalid_parameter_specification',
        message             => 'Parameter specification must be symbol or list',
        source_description  => $item->source_description,
        line_number         => $item->source_line_number,
    ) unless $item->isa('Script::SXC::Tree::List');

    my ($name_symbol, @spec) = @{ $item->contents };
    die "NYI!";
}

__PACKAGE__->meta->make_immutable;

1;
