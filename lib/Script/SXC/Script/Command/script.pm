=head1 NAME

Script::SXC::Script::Command::script - run an sxc script file

=cut

package Script::SXC::Script::Command::script;
use Moose;
use MooseX::Method::Signatures;

use Data::Dump qw( pp );

use autodie;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Script::Command';

method run (HashRef $options!, ArrayRef $args!) {
    my ($filename)   = @$args;
    my $out_filename = $filename . 'c';
    if (-e $out_filename) {
        warn "FOUND OUTFILE\n";
        $self->run_compiled_file($out_filename);
    }

    open my $fh, '<:utf8', $filename;
    my $body = eval {
        my @content  = <$fh>;
        shift @content
            if @content and $content[0] =~ /^#!/;
        my $content  = join '', @content;
        my $stream   = $self->build_stream(\$content);
        my $tree     = $stream->transform;
        my $compiled = $self->compile_tree($tree);
        ''. $compiled->get_full_body;
    };
#    warn "BADA\n";
    print $@ and exit if $@;

    open my $out_fh, '>:utf8', $out_filename;
    print $out_fh $body;
    #warn "DONE $out_filename\n";
    $self->run_compiled_file($out_filename);
}

method run_compiled_file ($filename) {
    exec $^X, $filename;
}

__PACKAGE__->meta->make_immutable;

1;
