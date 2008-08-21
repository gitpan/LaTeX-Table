#!/usr/bin/perl 

use strict;
use warnings;

use LaTeX::Table;
use LaTeX::Encode;
use Number::Format qw(:subs);
use Data::Dumper;

my $test_data = [
    [ 'Gnat',      'per gram', '13.651' ],
    [ '',          'each',     '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59' ],
    [ 'Emu',       'stuffed',  '33.33' ],
    [ 'Armadillo', 'frozen',   '8.99' ],
];

my $test_data_large = [];

for my $i ( 1 .. 6 ) {
    $test_data_large = [ @$test_data_large, @$test_data ];
}

my $table = LaTeX::Table->new(
    {   position    => 'htb',
        maincaption => 'Price List',
        caption     => 'Try our special offer today!',
        size        => 'large',
        callback  => sub {
              my ($row, $col, $value, $is_header ) = @_;
              if ($col == 2 && !$is_header) {
                  $value = format_price($value, 2, '');
              }
              return $value;
         },
    }
);

my $themes = {
    'Custom' => {
        'HEADER_FONT_STYLE'  => 'sc',
        'HEADER_CENTERED'    => 1,
        'CAPTION_FONT_STYLE' => 'sc',
        'VERTICAL_LINES'     => [ 1, 2, 1 ],
        'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
    },
};

$table->set_custom_themes($themes);

foreach my $theme ( keys %{ $table->get_available_themes } ) {

    my $test_header
        = [ [ 'Item:2|c|', '' ], [ 'Animal', 'Description', 'Price' ] ];

    # no vertical lines in the miami theme
    if ( $theme eq 'Miami' || $theme eq 'plain' ) {
        $test_header
            = [ [ 'Item:2c', '' ], [ 'Animal', 'Description', 'Price' ] ];
    }
    elsif ( $theme eq 'Zurich' ) {
        $test_header = [
            [ 'Item:2c', '' ],
            ['\cmidrule(r){1-2}'],
            [ 'Animal', 'Description', 'Price' ]
        ];
    }

    $table->set_filename("$theme.tex");
    $table->set_theme($theme);
    $table->set_type('std');
    $table->set_header($test_header);
    $table->set_data($test_data);
    $table->generate();
#    warn Dumper $test_data;
    $table->set_type('xtab');
    $table->set_filename("${theme}multipage.tex");
    $table->set_xentrystretch(-0.1);
    $table->set_header($test_header);
    $table->set_data($test_data_large);
    $table->generate();
}

open my $OUT, '>', 'examples.tex';
foreach my $line (<DATA>) {
    print $OUT $line;
}
my $code = << 'EOC'
my $header = [ [ 'Character', 'Fullname', 'Voice' ], ];
my $data = [
    [ 'Homer', 'Homer Jay Simpson',               'Dan Castellaneta', ],
    [ 'Marge', 'Marjorie Simpson (née Bouvier)', 'Julie Kavner', ],
    [ 'Bart',  'Bartholomew Jojo Simpson',        'Nancy Cartwright', ],
    [ 'Lisa',  'Elizabeth Marie Simpson',         'Yeardley Smith', ],
    [   'Maggie',
        'Margaret Simpson',
        'Elizabeth Taylor, Nancy Cartwright, James Earl Jones,'
            . 'Yeardley Smith, Harry Shearer',
    ],
];
$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        label     => 'wrap1',
        caption   => 'LaTeX paragraph column attribute.',
    }
);

EOC
;

my $header = [ [ 'Character', 'Fullname', 'Voice' ], ];
my $data = [
    [ 'Homer', 'Homer Jay Simpson',               'Dan Castellaneta', ],
    [ 'Marge', 'Marjorie Simpson (née Bouvier)', 'Julie Kavner', ],
    [ 'Bart',  'Bartholomew Jojo Simpson',        'Nancy Cartwright', ],
    [ 'Lisa',  'Elizabeth Marie Simpson',         'Yeardley Smith', ],
    [   'Maggie',
        'Margaret Simpson',
        'Elizabeth Taylor, Nancy Cartwright, James Earl Jones,'
            . 'Yeardley Smith, Harry Shearer',
    ],
];
$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        label     => 'wrap1',
        caption   => 'LaTeX paragraph column attribute.',
    }
);

print ${OUT} "{\\tiny\\begin{lstlisting}\n$code\n\\end{lstlisting}}";

#$table->set_tabledef_strategy( { 'LONG_COL' => 'p{4cm}', 'IS_LONG' => 30 } );
print ${OUT} $table->generate_string;

