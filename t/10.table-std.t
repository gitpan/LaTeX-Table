use Test::More tests => 6;

use LaTeX::Table;

my $test_header
    = [ [ 'Name', 'Beers:2|c|' ], [ '', 'before 4pm', 'after 4pm' ] ];
my $test_data = [
    [ 'Lisa',   '0', '0' ],
    [ 'Marge',  '0', '1' ],
    [ 'Wiggum', '0', '5' ],
    [ 'Otto',   '1', '3' ],
    [ 'Homer',  '2', '6' ],
    [ 'Barney', '8', '16' ],
];

my $table = LaTeX::Table->new(
    {   filename          => 't/tmp/out.tex',
        label             => 'beercounter',
        maincaption       => 'Beer Counter',
        caption           => 'Number of beers before and after 4pm.',
        table_environment => 0,
        theme             => 'Dresden',
        header            => $test_header,
        data              => $test_data,
    }
);

my $expected_output = <<'EOT'
\begin{tabular}{|l||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline

Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{tabular}

EOT
    ;

my $output = $table->generate_string();
my @expected_output = split "\n", $expected_output;

is_deeply(
    [ split( "\n", $output ) ],
    \@expected_output,
    'without table environment'
);

mkdir 't/tmp';
$table->generate();

open my $FH, '<', 't/tmp/out.tex';
my @filecontent = <$FH>;
chomp @filecontent;
close $FH;
push @expected_output, q{};

is_deeply( \@filecontent, [@expected_output],
    'without table environment, generate()' )
    or die;

unlink 't/tmp/out.tex';
rmdir 't/tmp';
## with table environment
$table->set_table_environment(1);

$expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline

Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{tabular}
\caption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}
\end{center}
\end{table}
EOT
    ;
$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment'
);

# without label and maincaption
$table->set_table_environment(1);
$table->set_label('');
$table->set_maincaption('');

$expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline

Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{tabular}
\caption{Number of beers before and after 4pm.}
\end{center}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption and label'
);

## without center

$table = LaTeX::Table->new(
    {   table_environment => 1,
        center            => 0,
        theme             => 'Dresden',
        header            => $test_header,
        data              => $test_data,
    }
);
$expected_output = <<'EOT'
\begin{table}
\begin{tabular}{|l||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline

Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{tabular}
\end{table}
EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with table environment, without maincaption, center and label'
);

## with tabledef
$table = LaTeX::Table->new(
    {   table_environment => 0,
        tabledef          => "|l||l|l|",
        header            => $test_header,
        data              => $test_data,
        theme             => 'Dresden',
    }
);
$expected_output = <<'EOT'
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline

Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{tabular}

EOT
    ;

$output = $table->generate_string();
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'with tabledef'
);

