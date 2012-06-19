#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'App::PRF',
    VERSION_FROM => 'lib/App/PRF.pm',
    ABSTRACT     => 'Perl refactoring toolkit',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/app-prf',
                    bugtracker => 'http://github.com/vti/app-prf/issues'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
    EXE_FILES => ['bin/prf'],

    PREREQ_PM => {
        'Cwd'              => 0,
        'File::Basename'   => 0,
        'File::Copy'       => 0,
        'File::Find'       => 0,
        'Module::CoreList' => 0,

        'Class::Load' => 0,
        'PPI'         => 0,

        'Test::More'  => 0,
        'Test::Class' => 0,
        'Test::Fatal' => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);
