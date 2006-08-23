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
                             });

#warn $table->generate($test_header, $test_data);
ok(1, 'not yet implemented.');

diag( "Testing LaTeX::Table $LaTeX::Table::VERSION Run generate_examples.pl!" );
