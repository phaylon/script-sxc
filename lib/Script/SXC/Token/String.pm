package Script::SXC::Token::String;
use Moose;

use Script::SXC::Types  qw( Str );

use aliased 'Script::SXC::Exception::ParseError',   'ParseError';
use aliased 'Script::SXC::Tree::Symbol',            'SymbolItemClass';
use aliased 'Script::SXC::Tree::String',            'StringItemClass';
use aliased 'Script::SXC::Tree::List',              'ListClass';
use aliased 'Script::SXC::Tree::Builtin',           'BuiltinClass';

use constant STATE_STRING => 'state:string';
use constant STATE_VAR    => 'state:var';
use constant STATE_APPLY  => 'state:apply';

use namespace::clean -except => 'meta';
use Method::Signatures;

extends 'Script::SXC::Token::Symbol';

has '+value' => (isa => Str);

method match_regex {
    qr/" .*? (?<! \\ ) "/xsm;
};

method build_tokens ($value) {
    my $class = ref($self) || $self;
    
    # new token without modification
    return $class->new(value => $value);
};

method transform ($stream) {
    
    (my $rest   = $self->value) =~ s/(^"|"$)//g;
    my $current = [];
    my $app_lev = 0;
    my $state   = STATE_STRING;
    my $app_str;

    while (length $rest) {
        
        if ($state eq STATE_STRING) {

            if ($rest =~ s/^\\(.)//) {
                push @$current, $1;
            }

            elsif ($rest =~ s/^\$\{//) {
                $state = STATE_VAR;
            }

            elsif ($rest =~ s/^\$\(//) {
                $state   = STATE_APPLY;
                $app_lev = 1;
                $app_str = '(';
            }

            else {
                $rest =~ s/^(.)//;
                push @$current, $1;
            }
        }

        elsif ($state eq STATE_VAR) {
            $rest =~ s/^\s*(.*)\s*\}//
                or ParseError->throw(
                    type                => 'unclosed_string_interpolation',
                    message             => 'Unclosed variable interpolation',
                    line_number         => $self->line_number,
                    source_description  => $self->source_description,
                );

            # TODO make type for symbol and check here for validity
            push @$current, SymbolItemClass->new(value => $1, $self->source_information);
            $state = STATE_STRING;
        }

        elsif ($state eq STATE_APPLY) {
            $rest =~ s/^(.)//;
            my $str = $1;

            if ($str =~ /\(|\[/) {
                $app_lev++;
            }
            elsif ($str =~ /\)|\]/) {
                $app_lev--;
            }

            $app_str .= $str;

            if ($app_lev == 0) {

                # TODO error handling for different stages of creation
                my $expr_stream = $stream->new(source => \$app_str);
                push @$current, $expr_stream->transform->get_content_item(0);

                $state = STATE_STRING;
                undef $app_str;
            }
        }

    }

    unless ($state eq STATE_STRING) {
        ParseError->throw(
            type                => 'unclosed_string_interpolation',
            message             => sprintf('Unclosed %s interpolation',
                                    ($state eq STATE_VAR) ? 'variable' : 'applied'),
            line_number         => $self->line_number,
            source_description  => $self->source_description,
        );
    }

    my @contents;
    for my $element (@$current) {
        if (not ref $element) {
            if (@contents and $contents[-1]->isa(StringItemClass)) {
                $contents[-1]->append_value($element);
            }
            else {
                push @contents, StringItemClass->new(value => $element, $self->source_information);
            }
        }
        else {
            push @contents, $element;
        }
    }

    @contents = ListClass->new(
        contents => [
            BuiltinClass->new(value => 'str-append', $self->source_information),
            @contents,
        ]
    ) if @contents > 1;

    return $contents[0];
};

__PACKAGE__->meta->make_immutable;

1;
