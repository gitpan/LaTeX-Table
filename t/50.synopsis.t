use Test::More tests => 1;
use English qw( -no_match_vars ) ;

my $SYNOPSIS = <<'EOT'

  use LaTeX::Table;
  
  my $header
  	= [ [ 'Name', 'Beers:2|c|' ], [ '', 'before 4pm', 'after 4pm' ] ];
  
  my $data = [
  	[ 'Lisa',   '0', '0' ],
  	[ 'Marge',  '0', '1' ],
  	[ 'Homer',  '2', '6' ],
  	[],  # horizontal line
  	[ 'Wiggum', '0', '5' ],
  	[ 'Otto',   '1', '3' ],
  	[ 'Barney', '8', '16' ],
  ];
  
  my $table = LaTeX::Table->new(
  	{   
        filename    => 'counter.tex',
        caption     => 'Number of beers before and after 4pm.',
        maincaption => 'Beer Counter',
        label       => 'table_beercounter',
        theme       => 'Houston',
        tablepos    => 'htb',
        header      => $header,
        data        => $data,
  	}
  );
  
  # write LaTeX code in counter.tex
  $table->generate_string();

  # wrap the second column after 70 characters
  $table->set_text_wrap([ undef, 70 ]);

  # callback functions
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 1) {
           $value = uc $value;
       }
       return $value;
  });     
  
  $table->generate_string();

EOT
;

eval $SYNOPSIS;
ok(!$EVAL_ERROR,"Test Synopsis") || diag $EVAL_ERROR;

