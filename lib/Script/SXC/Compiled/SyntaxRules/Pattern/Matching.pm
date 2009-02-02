package Script::SXC::Compiled::SyntaxRules::Pattern::Matching;
use 5.010;
use Moose::Role;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
   ['Script::SXC::Compiled::SyntaxRules::Pattern::Symbol',  'SymbolPattern'],
   ['Script::SXC::Compiled::SyntaxRules::Pattern::List',    'ListPattern'];

use constant ListClass   => 'Script::SXC::Tree::List';
use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use namespace::clean -except => 'meta';

requires qw(
    new_from_uncompiled
);

method transform (Object $compiler, Object $env, Object $item, Object $sr, Object $pattern) {

    my $pattern_class =
        (   $item->isa(ListClass)   ? ListPattern
          : $item->isa(SymbolClass) ? SymbolPattern
          : undef );

    $item->throw_parse_error(invalid_pattern_item => "Invalid pattern item")
        unless $pattern_class;

    return $pattern_class->new_from_uncompiled($compiler, $env, $item, $sr, $pattern);
}

1;
