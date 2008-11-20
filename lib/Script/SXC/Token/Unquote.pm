package Script::SXC::Token::Unquote;
use Moose;

use Script::SXC::Types qw( Str );

use aliased 'Script::SXC::Tree::Builtin',   'BuiltinItemClass';
use aliased 'Script::SXC::Tree::List',      'ListItemClass';

use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Token::MatchByRegex';
with 'Script::SXC::Token::TransformNextItem';
with 'Script::SXC::Token';

has '+value' => (isa => Str);

my $SymbolUnquote       = q(,);
my $SymbolUnquoteSplice = q(,@);
my %UnquoteBuiltin      = (
    $SymbolUnquote          => 'unquote', 
    $SymbolUnquoteSplice    => 'unquote-splicing',
);

method match_regex {
    [$SymbolUnquoteSplice, $SymbolUnquote];
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method is_splicing { $self->value eq q{,@} };

method transform_item ($item) {
    return ListItemClass->new_from_token(
        $self,
        contents => [
            BuiltinItemClass->new_from_token(
                $self,
                value => $UnquoteBuiltin{ $self->value },
            ),
            $item,
        ],
    );
};

method end_of_stream_error_message {
    $UnquoteBuiltin{ $self->value } . ' expected another item';
};

__PACKAGE__->meta->make_immutable;

1;
