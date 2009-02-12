package Script::SXC::Library::Core::Syntax;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Compiled::SyntaxRules';

use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ListClass           => 'Script::SXC::Tree::List';
use constant SyntaxTransformRole => 'Script::SXC::Compiled::SyntaxTransform';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_inliner('define-syntax', via => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol, :$allow_definitions) {

    # check if we are allowed to define here
    $error_cb->('illegal_definition', message => 'Illegal definition: Definitions only allowed on top-level or as expression in a lambda body')
        unless $allow_definitions;

    # check and unpack arguments
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
    my ($syn_name, $transformer) = @$exprs;
    $syn_name->throw_parse_error(invalid_syntax_variable => "$name expected a symbol as first argument")
        unless $syn_name->isa(SymbolClass);

    # compile transformer
    my $compiled_transformer = $transformer->compile($compiler, $compiler->top_environment);
    $error_cb->('invalid_syntax_transformer', message => "$name expected its second argument to return a compiled syntax transformer")
        unless $compiled_transformer->does(SyntaxTransformRole);

    $env->set_variable($syn_name->value, $compiled_transformer);
    return $compiled_transformer;
});

CLASS->add_inliner('syntax-rules', via => method (:$compiler, :$env, :$name, :$error_cb, :$exprs, :$symbol) {

    # check and unpack arguments
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
    my ($literals, @rules) = @$exprs;

    return SyntaxRules->new_from_uncompiled($compiler, $env, $literals, \@rules, $symbol, $name);
});

__PACKAGE__->meta->make_immutable;

1;
