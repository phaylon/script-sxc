package Script::SXC::Tree::Item;
use Moose::Role;
use MooseX::Method::Signatures;

use constant 'SourcePositionRole', 'Script::SXC::SourcePosition';

use namespace::clean -except => 'meta';

with 'Script::SXC::SourcePosition';

#method new_from_token ($class: $token, @args) {
#    my $class = ref($self) || $self;
sub new_from_token {
    my ($class, $token, @args) = @_;
    my %args = @args == 1 ? %{ $args[0] } : @args;

    return $class->new(%args)
        unless  $token->does(SourcePositionRole)
            and $class->does(SourcePositionRole);

    return $class->new(
        line_number         => $token->line_number,
        source_description  => $token->source_description,
        %args,
    );
};

1;
