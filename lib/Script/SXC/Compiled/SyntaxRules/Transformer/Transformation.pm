package Script::SXC::Compiled::SyntaxRules::Transformer::Transformation;
use Moose::Role;

use namespace::clean -except => 'meta';

requires qw(
    transform_to_tree
);

1;
