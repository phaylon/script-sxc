package Script::SXC::Token::Keyword;
use Moose;

use Script::SXC::Types qw( Str );

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::DirectTransform';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

method match_regex { 
    my $identifier = qr/
        (?:
            [a-z]
            [a-z0-9_-]*
            [a-z0-9]
          |
            [a-z]
        )
    /xi;
    return qr/
        (?:
            :$identifier
          |
            $identifier:
        )
    /xi;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;

    # just strip double colons
    $value =~ s/://;

    return $class->new(value => $value);
};

method tree_item_class { 'Script::SXC::Tree::Keyword' };

__PACKAGE__->meta->make_immutable;

1;
