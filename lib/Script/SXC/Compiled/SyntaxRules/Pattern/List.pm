package Script::SXC::Compiled::SyntaxRules::Pattern::List;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $list, Object $sr, Object $pattern) {
    return $class->new(items => [ map { $class->transform($compiler, $env, $_, $sr, $pattern) } @{ $list->contents } ]);
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching';
with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

1;
