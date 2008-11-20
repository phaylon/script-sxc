#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Script::SXC::Test::Library::Data;
use Test::More ();
for my $tailcall (0, 1) {
    $ENV{TEST_TAILCALLOPT} = $tailcall;
    for my $firstclass (0, 1) {
        $ENV{TEST_TAILCALLOPT} = $firstclass;
        Test::More::note(sprintf 'Tailcall Optimization: %d, Firstclass Procedures: %d', $tailcall, $firstclass);
        Test::Class->runtests;
    }
}

