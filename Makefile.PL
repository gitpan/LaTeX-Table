use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LaTeX::Table',
    AUTHOR              => 'Markus Riester <mriester@gmx.de>',
    VERSION_FROM        => 'lib/LaTeX/Table.pm',
    ABSTRACT_FROM       => 'lib/LaTeX/Table.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Class::Std'     => 0,
        'Scalar::Util'   => 0,
        'Regexp::Common' => 0,
        'Text::Wrap'     => 0,
        'version'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LaTeX-Table-*' },
);
