package Script::SXC::Tree::List;
use Moose;
use MooseX::Method::Signatures;

use aliased 'Script::SXC::Compiled::Value',         'CompiledValue';
use aliased 'Script::SXC::Compiled::Application',   'CompiledApplication';
use aliased 'Script::SXC::Compiled::Context',       'CompiledContext';
use aliased 'Script::SXC::Compiled::Goto',          'CompiledGoto';
use aliased 'Script::SXC::Exception::ParseError',   'ParseError';

use namespace::clean -except => 'meta';

with 'Script::SXC::Tree::Item';
with 'Script::SXC::Tree::Container';

method quoted (Object $compiler!, Object $env!, Bool :$allow_unquote) {

    return CompiledValue->new(
        content  => sprintf('[%s]', 
                        join ', ', 
                        map  { $compiler->quote_tree($_, $env, allow_unquote => $allow_unquote)->render }
                        @{ $self->contents }),
        typehint => 'list',
    );
}

with 'Script::SXC::Tree::Quotability';

method compile (Object $compiler, Object $env, Bool :$allow_definitions?, Str :$return_type?, Bool :$optimize_tailcalls?) {
    $return_type ||= 'scalar';

    # empty list
    if ($self->content_count == 0) {
        return CompiledValue->new(content => '[]');
    }

    # not empty, fetch operand and arguments
    my ($op, @args) = @{ $self->contents };

    return(($optimize_tailcalls ? CompiledGoto : CompiledApplication)->new_from_uncompiled(
        $compiler,
        $env,
        invocant    => $op,
        arguments   => \@args,
        return_type => $return_type,
      ( ($return_type eq 'list' or $return_type eq 'hash') ? (typehint => $return_type) : () ),
        options     => {
            allow_definitions   => $allow_definitions,
            optimize_tailcalls  => $optimize_tailcalls,
            first_class         => $compiler->force_firstclass_procedures,
            source              => $self,
        },
    ));
};

__PACKAGE__->meta->make_immutable;

1;
