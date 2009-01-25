package Script::SXC::Library;
use 5.010;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Method::Signatures;

use Scalar::Util qw( blessed );
use Data::Dump   qw( pp );

use Script::SXC::Types qw( HashRef );
use Script::SXC::Runtime::Validation;

use Script::SXC::lazyload
    [qw( Script::SXC::Compiled::Value   CompiledValue )],
    'Script::SXC::Compiler::Environment::Variable',
    'Script::SXC::Library::Item::Procedure',
    'Script::SXC::Library::Item::Inline',
    'Script::SXC::Exception::ArgumentError';

use constant ApplyLibrary => 'Script::SXC::Library::Core::Apply';

use CLASS;
use namespace::clean -except => 'import';

my (%Items, %DelegatedItems);

method _items {
    my $class = ref($self) || $self;
    return $Items{ $class } //= {};
}

method _delegated_items {
    my $class = ref($self) || $self;
    return $DelegatedItems{ $class } //= {};
}

#class_has _items => (
#    is          => 'rw',
#    isa         => HashRef,
#    default     => sub { {} },
#);
#
#class_has _delegated_items => (
#    is          => 'rw',
#    isa         => HashRef,
#    default     => sub { {} },
#);

method add_delegated_items (Str $class: HashRef $item_map!) {
    
    for my $library (keys %$item_map) {
        for my $item (@{ $item_map->{ $library } }) {
            $class->_delegated_items->{ $item } = $library;
        }
    }
}

method build_joining_operator (Str $operator!, CodeRef :$around_args?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {
        return CompiledValue->new(content => 0)
            unless @$exprs;
        return CompiledValue->new(content => sprintf(
            '(%s)', 
            join " $operator ", 
            map { $around_args ? $around_args->($_, $compiler, $env) : $_->compile($compiler, $env)->render } 
            @$exprs,
        ));
    };
}

method build_firstclass_sequence_operator (Str $operator!, CodeRef $test!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($operator, [@_], min => 2);
        my $last = shift;
        while (@_) {
            return undef
                unless $test->($last, $_[0]);
            $last = shift;
        }
        return 1;
    }, runtime_req => ['Validation'], runtime_lex => { '$operator' => $operator, '$test' => $test };
}

method build_firstclass_equality_operator (Str $operator!, CodeRef $test!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($operator, [@_], min => 2);
        my $val = shift;
        $test->($val, $_) 
            or return undef
            for @_;
        return 1;
    }, runtime_req => ['Validation'], runtime_lex => { '$operator' => $operator, '$test' => $test };
}

method build_direct_inliner ($lib: Str $package!, Str $name!, Int :$min?, Int :$max?, Str :$typehint?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!, :$symbol!) {
        $lib->check_arg_count(
            $error_cb, $name, $exprs,
            ( $min ? (min => $min) : () ),
            ( $max ? (max => $max) : () ),
        ) if defined $min or defined $max;
        $compiler->add_required_package($package);
        return CompiledValue->new(($typehint ? (typehint => $typehint) : ()), content => sprintf
            '(do { %sscalar(%s::%s(%s)) })',
            sprintf(
                qq{\n#line %d "%s"\n},
                $symbol->line_number,
                $symbol->source_description,
            ),
            $package,
            $name,
            join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
        );
    };
}

method build_direct_firstclass ($lib: Str $package!, Str $name!, Int :$min?, Int :$max?, Str :$procname?) {
    $procname //= $name;
    my $proc;
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion(
            $procname, [@_],
            ( $min ? (min => $min) : () ),
            ( $max ? (max => $max) : () ),
        ) if defined $min or defined $max;
        unless ($proc) {
            Class::MOP::load_class($package);
            $proc = do { no strict 'refs'; \&{ "${package}::${name}" } };
        }
        goto $proc;
    }, runtime_req => ['Validation', '+Class::MOP'], runtime_lex => {
        '$proc'     => undef,
        '$package'  => $package,
        '$name'     => $name,
        '$min'      => $min,
        '$max'      => $max,
        '$procname' => $procname,
    };
}

method build_firstclass_reftest_operator ($lib: Str $name!, Str $reftype!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($name, [@_], min => 1);
        ref($_) and ref($_) eq $reftype or return undef
            for @_;
        return 1;
    }, runtime_req => ['Validation'], runtime_lex => { '$name' => $name, '$reftype' => $reftype };
}

method build_inline_reftest_operator ($lib: Str $reftype!) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        $lib->check_arg_count($error_cb, $name, $exprs, min => 1);
        $compiler->add_required_package('List::MoreUtils');
        return CompiledValue->new(typehint => 'bool', content => sprintf
            '( not( grep { not(ref and ref eq %s) } (%s) ) ? 1 : undef )',
            pp($reftype),
            join ', ', map { $_->compile($compiler, $env)->render } @$exprs,
        );
    };
}

