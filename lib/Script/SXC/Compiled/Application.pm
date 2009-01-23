package Script::SXC::Compiled::Application;
use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object ArrayRef Str Bool );

use Data::Dump qw( pp );

use constant VariableClass  => 'Script::SXC::Compiler::Environment::Variable';
use constant ProcedureClass => 'Script::SXC::Library::Item::Procedure';

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Context',      'CompiledContext'   ],
    ['Script::SXC::Compiled::Value',        'CompiledValue'     ],
    ['Script::SXC::Compiled::Goto',         'CompiledGoto'      ],
    'Script::SXC::Exception::TypeError',
    'Script::SXC::Exception::ParseError',
    'Script::SXC::Exception::ArgumentError',
    VariableClass;

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

my $AppMarker = '$___SXC_CALLER_INFO___';

method _wrap_return (Str $body!) {
#    return $body 
#        if $self->return_type eq 'scalar';
    return CompiledContext->new(
        expression  => CompiledValue->new(content => $body),
        type        => $self->return_type,
    )->render;
}

method render_code_application (Object $invocant!, Str $args!) {
    return sprintf 'do { my %s = %s; (%s)->(%s) }',
        $AppMarker,
        pp(+{ $self->source_information }),
        $invocant->render, 
        $args;
}

method render_hash_application (Object $invocant!, Str $args!) {
    return sprintf '( (%s)->{ %s } )',
        $invocant->render,
        $self->_render_single_value_check($args, 'hash');
}

method render_list_application (Object $invocant!, Str $args!) {
    return sprintf '( (%s)->[%s] )',
        $invocant->render,
        $self->_render_single_value_check($args, 'list');
}

method render_object_application (Object $invocant!, Str $args!, ArrayRef $raw_args?) {
    my $method_var = Variable->new_anonymous('method');
    my $args_var   = Variable->new_anonymous('method_args', sigil => '@');
    my ($method, @args) = @$raw_args;
    return sprintf '(do { my %s = (%s); my %s = q() . shift(%s); %s; %s->%s(%s) })',
        $args_var->render,
        $args,
        $method_var->render,
        $args_var->render,
        $self->_render_method_check($invocant, $method_var, 1),
        $invocant->render,
        $method_var->render,
        $args_var->render;
}

method render_string_application (Object $invocant!, Str $args!, ArrayRef $raw_args?) {
    my $method_var = Variable->new_anonymous('classmethod');
    my $args_var   = Variable->new_anonymous('classmethod_args', sigil => '@');
    my ($method, @args) = @$raw_args;
    return sprintf '(do { %s; my %s = (%s); my %s = q() . shift(%s); %s; %s->%s(%s) })',
        sprintf(
            'unless (%s =~ /^\D/) { require %s; %s->throw(%s, %s) }',
            $invocant->render,
            ('Script::SXC::Exception') x 2,
            sprintf(
                q(message => join('', "Invalid class name for method call: '", %s, "'")),
                $invocant->render,
            ),
            pp(type => 'invalid_invocant_type', $self->source_information),
        ),
        $args_var->render,
        $args,
        $method_var->render,
        $args_var->render,
        $self->_render_method_check($invocant, $method_var, 0),
        $invocant->render,
        $method_var->render,
        $args_var->render;
}

method _render_method_check (Object $invocant_var!, Object $method_var!, Bool $is_object!) {
    return sprintf 'unless (%s->can(%s)) { require %s; %s->throw(%s, %s) }',
        $invocant_var->render,
        $method_var->render,
        ('Script::SXC::Exception') x 2,
        sprintf(
            q(message => join('', "Unable to call method '%s' on %s ", %s)),
            $method_var->render,
            ($is_object ? 'instance of class' : 'class'),
            ($is_object ? sprintf('ref(%s)', $invocant_var->render) : $invocant_var->render),
        ),
        pp(type => 'missing_method', $self->source_information);
}

method _render_single_value_check (Str $args!, Str $type!) {

    my $var = Variable->new_anonymous('single_val');

    return sprintf '(do { my %s = [ %s ]; %s->throw(%s) if @{ %s } != 1; @{ %s }[0] })',
        $var->render,
        $args,
        ArgumentError,
        pp( $self->source_information,
            type    => 'invalid_application_argument',
            message => "$type application expects single argument",
        ),
        $var->render,
        $var->render;
}

method tailcall_alternative { CompiledGoto }

