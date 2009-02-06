package Script::SXC::Compiled::SyntaxRules::Pattern::Matching;
use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
   ['Script::SXC::Compiled::SyntaxRules::Pattern::Symbol',   'SymbolPattern'],
   ['Script::SXC::Compiled::SyntaxRules::Pattern::Hash',     'HashPattern'],
   ['Script::SXC::Compiled::SyntaxRules::Pattern::Constant', 'ConstantPattern'],
   ['Script::SXC::Compiled::SyntaxRules::Pattern::List',     'ListPattern'];

use constant ListClass    => 'Script::SXC::Tree::List';
use constant HashClass    => 'Script::SXC::Tree::Hash';
use constant SymbolClass  => 'Script::SXC::Tree::Symbol';
use constant ConstantRole => 'Script::SXC::Tree::Constant';
use constant GreedyRole   => 'Script::SXC::Compiled::SyntaxRules::Pattern::Greedy';

use namespace::clean -except => 'meta';

requires qw(
    new_from_uncompiled
    match
);

method transform (Object $compiler, Object $env, Object $item, Object $sr, Object $pattern, $greed_level) {
    $greed_level //= 0;
    $pattern->update_greedy_max_depth($greed_level);

    # the pattern class depends on the input type
    my $pattern_class =
        (   $item->isa(ListClass)     ? ListPattern
          : $item->isa(SymbolClass)   ? SymbolPattern
          : $item->isa(HashClass)     ? HashPattern
          : $item->does(ConstantRole) ? ConstantPattern
          : undef );

    # if we don't recognize it here, we can't turn it into a pattern
    $item->throw_parse_error(invalid_pattern_item => "Invalid pattern item")
        unless $pattern_class;

    # return a new pattern object
    return $pattern_class->new_from_uncompiled($compiler, $env, $item, $sr, $pattern, $greed_level);
}

method transform_sequence (Object $compiler, Object $env, ArrayRef $seq, Object $sr, Object $pattern, $greed_level) {
    $greed_level //= 0;

    my @items = @$seq;
    my @transformed;

    # transform all items
    while (my $item = shift @items) {
        my $subpattern;

        # the following symbol is an ellipsis
        if (@items and $items[0]->isa(SymbolClass) and $items[0] eq '...') {
            my $ellipsis = shift @items;

            # there shouldn't be anything left after the ellipsis
            if (@items) {
                $ellipsis->throw_parse_error(invalid_syntax_ellipsis => "Ellipsis must be last element in syntax-rules pattern");
            }

            # transform the item into a subpattern
            $subpattern = $self->transform($compiler, $env, $item, $sr, $pattern, $greed_level + 1);
            
            # make sure we can make this subpattern greedy
            unless ($subpattern->does(GreedyRole) and $subpattern->allow_greedy) {
                $item->throw_parse_error(
                    'invalid_syntax_ellipsis',
                    sprintf 'syntax-rules is unable to greedify %s (result of %s)', ref($subpattern), ref($item),
                );
            }

            # set the greed level of the subpattern
            $subpattern->is_greedy(1);
            $subpattern->greed_level($greed_level + 1);
        }

        # not greedy
        else {

            # ellipsis can't be at the beginning
            if ($item->isa(SymbolClass) and $item eq '...') {
                $item->throw_parse_error(invalid_syntax_ellipsis => "Ellipsis must follow greedifiable syntax-rules pattern");
            }

            # transform item as is
            $subpattern = $self->transform($compiler, $env, $item, $sr, $pattern, $greed_level);
        }

        push @transformed, $subpattern;
    }

    return \@transformed;
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::Greedy';

1;
