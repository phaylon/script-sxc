package Script::SXC::Reader::Source::String;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;

use Script::SXC::Reader::Types qw( Str SourceObject ScalarRef );

use Data::Dump qw( dump );
use CLASS;
use namespace::clean -except => 'meta';
use Method::Signatures;

with 'Script::SXC::Reader::Source';

coerce SourceObject, from ScalarRef, 
    via { CLASS->new(lines => $$_) };

has lines => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    coerce      => 1,
    provides    => {
        'count'     => 'line_count',
        'get'       => 'get_line_at_index',
    },
);

method next_line {

    unless ($self->has_line_number) {
        $self->line_number(1);
    }

    if ($self->end_of_stream) {
        $self->reset_line_number;
        $self->clear_line_content;
        return undef;
    }

    $self->inc_line_number;
    $self->line_content($self->get_line_at_index($self->line_number - 1));

    return $self->line_content;
};

method end_of_stream { $self->line_number >= $self->line_count };

method source_description { '(scalar)' };

1;
