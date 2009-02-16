package Script::SXC::Compiled::Package;
use 5.010;
use Moose;
use MooseX::Types::Moose    qw( Str Object ArrayRef );
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );
use Class::Inspector;

use constant ListClass           => 'Script::SXC::Tree::List';
use constant SymbolClass         => 'Script::SXC::Tree::Symbol';
use constant GlobalVariableClass => 'Script::SXC::Compiler::Environment::Variable::Global';

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

with 'Script::SXC::SourcePosition';

has name => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
);

has filename => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    lazy        => 1,
    default     => sub { Class::Inspector->filename($_[0]->name) },
);

has version_expression => (
    is          => 'rw',
    isa         => Object,
);

has symbol_export_expressions => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Object],
    default     => sub { [] },
    provides    => {
        'count'     => 'symbol_export_count',
    }
);

has environment => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

method render {

    # build package body
    return sprintf '(do { package %s; $INC{%s} ||= %s; %s })',
        $self->name,
        pp($self->filename),
        pp($self->source_description),
        join('; ',
            $self->render_body_parts,
            pp($self->name),
        );
}

method render_body_parts {
    return( $self->render_version, $self->render_exports );
}

method render_exports {

    # no exports
    return () unless $self->symbol_export_count;

    # somewhere to store the whole map of things we could export
    my $available_var = Variable->new_anonymous('available')->render;

    # build exporter body
    return sprintf '%s; my %s = +{ %s }; %s::setup_exporter(%s)',
        join('; ',
            map { "require $_" }
            'Script::SXC::Exception::TypeError',
            'Sub::Exporter',
            'Sub::Name',
        ),
        $available_var,
        $self->render_available_list,
        'Sub::Exporter',
        sprintf(
            '+{ "exports", [map { %s } %s] }',
            sprintf(
                '( (ref($_) and ref($_) eq "%s") ? %s : %s )',
                'Script::SXC::Runtime::Symbol',
                sprintf(
                    '( exists(%s->{ $_->value }) ? %s : %s )',
                    $available_var,
                    sprintf(
                        '( $_->value, %s->{ $_->value } )',
                        $available_var,
                    ),
                    sprintf(
                        '( %s->throw(message => q{Unknown exported symbol: } . $_->value, %s) )',
                        'Script::SXC::Exception',
                        pp($self->source_information),
                    ),
                ),
                sprintf(
                    '( %s->throw(%s) )',
                    'Script::SXC::Exception::TypeError',
                    pp( message => 'Only symbols expected in exports list',
                        $self->source_information,
                    ),
                ),
            ),
            join(
                ', ',
                map { $_->render } @{ $self->symbol_export_expressions }
            ),
        ),
}

method render_available_list {

    my $rendered_var = Variable->new_anonymous('available_value')->render;
    my $name_var     = Variable->new_anonymous('available_name')->render;
    my @names        = $self->environment->variable_names;

    return sprintf '(map { my (%s, %s) = @$_; %s } (%s))',
        $name_var,
        $rendered_var,
        sprintf(
            '($_->[0], ( (ref(%s) eq q(CODE)) ? %s : %s ))',
            $rendered_var,
            sprintf(
                'sub { Sub::Name::subname(join(q(::), %s, %s), %s) }',
                pp($self->name),
                $name_var,
                $rendered_var,
            ),
            sprintf(
                'sub { Sub::Name::subname(join(q(::), %s, %s), sub () { %s }) }',
                pp($self->name),
                $name_var,
                $rendered_var,
            ),
        ),
        join(', ',
            map {
                sprintf(
                    '[%s, %s]',
                    pp($_->[0]),
                    $_->[1]->render,
                )
            }
            grep { not $_->[1]->isa(GlobalVariableClass) }
            map  { [$_, $self->environment->find_variable($_)] }
            @names,
        );
}

method render_version {

    # no version specified
    return () unless $self->version_expression;

    # render version package var setting
    return sprintf '$%s::VERSION = %s',
        $self->name,
        $self->version_expression->render;
}

method new_from_uncompiled (Str $class: Object $compiler, Object $env, Str $package, ArrayRef $body, Object $symbol) {

    # where we store our new attributes
    my %attrs = (
        name        => $package,
        environment => $env,
    );

    # dispatch body expressions to population methods
    for my $expr (@$body) {

        # expecting a list
        $expr->throw_parse_error(invalid_package_body => 'Only list expressions are expected in define-package body')
            unless $expr->isa(ListClass);

        # expecting at least a symbol
        $expr->throw_parse_error(invalid_package_body => 'Expecting at least a symbol in define-package body expression')
            unless $expr->content_count;

        # and it must be a symbol
        $expr->throw_parse_error(invalid_package_body => 'First item in define-package body expression must be symbol')
            unless $expr->get_content_item(0)->isa(SymbolClass);

        # try to find a method to parse with
        my $method_name = sprintf '_populate_with_%s_option', lc $expr->get_content_item(0)->value;
        $method_name    =~ s/-/_/g;
        my $method      = $class->can($method_name)
            or $expr->get_content_item(0)->throw_parse_error(
                invalid_package_body => sprintf "Invalid define-package body definition '%s'", $expr->get_content_item(0)->value,
            );

        # populate our attrs
        $class->$method(
            $compiler, $env, 
            \%attrs, 
            $package, 
            [@{ $expr->contents }[1 .. $expr->content_count - 1]],
            $expr->get_content_item(0),
            $symbol,
        );
    }

    # build our new class
    return $class->new(%attrs, $symbol->source_information);
}

method _populate_with_version_option (Object $compiler, Object $env, HashRef $attrs, Str $package, ArrayRef $args, $option, $symbol) {

    # allow this only once
    $option->throw_parse_error(
        invalid_version_definition => sprintf('You can only define the version for %s once', $symbol->value),
    ) if exists $attrs->{version};

    # version needs to be available
    $option->throw_parse_error(
        invalid_version_definition => sprintf('The version definition for %s expects only one argument', $symbol->value),
    ) unless @$args == 1;

    # store version expression
    $attrs->{version_expression} = $args->[0]->compile($compiler, $env);
}

method _populate_with_exports_option (Object $compiler, Object $env, HashRef $attrs, Str $package, ArrayRef $args, $option, $symbol) {

    # we need arguments
    $option->throw_parse_error(
        invalid_export_definition => sprintf('The export declaration in %s needs arguments', $symbol->value),
    ) unless @$args;

    # add exports to list
    push @{ $attrs->{symbol_export_expressions} //= [] },
        map { $_->compile($compiler, $env) } @$args;
}

__PACKAGE__->meta->make_immutable;

1;
