use Test::More tests => 1;

use LaTeX::Table;

my $test_header =  [ ['Name','Beers:2|c|'], ['','before 4pm', 'after 4pm'] ];
my $test_data   =  [ 
						['Lisa','0','0'], 
						[ 'Marge','0','1'], 
						[ 'Wiggum','0','5'],
						[ 'Otto','1','3'],
						[ 'Homer','2','6'],
						[ 'Barney','8','16'],
				];

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                                header    => $test_header,
                                data      => $test_data,
                                type      => 'xtab',
                             });

my $expected_output =<<'EOT'
{
\center
\bottomcaption[Beer Counter]{\textbf{Beer Counter. }Number of beers before and after 4pm.}
\label{beercounter}

\tablehead{\hline
\multicolumn{1}{|c||}{\textbf{Name}} & \multicolumn{2}{|c|}{\textbf{Beers}}\\ 
\multicolumn{1}{|c||}{\textbf{}} & \multicolumn{1}{c|}{\textbf{before 4pm}} & \multicolumn{1}{c|}{\textbf{after 4pm}}\\ 
\hline
\hline
}
\tabletail{\hline
\multicolumn{3}{|r|}{{Continued on next page}} \\ 
\hline
}
\tablelasttail{\hline
}
\begin{xtabular}{|l||r|r|}
Lisa&0&0\\ 
Marge&0&1\\ 
Wiggum&0&5\\ 
Otto&1&3\\ 
Homer&2&6\\ 
Barney&8&16\\ 
\hline
\end{xtabular}
} 
EOT
;

my $output = $table->generate_string();

is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');

