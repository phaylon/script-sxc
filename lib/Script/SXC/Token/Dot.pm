package Script::SXC::Token::Dot;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

extends 'Script::SXC::Token::Symbol';
with    'Script::SXC::Token::DirectTransform';

method match_regex {
    qr/\.+/
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return +(length($value) == 1 ? $class : 'Script::SXC::Token::Symbol')->new(value => $value);
};

method tree_item_class { 'Script::SXC::Tree::Dot' };

__PACKAGE__->meta->make_immutable;

1;
