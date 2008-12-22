package Script::SXC::Token::Regex;
use Moose;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( Str RegexpRef );

use namespace::clean -except => 'meta';

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::DirectTransform';
with 'Script::SXC::Token';

has '+value' => (isa => RegexpRef);

method match_regex { 
    qr{
        (?:
            /
                .+?
                (?<! \\ )
            /
        |
            //
        )
        [a-z]* 
        (?:
            -
            [a-z]+
        )?
    }x;
};

method build_tokens (Str $value) {
    my $class = ref($self) || $self;

    # remove modifiers
    $value =~ s{/([a-z-]*)$}{/};
    my $mods = $1;

    # remove leading and trailing slash
    $value =~ s{(^/|/$)}{}g;

    # clean modifiers
    $mods  =~ s/[^xism-]//g;

    # remove interpolations
    $value =~ s/(?<!\\)(\$|\@|\%)/\\$1/g;

    # return new token
    return $class->new(value => qr/(?$mods:$value)/x);
};

method tree_item_class { 'Script::SXC::Tree::Regex' };

__PACKAGE__->meta->make_immutable;

1;
