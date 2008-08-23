use Test::More tests => 3;
use Test::NoWarnings;

use LaTeX::Table;

my $header = [ [ 'A', 'B', 'C' ], [ 'a', 'b', 'c' ] ];
my $data = [
    [ 'Marge', 'Homer', 'Bart' ],
    [ 'Marge', 'Homer', 'Bart' ],
    [ 'Marge', 'Homer', 'Bart' ],
];

my $table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        theme    => 'Dresden',
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $row == 1 && !$is_header ) {
                return lc $value;
            }
            if ( $row == 0 && $is_header ) {
                return lc $value;
            }
            if ( ( $row + $col ) % 2 == 0 ) {
                return uc $value;
            }
            return 'foo';
        },
    }
);
my $expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{\textbf{a}} & \multicolumn{1}{c|}{\textbf{b}} & \multicolumn{1}{c|}{\textbf{c}}\\ 
\multicolumn{1}{|c||}{\textbf{foo}} & \multicolumn{1}{c|}{\textbf{B}} & \multicolumn{1}{c|}{\textbf{foo}}\\ 
\hline
\hline

MARGE & foo & BART\\ 
marge & homer & bart\\ 
MARGE & foo & BART\\ 
\hline
\end{tabular}
\end{table}
EOT
    ;
my $output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback seems to work with words',
);

$header = [ [ 'A:2c', 'C' ], [ 'a', 'b', 'c' ] ];
$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        callback => sub {
            my ( $row, $col, $value, $is_header ) = @_;
            if ( $is_header ) {
                return uc $value;
            }
        },
    }
);

$expected_output = <<'EOT'
\begin{table}
\centering
\begin{tabular}{lll}
    \toprule
\multicolumn{2}{c}{\textbf{A}} & \multicolumn{1}{c}{\textbf{C}}\\ 
\multicolumn{1}{c}{\textbf{A}} & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}}\\ 
\midrule

0 & 0 & 0\\ 
0 & 0 & 0\\ 
0 & 0 & 0\\ 
\bottomrule
\end{tabular}
\end{table}

EOT
    ;
$output = $table->generate_string;

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'callback seems to work with uc headers and shortcuts',
);
