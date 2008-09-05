package Script::SXC::Token::Quote;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Tree::Builtin',   'BuiltinItemClass';
use aliased 'Script::SXC::Tree::List',      'ListItemClass';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::TransformNextItem';
with 'Script::SXC::Token';

my %QuoteBuiltin = (q{'} => 'quote', q{`} => 'quasiquote');

has '+value' => (isa => Str);

method match_regex {
    [qw( ' ` )]
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method is_quasiquote { $self->value eq q{`} };

method transform_item ($item) {
    return ListItemClass->new_from_token(
        $self,
        contents => [
            BuiltinItemClass->new_from_token(
                $self,
                value => $QuoteBuiltin{ $self->value },
            ),
            $item,
        ],
    );
};

method end_of_stream_error_message {
    $QuoteBuiltin{ $self->value } . ' expected another item';
};

1;
