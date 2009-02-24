BEGIN { our $WARNMSG; $SIG{'__WARN__'} = sub { $WARNMSG = $_[0]; } };

use Test::More tests => 4;

use LaTeX::Table;


my $test_header = [ [ 'A', 'B', 'C' ], ];
my $test_data = [ [ '1', 'w', 'x' ], [], [ '2', 'y', 'z' ], ];

my $table = LaTeX::Table->new({ tablepos => 'ht',
                                table_environment => 'sidewaystable',
                                tabledef  => 'lcc',
                                theme     => 'Zurich',
                            });

$table->generate_string($test_header, $test_data);
like($WARNMSG, qr{DEPRECATED. Use options header and data instead},
    'DEPRECATED warning');

my $expected_output = <<'EOT'
\begin{sidewaystable}[ht]
\centering
\begin{tabular}{lcc}
\toprule
\textbf{A} & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
1 & w & x \\
\midrule
2 & y & z \\
\bottomrule
\end{tabular}
\end{sidewaystable}
EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'with < 0.1.0 API'
);

$table = LaTeX::Table->new({ tablepos => 'ht',
                            header => $test_header, 
                            data => [ [ '1', 'w', 'x' ], [], [ '2.1',
                            'y12345', 'z' ], ],
                            theme => 'Zurich',
                            });

$table->set_tabledef_strategy({
        IS_A_NUMBER => qr{\A \d+ \z}xms,
        IS_LONG => 5,
        LONG_COL => 'p{5cm}',
        DEFAULT_X => 'c',
        DEFAULT   => 'r',
    });

$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabular}{lp{5cm}r}
\toprule
\textbf{A} & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
1   & w      & x \\
\midrule
2.1 & y12345 & z \\
\bottomrule
\end{tabular}
\end{table}
EOT
    ;

$output = $table->generate_string();

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'three number columns'
);

$table->set_width('300pt');
$table->set_width_environment('tabularx');

$expected_output = <<'EOT'
\begin{table}[ht]
\centering
\begin{tabularx}{300pt}{lXc}
\toprule
\textbf{A} & \multicolumn{1}{c}{\textbf{B}} & \multicolumn{1}{c}{\textbf{C}} \\
\midrule
1   & w      & x \\
\midrule
2.1 & y12345 & z \\
\bottomrule
\end{tabularx}
\end{table}
EOT
    ;

$output = $table->generate_string();

is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'three number columns'
);