method new_from_uncompiled 
    ($class: Object $compiler!, Object $env!, Object :$invocant!, ArrayRef :$arguments!, HashRef :$options = {}, :$return_type, :$typehint, :$line_number, :$source_description, :$tailcalls, :$inline_invocant, :$inline_firstclass_args) {

    $inline_invocant        //= 1;
    $inline_firstclass_args //= 0;

    $class = $class->tailcall_alternative
        if $tailcalls;

    # invocant can be keyword
    if ($invocant->isa('Script::SXC::Tree::Keyword')) {
        my $real_invocant = $arguments->[0];
        $arguments = [$invocant, @$arguments[1 .. $#$arguments]];
        $invocant  = $real_invocant;
    }

    # prepare invocant for introspection
    my $compiled_invocant = $class->prepare_uncompiled_invocant($compiler, $env, $invocant);
#    warn "<COMPILED INVOCANT $compiled_invocant " . ($invocant->can('name') ? $invocant->name : '(novalue)') . ">\n";
#    warn "INLINER? " . ($compiled_invocant->can('inliner') // 'no') . "\n";
#    warn "INLINE?  " . ($inline_invocant // 'no') . "\n";
#    warn "DOES IT? " . ($compiled_invocant->does('Script::SXC::Library::Item::Inlining') // 'no') . "\n";

    # procedures and inliners are compiled here
    if (    ($invocant->isa('Script::SXC::Tree::Symbol') or $invocant->isa(ProcedureClass))
        and $inline_invocant
        and $compiled_invocant->does('Script::SXC::Library::Item::Inlining')
        and $compiled_invocant->inliner
        and ( not($compiled_invocant->can('firstclass')) or not($options->{first_class}) )
    ) {
#        warn "INLINING\n";
        my $inliner  = $compiled_invocant->inliner;
        my $compiled = $inliner->($compiled_invocant, 
            compiler            => $compiler, 
            env                 => $env, 
            name                => ($invocant->can('value') ? $invocant->value : $invocant->name), 
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
        invocant                    => $compiled_invocant,
        arguments                   => [ $class->prepare_uncompiled_arguments($compiler, $env, $arguments) ],
        return_type                 => $return_type,
        line_number                 => $line_number,
        source_description          => $source_description,
      ( $typehint ? (typehint => $typehint) : () ),
    );
}

method prepare_uncompiled_invocant (Object $compiler!, Object $env!, Object $invocant!) {
    return $invocant->compile($compiler, $env);
}

method prepare_uncompiled_arguments (Object $compiler!, Object $env!, ArrayRef $args, :$fc_inline) {
    return map { $_->compile($compiler, $env, fc_inline_optimise => $fc_inline) } @$args;
}

method render {

    # used anonymouse variables
    my $var_invocant 
      = $self->invocant->isa('Script::SXC::Compiler::Environment::Variable')
      ? $self->invocant
      : Variable->new_anonymous('apply_invocant');

    # render arguments
    my @raw_args = @{ $self->arguments };
    my @args     = map { $_->render } @raw_args;
    my $args     = join ', ', @args;

    # see if we can optimise by type
    if ($self->invocant_does('Script::SXC::TypeHinting') and $self->invocant_typehint) {

        given ($self->invocant_typehint) {
            when ('code') {
                return $self->_wrap_return($self->render_code_application($self->invocant, $args));
            }
            when ('list') {
                return $self->_wrap_return($self->render_list_application($self->invocant, $args));
            }
            when ('hash') {
                return $self->_wrap_return($self->render_hash_application($self->invocant, $args));
            }
            when ('string') {
                return $self->_wrap_return($self->render_string_application($self->invocant, $args, \@raw_args));
            }
            when ('object') {
                return $self->_wrap_return($self->render_object_application($self->invocant, $args, \@raw_args));
            }
            default {
                $self->invocant->throw_parse_error(
                    'invalid_invocant_type',
                    sprintf("Invalid invocant: Don't know how to apply %s", $self->invocant_typehint),
                );
            }
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

        my @apply_cases = (
            [ sprintf('ref(%s) eq q(CODE)',        
                $var_invocant->render,
              ), 
              'render_code_application',
            ],
            [ sprintf('ref(%s) eq q(ARRAY)',       
                $var_invocant->render,
              ), 
              'render_list_application',
            ],
            [ sprintf('ref(%s) eq q(HASH)',        
                $var_invocant->render,
              ), 
              'render_hash_application',
            ],
            [ sprintf('(Scalar::Util::blessed(%s) and not(%s->isa(q(Script::SXC::Runtime::Object))))', 
                ($var_invocant->render) x 2,
              ), 
              'render_object_application',
            ],
            [ sprintf(
                'defined(%s) and not ref(%s) and %s =~ /^\D/',  
                ($var_invocant->render) x 3,
              ), 
            'render_string_application',
            ],
        );

        $body .= sprintf 'if %s else { require %s; %s->throw(%s) }',
            join(' elsif ',
                map {
                    my $method = $_->[1];
                    sprintf '(%s) { %s = %s }', 
                        $_->[0], 
                        $var_result->render,
                        $self->_wrap_return($self->$method($var_invocant, $args, \@raw_args));
                } @apply_cases
            ),
            TypeError,
            TypeError,
            pp( $self->source_information,
                type    => 'invalid_invocant_type',
                message => 'Invocant for application needs to be code, object, string, list or hash',
            );

        # code reference as invocant
        #$body .= sprintf 'if (ref(%s) eq q(CODE)) { %s = %s } ',
        #    $var_invocant->render,
        #    $var_result->render,
        #    $self->_wrap_return($self->render_code_application($var_invocant, $args));

        # finish body and return it
        $body .= $var_result->render . ' }';
        return $body;
    }
}

__PACKAGE__->meta->make_immutable;

1;
