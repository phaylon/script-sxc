package Script::SXC::Test::Library::Core::Syntax;
use 5.010;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump   qw( pp );
use Scalar::Util qw( refaddr );

use constant SyntaxRulesClass    => 'Script::SXC::Compiled::SyntaxRules';
use constant PatternClass        => join('::', SyntaxRulesClass, 'Pattern');
use constant TransformerClass    => join('::', SyntaxRulesClass, 'Transformer');
use constant LibraryItemClass    => join('::', TransformerClass, 'LibraryItem');
use constant InsertCapturedClass => join('::', TransformerClass, 'InsertCaptured');
use constant GeneratedClass      => join('::', TransformerClass, 'Generated');
use constant RuleClass           => join('::', SyntaxRulesClass, 'Rule');
use constant ListPattern         => join('::', SyntaxRulesClass, 'Pattern::List');
use constant SymbolPattern       => join('::', SyntaxRulesClass, 'Pattern::Symbol');
use constant LiteralPattern      => join('::', SyntaxRulesClass, 'Pattern::Symbol::Literal');
use constant CapturePattern      => join('::', SyntaxRulesClass, 'Pattern::Symbol::Capture');
use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant ListClass           => 'Script::SXC::Tree::List';
use constant NumberClass         => 'Script::SXC::Tree::Number';
use constant NumberLibrary       => 'Script::SXC::Library::Data::Numbers';
use constant LetLibrary          => 'Script::SXC::Library::Core::Let';
use constant ProcedureClass      => 'Script::SXC::Library::Item::Procedure';

sub T100_syntax_rules_api: Tests {
    my $self = shift;

    {   my $body   = '(syntax-rules (to) ((add (x to y)) (+ x y)) ((add x) (let ((y 3)) (+ x y))))';
        my $simple;
        lives_ok { $simple = $self->sx_compile_tree($body) } 'syntax-rules compiles';
        is scalar(@{ $simple->expressions }), 1, 'syntax-rules compiled to single transformer item';

        isa_ok +(my $sr = $simple->expressions->[0]), SyntaxRulesClass;
        is $sr->literal_count, 1, 'transformer contains one literal';
        is $sr->rule_count, 2, 'transformer contains two rules';

        my ($rule1, $rule2) = @{ $sr->rules };
        my $literal         = $sr->literals->[0];
        isa_ok $literal, SymbolClass;
        is $literal->value, 'to', 'literal symbol has correct value';
        isa_ok $_, RuleClass for $rule1, $rule2;

        {   say '# first rule pattern';
            my $pattern = $rule1->pattern;
            isa_ok $pattern, PatternClass;
            is $pattern->item_count, 1, 'pattern for first rule contains single item';

            my $list = $pattern->get_item(0);
            isa_ok $list, ListPattern;
            is $list->item_count, 3, 'list item contains three subitems';

            {   my ($x, $to, $y) = @{ $list->items };
                isa_ok $x,  CapturePattern;
                isa_ok $y,  CapturePattern;
                isa_ok $to, LiteralPattern;
                is $x->value,  'x',  'first capture pattern has correct value';
                is $y->value,  'y',  'second capture pattern has correct value';
                is $to->value, 'to', 'literal pattern has correct value';
            }
        }

        {   say '# first rule transformer';
            my $trans = $rule1->transformer;
            isa_ok $trans, TransformerClass;
            
            my $template = $trans->template;
            isa_ok $template, ListClass;
            is $template->content_count, 3, 'template for first rule is list with three elements';

            my ($add, $x, $y) = @{ $template->contents };
            isa_ok $add, LibraryItemClass;
            is $add->library, NumberLibrary, 'library procedure is bound to its library';
            is $add->name, '+', 'procedure has correct name';
            isa_ok $x, InsertCapturedClass;
            is $x->name, 'x', 'first capture has correct name';
            isa_ok $y, InsertCapturedClass;
            is $y->name, 'y', 'second capture has correct name';
        }

        {   say '# second rule pattern';
            my $pattern = $rule2->pattern;
            isa_ok $pattern, PatternClass;
            is $pattern->item_count, 1, 'pattern for second rule contains single item';

            my $x = $pattern->get_item(0);
            isa_ok $x, CapturePattern;
            is $x->value, 'x', 'capture pattern has correct value';
        }

        {   say '# second rule transformer';
            my $trans = $rule2->transformer;
            isa_ok $trans, TransformerClass;
            
            my $template = $trans->template;
            isa_ok $template, ListClass;
            is $template->content_count, 3, 'template for second rule is list with three elements';

            my ($let_sym, $let_vars, $let_expr) = @{ $template->contents };

            isa_ok $let_sym, LibraryItemClass;
            is $let_sym->library, LetLibrary, 'let element is bound to its library';
            is $let_sym->name, 'let', 'let element has correct name';

            isa_ok $let_vars, ListClass;
            is $let_vars->content_count, 1, 'let contains single definition';
            isa_ok $let_vars->get_content_item(0), ListClass;
            is $let_vars->get_content_item(0)->content_count, 2, 'definition contains two expressions';

            my ($var_sym, $var_expr) = @{ $let_vars->get_content_item(0)->contents };
            isa_ok $var_sym, GeneratedClass;
            is $var_sym->value, 'y', 'generated symbol has correct value';
            isa_ok $var_expr, NumberClass;
            is $var_expr->value, '3', 'constant number has correct value';

            isa_ok $let_expr, ListClass;
            is $let_expr->content_count, 3, 'let expression is list with three elements';

            my ($add, $x, $y) = @{ $let_expr->contents };
            isa_ok $add, LibraryItemClass;
            is $add->library, NumberLibrary, 'library procedure is bound to its library';
            is $add->name, '+', 'procedure has correct name';
            isa_ok $x, InsertCapturedClass;
            is $x->name, 'x', 'capture has correct name';
            isa_ok $y, GeneratedClass;
            is $y->value, 'y', 'generated symbol has correct name';
            is refaddr($y), refaddr($var_sym), 'generated symbols in let variables and let expression are the same object';
        }

        {   say '# transforming first syntax-rule';
            my $ls = $self->sx_build_stream('(3 to 5)')->contents->[0];

            my ($rule, $cap) = $sr->find_matching_rule([$ls]);
            isa_ok $rule, RuleClass;
            is ref($cap), 'HASH', 'captures result is a hash reference';
            ok exists($cap->{x}), 'capture hash reference contains first capture name';
            ok exists($cap->{y}), 'capture hash reference contains second capture name';
            isa_ok $cap->{x}, NumberClass;
            isa_ok $cap->{y}, NumberClass;

            my $tree = $rule->build_tree($self->compiler, $self->compiler->top_environment, $cap);
            isa_ok $tree, ListClass;
            is $tree->content_count, 3, 'transformed expression has correct number of items';

            my ($add, $x, $y) = @{ $tree->contents };
            isa_ok $add, SymbolClass;
            isa_ok $x,   NumberClass;
            isa_ok $y,   NumberClass;
            is $add->value, '+', 'transformed expression has correct procedure';
            is $x->value, 3, 'first constant has correct value';
            is $y->value, 5, 'second constant has correct value';
        }

        #exit;
    }
}

1;
