use Test::More tests => 2;

use LaTeX::Table;
use English qw( -no_match_vars ) ;

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                             });

eval { $table->_add_font_family({ value => 'test'}, 'test') }; 
ok($EVAL_ERROR, 'unknown font family');

eval { $table->_add_font_family({ value => 'test'}, 'bf') }; 
ok(!$EVAL_ERROR, 'known font family');
diag( "Testing LaTeX::Table $LaTeX::Table::VERSION exceptions" );
