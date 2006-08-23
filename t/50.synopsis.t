use Test::More tests => 2;
use English qw( -no_match_vars ) ;

my $SYNOPSIS = <<'EOT'

  use LaTeX::Table;
  
  my $data = [
  	[ 'Lisa',   '0', '0' ],
  	[ 'Marge',  '0', '1' ],
  	[ 'Homer',  '2', '6' ],
  	[],  # horizontal line
  	[ 'Wiggum', '0', '5' ],
  	[ 'Otto',   '1', '3' ],
  	[ 'Barney', '8', '16' ],
  ];
  
  my $header
  	= [ [ 'Name', 'Beers:2|c|' ], [ '', 'before 4pm', 'after 4pm' ] ];
  
  my $table = LaTeX::Table->new(
  	{   
  	   filename    => 'counter.tex',
  	   caption     => 'Number of beers before and after 4pm.',
  	   maincaption => 'Beer Counter',
  	   label       => 'table_beercounter',
  	   theme       => 'Houston',
	   tablepos    => 'htb',
  	}
  );
  
  # write LaTeX code in counter.tex
  $table->generate_string( $header, $data );
EOT
;

eval $SYNOPSIS;
ok(!$EVAL_ERROR,"Test Synopsis");

eval 'my $table = LaTeX::Table->new()';
ok($EVAL_ERROR,"Wrong synopsis");

diag( "Testing LaTeX::Table $LaTeX::Table::VERSION SYNOPSIS" );
