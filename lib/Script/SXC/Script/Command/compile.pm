=head1 NAME

Script::SXC::Script::Command::compile - compile SXC files to Perl

=cut

package Script::SXC::Script::Command::compile;
use Moose;
use 5.010;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( Bool );

use IO::Handle;
use Perl::Tidy qw( perltidy );

use autodie;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Script::Command';

has pretty => (
    is              => 'rw',
    isa             => Bool,
    documentation   => 'enable prettying of generated perl-code (via Perl::Tidy)',
);

method run (HashRef $options, ArrayRef $arguments) {

    my $body = do {
        local $/;
        @$arguments
            ? do { open my $fh, '<', $arguments->[0]; <$fh> }
            : <STDIN>;
    };

    $body =~ s/\A#!.*?\n/\n/;

    my $compiled = eval {
        my $stream   = $self->build_stream(\$body);
        my $tree     = $stream->transform;
        $self->compile_tree($tree);
    };

    if (my $e = $@) {
        warn "An error occured during compilation: $e\n";
        exit 23;
    }

    my $compiled_body = $compiled->get_full_body;

    if ($self->pretty) {
        local @ARGV;
        perltidy(source => \$compiled_body, destination => \$compiled_body);
    }

    say $compiled_body;
}

__PACKAGE__->meta->make_immutable;

1;
