use 5.008;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LaTeX::Table',
    AUTHOR              => 'Markus Riester <mriester@gmx.de>',
    VERSION_FROM        => 'lib/LaTeX/Table.pm',
    ABSTRACT_FROM       => 'lib/LaTeX/Table.pm',
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
            ('LICENSE'  => 'perl')         : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Test::NoWarnings' => 0,
        'Class::Std'     => 0,
        'Scalar::Util'   => 0,
        'Text::Wrap'     => 0,
        'version'        => 0,
        'Readonly'       => 0,
    },
    EXE_FILES         => [ 'bin/csv2pdf' ], 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LaTeX-Table-*' },
);
