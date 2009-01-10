=head1 NAME

Script::SXC::Library::Core::Conditionals - Core Conditionals

=cut

package Script::SXC::Library::Core::Conditionals;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    ['Script::SXC::Compiled::Value',        'CompiledValue'],
    ['Script::SXC::Compiled::Conditional',  'CompiledConditional'];

use List::MoreUtils qw( none );

use constant SymbolClass => 'Script::SXC::Tree::Symbol';
use constant ListClass   => 'Script::SXC::Tree::List';

use CLASS;
use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

=head1 SYNTAX ELEMENTS

=head2 if

Syntax:

  (if <condition> <consequence> <alternative>?)

This syntax element will evaluate condition and then, if true, evaluate
the consequence, or the alternative, if false.

If no alternative is given an undefined value will be returned on false.

Examples:

  (if 23 "yes" "no")                => "yes"
  (if 0  "yes" "no")                => "no"
  (if 0  "yes")                     => undef

=cut

for my $cond_name (qw( if unless )) {
    CLASS->add_inliner($cond_name,
        via => method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, Str :$name!, :$error_cb!) {
            CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 3);

            # TODO check args, throw exceptions
            my ($cnd, $csq, $alt) = @$exprs;

            return CompiledConditional->new(
                mode        => $cond_name,
                condition   => $cnd->compile($compiler, $env),
                consequence => $csq->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls),
               ( $alt ? (alternative => $alt->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls)) : () ),
            );
        },
    );
}

#   ((foo) 23)
#   ((foo) -> (* 2 _))
#   ((foo) => ++)

my $TransformConditions = method (Object :$compiler, Object :$env, ArrayRef :$exprs, Bool :$optimize_tailcalls, Str :$name!, :$error_cb!) {

    # this is where the clause result will be stored
    my $result_var = Variable->new_anonymous('clause_result');

    my $rec;
    $rec = sub (@conditions) {
        
        # no more conditions, default to undef
        unless (@conditions) {
            return CompiledValue->new(content => 'undef');
        }

        # conditions must be lists
        $conditions[0]->throw_parse_error(invalid_cond_clause => 'Invalid cond clause. Expected list with 2 or 3 elements')
            if not $conditions[0]->isa(ListClass) or none { $_ == $conditions[0]->content_count } 2, 3;

        # get current parts
        my @current = @{ shift(@conditions)->contents };

        # get clause
        my $clause = shift @current;

        # else condition
        if ($clause->isa(SymbolClass) and $clause->value eq 'else') {

            # expect exactly one other expression
            $clause->throw_parse_error(missing_else_consequence => 'Missing a consequence for cond else clause')
                unless @current;
            $current[1]->throw_parse_error(invalid_else_clause => 'Too many consequences for cond else clause')
                if @current > 1;
    
            # render else consequence
            my $conseq = shift @current;
            return $conseq->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls);
        }

        # we need this a few times
        my $build_conditional = sub ($consequence) {

            return CompiledConditional->new(
                mode        => 'if',
                condition   => CompiledValue->new(
                    content => sprintf '(do { %s = %s })', $result_var->render, $clause->compile($compiler, $env)->render,
                ),
                consequence => $consequence->compile($compiler, $env, optimize_tailcalls => $optimize_tailcalls),
                alternative => $rec->(@conditions),
            );
        };

        # normal condition
        if (@current == 1) {
            return $build_conditional->($current[0]);
        }

        # extract application symbol and consequence
        my ($symbol, $conseq) = @current;

        # symbol really needs to be, well, a symbol.
        $symbol->throw_parse_error(invalid_application_symbol => q(Invalid cond application type specification. Expected either '->' or '=>'))
            if not $symbol->isa(SymbolClass) or none { $symbol->value eq $_ } qw( -> => );

        # apply function
        if ($symbol->value eq '=>') {

            return $build_conditional->($conseq->new_item_with_source(List => { contents => [
                $conseq,
                $result_var,
            ]}));
        }

        # apply inline
        if ($symbol->value eq '->') {

            return $build_conditional->($conseq->new_item_with_source(List => { contents => [
                $conseq->new_item_with_source(Builtin => { value => 'let' }),
                $conseq->new_item_with_source(List => { contents => [
                    $conseq->new_item_with_source(List => { contents => [
                        $conseq->new_item_with_source(Symbol  => { value => '_' }),
                        $result_var,
                    ]}),
                ]}),
                $conseq,
            ]}));
        }
    };

    return CompiledValue->new(content => sprintf
        '(do { my %s; %s })',
        $result_var->render,
        $rec->(@$exprs)->render,
    );
};

CLASS->add_inliner('cond', via => sub { $TransformConditions->(@_) });

1;
