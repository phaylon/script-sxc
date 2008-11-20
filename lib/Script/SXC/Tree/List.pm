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

    # symbol application
    if ($op->isa('Script::SXC::Tree::Symbol')) {
        my $invo = $op->compile($compiler, $env);

        # procedures and inliners are compiled here
        if ((    $invo->isa('Script::SXC::Library::Item::Procedure')
             and $invo->inliner 
             and not $compiler->force_firstclass_procedures )
            or   $invo->isa('Script::SXC::Library::Item::Inline')
        ) {
            my $inliner  = $invo->inliner;
            my $compiled = $inliner->($invo, 
                compiler            => $compiler, 
                env                 => $env, 
                name                => $op->value, 
                exprs               => [@args],
                symbol              => $op,
                allow_definitions   => $allow_definitions,
                optimize_tailcalls  => $optimize_tailcalls,
                error_cb            => sub {
                    my ($type, %other_args) = @_;

                    # args
                    my $message   = delete $other_args{message};
                    my $source    = delete $other_args{source};
                    my $exception = delete $other_args{exception};

                    # default source is operator
                    $source ||= $self;

                    # default exception is a parse error
                    $exception ||= ParseError;

                    # throw error
                    $exception->throw(
                        type                => $type,
                        message             => $message,
                        source_description  => $source->source_description,
                        line_number         => $source->line_number,
                        %other_args,
                    );
                },
            );

            return $return_type eq 'scalar' 
                ? $compiled 
                : CompiledContext->new(expression => $compiled, type => $return_type);
        }
    }

    # an invocation object is our fallback
    return ($optimize_tailcalls ? CompiledGoto : CompiledApplication)->new(
        invocant    => $op->compile($compiler, $env),
        arguments   => [ map { $_->compile($compiler, $env) } @args ],
        return_type => $return_type,
      ( ($return_type eq 'list' or $return_type eq 'hash') ? (typehint => $return_type) : () ),
    );
};

__PACKAGE__->meta->make_immutable;

1;
