use Test::More tests => 12;

use LaTeX::Table;
use English qw( -no_match_vars );

my $table = LaTeX::Table->new();
# font family test 1
eval { $table->_add_font_family( { value => 'test' }, 'test' ) };
ok( $EVAL_ERROR, 'unknown font family' );

#font family test 2
eval { $table->_add_font_family( { value => 'test' }, 'bf' ) };
ok( !$EVAL_ERROR, 'known font family' );

# callback test 1
my $header = [ [ 'a', 'b' ] ];
my $data   = [ [ '1', '2' ] ];

$table = LaTeX::Table->new(
    {   header   => $header,
        data     => $data,
        callback => [],
    }
);

eval { $table->generate_string; };
cmp_ok(
    $EVAL_ERROR, '=~',
    qr{callback is not a code reference},
    'callback not a code reference'
) || diag $EVAL_ERROR;

# callback test 2
$table->set_callback( sub { return 'a'; } );

eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid callback' ) || diag $EVAL_ERROR;

# text_wrap test 1

$table = LaTeX::Table->new(
    {   header    => $header,
        data      => $data,
        text_wrap => {},
    }
);

eval { $table->generate_string; };
cmp_ok(
    $EVAL_ERROR, '=~',
    qr{text_wrap is not an array reference},
    'text_wrap is not an array reference'
) || diag $EVAL_ERROR;

# text_wrap test 2
$table->set_text_wrap(['1', 'b']);

eval { $table->generate_string; };
cmp_ok(
    $EVAL_ERROR, '=~',
    qr{Value in text_wrap not an integer: b},
    'text_wrap: b not integer'
) || diag $EVAL_ERROR;

# text_wrap test 3
$table->set_text_wrap([10, 10]);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid text_wrap' ) || diag $EVAL_ERROR;

$table->set_text_wrap([undef,10]);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid text_wrap' ) || diag $EVAL_ERROR;

# xentrystretch test 1
$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        type         => 'xtab',
        xentrystretch => 'a',
    }
);

eval { $table->generate_string; };
cmp_ok(
    $EVAL_ERROR, '=~',
    qr{xentrystretch not a number},
    'xentrystretch not a number'
) || diag $EVAL_ERROR;

# xentrystretch test 2
$table->set_xentrystretch(0.8);
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid xentrystretch' ) || diag $EVAL_ERROR;

# theme test 1
# xentrystretch test 1
$table = LaTeX::Table->new(
    {   header  => $header,
        data    => $data,
        theme   => 'Leipzig',
    }
);

eval { $table->generate_string; };
cmp_ok(
    $EVAL_ERROR, '=~',
    qr{Unknown theme: Leipzig},
    'unknow theme'
) || diag $EVAL_ERROR;

$table->set_theme('Dresden');
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid theme' ) || diag $EVAL_ERROR;
