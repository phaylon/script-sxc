package Script::SXC::Test::Library::Core::Syntax;
use 5.010;
use strict;
use parent 'Script::SXC::Test::Library::Core';
use CLASS;
use Test::Most;
use Data::Dump qw( pp );

use constant SyntaxRulesClass   => 'Script::SXC::Compiled::SyntaxRules';
use constant PatternClass       => join('::', SyntaxRulesClass, 'Pattern');
use constant RuleClass          => join('::', SyntaxRulesClass, 'Rule');
use constant ListPattern        => join('::', SyntaxRulesClass, 'Pattern::List');
use constant SymbolPattern      => join('::', SyntaxRulesClass, 'Pattern::Symbol');
use constant LiteralPattern     => join('::', SyntaxRulesClass, 'Pattern::Symbol::Literal');
use constant CapturePattern     => join('::', SyntaxRulesClass, 'Pattern::Symbol::Capture');
use constant SymbolClass        => 'Script::SXC::Tree::Symbol';

sub T100_syntax_rules_api: Tests {
    my $self = shift;

    {   my $body   = '(syntax-rules (to) ((add (x to y)) (+ x y)) ((add x) (+ x x)))';
        my $simple = $self->sx_compile_tree($body);
        is scalar(@{ $simple->expressions }), 1, 'syntax-rules compiled to single transformer item';

        isa_ok +(my $sr = $simple->expressions->[0]), SyntaxRulesClass;
        is $sr->literal_count, 1, 'transformer contains one literal';
        is $sr->rule_count, 2, 'transformer contains two rules';

        my ($rule1, $rule2) = @{ $sr->rules };
        my $literal         = $sr->literals->[0];
        isa_ok $literal, SymbolClass;
        is $literal->value, 'to', 'literal symbol has correct value';
        isa_ok $_, RuleClass for $rule1, $rule2;

        {   my $pattern = $rule1->pattern;
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

        {   my $pattern = $rule2->pattern;
            isa_ok $pattern, PatternClass;
            is $pattern->item_count, 1, 'pattern for second rule contains single item';

            my $x = $pattern->get_item(0);
            isa_ok $x, CapturePattern;
            is $x->value, 'x', 'capture pattern has correct value';
        }

        say pp $simple;
        exit;
    }
}

1;
