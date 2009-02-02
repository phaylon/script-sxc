=head1 NAME

Script::SXC::Script::Command::repl - the SXC read/eval/print loop

=cut

package Script::SXC::Script::Command::repl;
use Moose;
use MooseX::Method::Signatures;
use MooseX::AttributeHelpers;
use MooseX::CurriedHandles;
use MooseX::Types::Moose qw( Object Str ArrayRef Int Bool );

use CLASS;
use Term::ReadLine;
use Lexical::Persistence;
use File::HomeDir;
use Path::Class::Dir;
use Path::Class::File;
use Cwd;
use File::Path      qw( mkpath );
use Data::Dump      qw( pp );
use Perl::Tidy      qw( perltidy );
use Scalar::Util    qw( blessed );
use List::MoreUtils qw( uniq );

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

has _history => (
    metaclass   => 'Collection::Array',
    is          => 'rw',
    isa         => ArrayRef,
    required    => 1,
    builder     => '_read_history_file',
    provides    => {
        'unshift'   => 'add_to_history',
        'pop'       => 'remove_last_history_item',
        'count'     => 'history_item_count',
    },
);

has history_max_lines => (
    is              => 'rw',
    isa             => Int,
    required        => 1,
    default         => 200,
    documentation   => 'maximum number of lines the history will remember persistently (default: 200)',
);

after add_to_history => sub {
    my $self = shift;
    $self->_history([ uniq @{ $self->_history } ]);
    $self->remove_last_history_item
        if $self->history_item_count > $self->history_max_lines;
};

method build_default_history_filename { '.script-sxc-history' };

has history_filename => (
    is              => 'rw',
    isa             => Str,
    required        => 1,
    builder         => 'build_default_history_filename',
    lazy            => 1,
    documentation   => 'name of history file (default: ' . (CLASS->build_default_history_filename) . ')',
);

method build_default_history_file {
    use autodie;
    my $filepath = Path::Class::Dir->new((-w cwd) ? cwd : (File::Homedir->my_data, '.sxc'));
    my $file = $filepath->file($self->history_filename)->stringify;
    return $file;
};

has history_file => (
    is              => 'rw',
    isa             => Str,
    required        => 1,
    builder         => 'build_default_history_file',
    lazy            => 1,
    documentation   => 'complete path to history file',
);

has pretty => (
    is              => 'rw',
    isa             => Bool,
    documentation   => 'pretty print compiled output',
);

has add_line_numbers => (
    is              => 'rw',
    isa             => Bool,
    documentation   => 'add line numbers to compiled output',
);

method _build_default_terminal {
    my $class = ref($self) || $self;
    my $term = Term::ReadLine->new($class);
    $term->ornaments(0);
    return $term;
};

method _write_history_file {
    use autodie;
    my $filepath = Path::Class::File->new($self->history_file)->dir;
    mkpath $filepath->stringify
        unless -e $filepath;
    unless (-e $self->history_file) {
        open my $fh, '>', $self->history_file;
    }
    open my $fh, '>:utf8', $self->history_file;
    print $fh sprintf "%s\n", $_
        for uniq map { length($_) > 500 ? () : $_ }@{ $self->_history };
};

method _read_history_file {
    use autodie;
    open my $fh, '<', $self->history_file;
    my @lines = <$fh>;
    chomp @lines;
    $self->_terminal->AddHistory(reverse @lines)
        if @lines;
    return \@lines;
};

override _build_default_compiler => method {
    my $compiler = super;
    $compiler->cleanup_environment(0);
    return $compiler;
};

method DEMOLISH {
    $self->_write_history_file;
};

method run {
    my $lex = Lexical::Persistence->new;
    my %lex;
    my @buf;
    my $chr = 0;

    $self->print_info("Welcome to the Script::SXC REPL\n", no_prefix => 1);
    
  READ:
    while (defined(my $line = (@buf ? $self->read_rest_of_expression(' ' x $chr) : $self->read_fresh_expression))) {
        local $@;

        my $body;   # body to print out
        my $stage;  # stage where an error might have occurred
        my $real_body;

        # try to get a result
        my $result = eval {

            # build token stream
            $stage       = 'tokenisation';
            my $code     = join("\n", @buf, $line);
            my $stream   = $self->build_stream(\$code);

            # transform to tree
            $stage       = 'transformation';
            my $tree     = $stream->transform;

            # compile the tree
            my $pre_text = join '',                                 # recreate lexicals
                map  { "my $_; " }
                keys %lex;
            $stage       = 'compilation';
            my $compiled = $self->compile_tree($tree);
            $compiled->pre_text($pre_text);                         # add lexical defintions
            $body        = $compiled->get_full_body;
            $real_body   = $body;

            # tidy up the body. the local sanitizes perltidy
            local @ARGV;
            perltidy(
                source      => \$body,
                destination => \$body,
                perltidyrc  => $self->shared_file('perltidyrc'),
            ) if $self->pretty;

            # remember all existing variables
            $lex{ $_->render }++
                for grep { 
                        $_->isa('Script::SXC::Compiler::Environment::Variable') 
                            and not
                        $_->isa('Script::SXC::Compiler::Environment::Variable::Global')
                    }
                    $self->top_environment->variables;

            # build the callback
            $stage       = 'evaluation';
            my $callback = $compiled->evaluated_callback;

            # run the code
            $stage       = 'execution';
            $lex->call($callback);
        };

        $body = do {
            my @lines  = split /\n/, $body;
            my $maxlen = length scalar @lines;
            my $ln     = 1;
            join "\n", map { sprintf(sprintf('%%%ds: %%s', $maxlen), $ln++, $_) } @lines;
        } if $self->add_line_numbers;

        # an error occured, warn and move on
        if (my $e = $@) {

            # the error was only an unclosed expression, we can continue on the next line
            if (blessed($e) and $e->isa('Script::SXC::Exception::MissingClose')) {
                push @buf, $line;
                $chr = $e->char_number;
                next READ;
            }

            # normal error
            no warnings;
            warn "\n# compiled result:\n$body\n";
            warn "An error occured during $stage:\n\t$e\n";
            do { chomp(my $l = $line); $self->add_to_history($l) };
            #$self->print_info($body, no_prefix => 1, filter => sub { "# $_" });
            #$self->print_warning("An error occurred during $stage: $e");
            @buf = ();
            next READ;
        }

        # history management
        do { chomp(my $l = $line); $self->add_to_history($l) };

        # print body and result
        $self->print_info($body, no_prefix => 1, filter => sub { "$_" });
        $self->print_info(pp($result) . "\n", no_prefix => 1);

        # reset buffer
        @buf = ();
    }
}

1;
