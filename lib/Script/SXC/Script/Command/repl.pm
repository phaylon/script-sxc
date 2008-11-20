=head1 NAME

Script::SXC::Script::Command::repl - the SXC read/eval/print loop

=cut

package Script::SXC::Script::Command::repl;
use Moose;
use MooseX::Method::Signatures;
use MooseX::CurriedHandles;
use MooseX::Types::Moose qw( Object );

use Term::ReadLine;
use Lexical::Persistence;
use Data::Dump   qw( pp );
use Perl::Tidy   qw( perltidy );
use Scalar::Util qw( blessed );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Script::Command';

my $FreshPrompt = '=> ';
my $RestPrompt  = '-> ';

has _terminal => (
    metaclass       => 'MooseX::CurriedHandles',
    is              => 'rw',
    isa             => Object,
    builder         => '_build_default_terminal',
    lazy            => 1,
    required        => 1,
    curried_handles => {
        'read_fresh_expression'   => { 'readline' => [sub { $FreshPrompt }] },
        'read_rest_of_expression' => { 'readline' => [sub { $RestPrompt }] },
    },
);

method _build_default_terminal {
    my $class = ref($self) || $self;
    my $term = Term::ReadLine->new($class);
    $term->ornaments(0);
    return $term;
}

override _build_default_compiler => method {
    my $compiler = super;
    $compiler->cleanup_environment(0);
    return $compiler;
};

method run {
    my $lex = Lexical::Persistence->new;
    my %lex;
    my $buf = '';
    my $chr = 0;

    $self->print_info("Welcome to the Script::SXC REPL\n", no_prefix => 1);
    
  READ:
    while (defined(my $line = ($buf ? $self->read_rest_of_expression(' ' x $chr) : $self->read_fresh_expression))) {

        my $body;   # body to print out
        my $stage;  # stage where an error might have occurred

        # try to get a result
        my $result = eval {

            # build token stream
            $stage       = 'tokenisation';
            my $code     = sprintf("%s%s\n", ($buf ? "$buf\n" : ''), $line);
            my $stream   = $self->build_stream(\$code);

            # transform to tree
            $stage       = 'transformation';
            my $tree     = $stream->transform;

            # compile the tree
            my $pre_text = join '', map { "my $_; " } keys %lex;    # recreate lexicals
            $stage       = 'compilation';
            my $compiled = $self->compile_tree($tree);
            $compiled->pre_text($pre_text);                         # add lexical defintions
            $body        = $compiled->get_body;

            # tidy up the body. the local sanitizes perltidy
            local @ARGV;
            perltidy(
                source      => \$body,
                destination => \$body,
            );

            # remember all existing variables
            $lex{ $_->render }++
                for grep { $_->isa('Script::SXC::Compiler::Environment::Variable') }
                    $self->top_environment->variables;

            # build the callback
            $stage       = 'evaluation';
            my $callback = $compiled->evaluated_callback;

            # run the code
            $stage       = 'execution';
            $lex->call($callback);
        };

        # an error occured, warn and move on
        if (my $e = $@) {

            # the error was only an unclosed expression, we can continue on the next line
            if (blessed($e) and $e->isa('Script::SXC::Exception::MissingClose')) {
                #warn pp($e), "\n";
                $buf .= "$line\n";
                $chr = $e->char_number;
                next READ;
            }

            # normal error
            $self->print_warning("An error occurred during $stage: $e");
            next READ;
        }

        # print body and result
        $self->print_info($body, no_prefix => 1, filter => sub { "# $_" });
        $self->print_info(pp($result) . "\n", no_prefix => 1);

        # reset buffer
        $buf = '';
    }
}

1;
