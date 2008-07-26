use Test::More tests => 4;
use Test::NoWarnings;

use LaTeX::Table;
use English qw( -no_match_vars ) ;

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                             });

my $test_data = [ [ 1, 2, 4], [ 2, 3 ] ];
my @summary = $table->_get_data_summary($test_data);
is_deeply(\@summary, [1,1,1], 'all integers');

$test_data = [ [ 'a', 2, 4], [ 'b', 3 ] ];
@summary = $table->_get_data_summary($test_data);
is_deeply(\@summary, [0,1,1], 'not all integers');

$test_data = [ [ 'a', 2, ], [ '1', 3 ] ];
@summary = $table->_get_data_summary($test_data);
is_deeply(\@summary, [0,1], 'not all integers');
