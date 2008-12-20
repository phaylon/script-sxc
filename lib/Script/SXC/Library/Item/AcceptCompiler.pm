package Script::SXC::Library::Item::AcceptCompiler;
use Moose::Role;
use MooseX::Method::Signatures;

use namespace::clean -except => 'meta';

requires qw( accept_compiler );

1;
