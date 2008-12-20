package Script::SXC::Signature::Parameter;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Bool Str Object );

use Perl6::Junction qw( any );
use Perl6::Gather;

use Script::SXC::lazyload
    'Script::SXC::Exception::ParseError',
    ['Script::SXC::Compiled::Validation::Where', 'WhereClause'];

use constant VariableClass => 'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

has where_clause => (
    is          => 'rw',
    isa         => Object,
    handles     => {
        'compile_where_clause' => 'compile',
    },
);

has symbol => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'name'      => 'value',
    },
);

method compile_validations (Object $compiler!, Object $env!, Bool :$rest_container?) {
    my @validations;

    #warn "PARAM " . $self->name . "\n";

    if ($self->where_clause) {
        #warn "WHERE\n";
        push @validations, WhereClause->new(
            expression  => $self->compile_where_clause($compiler, $env),
            symbol      => $self->symbol,
        );
    }

    #use Data::Dump qw(dump); warn dump \@validations;
    return \@validations;
}

method new_from_tree ($class: Object $item!, Object $compiler!, Object $env!) {

    # we have been given just a symbol
    if ($item->isa('Script::SXC::Tree::Symbol') or $item->isa(VariableClass)) {

        # we just have the name
        return $class->new(symbol => $item);
    }

    # it must be a list if it's not a symbol
    $item->throw_parse_error(invalid_parameter_specification => 'Parameter specification must be symbol or list')
        unless $item->isa('Script::SXC::Tree::List');

    # split up
    $item->throw_parse_error(missing_parameter_name => 'Missing parameter name in specification')
        unless $item->content_count;
    my ($name_symbol, @spec) = @{ $item->contents }; 

    # the name must be a symbol
    $name_symbol->throw_parse_error(invalid_parameter_name => 'Invalid parameter name: Only symbols allowed')
        unless $name_symbol->isa('Script::SXC::Tree::Symbol');

    # drill up options
    my %attrs = (symbol => $name_symbol);
    while (my $key = shift @spec) {

        # key needs to be a keyword
        $key->throw_parse_error(invalid_parameter_options => 'Invalid parameter options: Option names must be keywords')
            unless $key->isa('Script::SXC::Tree::Keyword');

        # only a finite set of options is allowed
        my $method = sprintf 'prepare_%s_clause_expression', $key->value;
        $key->throw_parse_error(invalid_parameter_option_name => 'Invalid parameter option name: ' . $key->value)
            unless $class->can($method);

        # fetch and prepare expression
        #my $expr = shift @spec;
        my @args = gather {
            take shift @spec
                while @spec and not $spec[0]->isa('Script::SXC::Tree::Keyword');
        };
        $attrs{ sprintf '%s_clause', $key->value } = $class->$method($key, \@args, $compiler, $env, symbol => $name_symbol);
    }

    # finished parameter
    return $class->new(%attrs);
}

method prepare_where_clause_expression (Str $class: Object $key!, ArrayRef $args!, Object $compiler!, Object $env!, Object :$symbol!) {

    # is our expression missing?
    $key->throw_parse_error(missing_parameter_option_argument 
        => sprintf(q{Missing parameter option argument on '%s': where clause expects an expression}, $symbol->value),
    ) unless @$args;

    # did we get too many arguments?
    $key->throw_parse_error(too_many_parameter_option_arguments 
        => sprintf(q{Too many parameter option arguments on '%s': where clause expects only one expression}, $symbol->value)
    ) unless @$args == 1;

    # take the expression
    my $expr = $args->[0];

    # build an application on the parameter out of it if it is only a symbol
    return $expr->new_item_with_source('List', { contents => [$expr, $symbol] })
        unless $expr->isa('Script::SXC::Tree::List');

    # take the clause itself if it's something else
    return $expr;
}

__PACKAGE__->meta->make_immutable;

1;
