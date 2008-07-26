use Test::More tests => 5;
use Test::NoWarnings;

use LaTeX::Table;

my $themes = {
    'Leipzig' => {
        'HEADER_FONT_STYLE' => 'sc',
        'HEADER_CENTERED'   => 1,
        'VERTICAL_LINES'    => [ 1, 2, 1 ],
        'HORIZONTAL_LINES'  => [ 1, 2, 0 ],
    },
    'Leipzig2' => {
        'HEADER_CENTERED'   => 1,
        'VERTICAL_LINES'    => [ 1, 2, 1 ],
        'HORIZONTAL_LINES'  => [ 1, 2, 0 ],
    },
    'Leipzig3' => {
        'VERTICAL_LINES'    => [ 1, 2, 1 ],
        'HORIZONTAL_LINES'  => [ 1, 2, 0 ],
    },
    'Leipzig3b' => {
        'HEADER_CENTERED'   => 0,
        'VERTICAL_LINES'    => [ 1, 2, 1 ],
        'HORIZONTAL_LINES'  => [ 1, 2, 0 ],
    },
};

my $test_header = [ [ 'A', 'B', 'C' ], ];
my $test_data = [ [ '1', 'w', 'x' ], [ '2', 'y', 'z' ], ];

my $table = LaTeX::Table->new(
    {   table_environment => 1,
        caption           => 'Test Caption',
        maincaption       => 'Test',
        header            => $test_header,
        data              => $test_data,
        custom_themes     => $themes,
        theme             => 'Leipzig',
    }
);

my $expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{\textsc{A}} & \multicolumn{1}{c|}{\textsc{B}} & \multicolumn{1}{c|}{\textsc{C}}\\ 
\hline
\hline

1&w&x\\ 
2&y&z\\ 
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{center}
\end{table}
EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without table environment'
);

$table->set_theme('Leipzig2');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{A} & \multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{C}\\ 
\hline
\hline

1&w&x\\ 
2&y&z\\ 
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{center}
\end{table}
EOT
    ;

@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without header font'
);

$table->set_theme('Leipzig3');
$output = $table->generate_string();

$expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||l|l|}
    \hline
A & B & C\\ 
\hline
\hline

1&w&x\\ 
2&y&z\\ 
\hline
\end{tabular}
\caption[Test]{Test. Test Caption}
\end{center}
\end{table}
EOT
    ;
@expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'theme, without header centered'
);

$table->set_theme('Leipzig3b');
$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'theme, without header centered'
);

