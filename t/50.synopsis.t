use Test::More tests => 2;
use Test::NoWarnings;
use English qw( -no_match_vars ) ;

my $SYNOPSIS = <<'EOT'

  use LaTeX::Table;
  
  my $header = [
      [ 'Item:2c', '' ],
      ['\cmidrule(r){1-2}'],
      [ 'Animal', 'Description', 'Price' ]
  ];
  
  my $data = [
      [ 'Gnat',      'per gram', '13.65' ],
      [ '',          'each',      '0.01' ],
      [ 'Gnu',       'stuffed',  '92.59' ],
      [ 'Emu',       'stuffed',  '33.33' ],
      [ 'Armadillo', 'frozen',    '8.99' ],
  ];

  
  my $table = LaTeX::Table->new(
  	{   
        filename    => 'prices.tex',
        maincaption => 'Price List',
        caption     => 'Try our special offer today!',
        label       => 'table_prices',
        position    => 'htb',
        header      => $header,
        data        => $data,
  	}
  );
  
  # write LaTeX code in prices.tex
  #$table->generate();

  # callback functions
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 0) {
           $value = uc $value;
       }
       return $value;
  });     
  
  print $table->generate_string();

EOT
;

eval $SYNOPSIS;
ok(!$EVAL_ERROR,"Test Synopsis") || diag $EVAL_ERROR;

