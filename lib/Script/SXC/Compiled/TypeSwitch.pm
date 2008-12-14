package Script::SXC::Compiled::TypeSwitch;
use Moose;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw( Object Str ArrayRef HashRef );

use Data::Dump qw( pp );

use aliased 'Script::SXC::Compiler::Environment::Variable';

use namespace::clean -except => 'meta';

has expression => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => {
        'render_expression' => 'render',
    },
);

has typemap => (
    metaclass   => 'Collection::Hash',
    is          => 'rw',
    isa         => HashRef[Str],
    required    => 1,
    default     => sub { {} },
    provides    => {
        'kv'        => 'typemap_pairs',
        'get'       => 'get_mapping_for_type',
        'exists'    => 'has_mapping_for_type',
        'keys'      => 'known_types',
    },
);

has source_item => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
    handles     => [qw( source_information )],
);

has error_type => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => 'type_error',
);

has message => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    lazy        => 1,
    default     => sub { 
        my $self = shift; 
        return 'Type error: Expected one of: ' . join(', ', $self->known_types);
    },
);

has error_class => (
    is          => 'rw',
    isa         => Str,
    required    => 1,
    default     => 'Script::SXC::Exception::TypeError',
);

my %InternalRuntimeType = (
    'string'        => '(not(ref(%s)) and defined(%s))',
    'object'        => 'Scalar::Util::blessed(%s)',
    'keyword'       => '(blessed(%s) and (%s)->isa(q(Script::SXC::Runtime::Keyword)))',
    'symbol'        => '(blessed(%s) and (%s)->isa(q(Script::SXC::Runtime::Symbol)))',
    'list'          => '(ref(%s) and ref(%s) eq q(ARRAY))',
    'hash'          => '(ref(%s) and ref(%s) eq q(HASH))',
    'code'          => '(ref(%s) and ref(%s) eq q(CODE))',
    'defined'       => 'defined(%s)',
);
my @InternalRuntimeTypeOrder = qw( defined string list hash code object keyword symbol );

method render {

    my $value_var  = Variable->new_anonymous('ts_value')->render;
    my $result_var = Variable->new_anonymous('ts_result')->render;
    my $if_state   = 'if';

    return sprintf 'do { my %s = %s; my %s; %s else { %s->throw(%s, message => "%s") } %s }',
        $value_var,
        $self->render_expression,
        $result_var,
        (   join ' ',
            map  { 
                    # switch if to elsif
                    my $st    = $if_state; 
                    $if_state = 'elsif';
                    # replace all %s in type specific expression with the value var
                    (my $map   = $self->get_mapping_for_type($_->[0])) =~ s/\%s/$value_var/g;
                    # build the condition
                    sprintf ' %s (%s) { %s = %s } ', $st, $_->[1], $result_var, $map;
                 }
            map  { (my $cond = $InternalRuntimeType{ $_ }) =~ s/\%s/$value_var/g; [$_, $cond] }
            grep { $self->has_mapping_for_type($_) }
                 @InternalRuntimeTypeOrder,
        ),
        $self->error_class,
        pp(
            $self->source_information, 
            type => $self->error_type,
        ),
        do { (my $msg = $self->message) =~ s/\%s/$value_var/g; $msg =~ s/"/\\"/g; $msg },
        $result_var,
        ;
}

1;
