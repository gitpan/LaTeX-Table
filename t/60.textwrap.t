use Test::More tests => 3;

use LaTeX::Table;

# test no words wrapping
my $header = [ [ 'A', 'B', ], ];
my $data = [
    [ '12345678', '12345678901234567890', '12345', ],
    [ '12345',    '1234567890',           '12345', ],
];

my $table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        text_wrap => [ 5, 12, 5 ],
        theme     => 'Dresden',
    }
);
my $expected_output = <<'EOT'
\begin{table}
\begin{center}
\begin{tabular}{|l||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{A}} & \multicolumn{1}{c|}{\textbf{B}}\\ 
\hline
\hline

1234&12345678901&12345\\ 
5678&234567890&\\ 
12345&1234567890&12345\\ 
\hline
\end{tabular}
\end{center}
\end{table}
EOT
    ;
is( $table->generate_string, $expected_output,
    'text wrap works with non words' );

$header = [ [ 'Character', 'Fullname', 'Voice' ], ];
$data = [
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
        text_wrap => [ 15, 30, 30 ],
        theme     => 'Dresden',
    }
);
$expected_output = <<'EOT';
\begin{table}
\begin{center}
\begin{tabular}{|l||l|l|}
    \hline
\multicolumn{1}{|c||}{\textbf{Character}} & \multicolumn{1}{c|}{\textbf{Fullname}} & \multicolumn{1}{c|}{\textbf{Voice}}\\ 
\hline
\hline

Homer&Homer Jay Simpson&Dan Castellaneta\\ 
Marge&Marjorie Simpson (née&Julie Kavner\\ 
&Bouvier)&\\ 
Bart&Bartholomew Jojo Simpson&Nancy Cartwright\\ 
Lisa&Elizabeth Marie Simpson&Yeardley Smith\\ 
Maggie&Margaret Simpson&Elizabeth Taylor, Nancy\\ 
&&Cartwright, James Earl\\ 
&&Jones,Yeardley Smith, Harry\\ 
&&Shearer\\ 
\hline
\end{tabular}
\end{center}
\end{table}
EOT
my $output = $table->generate_string;
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'text wrap works with words'
);
$table = LaTeX::Table->new(
    {   header            => $header,
        data              => $data,
        tabledef_strategy => { 'LONG_COL' => 'p{4cm}', },
        theme     => 'Dresden',
    }
);
$output = $table->generate_string;
$expected_output = <<'EOT';
\begin{table}
\begin{center}
\begin{tabular}{|l||l|p{4cm}|}
    \hline
\multicolumn{1}{|c||}{\textbf{Character}} & \multicolumn{1}{c|}{\textbf{Fullname}} & \multicolumn{1}{c|}{\textbf{Voice}}\\ 
\hline
\hline

Homer&Homer Jay Simpson&Dan Castellaneta\\ 
Marge&Marjorie Simpson (née Bouvier)&Julie Kavner\\ 
Bart&Bartholomew Jojo Simpson&Nancy Cartwright\\ 
Lisa&Elizabeth Marie Simpson&Yeardley Smith\\ 
Maggie&Margaret Simpson&Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer\\ 
\hline
\end{tabular}
\end{center}
\end{table}
EOT
;
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'text wrap works with paragraph attribute'
);
