use Test::More tests => 2;

use LaTeX::Table;
use English qw( -no_match_vars ) ;

my $table = LaTeX::Table->new();

eval { $table->_add_font_family({ value => 'test'}, 'test') }; 
ok($EVAL_ERROR, 'unknown font family');

eval { $table->_add_font_family({ value => 'test'}, 'bf') }; 
ok(!$EVAL_ERROR, 'known font family');
