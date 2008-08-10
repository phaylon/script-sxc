package Script::SXC::Token::Keyword;
use Moose;

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

method match_regex ($line_ref) { 
    qr/
        :
        (?:
            [a-z]
            [a-z0-9_-]*
            [a-z0-9]
          |
            [a-z]
        )
    /xi
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    $value =~ s/^://;
    return $class->new(value => $value);
};

1;
