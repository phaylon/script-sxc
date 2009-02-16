package Script::SXC::Library::Core::OO;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant StringClass    => 'Script::SXC::Tree::String';
use constant SymbolClass    => 'Script::SXC::Tree::Symbol';

use Script::SXC::lazyload
    ['Script::SXC::Compiled::Class', 'CompiledClass'];

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_inliner('define-class',
    via => method (Object :$compiler!, Object :$env!, Str :$name!, ArrayRef :$exprs!, :$error_cb, :$allow_definitions, :$symbol) {
        CLASS->check_arg_count($error_cb, $name, $exprs, min => 1);
        my ($class_name, @body) = @$exprs;

        $class_name->throw_parse_error(invalid_class_name => "Name of class for $name expected to be constant string or symbol")
            unless $class_name->isa(StringClass)
                or $class_name->isa(SymbolClass);

        $compiler->add_required_package('Moose::Meta::Class');

        $class_name = $class_name->value;
        return CompiledClass->new_from_uncompiled($compiler, $env, $class_name, [@body], $symbol);
    },
);

CLASS->add_procedure('class-of',
    inliner     => CLASS->build_direct_inliner('Scalar::Util', 'blessed', min => 1, max => 1),
    inline_fc   => 1,
    firstclass  => CLASS->build_direct_firstclass('Scalar::Util', 'blessed', min => 1, max => 1, procname => 'class-of'),
);

CLASS->meta->make_immutable;

1;
