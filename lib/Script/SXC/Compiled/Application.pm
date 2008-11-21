package Script::SXC::Compiled::Application;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object ArrayRef Str );

use aliased 'Script::SXC::Compiled::Context',       'CompiledContext';
use aliased 'Script::SXC::Compiled::Value',         'CompiledValue';
use aliased 'Script::SXC::Exception::ParseError',   'ParseError';
use aliased 'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

with 'Script::SXC::TypeHinting';
with 'Script::SXC::SourcePosition';

has invocant => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_invocant'   => 'render',
        'invocant_does'     => 'does',
        'invocant_typehint' => 'typehint',
    },
);

has arguments => (
    is          => 'rw',
    isa         => ArrayRef[Object],
    required    => 1,
    default     => sub { [] },
);

has return_type => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => 'scalar',
);

method _wrap_return (Str $body!) {
#    return $body 
#        if $self->return_type eq 'scalar';
    return CompiledContext->new(
        expression  => CompiledValue->new(content => $body),
        type        => $self->return_type,
    )->render;
}

method render_code_application (Object $invocant!, Str $args!) {
    return sprintf '(%s)->(%s)', $invocant->render, $args;
}

method new_from_uncompiled 
    ($class: Object $compiler!, Object $env!, Object :$invocant!, ArrayRef :$arguments!, HashRef :$options = {}, :$return_type, :$typehint) {

    # prepare invocant for introspection
    my $compiled_invocant = $class->prepare_uncompiled_invocant($compiler, $env, $invocant);

    # procedures and inliners are compiled here
    if (    $invocant->isa('Script::SXC::Tree::Symbol')
        and $compiled_invocant->does('Script::SXC::Library::Item::Inlining')
        and $compiled_invocant->inliner
        and ( not($compiled_invocant->can('firstclass')) or not($options->{first_class}) )
    ) {
        my $inliner  = $compiled_invocant->inliner;
        my $compiled = $inliner->($compiled_invocant, 
            compiler            => $compiler, 
            env                 => $env, 
            name                => $invocant->value, 
            exprs               => [@$arguments],
            symbol              => $invocant,
            allow_definitions   => $options->{allow_definitions},
            optimize_tailcalls  => $options->{optimize_tailcalls},
            error_cb            => sub {
                my ($type, %other_args) = @_;

                # args
                my $message   = delete $other_args{message};
                my $source    = delete $other_args{source};
                my $exception = delete $other_args{exception};

                # default source is operator
                $source ||= $options->{source} || $invocant;

                # default exception is a parse error
                $exception ||= ParseError;

                # throw error
                $exception->throw(type => $type, message => $message, $source->source_information, %other_args);
            },
        );

        return $return_type eq 'scalar' 
            ? $compiled 
            : CompiledContext->new(expression => $compiled, type => $return_type);
    }

    return $class->new(
        invocant    => $compiled_invocant,
        arguments   => [ $class->prepare_uncompiled_arguments($compiler, $env, $arguments) ],
        return_type => $return_type,
      ( $typehint ? (typehint => $typehint) : () ),
    );
}

method prepare_uncompiled_invocant (Object $compiler!, Object $env!, Object $invocant!) {
    return $invocant->compile($compiler, $env);
}

method prepare_uncompiled_arguments (Object $compiler!, Object $env!, ArrayRef $args) {
    return map { $_->compile($compiler, $env) } @$args;
}

method render {

    # used anonymouse variables
    my $var_invocant 
      = $self->invocant->isa('Script::SXC::Compiler::Environment::Variable')
      ? $self->invocant
      : Variable->new_anonymous('apply_invocant');

    # render arguments
    my @args = map { $_->render } @{ $self->arguments };
    my $args = join ', ', @args;

    # see if we can optimise by type
    if ($self->invocant_does('Script::SXC::TypeHinting') and $self->invocant_typehint) {

        # code references
        if ($self->invocant_typehint eq 'code') {
            return $self->_wrap_return($self->render_code_application($self->invocant, $args));
        }

        # don't know what to do with this invocant
        else {
            # TODO throw exception
        }
    }

    # we have no typehint
    else {

        # create an anon var for the result
        my $var_result = Variable->new_anonymous('apply_result');

        # application is surrounded by scoping block
        my $body = sprintf 'do { my %s; ',
            $var_result->render;

        # append invocant var definition if needed
        $body .= sprintf 'my %s = %s; ',
            $var_invocant->render,
            $self->render_invocant
          unless $self->render_invocant eq $var_invocant->render;

        # code reference as invocant
        $body .= sprintf 'if (ref(%s) eq q(CODE)) { %s = %s } ',
            $var_invocant->render,
            $var_result->render,
            $self->_wrap_return($self->render_code_application($var_invocant, $args));

        # finish body and return it
        $body .= $var_result->render . ' }';
        return $body;
    }
}

__PACKAGE__->meta->make_immutable;

1;
