use Test::More tests => 6;
use Test::NoWarnings;

use LaTeX::Table;

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                             });

my $test_def = 'test:1c';

is($table->_add_mc_def({ value => $test_def, align => 'r', cols => 2}), $test_def, 'no adding if already has a def');							 
is($table->_add_mc_def({ value => 'test', align => 'r', cols => 2}), 'test:2r', 'no adding if already has a def');							 
is_deeply($table->_get_mc_def('test'), { value => 'test' }, 'get without def');
is_deeply($table->_get_mc_def('test:2c'), { value => 'test', align => 'c', cols => 2 }, 'get with def');

is_deeply($table->_add_font_family('test:2r', 'bf'), '\\textbf{test}:2r', 'add bold fonts');							 

