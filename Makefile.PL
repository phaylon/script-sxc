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
test_requires   'Class::C3';
test_requires   'CLASS';
test_requires   'Carp';
test_requires   'Data::Dump';
test_requires   'DateTime';
test_requires   'self';
test_requires   'parent';
test_requires   'Method::Signatures';
test_requires   'Perl::Tidy';
test_requires   'Scalar::Util';
test_requires   'Sub::Exporter';
test_requires   'Sub::Information';
test_requires   'aliased';

requires        'aliased';
requires        'autodie',                      '1.997';
requires        'B::Deparse',                   '0.83';
requires        'Carp';
requires        'CLASS';
requires        'Class::Inspector',             '1.23';
requires        'Class::MOP',                   '0.75';
requires        'Data::Dump',                   '1.11';
requires        'DateTime';
requires        'File::HomeDir',                '0.82';
requires        'File::Path';
requires        'IO::Handle';
requires        'Lexical::Persistence',         '0.98';
requires        'List::Util',                   '1.19';
requires        'List::MoreUtils',              '0.22';
requires        'Method::Signatures',           '0.02';
requires        'Moose',                        '0.64';
requires        'MooseX::Types',                '0.07';
requires        'MooseX::AttributeHelpers',     '0.13';
requires        'MooseX::Method::Signatures',   '0.06';
requires        'MooseX::ClassAttribute',       '0.07';
requires        'MooseX::CurriedHandles',       '0.03';
requires        'namespace::clean',             '0.09';
requires        'PadWalker',                    '1.7';
requires        'Path::Class',                  '0.16';
requires        'Perl6::Caller',                '0.04';
requires        'Perl6::Gather',                '0.04';
requires        'Perl6::Junction',              '1.40000';
requires        'Perl::Tidy',                   '20071205';
requires        'signatures',                   '0.02';
requires        'Sub::Exporter',                '0.979';
requires        'Sub::Install',                 '0.924';
requires        'Sub::Name',                    '0.04';
requires        'Scalar::Util',                 '1.19';
requires        'Term::ReadLine',               '1.03';
requires        'Time::HiRes',                  '1.9711';
requires        'File::ShareDir',               '1.00';

no_index        directory   => 'examples';

install_script  'script/sxc';
install_script  'script/sxc.pl';

install_share   'share';

WriteAll;
