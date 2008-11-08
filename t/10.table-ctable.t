use Test::More tests => 2;
use Test::NoWarnings;

use LaTeX::Table;

my $test_header =  [ ['Name','Beers:2c'], ['','before 4pm', 'after 4pm'] ];
my $test_data   =  [ 
						['Lisa\tmark','0','0'], 
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
                                type      => 'ctable',
                             });

$table->set_foottable('\tnote{footnotes are placed under the table}');

my $expected_output =<<'EOT'
{
\ctable[cap = {Beer Counter},
caption = {Beer Counter. Number of beers before and after 4pm.},
botcap,
label = {beercounter},
center,
]{lrr}{\tnote{footnotes are placed under the table}}{
\toprule
\multicolumn{1}{c}{\textbf{Name}} & \multicolumn{2}{c}{\textbf{Beers}}\\ 
\multicolumn{1}{c}{\textbf{}} & \multicolumn{1}{c}{\textbf{before 4pm}} & \multicolumn{1}{c}{\textbf{after 4pm}}\\ 
\midrule
Lisa\tmark & 0 & 0\\ 
Marge & 0 & 1\\ 
Wiggum & 0 & 5\\ 
Otto & 1 & 3\\ 
Homer & 2 & 6\\ 
Barney & 8 & 16\\ 
\bottomrule
}

}
EOT
;

my $output = $table->generate_string();
#warn $output;
is_deeply([ split("\n",$output) ], [split("\n",$expected_output)], 'without table environment');