$code = << 'EOC'
We can use the \texttt{tabularx} package to find better column widths than the
default 5cm. See Table~\ref{wrap2} for the results.
{
\small
\begin{lstlisting}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        label             => 'wrap2',
        width             => '0.9\textwidth',
        width_environment => 'tabularx',
        caption           => 'tabularx X column attribute.',
    }
);
\end{lstlisting}
}
EOC
;
$table->set_label('wrap2');
$table->set_caption(
    'tabularx X column attribute.');

$table->set_width('0.9\textwidth');
$table->set_width_environment('tabularx');
print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Table rotate}
Table ~\ref {rotate} demonstrates table sideways
feature. Requires the \texttt{rotating} package.
{
\small
\begin{lstlisting}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        label             => 'rotate',
        width             => '0.9\textwidth',
        width_environment => 'tabularx',
        environment       => 'sidewaystable',
        caption           => 'tabularx X column attribute.',
    }
);
\end{lstlisting}
}
EOC
;

$table->set_environment('sidewaystable');
$table->set_label('rotate');
print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Table width, tabular* environment}
Table ~\ref {width} demonstrates a fixed-width table in the \texttt{tabular*}
environment. Here, the space between the columns is filled with spaces.
{
\small
\begin{lstlisting}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        label             => 'width',
        width             => '0.7\textwidth',
        caption           => '0.7 of textwidth',
    }
);
\end{lstlisting}
}
EOC
;
my $test_header = [ [ 'Name', 'Beer', 'Wine' ] ];
$table = LaTeX::Table->new(
    {   header  => $test_header,
        data    => $test_data,
        label   => 'width',
        width   => '0.7\textwidth',
        caption => '0.7 of textwidth',
    }
);
print ${OUT} $code . $table->generate_string;

$code = << 'EOC'
\subsection{Callback functions}
Callback functions are an easy way of formatting the cells. Note that the
prices for Gnat are rounded:

{
\small
\begin{lstlisting}

         my $header = [
             [ ’Item:2c’, ’’ ],
             [’\cmidrule(r){1-2}’],
             [ ’Animal’, ’Description’, ’Price’ ]
         ];

         my $data = [
             [ ’Gnat’,      ’per gram’, ’13.651’   ],
             [ ’’,          ’each’,      ’0.012’ ],
             [ ’Gnu’,       ’stuffed’,  ’92.59’   ],
             [ ’Emu’,       ’stuffed’,  ’33.33’   ],
             [ ’Armadillo’, ’frozen’,    ’8.99’   ],
         ];

         my $table = LaTeX::Table->new(
               {
               filename    => ’prices.tex’,
               maincaption => ’Price List’,
               caption     => ’Try our special offer today!’,
               label       => ’table:prices’,
               position    => ’htb’,
               header      => $header,
               data        => $data,
               callback    => sub {
                    my ($row, $col, $value, $is_header ) = @_;
                    if ($col == 2 && $!is_header) {
                        $value = format_price($value, 2, ’’);
                    }
                    return $value;
              },
         });

\end{lstlisting}
}
EOC
;

print $OUT $code. "\\input{Zurich.tex}";

$code = << 'EOT';
\clearpage\section{Themes}
For each theme, two example tables are shown, one of type
\textit{std}, the standard \LaTeX~table, and one of type \textit{xtab}. Note that the
second column is left justified because this column contains numbers and
strings, whereas the third column is a number column and therefore right
justified.
EOT
;

print $OUT $code;

foreach my $theme ( keys %{ $table->get_available_themes } ) {
    print $OUT "\\subsection{$theme Theme}\n \\input{$theme.tex}\n";
    print $OUT "\\input{${theme}multipage.tex} \\clearpage \\newpage\n";
}

print ${OUT}
    "\\section{Version}\\small{Generated with LaTeX::Table Version $LaTeX::Table::VERSION}\n";
print ${OUT} "\\end{document}\n";

close $OUT;

__DATA__
\documentclass{article}
\usepackage{url}
\usepackage{graphics, graphicx}
\usepackage{xtab}
\usepackage{booktabs}
\usepackage{rotating}
\usepackage{tabularx}
\usepackage{listings}
\begin{document}
\title{LaTeX::Table}
\date{\today}
\author{Markus Riester}
\maketitle
\section{About this document}
This document is generated by \texttt{generate\_examples.pl} from
\textsc{LaTeX::Table}. 
\section{Examples}

The first basic example is a small table with two larger columns. LaTeX::Table
automatically sets the column to \texttt{p\{5cm\}} when a cell in a column has more than
30 characters. \LaTeX~generates the nice Table ~\ref{wrap1}.


