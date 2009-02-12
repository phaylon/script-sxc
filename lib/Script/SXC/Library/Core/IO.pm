package Script::SXC::Library::Core::IO;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Value', 'CompiledValue'];

use IO::Handle;
use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

for my $symbol_name (qw( say print )) {
    CLASS->add_procedure($symbol_name,
        firstclass  => sub { $symbol_name eq 'say' ? say(@_) : do { print @_ } },
        inline_fc   => 1,
        runtime_lex => { '$symbol_name' => $symbol_name },
        inliner     => method (Object :$compiler!, Object :$env!, ArrayRef :$exprs!, :$error_cb!, :$name!) {
            $compiler->add_required_package('IO::Handle');
            return CompiledValue->new(content => sprintf
                '(do { STDOUT->%s(%s); })',
                $symbol_name,
                join ', ',
                map { $_->compile($compiler, $env)->render } @$exprs,
            );
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;