method build_firstclass_nonequality_operator (Str $operator!, CodeRef $test!) {
    return sub {
        Script::SXC::Runtime::Validation->runtime_arg_count_assertion($operator, [@_], min => 2);
        my $current = shift;
        while (@_) {
            return undef 
                if grep { not $test->($current, $_) } @_;
            $current = shift;
        }
        return 1;
    }, runtime_req => ['Validation'], runtime_lex => { '$operator' => $operator, '$test' => $test };
}

method build_inline_nonequality_operator (Str $operator!, Str :$perl_operator?, Bool :$to_string?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        # TODO: optimize var-expr case, optimize single-arg case, optimize $var rendering
        my $curr   = Variable->new_anonymous('neq_current');
        my $values = Variable->new_anonymous('neq_values', sigil => '@');
        my $true   = Variable->new_anonymous('neq_true');
        return CompiledValue->new(content => sprintf 
            '(do { %s })',
            join '; ',
            sprintf('my %s = (%s)',
                $values->render,
                join ', ', 
                map { $_->compile($compiler, $env, to_string => $to_string)->render }
                @$exprs
            ),
            sprintf('my %s = shift(%s)',
                $curr->render,
                $values->render,
            ),
            sprintf('my %s = 1',
                $true->render,
            ),
            sprintf('while (%s and %s) { %s }',
                $true->render,
                $values->render,
                join('; ',
                    sprintf('%s = ( not(grep { not(%s %s $_) } %s) ? 1 : undef )',
                        $true->render,
                        $curr->render,
                        $perl_operator // $operator,
                        $values->render,
                    ),
                    sprintf('%s = shift(%s)',
                        $curr->render,
                        $values->render,
                    ),
                ),
            ),
            $true->render,
        );
    };
}

method build_inline_equality_operator (Str $operator!, Str :$perl_operator?, Bool :$to_string?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        # TODO: optimize var-expr case, optimize single-arg case, optimize $var rendering
        my $curr   = Variable->new_anonymous('eq_current');
        my $values = Variable->new_anonymous('eq_values', sigil => '@');
        my $true   = Variable->new_anonymous('eq_true');
        return CompiledValue->new(content => sprintf
            '(do { my %s = (%s); my %s = shift(%s); my %s = 1; while (%s and %s) { %s = ( (%s %s shift(%s)) ? 1 : undef ) } %s })',
            $values->render,
            join(', ', map { $_->compile($compiler, $env, to_string => $to_string)->render } @$exprs),
            $curr->render,
            $values->render,
            $true->render,
            $true->render,
            $values->render,
            $true->render,
            $curr->render,
            $perl_operator // $operator,
            $values->render,
            $true->render,
        );
    },
}

method build_inline_sequence_operator (Str $operator!, Str :$perl_operator?, Bool :$to_string?) {
    return method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$name!, :$error_cb) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 2);
        # TODO: optimize var-expr case, optimize single-arg case, optimize $var rendering
        my $values = Variable->new_anonymous('seq_values', sigil => '@');
        my $last   = Variable->new_anonymous('seq_last');
        my $true   = Variable->new_anonymous('seq_true');
        return CompiledValue->new(content => sprintf
            '(do { %s })',
            join '; ',
            sprintf('my %s = (%s)', 
                $values->render, 
                join ', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs,
            ),
            sprintf('my %s = shift(%s)',
                $last->render,
                $values->render,
            ),
            sprintf('my %s = 1',
                $true->render,
            ),
            sprintf('while (%s and %s) { %s }',
                $true->render,
                $values->render,
                join('; ',
                    sprintf('%s = ( (%s %s %s) ? 1 : undef )',
                        $true->render,
                        $last->render,
                        $perl_operator // $operator,
                        $values->render_array_access(0),
                    ),
                    sprintf('%s = shift(%s)',
                        $last->render,
                        $values->render,
                    ),
                ),
            ),
            $true->render
        );
    };
}

method get (Str $name!) {
#    warn "LIBRARY $self (FETCHING $name)\n";

    if (my $delegated_lib = $self->_delegated_items->{ $name }) {
        Class::MOP::load_class($delegated_lib);
#        warn "FETCHING $name FROM DELEGATED $delegated_lib\n";
        return $delegated_lib->get($name);
    }

    my $item = $self->_items->{ $name }
        or die "Unable to find $name in $self";

    return $item;
};

