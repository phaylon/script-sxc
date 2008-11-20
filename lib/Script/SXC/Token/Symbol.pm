package Script::SXC::Token::Symbol;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::DirectTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex { 
    qr/
        [^\s()\[\]\{\[#"';\d:]
        [^\s()\[\]\{\[#";]*
    /x 
};

method build_tokens (Str $value) {
    my $class = ref($self) || $self;

    # no transformations required
    return $class->new(value => $value);
};

method tree_item_class { 'Script::SXC::Tree::Symbol' };

__PACKAGE__->meta->make_immutable;

1;
