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
        = [ [ 'Item:2c', '' ], [ 'Animal', 'Description', 'Price' ] ];

    if ( $theme eq 'Zurich' ) {
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
#    $table->set_caption_top(1);
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
default 5cm. See Table \ref{wrap2} for the results.
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
Table \ref {rotate} demonstrates the table sideways
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
\subsection{Table resize}
In Tables \ref{resize} and \ref{resize2}, the resizebox feature was used to get the desired
width (and height in the second example). Requires the \texttt{graphicx} package.
{
\small
\begin{lstlisting}
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        label             => 'resize',
        resizebox         => [ '0.6\textwidth' ],
        caption           => 
        'scaled to 0.6\textwidth with a resizebox (graphicx package)',
    }
);

$table->set_resizebox([ '300pt', '120pt' ]);
\end{lstlisting}
}
EOC
;


$table->set_environment('table');
$table->set_label('resize');
$table->set_resizebox([ '0.6\textwidth' ]);
$table->set_caption( 'scaled to 60\% of the text width');

print ${OUT} $code . $table->generate_string;

$table->set_label('resize2');
$table->set_resizebox([ '300pt', '120pt' ]);
$table->set_caption( 'scaled to a size of 300pt x 120pt');
print ${OUT} $table->generate_string;

$code = << 'EOC'
\subsection{Table width, tabular* environment}
Table \ref{width} demonstrates a fixed-width table in the \texttt{tabular*}
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
my $test_header = [ [ 'Animal', 'Description', 'Price' ] ];
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
    [ ’Gnat’,      ’per gram’, ’13.651’  ],
    [ ’’,          ’each’,      ’0.012’  ],
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

$header = [
    [ 'Item:2c', '' ],
    ['\cmidrule(r){1-2}'],
    [ 'Animal', 'Description', 'Price' ]
];

$data = [
    [ 'Gnat',      'per gram', '13.651'   ],
    [ '',          'each',      '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59'   ],
    [ 'Emu',       'stuffed',  '33.33'   ],
    [ 'Armadillo', 'frozen',    '8.99'   ],
];

$table = LaTeX::Table->new(
    {
    filename    => 'prices.tex',
    caption     => 'Try our special offer today!',
    caption_top => 1,
    label       => 'table:pricestop',
    position    => 'htb',
    header      => $header,
    data        => $data,
    callback    => sub {
        my ($row, $col, $value, $is_header ) = @_;
        if ($is_header) {
            $value = uc $value;
        }    
        elsif ($col == 2 && !$is_header) {
            $value = format_price($value, 2, '');
        }
        return $value;
    },
});


$code = << 'EOT';
\subsection{Top Captions}
Tables can be placed on top of the tables with \texttt{caption\_top => 1}. See
Table \ref{table:pricestop}. Note that the standard \LaTeX~macros are
optimized for bottom captions. Use something like 
\begin{lstlisting}
\usepackage[tableposition=top]{caption} 
\end{lstlisting}

to fix the spacing. Alternatively, you could fix the
spacing by yourself by providing your own command(s) (Table
\ref{table:pricestop2}):
{
\tiny
\begin{lstlisting}
$table->set_caption_top(
'\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\caption'
);
\end{lstlisting}
}
EOT
;

print $OUT $code . $table->generate_string();
$table->set_caption_top('\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\caption');
$table->set_label('table:pricestop2');


print $OUT $table->generate_string();

$code = << 'EOT';
\subsection{Custom Themes}

Table \ref{table:customtheme1} displays our example table with the
\textit{NYC} theme, which is meant for presentations (with LaTeX Beamer for
example). You can change the theme by copying it, changing it and
then storing it in \texttt{custom\_themes}. Admire the resulting Table \ref{table:customtheme2}. 
{
\small
\begin{lstlisting}
my $nyc_theme = $table->get_available_themes->{'NYC'};
$nyc_theme->{'DEFINE_COLORS'}       = 
          '\definecolor{latextablegreen}{RGB}{93,127,114}';
$nyc_theme->{'HEADER_BG_COLOR'}     = 'latextablegreen';
$nyc_theme->{'DATA_BG_COLOR_ODD'}   = 'latextablegreen!25';
$nyc_theme->{'DATA_BG_COLOR_EVEN'}  = 'latextablegreen!10';

$table->set_custom_themes({ CENTRALPARK => $nyc_theme });
$table->set_theme('CENTRALPARK');
\end{lstlisting}
}
EOT
;

$header = [
    [ 'Item:2c', '' ],
    [ 'Animal', 'Description', 'Price' ]
];

$table->set_callback(sub {
        my ($row, $col, $value, $is_header ) = @_;
        if ($col == 2 && !$is_header) {
            $value = format_price($value, 2, '');
        }
        return $value;
    });

$table->set_header($header);
$table->set_theme('NYC');
$table->set_caption_top(0);
$table->set_label('table:customtheme1');

print $OUT $code .  $table->generate_string() ;

my $nyc_theme = $table->get_available_themes->{'NYC'};
$nyc_theme->{'DEFINE_COLORS'}       = 
          '\definecolor{latextablegreen}{RGB}{93,127,114}';
