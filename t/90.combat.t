BEGIN { our $WARNMSG; $SIG{'__WARN__'} = sub { $WARNMSG = $_[0]; } };

use Test::More tests => 2;

use LaTeX::Table;

my $test_header = [ [ 'A', 'B', 'C' ], ];
my $test_data = [ [ '1', 'w', 'x' ], [ '2', 'y', 'z' ], ];

my $table = LaTeX::Table->new();
$table->generate($test_header, $test_data);
like($WARNMSG, qr{DEPRECATED. Use options header and data instead},
    'DEPRECATED warning');

my $expected_output = <<'EOT'
\begin{table}
\center
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{\textbf{A}} & \multicolumn{1}{c|}{\textbf{B}} & \multicolumn{1}{c|}{\textbf{C}}\\ 
\hline
\hline

1&w&x\\ 
2&y&z\\ 
\hline
\end{tabular}
\end{table}
EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'with < 0.1.0 API'
);

