use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LaTeX::Table',
    license             => 'perl',
    dist_author         => 'Markus Riester <mriester@gmx.de>',
    dist_version_from   => 'lib/LaTeX/Table.pm',
    requires => {
        'Test::More'     => 0,
        'Class::Std'     => 0,
        'Scalar::Util'   => 0,
        'Regexp::Common' => 0,
        'Text::Wrap'     => 0,
        'version'        => 0,
    },
    add_to_cleanup      => [ 'LaTeX-Table-*' ],
);

$builder->create_build_script();
