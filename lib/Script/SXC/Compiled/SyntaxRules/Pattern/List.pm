package Script::SXC::Compiled::SyntaxRules::Pattern::List;
use Moose;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Object $list, Object $sr, Object $pattern, Int $greed_level) {

    # create a new container placeholder with transformed contents
    return $class->new(
        container_class => ref($list), 
        items           => $class->transform_sequence($compiler, $env, $list->contents, $sr, $pattern, $greed_level),
    );
}

with 'Script::SXC::Compiled::SyntaxRules::Pattern::SequenceMatching';
with 'Script::SXC::Compiled::SyntaxRules::Pattern::Matching';

has '+alternate_reftype' => (default => 'ARRAY');

__PACKAGE__->meta->make_immutable;

1;