$nyc_theme->{'HEADER_BG_COLOR'}     = 'latextablegreen';
$nyc_theme->{'DATA_BG_COLOR_ODD'}   = 'latextablegreen!25';
$nyc_theme->{'DATA_BG_COLOR_EVEN'}  = 'latextablegreen!10';

$table->set_custom_themes({ CENTRALPARK => $nyc_theme });
$table->set_theme('CENTRALPARK');
$table->set_label('table:customtheme2');


print $OUT  $table->generate_string() ;

$code = << 'EOT';
\subsection{Multicolumns}
If you want tables with vertical lines (are you sure?) you should use our
shortcut to generate them. They are not only much less typing work, but they
also automatically add the vertical lines, see Table \ref{table:mc}.
{
\small
\begin{lstlisting}
$header = [ [ 'A:3c' ] , [ 'A:2c', 'B' ], ['A', 'B', 'C' ], ];
$data = [ [ '1', 'w', 'x' ], [ '2', 'c:2c' ], ];

$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        theme             => 'Dresden',
    }
);
\end{lstlisting}
}
EOT
;

$header = [ [ 'A:3c' ] , [ 'A:2c', 'B' ], ['A', 'B', 'C' ], ];
$data = [ [ '1', 'w', 'x' ], [ '2', 'c:2c' ], ];

$table = LaTeX::Table->new(
    {   environment       => 1,
        header            => $header,
        data              => $data,
        label             => 'table:mc',
        caption           => 'Multicolumns made easy \dots',
        theme             => 'Dresden',
    }
);

print $OUT $code . $table->generate_string();

$data = [
    [ 'Gnat',      'per gram', '13.651'   ],
    [ '',          'each',      '0.012' ],
    [ 'Gnu',       'stuffed',  '92.59'   ],
    [ 'Emu',       'stuffed',  '33.33'   ],
    [ 'Armadillo', 'frozen',    '8.99'   ],
];

$table = LaTeX::Table->new(
    {
    caption     => 'Headers are not mandatory',
    label       => 'table:noheader',
    data        => $data,
});


$code = << 'EOT';
\subsection{Headers}
If you don't need headers, just leave them undefined (see
Table~\ref{table:noheader}). If you want that the first column looks like a
header, you can define this with the \texttt{columns\_like\_header} Option
(Table~\ref{table:collikeheader} and Table~\ref{table:collikeheader2}).
{
\small
\begin{lstlisting}
$table = LaTeX::Table->new(
    {
    caption     => 'Headers are not mandatory',
    label       => 'table:noheader',
    data        => $data,
});
\end{lstlisting}
}
EOT
;

print $OUT $code . $table->generate_string();

$table->set_theme('NYC');
$table->set_columns_like_header([0]);
$table->set_label('table:collikeheader');
$table->set_caption('We can format columns with the theme header definition');

print $OUT $table->generate_string();

$table->set_label('table:collikeheader2');
$table->set_header($header);

print $OUT $table->generate_string();

print ${OUT}
    "\\section{Version}\\small{Generated with LaTeX::Table Version $LaTeX::Table::VERSION}\n";

$code = << 'EOT';
\clearpage\begin{appendix}
\section{Themes}
For each theme, two example tables are shown, one of type
\textit{std}, the standard \LaTeX~table, and one of type \textit{xtab}. Note that the
first and second column is left justified because these columns contain only
strings, whereas the third column is a number column and therefore right
justified.
EOT
;

print $OUT $code;

for my $theme ( sort keys %{ $table->get_available_themes } ) {
    print $OUT "\\subsection{$theme Theme}\n \\input{$theme.tex}\n";
    print $OUT "\\input{${theme}multipage.tex} \\clearpage \\newpage\n";
}

print $OUT '\end{appendix}\end{document}' . "\n";
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
\usepackage{color}
\usepackage{colortbl}
\usepackage{xcolor}
\usepackage{graphicx}
%\usepackage[tableposition=top]{caption}
\begin{document}
\title{LaTeX::Table}
\date{\today}
\author{Markus Riester}
\maketitle
\begin{abstract}

\textsc{LaTeX::Table} is a Perl module that provides functionality for an intuitive and easy generation of
LaTeX tables. It ships with some predefined good looking
table styles. This module supports multipage tables via the \texttt{xtab} package and publication
quality tables with the \texttt{booktabs} package. It also supports the
\texttt{tabularx}
package for nicer fixed-width tables. Furthermore, it supports the \texttt{colortbl}
package for colored tables optimized for presentations.

\end{abstract}

\section{Installation}
You can install it with the \texttt{cpan} command.
    
\begin{lstlisting}
  $ cpan LaTeX::Table
\end{lstlisting}
Alternatively, download it from
\url{http://search.cpan.org/dist/LaTeX-Table/} and install in manually:
\begin{lstlisting}
  $ tar xvfz LaTeX-Table-VERSION.tar.gz
  $ perl Build.PL
  $ ./Build test
  $ ./Build install
\end{lstlisting}

\section{Examples}
\subsection{Large Columns}
The first basic example is a small table with two larger columns. LaTeX::Table
automatically sets the column to \texttt{p\{5cm\}} when a cell in a column has more than
30 characters. \LaTeX~generates the nice Table \ref{wrap1}.


