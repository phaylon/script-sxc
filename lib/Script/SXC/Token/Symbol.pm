package Script::SXC::Token::Symbol;
use Moose;

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

method match_regex ($line_ref) { 
    qr/
        [^\s()\[\]#;\d:]
        [^\s()\[\]#;]+
    /x 
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    return $class->new(value => $value);
};

1;
