package Script::SXC::Runtime;
use strict;
use warnings;

use aliased 'Script::SXC::Runtime::Keyword', 'RuntimeKeyword';

use Sub::Exporter -setup => {
    exports => [qw(
        make_keyword
    )],
};

use namespace::clean -except => [qw( import )];

my %KeywordSingleton;

sub make_keyword {
    my ($value) = @_;
    return $KeywordSingleton{ $value }
        if exists $KeywordSingleton{ $value };
    return( $KeywordSingleton{ $value } = RuntimeKeyword->new(value => $value) );
}

1;
