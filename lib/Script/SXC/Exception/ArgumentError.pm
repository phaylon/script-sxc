package Script::SXC::Exception::ArgumentError;
use Moose;
use MooseX::Method::Signatures;

use Perl6::Caller;
use PadWalker   qw( peek_my );
use Data::Dump  qw( dump );

use namespace::clean -except => 'meta';

extends 'Script::SXC::Exception';

1;
