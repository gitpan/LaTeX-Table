use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LaTeX::Table',
    license             => 'perl',
    dist_author         => 'Markus Riester <mriester@gmx.de>',
    dist_version_from   => 'lib/LaTeX/Table.pm',
    requires => {
        'perl'           => '5.8.0', 
        'English'        => 0,
        'Class::Std'     => 0,
        'Scalar::Util'   => 0,
        'Text::Wrap'     => 0,
        'Carp'           => 0,
        'version'        => 0,
        'Readonly'       => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'File::Spec'       => 0,
    }, 
    recommends => {
        'Text::CSV_XS'   => 0,
        'LaTeX::Driver'  => 0,
        'LaTeX::Encode'  => 0,
        'Getopt::Long'   => 0,
    },    
    script_files        => [ 'bin/csv2pdf' ], 
    add_to_cleanup      => [ 'LaTeX-Table-*' ],
);

$builder->create_build_script();
