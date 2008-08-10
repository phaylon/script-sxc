package Script::SXC::Token::Number;
use Moose;

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token';

method match_regex ($line_ref) { 
    qr/
        (?:
            0x
            [\da-f]+
          |
            [+-]?
            (?:
                \d+[_\d]+\d+
                |
                \d+
            )
            (?:\.\d+)?
        )
    /xi;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    if ($value =~ /^0x(.+)$/) {
        $value = hex $1;
    }
    elsif ($value =~ /^0(.+)$/) {
        $value = oct $1;
    }

    $value =~ s/_//g;
    return $class->new(value => 0+$value);
};

1;
