package Script::SXC::Library::Data::Regex;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::Runtime::Validation;

use Script::SXC::lazyload
    'Script::SXC::Compiler::Environment::Variable',
    ['Script::SXC::Compiled::TypeCheck',    'CompiledTypeCheck'],
    ['Script::SXC::Compiled::Value',        'CompiledValue'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

for my $match_name ('match', 'match-all') {
    CLASS->add_procedure($match_name,
        firstclass => sub {
            Script::SXC::Runtime::Validation->runtime_arg_count_assertion($match_name, [@_], min => 2, max => 2);
            Script::SXC::Runtime::Validation->runtime_type_assertion(
                $_[0], 'regex', $match_name . ' expects a regular expression as first argument');
            my ($regex, $matchee) = @_;
            my $res = [ $match_name eq 'match' ? ($matchee =~ $regex) : ($matchee =~ /$regex/g) ];
            return @$res ? $res : undef;
        },
        inline_fc => 1,
        runtime_req => ['Validation'],
        runtime_lex => { '$match_name' => $match_name },
        inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
            CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
            my $resvar = Variable->new_anonymous('matches');
            my $rxvar  = Variable->new_anonymous('regex');
            return CompiledValue->new(content => sprintf
                '(do { my %s = %s; my %s = [ %s =~ /%s/%s ]; scalar(@{ %s }) ? %s : undef })',
                $rxvar->render,
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'regex',
                    source_item => $exprs->[0],
                    message     => "$name expects a regular expression as first argument",
                )->render,
                $resvar->render,
                $exprs->[1]->compile($compiler, $env)->render,
                $rxvar->render,
                ( $match_name eq 'match' ? '' : 'g' ),
                $resvar->render,
                $resvar->render,
            );
        },
    );
}

for my $match_name ('named-match', 'named-match-full') {
    CLASS->add_procedure($match_name,
        firstclass => sub {
            Script::SXC::Runtime::Validation->runtime_arg_count_assertion($match_name, [@_], min => 2, max => 2);
            Script::SXC::Runtime::Validation->runtime_type_assertion(
                $_[0], 'regex', $match_name . ' expects a regular expression as first argument');
            my @res = ($_[1] =~ $_[0]);
            return 
                @res 
                ? +{ $match_name eq 'named-match' ? %+ : %- }
                : undef;
        },
        inline_fc => 1,
        runtime_req => ['Validation'],
        runtime_lex => { '$match_name' => $match_name },
        inliner => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
            CLASS->check_arg_count($error_cb, $name, $exprs, min => 2, max => 2);
            my $resvar = Variable->new_anonymous('named_matchlist', sigil => '@');
            return CompiledValue->new(content => sprintf
                '(do { my %s = (%s =~ %s); %s ? +{ %s } : undef })',
                $resvar->render,
                $exprs->[1]->compile($compiler, $env)->render,
                CompiledTypeCheck->new(
                    expression  => $exprs->[0]->compile($compiler, $env),
                    type        => 'regex',
                    source_item => $exprs->[0],
                    message     => "$name expects a regular expression as first argument",
                )->render,
                $resvar->render,
                ( $match_name eq 'named-match' ? '%+' : '%-' ),
            );
        },
    );
}

CLASS->add_procedure('regex?',
    firstclass  => CLASS->build_firstclass_reftest_operator('regex?', 'Regexp'),
    inline_fc   => 1,
    inliner     => CLASS->build_inline_reftest_operator('Regexp'),
);

__PACKAGE__->meta->make_immutable;

1;
