package Script::SXC::Library::Item::Procedure::Inlined;
use 5.010;
use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Object );

use Data::Dump qw( pp );
use B::Deparse;

use namespace::clean -except => 'meta';

extends 'Script::SXC::Library::Item::Procedure';

has compiler => (
    is          => 'rw',
    isa         => Object,
    required    => 1,
);

method render {
    state $deparser = B::Deparse->new;

    $self->compiler->add_required_package(
          $_ eq '+'         ? 'Script::SXC::Runtime' 
        : /^\+(.+)$/        ? $1
        :                     "Script::SXC::Runtime::$_"
    ) for @{ $self->runtime_req };

    return sprintf '(do { %s; sub %s })',
        join('; ',
            map { my $v = $self->runtime_lex->{ $_ }; sprintf(
                'my %s = %s',
                $_,
                ( ref($v) eq 'CODE' 
                  ? ('sub ' . $deparser->coderef2text($v))
                  : pp($v) ),
            ) } keys %{ $self->runtime_lex },
        ),
        $deparser->coderef2text($self->firstclass);
}

1;
