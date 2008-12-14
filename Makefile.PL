#!/usr/bin/perl
use strict;
use inc::Module::Install;

name            'Script-SXC';
author          'Robert \'phaylon\' Sedlacek <rs@474.at>';
license         'perl';
perl_version    '5.010';

all_from        'lib/Script/SXC.pm';

test_requires   'Test::Class';
test_requires   'Test::Most';
test_requires   'Class::Accessor::Fast';
test_requires   'self';
test_requires   'parent';

requires        'namespace::clean',             '0.09';
requires        'Method::Signatures',           '0.02';
requires        'Moose',                        '0.61';
requires        'MooseX::Types',                '0.07';
requires        'MooseX::AttributeHelpers',     '0.13';
requires        'aliased';
requires        'Data::Dump';
requires        'CLASS';
requires        'Carp';
requires        'Lexical::Persistence',         '0.98';
requires        'List::Util',                   '1.19';
requires        'MooseX::Method::Signatures',   '0.06';
requires        'MooseX::ClassAttribute',       '0.07';
requires        'MooseX::CurriedHandles',       '0.03';
requires        'PadWalker',                    '1.7';
requires        'Perl6::Caller',                '0.04';
requires        'Perl6::Gather',                '0.04';
requires        'Perl6::Junction',              '1.40000';
requires        'Perl::Tidy',                   '20071205';
requires        'signatures',                   '0.02';
requires        'Term::ReadLine',               '1.03';
requires        'Sub::Exporter',                '0.979';

no_index        directory   => 'examples';

WriteAll;
