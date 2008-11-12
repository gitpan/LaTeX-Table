use Test::More tests => 31;
use Test::NoWarnings;

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
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option callback: Not a code reference\.},
    'callback not a code reference'
) || diag $EVAL_ERROR;

# callback test 2
$table->set_callback( sub { return 'a'; } );

eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid callback' ) || diag $EVAL_ERROR;


# xentrystretch test 1
$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        type         => 'xtab',
        xentrystretch => 'a',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option xentrystretch: Not a number: a\.},
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
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option theme: Not known: Leipzig\.},
    'unknown theme'
) || diag $EVAL_ERROR;

$table->set_theme('Dresden');
eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid theme' ) || diag $EVAL_ERROR;

# size tests

$table = LaTeX::Table->new(
    {   header  => $header,
        data    => $data,
        size    => 'HUGE',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{^Invalid usage of option custom_themes: Size not known: HUGE. Valid sizes},
    'unknown size'
) || diag $EVAL_ERROR;
$table->set_size('Huge');

eval { $table->generate_string; };
ok( !$EVAL_ERROR, 'no error with valid size' ) || diag $EVAL_ERROR;

# header tests
$table = LaTeX::Table->new(
    {   header  => 'A, B',
        data    => $data,
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option header: Not an array reference\.},
    'header is not an array reference'
) || diag $EVAL_ERROR;
$table->set_header([ 'A', 'B' ]);
eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{\QInvalid usage of option header: header[0] Not an array reference.},
    'header[0] is not an array reference'
) || diag $EVAL_ERROR;

$table->set_header([ [ 'A', ['B'] ] ]);
eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{\QInvalid usage of option header: header[0][1] not a scalar.},
    'header[0][1] is not a scalar'
) || diag $EVAL_ERROR;

# data tests
$table = LaTeX::Table->new(
    {   header  => $header,
        data    =>  { 'A' => 1, 'B' => 1 },
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option data: Not an array reference\.},
    'data is not an array reference'
) || diag $EVAL_ERROR;

$table->set_data([ [ 'A', 'B'], { 'A' => 1, 'B' => 1 } ]);
eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{\QInvalid usage of option data: data[1] Not an array reference.},
    'data[1] is not an array reference'
) || diag $EVAL_ERROR;

$table->set_data([ [ 'A', 'B'], [ 'A', undef ] ]);
eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Undefined value in data\[1\]\[1\].},
    'undef value'
) || diag $EVAL_ERROR;

$table->set_data($data);
$table->set_coldef_strategy(1);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option coldef_strategy: Not a hash reference\.},
    'coldef_strategy not a hash'
) || diag $EVAL_ERROR;

$table->set_coldef_strategy(['a', 'b']);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option coldef_strategy: Not a hash reference\.},
    'coldef_strategy not a hash'
) || diag $EVAL_ERROR;

$table->set_coldef_strategy({
        URL => qr{ \A \s* http }xms,
});

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{^Invalid usage of option coldef_strategy: Missing column attribute URL_COL for URL\.},
    'Missing column attribute URL_COL for URL.'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header  => $header,
        data    => $data,
        width_environment => 'tabularx',
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option width_environment: Is tabularx and width is unset\. },
    'unknown width environment'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        columns_like_header => 2,
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{^Invalid usage of option columns_like_header: Not an array reference\.},
    'columns_like_header not an array reference'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        columns_like_header => { 1 => 2 },
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option columns_like_header: Not an array reference\.},
    'columns_like_header not an array reference'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        columns_like_header => 0,
    }
);

eval { $table->generate_string; };
ok(
    !$EVAL_ERROR, 
    'columns_like_header 0 is ok'
) || diag $EVAL_ERROR;

## resizebox

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        resizebox => 2,
    }
);
eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option resizebox: Not an array reference\.},
    'resizebox not an array reference'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        resizebox => { 1 => 2 },
    }
);

eval { $table->generate_string; };
like(
    $EVAL_ERROR, 
    qr{Invalid usage of option resizebox: Not an array reference\.},
    'resizebox not an array reference'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header              => $header,
        data                => $data,
        resizebox => 0,
    }
);

eval { $table->generate_string; };
ok(
    !$EVAL_ERROR, 
    'resizebox 0 is ok'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        environment  => 0,
        type         => 'xtab',
    }
);


eval { $table->generate_string; };

like(
    $EVAL_ERROR, 
    qr{Invalid usage of option environment: xtab requires an environment\.},
    'xtab requires environment'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        position     => 'htb',
        type         => 'xtab',
    }
);


eval { $table->generate_string; };

like(
    $EVAL_ERROR, 
    qr{Invalid usage of option position: xtab does not support position\.},
    'xtab does not support position'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        left => 1,
        center => 1,
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR, 
    qr{Invalid usage of option center, left, right},
    'only one allowed'
) || diag $EVAL_ERROR;

$table = LaTeX::Table->new(
    {   header       => $header,
        data         => $data,
        shortcaption => 'short',
        maincaption   => 'main',
    }
);

eval { $table->generate_string; };

like(
    $EVAL_ERROR, 
    qr{Invalid usage of option maincaption, shortcaption},
    'only one allowed'
) || diag $EVAL_ERROR;
