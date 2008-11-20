package Script::SXC::Library::Data;
use Moose;
use MooseX::Method::Signatures;

use CLASS;
use List::Util qw( min max );

use aliased 'Script::SXC::Compiled::Value', 'CompiledValue';

use signatures;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

#
#   lists
#

CLASS->add_procedure('list', 
    firstclass  => sub { [@_] },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {

        return CompiledValue->new(
            content  => sprintf('[( %s )]', join(', ', map { $_->compile($compiler, $env)->render } @$exprs)),
            typehint => 'list',
        );
    },
);

CLASS->add_procedure('head',
    firstclass  => sub ($ls, $num) {
        $num-- if defined $num;
        return defined $num 
            ? [ @$ls[0 .. min($num, $#$ls)] ]
            : ( @$ls ? $ls->[0] : undef );
    },
);

CLASS->add_procedure('tail',
    firstclass => sub ($ls, $num) {
        $num = $#$ls unless defined $num;
        return [ @$ls[ (@$ls - min(scalar(@$ls), $num)) .. $#$ls ] ];
    },
);

CLASS->add_procedure('size',
    firstclass  => sub ($ls) { scalar @$ls },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs) {

        return CompiledValue->new(
            content  => sprintf('scalar(@{( %s )})', $exprs->[0]->compile($compiler, $env)->render),
            typehint => 'number',
        );
    },
);

CLASS->add_procedure('last-index',
    firstclass  => sub ($ls) { $#{ $ls } },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs) {

        return CompiledValue->new(
            content  => sprintf('($#{( %s )})', $exprs->[0]->compile($compiler, $env)->render),
            typehint => 'number',
        );
    },
);

#
#   hashes
#

CLASS->add_procedure('hash', 
    firstclass  => sub { +{@_} },
    inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!) {

        return CompiledValue->new(
            content  => sprintf('+{( %s )}', join(', ', map { $_->compile($compiler, $env, to_string => 1)->render } @$exprs)),
            typehint => 'hash',
        );
    },
);

1;
