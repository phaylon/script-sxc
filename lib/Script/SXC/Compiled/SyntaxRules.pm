package Script::SXC::Compiled::SyntaxRules;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose    qw( ArrayRef Str );

use Script::SXC::lazyload
   ['Script::SXC::Compiled::Value', 'CompiledValue'],
    'Script::SXC::Compiled::SyntaxRules::Pattern',
    'Script::SXC::Compiled::SyntaxRules::Transformer',
    'Script::SXC::Compiled::SyntaxRules::Rule';

use Data::Dump      qw( pp );
use List::MoreUtils qw( first_value );

use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ListClass           => 'Script::SXC::Tree::List';

use namespace::clean -except => 'meta';

with 'Script::SXC::Compiled::SyntaxTransform';

has '+inliner' => (builder => 'build_inliner');

has literals => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[SymbolClass],
    default     => sub { [] },
    required    => 1,
    provides    => {
        'count'     => 'literal_count',
        'push'      => 'add_literal',
        'get'       => 'get_literal',
    },
);

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has rules => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Rule],
    default     => sub { [] },
    required    => 1,
    provides    => {
        'count'     => 'rule_count',
        'push'      => 'add_rule',
        'get'       => 'get_rule',
    },
);

method find_matching_rule (ArrayRef $exprs) {

    # try rules in their defined order
    for my $rule (@{ $self->rules }) {

        # go to the next rule if we didn't get a valid context from this one
        my $context = $rule->match($exprs)
            or next;

        # return the context if the rule matched
        return $context;
    }

    # no rule matched
    return undef;
}

method build_inliner {
    return method (Object $invocant: Object :$compiler, Object :$env, ArrayRef :$exprs, Object :$symbol, :$name) {

        # try to match our rules against the expression
        my $context = $self->find_matching_rule($exprs);
        $symbol->throw_parse_error(invalid_syntax_form => "No matching syntax-rule found in $name")
            unless $context;

        # return the newly compiled expression
        return $context->compile_tree($compiler, $env);
    };
}

# TODO 
# rendering of syntax-rules. this should set some kind of structure
# but will have to wait until exporting has stabilised.
method render { return pp "$self" }

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $literals, ArrayRef $rules, Object $symbol, Str $name) {
    
    # list of literals must always be a list
    $symbol->throw_parse_error(invalid_syntax_variable => "$name expected a list as first argument")
        unless $literals->isa(ListClass);

    # every item in the literal list must be a symbol
    $literals->get_content_item($_)->isa(SymbolClass) 
        or $literals
            ->get_content_item($_)
            ->throw_parse_error(invalid_syntax_literal => "$name expected a list of symbols as first argument (argument $_ is not a symbol)")
        for 0 .. $literals->content_count - 1;

    # create new syntax-rules instance
    my $self = $class->new(
        name        => $name,
        literals    => [@{ $literals->contents }],
        $symbol->source_information,
    );

    # compile and add rules
    $self->add_rule_from_uncompiled($compiler, $env, $_)
        for @$rules;

    return $self;
}

method create_rule (Object :$pattern, Object :$transformer) {

    # create a new rule and add it
    $self->add_rule(my $rule = Rule->new(
        pattern     => $pattern,
        transformer => $transformer,
    ));

    # return the created rule
    return $rule;
}

method add_rule_from_uncompiled (Object $compiler, Object $env, Object $rule) {
    my $name = $self->name;

    # validate format of this rule expression
    $rule->throw_parse_error(invalid_syntax_rule => "Rule for $name must be a list")
        unless $rule->isa(ListClass);
    $rule->throw_parse_error(invalid_syntax_rule => "Rule for $name expects two expressions: pattern and transformer")
        unless $rule->content_count == 2;

    # transform the pattern and transformer trees
    my ($pattern, $transformer) = @{ $rule->contents };
    my $transformed_pattern     = $self->build_pattern($compiler, $env, $pattern);
    my $transformed_transformer = $self->build_transformer($compiler, $env, $transformer, $transformed_pattern);

    # create a new rule and return it
    return $self->create_rule(
        pattern     => $transformed_pattern,
        transformer => $transformed_transformer,
    );
}

method build_transformer (Object $compiler, Object $env, Object $transformer, Object $transformed_pattern) {

    # transformer template can be in any format, so no validations
    return Transformer->new_from_uncompiled($compiler, $env, $transformer, $self, $transformed_pattern);
}

method build_pattern (Object $compiler, Object $env, Object $pattern) {
    my $name = $self->name;
    
    # validate pattern is a list with more than one expression
    $pattern->throw_parse_error(invalid_syntax_pattern => "Syntax pattern for $name must be a list")
        unless $pattern->isa(ListClass);
    $pattern->throw_parse_error(invalid_syntax_pattern => "Syntax pattern for $name expects at least one expression in list")
        unless $pattern->content_count;

    my (undef, @pattern_expressions) = @{ $pattern->contents };

    # create new pattern object
    return Pattern->new_from_uncompiled($compiler, $env, \@pattern_expressions, $self);
}

1;