method has (Str $name!) {
    return ! ! ( $self->_items->{ $name } or $self->_delegated_items->{ $name } );
};

method check_arg_count ($cb!, Str $name!, ArrayRef $exprs!, Int :$min?, Int :$max?) {

    # missing arguments
    $cb->('missing_arguments', 
        message => sprintf('Invalid argument count (missing arguments): %s expects at least %d argument%s (got %d)',
            $name, $min, (($min == 1) ? '' : 's'), scalar(@$exprs)),
    ) if defined $min and @$exprs < $min;

    # too many arguments
    $cb->('too_many_arguments', 
        message => sprintf('Invalid argument count (too many arguments): %s expects at most %d argument%s (got %d)',
            $name, $max, (($max == 1) ? '' : 's'), scalar(@$exprs)),
    ) if defined $max and @$exprs > $max;
}

=for history

method runtime_arg_count_assertion ($name!, $args!, :$min, :$max) {
    my $got = scalar @$args;

    ArgumentError->throw_to_caller(
        type        => 'missing_arguments',
        message     => "Missing arguments: $name expects at least $min arguments (got $got)",
        up          => 3,
    ) if defined $min and $got < $min;

    ArgumentError->throw_to_caller(
        type        => 'too_many_arguments',
        message     => "Too many arguments: $name expects at most $max arguments (got $got)",
        up          => 3,
    ) if defined $max and $got > $max;
}

my %InternalRuntimeType = (
    'string'        => sub { not ref $_[0] and defined $_[0] },
    'object'        => sub { blessed $_[0] },
    'keyword'       => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Keyword') },
    'symbol'        => sub { blessed $_[0] and $_[0]->isa('Script::SXC::Runtime::Symbol') },
    'list'          => sub { ref $_[0] and ref $_[0] eq 'ARRAY' },
    'hash'          => sub { ref $_[0] and ref $_[0] eq 'HASH' },
    'code'          => sub { ref $_[0] and ref $_[0] eq 'CODE' },
    'regex'         => sub { ref $_[0] and ref $_[0] eq 'Regexp' },
    'defined'       => sub { defined $_[0] },
);

method runtime_type_assertion ($value!, $type!, $message!) {
    unless ($InternalRuntimeType{ $type }->($value)) {
        ArgumentError->throw_to_caller(
            type    => 'invalid_argument_type',
            message => $message,
            up      => 3,
        );
    }
}

=cut

sub runtime_type_assertion      { goto \&Script::SXC::Runtime::Validation::runtime_type_assertion }
sub runtime_arg_count_assertion { goto \&Script::SXC::Runtime::Validation::runtime_arg_count_assertion }

method undef_when_empty (Str $body!) {
    return length($body) ? $body : 'undef';
}

method other_library ($class: Str $library!) {
    Class::MOP::load_class($library);
    return $library;
}

method call_in_other_library($class: Str $library!, Str $proc!, ArrayRef $args = []) {
    return $class->other_library($library)->get($proc)->firstclass->(@$args);
};

method add ($class: $name!, Object $item!) {
    #use Data::Dump qw( pp );
    #warn "AFTER ADD: " . pp(\%Items) . "\n";
    $class->_items->{ $_ } = $item
        for ref($name) ? @$name : $name;
    return $item;
};

method add_procedure ($class: $name!, Method :$firstclass!, Method :$inliner, :$setter?, :$inline_fc?, ArrayRef :$runtime_req?, :$runtime_lex) {
    $runtime_lex //= {};
    my $proc = Procedure->new(
        firstclass  => $firstclass,
        ($inliner     ? (inliner             => $inliner)     : ()),
        ($setter      ? (setter              => $setter)      : ()),
        ($inline_fc   ? (firstclass_inlining => $inline_fc)   : ()),
        ($runtime_req ? (runtime_req         => $runtime_req) : ()),
        ($runtime_lex ? (runtime_lex         => $runtime_lex) : ()),
        library     => $class,
        name        => (ref($name) ? $name->[0] : $name),
    );
    $class->add($_, $proc)
        for (ref($name) ? @$name : $name);
};

method add_inliner ($class: $name!, :$via!) {
    my $inliner = Inline->new(
        inliner     => $via,
    );
    return $class->add($name, $inliner);
};

method call_apply ($applicant!, ArrayRef $args!) {
    state $apply = $self->other_library(ApplyLibrary)->get('apply')->firstclass;
    @_ = ($applicant, $args);
    goto $apply;
}

method get_apply {
    state $apply = $self->other_library(ApplyLibrary)->get('apply')->firstclass;
    return $apply;
}

__PACKAGE__->meta->make_immutable;

1;
