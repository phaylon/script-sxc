package Script::SXC::Tree::Hash;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value',       'CompiledValue';
use aliased 'Script::SXC::Exception::ParseError', 'ParseError';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::Container';

method quoted (Object $compiler!, Object $env!, Bool :$allow_unquote) {

    return CompiledValue->new(
        typehint    => 'hash', 
        content     => sprintf('(+{( %s )})',
            join ', ',
            map { $compiler->quote_tree($_, $env, allow_unquote => $allow_unquote)->render }
                @{ $self->contents },
        ),
    );
}

with 'Script::SXC::Tree::Quotability';

method compile (Object $compiler!, Object $env!) {
    
    ParseError->throw(
        type        => 'odd_hash_values',
        message     => 'Inline hash constructor expects an even sized argument list',
        $self->source_information,
    ) if $self->content_count % 2;

    my $is_key = 1;
    return CompiledValue->new(typehint => 'hash', content => sprintf '(+{( %s )})',
        join ', ',
        map { $_->compile($compiler, $env, 'to_string', $is_key ? $is_key-- : $is_key++) } 
            @{ $self->contents },
    );
}

1;
