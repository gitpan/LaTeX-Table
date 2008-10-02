BEGIN { our $WARNMSG; $SIG{'__WARN__'} = sub { $WARNMSG = $_[0]; } };

use Test::More tests => 6;

use LaTeX::Table;
use English qw( -no_match_vars );

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
\centering
\begin{tabular}{|r||r|r|}
    \hline
\multicolumn{1}{|c||}{\textbf{A}} & \multicolumn{1}{c|}{\textbf{B}}\\ 
\hline
\hline

1234 & 12345678901 & 12345\\ 
5678 & 234567890 & \\ 
12345 & 1234567890 & 12345\\ 
\hline
\end{tabular}
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
    {   header            => $header,
        data              => $data,
        coldef_strategy => { 'LONG_COL' => 'p{4cm}', },
        theme     => 'Dresden',
    }
);
$output = $table->generate_string;
$expected_output = <<'EOT';
\begin{table}
\centering
\begin{tabular}{|l||p{4cm}|p{4cm}|}
    \hline
\multicolumn{1}{|c||}{\textbf{Character}} & \multicolumn{1}{c|}{\textbf{Fullname}} & \multicolumn{1}{c|}{\textbf{Voice}}\\ 
\hline
\hline

Homer & Homer Jay Simpson & Dan Castellaneta\\ 
Marge & Marjorie Simpson (née Bouvier) & Julie Kavner\\ 
Bart & Bartholomew Jojo Simpson & Nancy Cartwright\\ 
Lisa & Elizabeth Marie Simpson & Yeardley Smith\\ 
Maggie & Margaret Simpson & Elizabeth Taylor, Nancy Cartwright, James Earl Jones,Yeardley Smith, Harry Shearer\\ 
\hline
\end{tabular}
\end{table}
EOT
;
is_deeply(
    [ split( "\n", $output ) ],
    [ split( "\n", $expected_output ) ],
    'text wrap works with paragraph attribute'
);

# text_wrap test 1

my $header = [ [ 'a', 'b' ] ];
my $data   = [ [ '1', '2' ] ];

$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        text_wrap => {},
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option text_wrap: Not an array reference\.},
    'text_wrap is not an array reference'
) || diag $EVAL_ERROR;

# text_wrap test 2
$table->set_text_wrap(['1', 'b']);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option text_wrap: Not an integer: b\.},
    'text_wrap: b not integer'
) || diag $EVAL_ERROR;

# text_wrap test 3
$table->set_text_wrap([10, 10]);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid text_wrap' ) || diag $EVAL_ERROR;

$table->set_text_wrap([undef,10]);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid text_wrap' ) || diag $EVAL_ERROR;
