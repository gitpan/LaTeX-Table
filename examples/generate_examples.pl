#!/usr/bin/perl 

use strict;
use warnings;

use LaTeX::Table;

my $test_data = [
    [ 'Lisa',   '0', '0' ],
    [ 'Marge',  '0', '1' ],
    [ 'Homer',  'two', '6' ],
    [],
    [ 'Wiggum', '0', '5' ],
    [ 'Otto',   'one', '3' ],
    [ 'Barney', 'eight', '16.5' ],
];

my $test_data_large = [];

for my $i ( 1 .. 6 ) {
    $test_data_large = [ @$test_data_large, @$test_data ];
}

my $table = LaTeX::Table->new(
    {   tablepos    => 'htb',
        maincaption => 'Beer Counter',
        caption     => 'Number of beers before and after 4pm.',
        size        => 'large',
    }
);

my $themes = {
            'Custom' => {
                'HEADER_FONT_STYLE'  => 'sc',
                'HEADER_CENTERED'     => 1,
                'CAPTION_FONT_STYLE' => 'sc',
                'VERTICAL_LINES'      => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'    => [ 1, 2, 0 ],
            },
        };

$table->set_custom_themes($themes);


foreach my $theme ( keys %{ $table->get_available_themes } ) {

    my $test_header
        = [ [ 'Name', 'Beers:2|c|' ], [ '', 'before 4pm', 'after 4pm' ] ];

    # no vertical lines in the miami theme
    if ( $theme eq 'Miami' ) {
        $test_header
            = [ [ 'Name', 'Beers:2c' ], [ '', 'before 4pm', 'after 4pm' ] ];
    }

    $table->set_filename("$theme.tex");
    $table->set_theme($theme);
    $table->set_label("${theme}example");
    $table->set_type('std');
    $table->generate( $test_header, $test_data );
    $table->set_type('xtab');
    $table->set_filename("${theme}multipage.tex");
    $table->set_label("${theme}mpexample");
    $table->set_xentrystretch(-0.1);
    $table->generate( $test_header, $test_data_large );
}

open my $OUT, '>', 'examples.tex';
foreach my $line (<DATA>) {
    print $OUT $line;
}
foreach my $theme ( keys %{ $table->get_available_themes } ) {
    print $OUT "\\section{$theme}\n \\input{$theme.tex}\n";
    print $OUT "\\input{${theme}multipage.tex} \\clearpage \\newpage\n";
}
print $OUT "\\end{document}\n";
close $OUT;

__DATA__
\documentclass[twoside,12pt]{report}
\usepackage[margin=10pt,font=small,labelfont=bf]{caption}
\usepackage{url}
\usepackage{graphics, graphicx}
\usepackage{xtab}
\begin{document}
\chapter{Examples}

