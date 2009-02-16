package Script::SXC::Compiled::Class;
use 5.010;
use Moose;
use MooseX::Types::Moose    qw( ArrayRef Object Str HashRef );
use MooseX::AttributeHelpers;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use constant SymbolClass        => 'Script::SXC::Tree::Symbol';
use constant StringClass        => 'Script::SXC::Tree::String';
use constant ListClass          => 'Script::SXC::Tree::List';
use constant RuntimeTypeError   => 'Script::SXC::Exception::Runtime::TypeError';

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable';

require Script::SXC::Tree::Dot;

use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Compiled::Package';

has superclass_expressions => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef[Str],
    default     => sub { [] },
    required    => 1,
    provides    => {
        'push'      => 'add_to_superclass_expressions',
        'count'     => 'superclass_expression_count',
    },
);

has method_expressions => (
    metaclass   => 'Collection::Hash',
    is          => 'rw',
    isa         => HashRef[Str],
    default     => sub { {} },
    required    => 1,
    provides    => {
        'keys'      => 'method_names',
        'get'       => 'get_method_expression',
    },
);

method render {

    return sprintf(
        'do { Moose::Meta::Class->create(%s, %s); $INC{%s} ||= %s; %s }',
        pp($self->name),
        join(', ',
            $self->render_version,
            $self->render_superclass_expressions,
            $self->render_method_expressions,
        ),
        pp($self->filename),
        pp($self->source_description),
        pp($self->name),
    );
}

method render_version {

    return unless $self->version_expression;

    return sprintf 'version => %s', $self->version_expression->render;
}

method render_method_expressions {

    return unless $self->method_names;

    return sprintf 'methods => +{ %s }',
        join ', ',
        map { sprintf '%s => %s', pp($_), $self->get_method_expression($_) }
        $self->method_names;
}

method render_superclass_expressions {

    my @superclasses = @{ $self->superclass_expressions };
    @superclasses = (pp 'Moose::Object')
        unless @superclasses;

    return sprintf 'superclasses => [%s]', join ', ', @superclasses;
}

method _populate_with_method_option (Object $compiler, Object $env, HashRef $attrs, Str $package, ArrayRef $args, $option, $symbol) {
    my $name = $symbol->value;

    $symbol->throw_parse_error(invalid_method_options => "Method specification in $name expects name, signature and body")
        unless @$args >= 3;

    my ($method, $signature, @body) = @$args;

    $method->throw_parse_error(invalid_method_name => "Method name in $name must be a symbol")
        unless $method->isa(SymbolClass);

    if ($signature->isa(ListClass)) {
        $signature = $signature->new_item_with_source(List => { 
            contents => [
                $signature->new_item_with_source(Symbol => { value => 'self' }),
                @{ $signature->contents },
            ],
        });
    }
    elsif ($signature->isa(SymbolClass)) {
        $signature = $signature->new_item_with_source(List => {
            contents => [
                $signature->new_item_with_source(Symbol => { value => 'self' }),
                $signature->new_item_with_source(Dot    => { value => '.' }),
                $signature,
            ],
        });
    }
    else {
        $signature->throw_parse_error(invalid_method_signature => "Method signature in $name must be symbol or list");
    }

    $attrs->{method_expressions}{ $method->value } = $option->new_item_with_source(List => {
        contents => [
            $option->new_item_with_source(Builtin => { value => 'lambda' }),
            $signature,
            @body,
        ],
    })->compile($compiler, $env)->render;
}

method _populate_with_extends_option (Object $compiler, Object $env, HashRef $attrs, Str $package, ArrayRef $args, $option, $symbol) {
    my $name = $symbol->value;
    
    $symbol->throw_parse_error(invalid_superclasses => "$name expects at least one argument to extends option")
        unless @$args;

    my $value = Variable->new_anonymous('extend_value')->render;

    push @{ $attrs->{superclass_expressions} //= [] }, map { 
        sprintf(
            '(do { my %s = %s; %s })',
            $value,
            $_->compile($compiler, $env)->render,
            sprintf(
                '( (ref(%s) and ref(%s) eq %s) ? %s : %s )',
                $value,
                $value,
                pp('Script::SXC::Runtime::Symbol'),
                sprintf(
                    '%s->value',
                    $value,
                ),
                sprintf(
                    '( (defined(%s) and not ref(%s)) ? %s : %s )',
                    $value,
                    $value,
                    $value,
                    sprintf(
                        '(do { require %s; %s->throw(%s) })',
                        RuntimeTypeError,
                        RuntimeTypeError,
                        pp( message => "Valid values for extends can only be strings or symbols",
                            $_->source_information ),
                    ),
                ),
            ),
        );
    } @$args;

    return 1;
}

method _populate_with_exports_option (Object $compiler, Object $env, HashRef $attrs, Str $package, ArrayRef $args, $option, $symbol) {
    my $opt_name = $option->value;
    my $sym_name = $symbol->value;

    $option->throw_parse_error(invalid_class_option => "You cannot use '$opt_name' in $sym_name");
}

1;
