package Script::SXC::Library::Core;
use 5.010;
use Moose;
use MooseX::Method::Signatures;

use constant SymbolClass => 'Script::SXC::Tree::Symbol';

use CLASS;
use namespace::clean -except => 'meta';

extends 'Script::SXC::Library';

CLASS->add_delegated_items({
    'Script::SXC::Library::Core::Operators'     => [qw( or and err def not ~~ )],

    'Script::SXC::Library::Core::Sequences'     => [qw( begin )],

    'Script::SXC::Library::Core::Conditionals'  
        => [qw( if unless cond )],

    'Script::SXC::Library::Core::Functions'     
        => [qw( lambda λ chunk λ… -> )],

    'Script::SXC::Library::Core::Let'           
        => [qw( let let* let-rec given )],

    'Script::SXC::Library::Core::Set'           => [qw( set! )],

    'Script::SXC::Library::Core::Quoting'       => [qw( quote quasiquote unquote unquote-splicing )],

    'Script::SXC::Library::Core::Goto'          => [qw( goto )],

    'Script::SXC::Library::Core::Definitions'   => [qw( define )],

    'Script::SXC::Library::Core::Contexts'      => [qw( values->list values->hash )],

    'Script::SXC::Library::Core::Apply'         => [qw( apply )],

    'Script::SXC::Library::Core::Recursion'     => [qw( recurse )],

    'Script::SXC::Library::Core::DateTime'      
        => [qw( current-datetime current-timestamp sleep usleep )],

    'Script::SXC::Library::Core::IO'
        => [qw( 
                say print read-line read-all-lines
                with-input-from-file    with-output-to-file
                with-input-from-string  with-output-to-string
                with-input-from-handle  with-output-to-handle
            )],

    'Script::SXC::Library::Core::Packages'
        => [qw( require define-package )],
});

CLASS->add_inliner('builtin', via => method (:$compiler!, :$env!, :$name!, :$exprs!, :$error_cb!) {
    CLASS->check_arg_count($error_cb, $name, $exprs, min => 1, max => 1);
    my $symbol = $exprs->[0];

    $symbol->throw_parse_error(invalid_builtin_name => "Invalid builtin name: $name expected symbol")
        unless $symbol->isa(SymbolClass);

    return $symbol->compile($compiler, $compiler->top_environment);
});

CLASS->add_procedure('display', firstclass => sub { print @_, "\n" });

# TODO still missing:
#   * core;
#   - (given (get-foo) 
#      (ref?                            "ref") 
#      ((and (list? _) (< 0 (size _)))  (list-ref _ 1)) 
#      (default                         #f))
#   - (cond ((< x 23) :smaller)
#           ((> x 23) :larger)
#           (else     :equal))
#   - (cond ((foo) => do-with-foo)
#           (else  => do-with-else))
#   - (cond test: defined?
#      (foo  :foo)
#      (else :bar))
#   - (state ((x (foo))) x)
#   - (try (λ () (foo 23))
#          (λ (e) (isa: e "My::Error"))         ; could also be (catch class! ...)
#          (λ (e) (say (message: e))))
#   - (sleep 0.1)
#   * OO
#   - (package Foo::Bar
#      (exports
#       (foo: make-foo foo? foo-value)
#       (default: find-some-foo)))
#   - (class Bar::Baz :is-immutable
#      (extends BaseA BaseB)
#      (with RoleA RoleB)
#      (has id isa:      Int
#              required: 1
#              builder:  build_default_id)
#      (method (build_default_id self)
#        23)
#      (multimethod (add (Str a) (Str b))
#       (string a b))
#      (multimethod (add (Int a) (Int b))
#       (+ a b)))
#      (method (sub x y) (- x y))
#   - (role RoleA
#      (multimethod (add a b)
#       (croak "Unable to find a way to add $(typa a) to $(type b)")))
#   * I/O
#   - (with-input-port port
#      (do :something))
#   - (with-standard-output-port
#      (do :something))
#   - (say "foo" "bar)
#   - (print (string "foo" "bar") *stdin*)
#   - (path "foo" "bar")
#   - (file "foo" "bar" "baz.txt")
#   * Math
#   * standalone compiler
#   * inline compiler
#   * regular expressions
#   - (define rx ~/^foo(.*)oo$/i)
#   - (replace: rx "bar${1}baz" :global)
#   * runtime compilation
#   * runtime types
#   * macros
#   * eval
#   - (eval '(+ 2 3))                   => 5
#     (let ((foo (λ (n) (list n))))
#      (eval '(foo 23) :inject foo))    => (23)
#     (let ((foo (λ (n) (* n n))))
#      (eval '(foo 3) :inject-all))     => 9
#   - (eval-string "(+ 2 3)")           => 5

__PACKAGE__->meta->make_immutable;

1;
