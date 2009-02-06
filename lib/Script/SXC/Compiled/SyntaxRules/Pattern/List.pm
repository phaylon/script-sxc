package Script::SXC::Compiled::SyntaxRules::Pattern::List;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $list, Object $sr, Object $pattern, Int $greed_level) {
    return $class->new(
        container_class => ref($list), 
        items           => $class->transform_sequence($compiler, $env, $list->contents, $sr, $pattern, $greed_level),
    );
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching';
with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+alternate_reftype' => (default => 'ARRAY');

1;
