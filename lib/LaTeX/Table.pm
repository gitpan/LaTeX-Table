#############################################################################
#   $Author: markus $
#     $Date: 2008-08-27 21:45:12 +0200 (Wed, 27 Aug 2008) $
# $Revision: 932 $
#############################################################################

package LaTeX::Table;
use 5.008;

use warnings;
use strict;

use version; our $VERSION = qv('0.9.1');

use Carp;
use Fatal qw( open close );
use Scalar::Util qw(reftype);
use English qw( -no_match_vars );
use Readonly;

use Text::Wrap qw(wrap);

Readonly my $RULE_TOP_ID    => 0;
Readonly my $RULE_MID_ID    => 1;
Readonly my $RULE_INNER_ID  => 2;
Readonly my $RULE_BOTTOM_ID => 3;

Readonly my $DEFAULT_IS_LONG    => 30;
Readonly my $DEFAULT_LONG_COL   => 'p{5cm}';
Readonly my $DEFAULT_LONG_COL_X => 'X';

use Class::Std;
{

    my %filename : ATTR( :name<filename> :default('latextable.tex') );
    my %label : ATTR( :name<label> :default(0) );
    my %type : ATTR( :name<type> :default('std') );
    my %maincaption : ATTR( :name<maincaption> :default(0) );
    my %header : ATTR( :name<header> :default(0));
    my %data : ATTR( :name<data> :default(0) );
    my %table_environment : ATTR( :name<table_environment> :default('deprecated') );
    my %environment : ATTR( :name<environment> :default('table') );
    my %caption : ATTR( :name<caption> :default(0) );
    my %caption_top : ATTR( :name<caption_top> :default(0) );
    my %tabledef : ATTR( :name<tabledef> :default('deprecated') );
    my %tabledef_strategy : ATTR( :name<tabledef_strategy> :default('deprecated') );
    my %coldef : ATTR( :name<coldef> :default(0) );
    my %coldef_strategy : ATTR( :name<coldef_strategy> :default(0) );
    my %theme : ATTR( :name<theme> :default('Zurich') );
    my %predef_themes : ATTR( :get<predef_themes> );
    my %custom_themes : ATTR( :name<custom_themes> :default(0) );
    my %text_wrap : ATTR( :name<text_wrap> :default(0) );
    my %columns_like_header : ATTR( :name<columns_like_header> :default(0) );
    my %width : ATTR( :name<width> :default(0) );
    my %width_environment : ATTR( :name<width_environment> :default('tabular*') );
    my %tablepos : ATTR( :name<tablepos> :default('deprecated') );
    my %position : ATTR( :name<position> :default(0) );
    my %center : ATTR( :name<center> :default(1) );
    my %size : ATTR( :name<size> :default(0) );
    my %callback : ATTR( :name<callback> :default(0) );
    my %tabletailmsg :
        ATTR( :name<tabletailmsg> :default('Continued on next page') );
    my %tabletail : ATTR( :name<tabletail> :default(0) );
    my %xentrystretch : ATTR( :name<xentrystretch> :default(0) );
    my %resizebox : ATTR( :name<resizebox> :default(0) );

    sub _compatibility_layer {
        my ( $self, @args ) = @_;
        if ($self->get_tablepos ne 'deprecated') {
            carp('DEPRECATED: Use position instead of tablepos.');
            $self->set_position($self->get_tablepos);
        }
        if ($self->get_table_environment ne 'deprecated') {
            carp('DEPRECATED: Use environment instead of table_environment.');
            $self->set_environment($self->get_table_environment);
        }
        if ($self->get_tabledef ne 'deprecated') {
            carp('DEPRECATED: Use coldef instead of tabledef.');
            $self->set_coldef($self->get_tabledef);
        }
        if ($self->get_tabledef_strategy ne 'deprecated') {
            carp('DEPRECATED: Use coldef_strategy instead of tabledef_strategy.');
            $self->set_coldef_strategy($self->get_tabledef_strategy);
        }
        return if !defined $args[0];
        if ( reftype $args[0] eq 'ARRAY' ) {
            carp('DEPRECATED. Use options header and data instead.');
            $self->set_header( $args[0] );
            if ( reftype $args[1] eq 'ARRAY' ) {
                $self->set_data( $args[1] );
            }
        }
        return;
    }


    ###########################################################################
    # Usage      : $table->generate_string();
    # Purpose    : generates LaTex data
    # Returns    : code
    # Parameters : node
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub generate_string {
        my ( $self, @args ) = @_;

        # support for < 0.8.0 API
        $self->_compatibility_layer(@args);

        # are the user provided options ok?
        $self->_check_options();

        # generate the table header LaTeX code
        my $code = $self->_header( $self->get_header, $self->get_data );

        my $theme = $self->_get_theme_settings;
        my $i      = 0;
        my $row_id = 0;

        # check the data and apply callback function
        my @data  = $self->_examine_data;
    ROW:
        for my $row (@data) {
            $i++;

            # empty rows produce a horizontal line
            if ( !@{$row} ) {
                $code .= $self->_get_single_hline_code();
                next ROW;
            }
            else {
                # single column rows that start with a backslash are just
                # printed out
                if (scalar(@{$row}) == 1 && $row->[0] =~ m{\A \s* \\ }xms) {
                    $code .= $row->[0] . "\n";
                    next ROW;
                }

                $row_id++;

                # now print the row LaTeX code
                my $bgcolor = $theme->{'DATA_BG_COLOR_EVEN'};
                if (($row_id % 2) == 1) {
                    $bgcolor = $theme->{'DATA_BG_COLOR_ODD'};
                }
                $code .= $self->_get_row_code( $row, $bgcolor, 0 );

                # do we have to draw a horizontal line?
                if ( $i == scalar @data ) {
                    $code .= $self->_get_hline_code($RULE_BOTTOM_ID);
                }
                else {
                    $code .= $self->_get_hline_code($RULE_INNER_ID);
                }
            }
        }

        # and finally the footer
        $code .= $self->_footer();
        return $code;
    }

    sub _check_options {
        my ( $self ) = @_;

        # default floating enviromnent is table
        if ($self->get_environment eq '1') {
            $self->set_environment('table');
        }

        # check header and data
        $self->_check_2d_array( $self->get_header, 'header' );
        $self->_check_2d_array( $self->get_data,   'data' );

        if ( $self->get_callback && reftype $self->get_callback ne 'CODE' ) {
            croak 'callback is not a code reference.';
        }
        if ($self->get_columns_like_header) {
            $self->_check_1d_array($self->get_columns_like_header,
                'columns_like_header');
        }
        if ($self->get_resizebox) {
            $self->_check_1d_array($self->get_resizebox,
                'resizebox');
        }

        return;
    }

    sub _check_text_wrap {
        my ($self) = @_;
        if ( reftype $self->get_text_wrap ne 'ARRAY' ) {
            croak 'text_wrap is not an array reference.';
        }
        for my $value ( @{ $self->get_text_wrap } ) {
            if ( defined $value && $value !~ m{\A \d+ \z}xms ) {
                croak 'Value in text_wrap not an integer: ' . $value;
            }
        }
        carp('DEPRECATED: use for example tabularx instead.');
        return;
    }

    sub _check_1d_array {
        my ( $self, $arr_ref_1d, $desc ) = @_;
        if ( !defined reftype $arr_ref_1d || reftype $arr_ref_1d ne 'ARRAY' )
        {
            croak "$desc is not an array reference.";
        }
        return;
    }

    sub _check_2d_array {
        my ( $self, $arr_ref_2d, $desc ) = @_;
        $self->_check_1d_array($arr_ref_2d, $desc);
        my $i = 0;
        for my $arr_ref ( @{$arr_ref_2d} ) {
            $self->_check_1d_array($arr_ref, "$desc\[$i\]");
            my $j = 0;
            for my $scalar ( @{$arr_ref} ) {
                my $rt_scalar = reftype $scalar;
                if ( defined $rt_scalar ) {
                    croak "$desc\[$i\]\[$j\] is not a scalar.";
                }
                if (!defined $scalar) {
                    croak "Undefined value in $desc\[$i\]\[$j\]";
                }
                $j++;
            }
            $i++;
        }
        return;
    }

    sub _apply_callback {
        my ( $self, $i, $j, $value, $is_header ) = @_;
        my $col_cb = $self->_get_mc_def($value);
        $col_cb->{value}  = &{ $self->get_callback }( $i, $j,
            $col_cb->{value}, $is_header );
        return $self->_get_mc_value($col_cb);
    }

    sub _examine_data {
        my ($self)    = @_;
        my $text_wrap = $self->get_text_wrap;
        my @data      = @{ $self->get_data };
        if ( $self->get_callback ) {
            for my $i ( 0 .. $#data ) {
                my @row = @{$data[$i]};
                my $k = 0;
                for my $j ( 0 .. ( scalar @{ $data[$i] } - 1 ) ) {
                    $row[$j] = $self->_apply_callback( $i, $k,
                        $data[$i][$j],0);
                    $k += $self->_extract_number_columns($data[$i][$j])
                }
                $data[$i] = \@row;
            }
        }
        return @data if !$text_wrap;
        $self->_check_text_wrap;

        my @data_wrapped;
        my $i = 0;
        for my $row (@data) {
            my $j = 0;
            my @rows;
            for my $col ( @{$row} ) {
                if ( defined $text_wrap->[$j]
                    && length $col > $text_wrap->[$j] )
                {
                    my $l = 0;

                    ## no critic
                    local ($Text::Wrap::columns) = $text_wrap->[$j];
                    ## use critic
                    my $lines = wrap( q{}, q{}, $col );
                    for my $wrapped_line ( split /\n/xms, $lines ) {
                        $rows[$l][$j] = $wrapped_line;
                        $l++;
                    }
                }
                else {
                    $rows[0][$j] = $col;
                }
                $j++;
            }

            for my $row_row (@rows) {
                push @data_wrapped, [];
                for my $row_i ( 0 .. ( scalar( @{$row} ) - 1 ) ) {
                    if ( defined $row_row->[$row_i] ) {
                        $data_wrapped[-1]->[$row_i] = $row_row->[$row_i];
                    }
                    else {
                        $data_wrapped[-1]->[$row_i] = q{};
                    }
                }
            }
            $i += scalar @rows;
        }
        return @data_wrapped;
    }

    sub generate {
        my ( $self, $header, $data ) = @_;
        my $code = $self->generate_string( $header, $data );
        open my $LATEX, '>', $self->get_filename;
        print {$LATEX} $code    or croak q{Couldn't write '}. $self->get_name .
            "': $OS_ERROR";
        close $LATEX;
        return 1;
    }

    ###########################################################################
    # Usage      : $self->_header(\@header,\@data);
    # Purpose    : create the LaTeX header
    # Returns    : LaTeX code
    # Parameters : header and data columns
    # Throws     :
    # Comments   : n/a
    # See also   : _footer

    sub _header {
        my ( $self, $header, $data ) = @_;

        # if specified, use coldef, otherwise guess a good definition
        my $table_def;
        if ( $self->get_coldef ) {
            $table_def = $self->get_coldef;
        }
        else {
            $table_def = $self->_get_coldef_code($data);
        }

        my $pos  = $self->_get_pos_code() . "\n";
        my $code = $self->_get_header_columns_code($header);

        my $begin_center = q{};
        if ( $self->get_center ) {
            if ($self->get_type eq 'std') {
                $begin_center = "\\centering\n";
            }
            else {
                $begin_center = "\\begin{center}\n";
            }
        }
        my $width = q{};
        my $asterisk = q{};
        if ( $self->get_width ) {
            $width = '{' . $self->get_width . '}';
            if ($self->get_width_environment eq 'tabular*') {
            ## no critic
            $table_def = '@{\extracolsep{\fill}} ' . $table_def;
            ## use critic
            $asterisk = q{*};
            }
            elsif ($self->get_width_environment eq 'tabularx' &&
                $self->get_type eq 'std' ) {
                $asterisk = q{x};
            }
            else {
                croak(
                    'Width environment not known: ',
                    $self->get_width_environment ,
                 '. Valid environments are: tabular*, tabularx (not for xtab).'
                );
            }
        }
        elsif( $self->get_width_environment eq 'tabularx') {
            croak('width_environment is tabularx and width is unset.');
        }
        my $colordef = q{};

        if (defined $self->_get_theme_settings->{DEFINE_COLORS}) {
            $colordef = $self->_get_theme_settings->{DEFINE_COLORS} . "\n";
        }

        my $size    = $self->_get_size_code();
        my $caption = $self->_get_caption_code(0);
        my $label   = $self->_get_label_code;

        my $tabletail     = $self->_get_tabletail_code( $data, 0 );
        my $tabletaillast = $self->_get_tabletail_code( $data, 1 );

        my $begin_resizebox = q{};
        if ($self->get_resizebox) {
            my $rb_width = $self->get_resizebox->[0];
            my $rb_height = q{!};
            if (defined $self->get_resizebox->[1]) {
                $rb_height =  $self->get_resizebox->[1];
            }
            $begin_resizebox = "\\resizebox{$rb_width}{$rb_height}{\n";
        }

        my $xentrystretch = q{};
        if ( $self->get_xentrystretch ) {
            my $xs = $self->get_xentrystretch();
            croak('xentrystretch not a number') if $xs !~
                /\A-?(?:\d+(?:\.\d*)?|\.\d+)\z/xms;
            $xentrystretch = "\\xentrystretch{$xs}\n";
        }

        if ( $self->get_type eq 'xtab' ) {
            return <<"EOXT"
{
$colordef$size$caption$xentrystretch$label
\\tablehead{$code}
$tabletail
$tabletaillast
$begin_center$begin_resizebox\\begin{xtabular$asterisk}${width}{$table_def}
EOXT
        }
        else {
            my $environment = q{};
            $caption = $self->_get_caption_code(1);
            if ( $self->get_environment ) {
                $environment = join q{},
                '\\begin{', $self->get_environment, "}$pos", $size,
                    $begin_center, $caption;
            }
            return <<"EOST"
$colordef$environment$begin_resizebox\\begin{tabular$asterisk}${width}{$table_def}
    $code
EOST
                ;
        }
    }

    ###########################################################################
    # Usage      : $self->_footer();
    # Purpose    : create the LaTeX footer
    # Returns    : LaTeX code
    # Parameters : none
    # See also   : _header

    sub _footer {
        my ($self)  = @_;
        my $label   = $self->_get_label_code();
        my $caption = $self->_get_caption_code(0);
        my $asterisk = q{};
        if ( $self->get_width ) {
            if ($self->get_width_environment eq 'tabular*') {
                $asterisk = q{*};
            }
            else {
                $asterisk = q{x};
            }
        }
        my $end_resizebox = q{};
        if ($self->get_resizebox) {
            $end_resizebox = "}\n";
        }
        if ( $self->get_type eq 'xtab' ) {
            my $end_center = q{};
            if ( $self->get_center ) {
                $end_center = "\\end{center}";
            }
            return <<"EOXT"
\\end{xtabular$asterisk}
$end_resizebox$end_center
} 
EOXT
        }
        else {
            my $environment = q{};
            if ( $self->get_environment ) {
                $environment = join q{}, $caption, $label,
                    '\\end{', $self->get_environment, '}';

            }
            return <<"EOST"
\\end{tabular$asterisk}
$end_resizebox$environment
EOST
                ;
        }
    }

    sub _default_coldef_strategy {
        my ($self) = @_;
        my $STRATEGY = {
            #IS_A_NUMBER => $RE{num}{real},
            IS_A_NUMBER =>
                qr{\A([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z}xms,
            IS_LONG       => $DEFAULT_IS_LONG,
            NUMBER_COL    => 'r',
            NUMBER_COL_X  => 'r',
            LONG_COL      => $DEFAULT_LONG_COL,
            LONG_COL_X    => $DEFAULT_LONG_COL_X,
            DEFAULT       => 'l',
            DEFAULT_X     => 'l',
        };
        $self->set_coldef_strategy($STRATEGY);
        return $STRATEGY;
    }

    sub _check_coldef_strategy {
        my ( $self , $strategy ) = @_;
        my $rt_strategy = reftype $strategy;
        if (!defined $rt_strategy || $rt_strategy ne 'HASH') {
            croak 'coldef_strategy not a hash reference.';
        }
        my $default = $self->_default_coldef_strategy;
        for my $key (keys %{$default}) {
            if (!defined $strategy->{$key}) {
                $strategy->{$key} = $default->{$key};
            }
        }
        $self->set_coldef_strategy($strategy);
        return;
    }

    sub _extract_number_columns {
        my ( $self, $col ) = @_;
        my $def = $self->_get_mc_def($col);
        if (defined $def->{cols}) {
            return $def->{cols};
        }
        else {
            return 1;
        }
    }

    ###########################################################################
    # Usage      : $self->_get_data_summary(\@data);
    # Purpose    : find out how many columns we need and if column consists of
    #              numbers only
    # Returns    : an array with one entry for every column. Entry is either 1
    #              (column is numerical) or 0.
    # Parameters : data columns
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub _get_data_summary {
        my ( $self, $data ) = @_;
        my @max_row;
        my $strategy = $self->get_coldef_strategy;
        if ( !$strategy ) {
            $strategy = $self->_default_coldef_strategy;
        } else {
            $self->_check_coldef_strategy($strategy);
        }
        my %is_a_number;
        my %not_a_number;
        my %is_long;
        for my $row ( @{$data} ) {
            if ( scalar @{$row} > scalar @max_row ) {
                @max_row = @{$row};
            }
            my $i = 0;
            for my $col ( @{$row} ) {
                if ( $col =~ $strategy->{IS_A_NUMBER} ) {
                    $is_a_number{$i}++;
                }
                elsif ( length $col >= $strategy->{IS_LONG} ) {
                    $is_long{$i}++;
                }
                else {
                    $not_a_number{$i}++;
                }
                $i += $self->_extract_number_columns($col);
            }
        }
        my @summary;
        for my $i ( 0 .. $#max_row ) {
            my $number = 0;
            if ( defined $is_a_number{$i} && !defined $not_a_number{$i} ) {
                $number = 1;
            }
            if ( defined $is_long{$i} && !$self->get_text_wrap ) {
                $number = 2;
            }
            push @summary, $number;
        }
        return @summary;
    }

    sub _get_hline_code {
        my ( $self,  $id ) = @_;
        my $theme  = $self->_get_theme_settings;
        my $hlines = $theme->{'HORIZONTAL_LINES'};
        my $line = 'hline';
        if (defined $theme->{'BOOKTABS'} && $theme->{'BOOKTABS'}) {
            my @line_type = qw(toprule midrule midrule bottomrule);
            $line = $line_type[$id];
        }
        if ($id == $RULE_BOTTOM_ID) {
            $id = 0;
        }
        return "\\$line\n" x $hlines->[$id];
    }

    sub _get_single_hline_code {
        my ( $self,  $id ) = @_;
        my $theme  = $self->_get_theme_settings;
        my $line = 'hline';
        if (defined $theme->{'BOOKTABS'} && $theme->{'BOOKTABS'}) {
            $line = 'midrule';
        }
        return "\\$line\n";
    }

    ###########################################################################
    # Usage      : $self->_get_header_columns_code(\@header);
    # Purpose    : generate the header LaTeX code
    # Returns    : LaTeX code
    # Parameters : header columns
    # Throws     :
    # Comments   : n/a
    # See also   : _get_row_code

    sub _get_header_columns_code {
        my ( $self, $header ) = @_;
        my $code   = q{};
        my $theme  = $self->_get_theme_settings;
        $code .= $self->_get_hline_code($RULE_TOP_ID);

        my $i = 0;

        CENTER_ROW:
        foreach my $row ( @{$header} ) {
            my @cols = @{$row};
            if (scalar(@cols) == 1 && $cols[0] =~ m{\A \s* \\ }xms) {
                $code .= $cols[0] . "\n";
                next CENTER_ROW;
            }

            my $j = 0;

            foreach my $col (@cols) {
                next if $col =~ m{\A \\ }xms;
                if ( $self->get_callback ) {
                    $col = $self->_apply_callback($i, $j, $col, 1);
                }
                $col = $self->_apply_header_formatting($col, 1);

                $j += $self->_extract_number_columns($col);
            }

            $code .= $self->_get_row_code(\@cols, $theme->{'HEADER_BG_COLOR'}, 1);
            $i++;
        }

        # without header, just draw the topline
        if ($i) {
            $code .= $self->_get_hline_code($RULE_MID_ID);
        }
        return $code;
    }
    
    sub _apply_header_formatting {
        my ( $self, $col, $aligning ) = @_;
        my $theme  = $self->_get_theme_settings;
        if ( $aligning && defined $theme->{'HEADER_CENTERED'}
            && $theme->{'HEADER_CENTERED'} ) {
            $col = $self->_add_mc_def(
                { value => $col, align => 'c', cols => '1' } );
        }
        if ( defined $theme->{'HEADER_FONT_STYLE'} ) {
            $col = $self->_add_font_family( $col,
                $theme->{'HEADER_FONT_STYLE'} );
        }
        if ( defined $theme->{'HEADER_FONT_COLOR'} ) {
            $col = $self->_add_font_color( $col,
                $theme->{'HEADER_FONT_COLOR'} );
        }
        return $col;
    }

    sub _get_cell_bg_color {
        my ( $self, $row_bg_color, $col_id ) = @_;
        my $cell_bg_color = $row_bg_color;
        if ($self->get_columns_like_header) {
            HEADER_COLUMN:
            for my $i ( @{ $self->get_columns_like_header } ) {
                if ($i == $col_id) {
                    $cell_bg_color = $self->_get_theme_settings->{'HEADER_BG_COLOR'};
                    last HEADER_COLUMN;
                }
            }
        }
        return $cell_bg_color;
    }

    ###########################################################################
    # Usage      : $self->_get_row_code($cols_ref);
    # Purpose    : generate the LaTeX code of a row
    # Returns    : LaTeX code
    # Parameters : the columns
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub _get_row_code {
        my ( $self, $cols_ref, $bgcolor, $is_header ) = @_;
        my @cols_defs = map { $self->_get_mc_def($_) } @{$cols_ref};
        my @cols = ();
        my $theme  = $self->_get_theme_settings;
        my $vlines = $theme->{'VERTICAL_LINES'};
        my $v0 = q{|} x $vlines->[0];
        my $v1 = q{|} x $vlines->[1];
        my $v2 = q{|} x $vlines->[2];
        my $j = 0; my $col_id = 0;
        for my $col_def (@cols_defs) {
            if (!$is_header && $self->get_columns_like_header) {
                HEADER_COLUMN:
                for my $i ( @{ $self->get_columns_like_header } ) {
                    next HEADER_COLUMN if $i != $col_id;
                    $col_def = $self->_get_mc_def(
                        $self->_apply_header_formatting(
                            $self->_get_mc_value( $col_def ), 0 ) );
                    if (!defined $col_def->{cols}) {
                        $col_def->{cols} = 1;
                        $col_def->{align} = 'l';
                    }
                }
            }
            if ( defined $col_def->{cols} ) {
                my $vl_pre  = q{};
                my $vl_post = q{};

                if ( $j == 0 ) {
                    $vl_pre = $v0;
                }

                if ( $j == ( scalar(@cols_defs) - 1 ) ) {
                    $vl_post =  $v0;
                }
                elsif ( $j == 0  && $col_def->{cols}  == 1) {
                    $vl_post =  $v1;
                }
                else {
                    $vl_post =  $v2;
                }

                my $color_code = q{};

                my $cell_bg_color = $self->_get_cell_bg_color($bgcolor, $col_id);
                if (defined $cell_bg_color) {
                    $color_code = '>{\columncolor{' . $cell_bg_color . '}}';
                }

                push @cols,
                    '\\multicolumn{'
                    . $col_def->{cols} . '}{'
                    . $vl_pre . $color_code . $col_def->{align} . $vl_post . '}{'
                    . $col_def->{value} . '}';

                $col_id += $col_def->{cols};
            }
            else {
                push @cols, $col_def->{value};
                $col_id++;
            }
            $j++;
        }
        if (defined $bgcolor && scalar(@cols) >= 0) {
            $cols[0] = "\\rowcolor{$bgcolor}" . $cols[0];
        }
        return join( ' & ', @cols ) . "\\\\ \n";
    }

    sub _add_mc_def {
        my ( $self, $arg_ref ) = @_;
        my $def = $self->_get_mc_def( $arg_ref->{value} );
        if ( defined $def->{cols} ) {
            return $arg_ref->{value};
        }
        else {
            return $self->_get_mc_value($arg_ref);
        }
    }

    sub _get_mc_value {
        my ( $self, $def ) = @_;
        if ( defined $def->{cols} ) {
            return $def->{value} . q{:} . $def->{cols} . $def->{align};
        }
        else {
            return $def->{value};
        }
    }

    sub _get_mc_def {
        my ( $self, $value ) = @_;
        if ( $value =~ m{ \A (.*)\:(\d)([clr]) \z }xms ) {
            return { value => $1, cols => $2, align => $3 };
        }
        else {
            return { value => $value };
        }
    }

    ###############################################################################
    # Usage      : $self->_add_font_family($col_def, 'bf');
    # Purpose    : add font family to value of column definition
    # Returns    : new column definition
    # Parameters : column definition and family (tt, bf, it, sc)
    # Throws     : exception when family is not known
    # Comments   : n/a
    # See also   :

    sub _add_font_family {
        my ( $self, $col, $family ) = @_;
        my %know_families = ( tt => 1, bf => 1, it => 1, sc => 1 );
        if ( !defined $know_families{$family} ) {
            croak(
                "Family not known: $family. Valid families are: " . join ', ',
                sort keys %know_families
            );
        }
        my $col_def = $self->_get_mc_def($col);
        $col_def->{value} = "\\text$family" . '{' . $col_def->{value} . '}';
        return $self->_get_mc_value($col_def);
    }

    sub _add_font_color {
        my ( $self, $col, $color ) = @_;
        my $col_def = $self->_get_mc_def($col);
        $col_def->{value} = "\\color{$color}" . $col_def->{value};
        return $self->_get_mc_value($col_def);
    }

    ###########################################################################
    # Usage      : $self->_get_coldef_code(\@data);
    # Purpose    : generate the LaTeX code of the table definition (e.g.
    #              |l|r|r|r|)
    # Returns    : LaTeX code
    # Parameters : the data columns
    # Throws     :
    # Comments   : Tries to be intelligent. Hope it is ;)
    # See also   :

    sub _get_coldef_code {
        my ( $self, $data ) = @_;
        my @cols   = $self->_get_data_summary($data);
        my $vlines = $self->_get_theme_settings->{'VERTICAL_LINES'};

        my $v0 = q{|} x $vlines->[0];
        my $v1 = q{|} x $vlines->[1];
        my $v2 = q{|} x $vlines->[2];

        my $table_def = q{};
        my $i         = 0;
        my $strategy  = $self->get_coldef_strategy();
        my $tabularx  = q{};
        
        if ($self->get_width_environment eq 'tabularx') {
            $tabularx = '_X';
        }

        for my $col (@cols) {

            # align text right, numbers left, first col always left
            my $align = $strategy->{"DEFAULT$tabularx"};
            if ( $col == 1 ) {
                $align = $strategy->{"NUMBER_COL$tabularx"};
            }
            elsif ( $col == 2 ) {
                $align = $strategy->{"LONG_COL$tabularx"};
            }

            if ( $i == 0 ) {
                $table_def .= $v0 . 'l' . $v1;
            }
            elsif ( $i == ( scalar(@cols) - 1 ) ) {
                $table_def .= $align . $v0;
            }
            else {
                $table_def .= $align . $v2;
            }
            $i++;
        }
        return $table_def;
    }

    ###########################################################################
    # Usage      : $self->_get_tabletail_code(\@data, $final_tabletail);
    # Purpose    : generates the LaTeX code of the xtab tabletail
    # Returns    : LaTeX code
    # Parameters : the data columns and a flag indicating whether it is the
    #              code for the final tail (1).
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub _get_tabletail_code {
        my ( $self, $data, $final_tabletail ) = @_;

        my $code;
        my $hlines  = $self->_get_theme_settings->{'HORIZONTAL_LINES'};
        my $vlines  = $self->_get_theme_settings->{'VERTICAL_LINES'};
        my $linecode1 = $self->_get_hline_code($RULE_MID_ID);
        my $linecode2 = $self->_get_hline_code($RULE_BOTTOM_ID);

        # if custom table tail is defined, then return it
        if ( $self->get_tabletail ) {
            $code = $self->get_tabletail;
        }
        elsif (!$final_tabletail) {
            my @cols    = $self->_get_data_summary($data);
            my $nu_cols = scalar @cols;

            my $v0 = q{|} x $vlines->[0];
            $code = "$linecode1\\multicolumn{$nu_cols}{${v0}r$v0}{{" .
                $self->get_tabletailmsg. "}} \\\\ \n";
        }
        if ($final_tabletail) {
            return "\\tablelasttail{}";
        }
        return "\\tabletail{$code$linecode2}";
    }

    ###########################################################################
    # Usage      : $self->_get_caption_code();
    # Purpose    : generates the LaTeX code of the caption
    # Returns    : LaTeX code
    # Parameters : header (1)
    # Throws     :
    # Comments   : header specifies whether this function has been called in
    #              the header or footer. ignored for xtab, because there it  
    #              is always placed on top
    # See also   :

    sub _get_caption_code {
        my ($self, $header)  = @_;
        my $f_caption = q{};
        my $s_caption = q{};
        my $theme     = $self->_get_theme_settings;
        
        my $c_caption;
        if ($self->get_caption_top) {
            if ( $self->get_type eq 'xtab' ) {
                $c_caption = $self->get_caption_top;
                if ($c_caption eq '1') {
                    $c_caption = 'topcaption';
                }
            }
            else {
                if (!$header) {
                    return q{};
                }
                $c_caption = $self->get_caption_top;
                $c_caption =~ s{ \A \\ }{}xms;
                if ($c_caption eq '1') {
                    $c_caption = 'caption';
                }
            }
        }
        else {
            if ( $self->get_type eq 'xtab' ) {
                $c_caption = 'bottomcaption';
            }
            else {
                if ($header) {
                    return q{};
                }
                $c_caption = 'caption';
            }
        }
        my $tmp = q{};
        if ( $self->get_maincaption ) {
            $f_caption = '[' . $self->get_maincaption . ']';
            $tmp       = $self->get_maincaption . '. ';
            if ( defined $theme->{CAPTION_FONT_STYLE} ) {
                $tmp = $self->_add_font_family( $tmp,
                    $theme->{CAPTION_FONT_STYLE} );
            }
        }
        else {
            return q{} if !$self->get_caption;
        }

        $s_caption = '{' . $tmp . $self->get_caption . '}';

        return q{\\} . $c_caption . $f_caption . $s_caption . "\n";
    }

    ###########################################################################
    # Usage      : $self->_get_size_code();
    # Purpose    : generates the LaTeX code of the size (e.g. \small, \large)
    # Returns    : LaTeX code
    # Parameters : none
    # Throws     : exception if size is not valid
    # Comments   : n/a
    # See also   :

    sub _get_size_code {
        my ($self) = @_;
        my %valid = (
            'tiny'         => 1,
            'scriptsize'   => 1,
            'footnotesize' => 1,
            'small'        => 1,
            'normal'       => 1,
            'large'        => 1,
            'Large'        => 1,
            'LARGE'        => 1,
            'huge'         => 1,
            'Huge'         => 1,
        );
        my $size = $self->get_size;
        return q{} if !$size;

        if ( !defined $valid{$size} ) {
            croak( "Size not known: $size. Valid sizes are: " . join ', ',
                sort keys %valid );
        }
        return "\\$size\n";
    }

    ###########################################################################
    # Usage      : $self->_get_label_code();
    # Purpose    : create the LaTeX label
    # Returns    : LaTeX code
    # Parameters : none

    sub _get_label_code {
        my ($self) = @_;
        my $label = $self->get_label;
        if ($label) {
            return "\\label{$label}\n";
        }
        return q{};
    }

    ###########################################################################
    # Usage      : $self->_get_pos_code();
    # Purpose    : generates the LaTeX code of the table position (e.g. [htb])
    # Returns    : LaTeX code
    # Parameters : none

    sub _get_pos_code {
        my ($self) = @_;
        if ( $self->get_position ) {
            return '[' . $self->get_position . ']';
        }
        else {
            return q{};
        }

    }

    ###########################################################################
    # Usage      : $self->_get_theme_settings();
    # Purpose    : return an hash reference with all settings of the current
    #              theme
    # Returns    : see purpose
    # Parameters : none
    # Throws     : exception if theme is unknown
    # Comments   : n/a
    # See also   : get_available_themes();

    sub _get_theme_settings {
        my ($self) = @_;
        my $themes = $self->get_available_themes;
        if ( defined $themes->{ $self->get_theme } ) {
            return $themes->{ $self->get_theme };
        }
        else {
            croak( 'Theme not known: ' . $self->get_theme );
        }
    }

    ###########################################################################
    # Usage      : called by Class::Std
    # Purpose    : initializing themes
    # Parameters : none
    # See also   : perldoc Class::Std

    sub BUILD {
        my ( $self, $ident, $arg_ref ) = @_;
        $predef_themes{$ident} = {
            'Dresden' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
                'BOOKTABS'           => 0,
            },
            'Berlin' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 1, 1, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
                'BOOKTABS'           => 0,
            },
            'Paris' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'HEADER_BG_COLOR'    => 'latextblgray',
                'DEFINE_COLORS'      =>
                '\definecolor{latextblgray}{gray}{0.7}',
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 1, 1, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
                'BOOKTABS'           => 0,
            },
            'Zurich' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'VERTICAL_LINES'     => [ 0, 0, 0 ],
                'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
                'BOOKTABS'           => 1,
            },
            'Houston' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 2, 1 ],
                'BOOKTABS'           => 0,
            },
            'Miami' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 0, 0, 0 ],
                'HORIZONTAL_LINES'   => [ 0, 1, 0 ],
                'BOOKTABS'           => 0,
            },
            'NYC' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_FONT_COLOR'  => 'white',
                'HEADER_BG_COLOR'    => 'latextbl',
                'DATA_BG_COLOR_ODD'  => 'latextbl!25',
                'DATA_BG_COLOR_EVEN' => 'latextbl!10',
                'DEFINE_COLORS'      =>
                '\definecolor{latextbl}{RGB}{78,130,190}',
                'HEADER_CENTERED'    => 1,
                'VERTICAL_LINES'     => [ 1, 0, 0 ],
                'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
                'BOOKTABS'           => 0,
            },
            'plain' => {
                'VERTICAL_LINES'     => [ 0, 0, 0 ],
                'HORIZONTAL_LINES'   => [ 0, 0, 0 ],
                'BOOKTABS'           => 0,
            },
        };
        return;
    }

    ###########################################################################
    # Usage      : called by Class::Std
    # Purpose    : initializing values 'cause Class::Std can also define
    #              simple default values
    # Parameters : none
    # See also   : perldoc Class::Std

    sub START {
        my ( $self, $ident, $args_ref ) = @_;
        if ( !$header{$ident} ) {
            $header{$ident} = [];
        }

        if ( !$data{$ident} ) {
            $data{$ident} = [];
        }

        if ( $custom_themes{$ident} == 0 ) {
            $custom_themes{$ident} = {};
        }
        return;
    }

    ###########################################################################
    # Usage      : $self->get_available_themes();
    # Purpose    : return an hash reference with all available themes
    #              (predefined and custom)
    # Returns    : see purpose
    # Parameters : none
    # Throws     : no exceptions
    # Comments   : n/a
    # See also   : _get_theme_settings()

    sub get_available_themes {
        my ($self) = @_;
        return {
            ( %{ $self->get_predef_themes }, %{ $self->get_custom_themes } )
        };
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

LaTeX::Table - Perl extension for the automatic generation of LaTeX tables.

=head1 VERSION

This document describes LaTeX::Table version 0.9.1

=head1 SYNOPSIS

  use LaTeX::Table;
  use Number::Format qw(:subs);  # use mighty CPAN to format values

  my $header = [
      [ 'Item:2c', '' ],
      [ '\cmidrule(r){1-2}' ],
      [ 'Animal', 'Description', 'Price' ]
  ];
  
  my $data = [
      [ 'Gnat',      'per gram', '13.65'   ],
      [ '',          'each',      '0.0173' ],
      [ 'Gnu',       'stuffed',  '92.59'   ],
      [ 'Emu',       'stuffed',  '33.33'   ],
      [ 'Armadillo', 'frozen',    '8.99'   ],
  ];

  
  my $table = LaTeX::Table->new(
  	{   
        filename    => 'prices.tex',
        maincaption => 'Price List',
        caption     => 'Try our special offer today!',
        label       => 'table:prices',
        position    => 'htb',
        header      => $header,
        data        => $data,
  	}
  );
  
  # write LaTeX code in prices.tex
  $table->generate();

  # callback functions help you to format values easily (as
  # a great alternative to LaTeX packages like rccol)
  #
  # Here, the first colum and the header is printed in upper
  # case and the third colum is formatted with format_price()
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 0 || $is_header) {
           $value = uc $value;
       }
       elsif ($col == 2 && !$is_header) {
           $value = format_price($value, 2, '');
       }
       return $value;
  });     
  
  print $table->generate_string();

Now in your LaTeX document:

  \documentclass{article}

  % for multipage tables
  \usepackage{xtab}
  % for publication quality tables
  \usepackage{booktabs}

  \begin{document}
  \input{prices}
  \end{document}
  
=head1 DESCRIPTION

LaTeX::Table provides functionality for an intuitive and easy generation of
LaTeX tables. It ships with some predefined good looking
table styles. This module supports multipage tables via the C<xtab> package and 
publication quality tables with the C<booktabs> package. It also supports the
C<tabularx> package for nicer fixed-width tables. Furthermore, it supports 
the C<colortbl> package for colored tables optimized for presentations.

LaTeX makes professional typesetting easy. Unfortunately,
this is not entirely true for tables. Many additional, highly specialized packages are 
therefore available on CTAN. This module supports the best packages and
visualizes your in Perl generated or summarized results with high quality. 

=head1 INTERFACE 

=over

=item C<my $table = LaTeX::Table-E<gt>new($arg_ref)>

Constructs a LaTeX::Table object. The parameter is an hash reference with
options (see below).

=item C<$table-E<gt>generate()>

Generates the LaTeX table code. The generated LaTeX table can be included in
a LaTeX document with the C<\input> command:
  
  % include prices.tex, generated by LaTeX::Table 
  \input{prices}

=item C<$table-E<gt>generate_string()>

Same as generate() but instead of creating a LaTeX file, this returns the LaTeX code
as string.

  my $latexcode = $table->generate_string();

=item C<$table-E<gt>get_available_themes()>

Returns an hash reference to all available (predefined and customs) themes. 
See L<"THEMES"> for details.

  for my $theme ( keys %{ $table->get_available_themes } ) {
    ...
  }


=back

=head1 OPTIONS

Options can be defined in the constructor hash reference or with the setter
set_<optionname>. Additionally, getters of the form get_<optionname> are
created.

=head2 BASIC OPTIONS

=over

=item C<filename>

The name of the LaTeX output file. Default is 'latextable.tex'.

=item C<type>

Can be either I<std> for the standard LaTeX table or I<xtab> for
a xtabular table for multipage tables (in appendices for example). The latter 
requires the C<xtab> LaTeX package (C<\usepackage{xtab}> in your LaTeX document). 
Default is I<std>.

=item C<header>

The header. It is a reference to an array (the rows) of array references (the
columns).

  $table->set_header([ [ 'Animal', 'Price' ] ]);

will produce following header:

  +--------+-------+
  | Animal | Price |
  +--------+-------+

Here an example for a multirow header:

  $table->set_header([ [ 'Animal', 'Price' ], ['', '(roughly)' ] ]);

This code will produce this header:

  +--------+-----------+
  | Animal |   Price   |
  |        | (roughly) |
  +--------+-----------+

Single column rows that start with a backslash are treated as LaTeX commands
and are not further formatted. So,

  my $header = [
      [ 'Item:2c', '' ],
      ['\cline{1-2}'],
      [ 'Animal', 'Description', 'Price' ]
  ];

will produce following LaTeX code in the default Zurich theme:

  \multicolumn{2}{c}{\textbf{Item}} & \multicolumn{1}{c}{\textbf{}}\\ 
  \cline{1-2}
  \multicolumn{1}{c}{\textbf{Animal}} & \multicolumn{1}{c}{\textbf{Description}} & \multicolumn{1}{c}{\textbf{Price}}\\ 

Note that there is no multicolum, textbf or \\ added to the second row.

=item C<data>

The data. Once again a reference to an array (rows) of array references
(columns). 

  $table->set_data([ [ 'Gnu', '92.59' ], [ 'Emu', '33.33' ] ]);

And you will get a table like this:

  +-------+---------+
  | Gnu   |   92.59 |
  | Emu   |   33.33 |
  +-------+---------+

An empty column array will produce a horizontal line:

  $table->set_data([ [ 'Gnu', '92.59' ], [], [ 'Emu', '33.33' ] ]);

And you will get a table like this:

  +-------+---------+
  | Gnu   |   92.59 |
  +-------+---------+
  | Emu   |   33.33 |
  +-------+---------+

Single column rows starting with a backslash are again printed without any
formatting. So,

  $table->set_data([ [ 'Gnu', '92.59' ], ['\hline'], [ 'Emu', '33.33' ] ]);

is equivalent to the example above (except that there always the correct line
command is used, i.e. C<\midrule> vs. C<\hline>).

=back

=head2 FLOATING TABLES

=over

=item C<environment>

If get_environment() returns a true value, then a floating environment will be 
generated. Default is 'table'. You can use 'sidewaystable' for rotated tables
(requires the C<rotating> package). This option only affects tables of C<type> I<std>.

  \begin{table}[htb]
      \centering
      \begin{tabular}{lrr}
      ...
      \end{tabular}
      \caption{Price list}
      \label{table:prices}
  \end{table} 

=item C<caption>

The caption of the table. Only generated if get_caption() returns a true value. 
Default is 0. Requires C<environment>.

=item C<caption_top>

If get_caption_top() returns a true value, then the caption is placed above the
table. To use the standard caption command (C<\caption> in I<std>,
C<\topcaption> in I<xtab>) , use 

   ...
   caption_top => 1, 
   ...

You can specify an alternative command here:

   ...
   caption_top => 'topcaption', # would require the topcapt package

Or even multiple commands: 

   caption_top =>
     '\setlength{\abovecaptionskip}{0pt}\setlength{\belowcaptionskip}{10pt}\caption',
   ...

Default 0 (caption below the table).  

=item C<center>

Defines whether the table is centered. Default 1 (centered). Requires 
C<environment>.

=item C<label>

The label of the table. Only generated if get_label() returns a true value.
In LaTeX you can create a reference to the table with C<\ref{label}>.
Default is 0. Requires C<environment>.

=item C<maincaption>

If get_maincaption() returns a true value, then this value will be displayed 
in the Table Listing (C<\listoftables>) and before the C<caption>. Default
0. Requires C<environment>.

=item C<size>

Font size. Valid values are 'tiny', 'scriptsize', 'footnotesize', 'small',
'normal', 'large', 'Large', 'LARGE', 'huge', 'Huge' and 0. Default is 0 (does 
not define a font size). Requires C<environment>.

=item C<position>

The position of the environment, e.g. C<htb>. Only generated if get_position()
returns a true value. Requires C<environment>.

=back

=head2 TABULAR ENVIRONMENT

=over 

=item C<callback>

If get_callback() returns a true value and the return value is a code reference,
then this callback function will be called for every column in C<header>
and C<data>. The return value of this function is then printed instead of the 
column value. 

The passed arguments are C<$row>, C<$col> (both starting with 0), C<$value> and 
C<$is_header>.

   use LaTeX::Encode;
   use Number::Format qw(:subs);  
   ...
   
   # use LaTeX::Encode to encode LaTeX special characters,
   # format the third column with Format::Number (only the data)
   my $table = LaTeX::Table->new(
       {   header   => $header,
           data     => $data,
           callback => sub {
               my ( $row, $col, $value, $is_header ) = @_;
               if ( $col == 2 && !$is_header ) {
                   $value = format_price($value, 2, '');
               }
               else {
                   $value = latex_encode($value);
               }
               return $value;
           },
       }
   );

=item C<coldef>

The table column definition, e.g. C<lrcr> which would result in:

  \begin{tabular}{lrcr}
  ..

If unset, C<LaTeX::Table> tries to 
guess a good definition. Columns containing only numbers are right-justified,
others left-justified. Columns with cells longer than 30 characters are
I<paragraph> columns of size 5 cm. These rules can be changed with
set_coldef_strategy(). Default is 0 (guess good definition).

=item C<coldef_strategy>

Controls the behaviour of the C<coldef> calculation when get_coldef()
does not return a true value. Is a reference to a hash with following keys:

=over

=item C<IS_A_NUMBER =E<gt> $regex>

Defines a column as I<NUMBER> when B<all> cells in this column match the
specified regular expression. Default is
C<qr{\A([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z}xms>.

=item C<IS_LONG =E<gt> $n>

Defines a column as I<LONG> when B<one> cell is equal or larger than C<$n> 
characters (default 30).

=item C<NUMBER_COL =E<gt> $attribute>, C<NUMBER_COL_X =E<gt> $attribute>

The C<coldef> attribute for I<NUMBER> columns. Default 'r' (right-justified).

=item C<LONG_COL =E<gt> $attribute>, C<LONG_COL_X =E<gt> $attribute>

The C<coldef> attribute for I<LONG> columns. Default 'p{5cm}' (paragraph
column with text vertically aligned at the top, width 5cm) and 'X' when the
C<tabularx> package is used.

=item C<DEFAULT =E<gt> $attribute>, C<DEFAULT_X =E<gt> $attribute>

The C<coldef> attribute for columns that are neither I<NUMBER> nor I<LONG>.
Default 'l' (left-justified).

=back

Example:

  $table->set_coldef_strategy({
    IS_A_NUMBER => qr{\A \d+ \z}xms, # integers only
    IS_LONG     => 60, # min. 60 characters
    LONG_COL    => 'm{7cm}', # vertically aligned at the middle, 7cm
  });

=item C<resizebox>

If get_resizebox() returns a true value, then the resizebox command is used to
resize the table. Takes as argument a reference to an array. The first element
is the desired witdth. If a second element is not given, then the hight is set to
a value so that the aspect ratio is still the same. Requires the C<graphicx>
LaTeX package. Default 0.

  $table->set_resizebox([ '0.6\textwidth' ]);

  $table->set_resizebox([ '300pt', '200pt' ]);

=item C<width>

If get_width() returns a true value, then
C<{tabular*}{width}{@{\extracolsep{\fill}} ... }> (or
C<{xtabular*}{width}{ ... }>, respectively) is used.
For tables of type 'std', you can also use the C<tabularx> LaTeX package (see below).

  # use 75% of textwidth 
  $table->set_width('0.75\textwidth');
  
  # or 300 points (1/72 inch)
  $table->set_width('300pt');

=item C<width_environment>

If get_width() (see above) returns a true value and table is of type std, then
this option specifies whether C<tabular*> or the C<tabularx> package should be
used. The latter is great when you have long columns because C<tabularx> tries
to optimize the column widths. Default is 'tabular*'.

=back

=head2 MULTIPAGE TABLES

=over

=item C<tabletailmsg>

Message at the end of a multipage table. 
Default is I<Continued on next page>. 

=item C<tabletail>

Custom table tail. 
Default is multicolumn with the tabletailmsg (see above) right-justified. 

=item C<xentrystretch>

Option for xtab. Play with this option if the number of rows per page is not 
optimal. Requires a number as parameter. Default is 0 (does not use this option).

    $table->set_xentrystretch(-0.1);

=back

=head2 THEMES

=over

=item C<theme>

The name of the theme. Default is I<Zurich>.

=item C<predef_themes>

All predefined themes. Getter only.

=item C<custom_themes>

All custom themes. See L<"CUSTOM THEMES">.

=item C<columns_like_header>

Takes as argument a reference to an array with column ids (again, starting
with 0). These columns are formatted like header columns.

   # a "transposed" table ...
   my $table = LaTeX::Table->new(
       {   data     => $data,
           columns_like_header => [ 0 ],
       };

=back

=head1 MULTICOLUMNS 

Multicolumns are defined in LaTeX with
C<\multicolumn{$cols}{$alignment}{$text}>. This module supports a simple 
shortcut of the format C<$text:$cols$alignment>. For example, C<Item:2c> is 
equivalent to C<\multicolumn{2}{c}{Item}>. Note that vertical lines (C<|>) are
automatically added here according the LINES settings in the theme. 
See L<"CUSTOM THEMES">. C<LaTeX::Table> also uses this shortcut to determine
the column ids. So in this example,

 my $data = [ [' \multicolumn{2}{c}{A}', 'B' ], [ 'C:2c', 'D' ] ];

'B' would have an column id of 1 and 'D' 2 ('A' and 'C' both 0). This is important 
for callback functions and for the coldef calculation. 
See L<"TABULAR ENVIRONMENT">.

=head1 THEMES

The theme can be selected with C<$table-E<gt>set_theme($themename)>. 
Currently, following predefined themes are available: I<Zurich>, I<plain> (no
formatting), I<NYC> (for presentations), I<Dresden>, I<Berlin>, I<Miami> and 
I<Houston>. The script F<generate_examples.pl> in the I<examples> directory of
this distributions generates some examples for all available themes.

The default theme, Zurich, is highly recommended. It requires 
C<\usepackage{booktabs}> in your LaTeX document. The top and bottom lines are 
slightly heavier (ie thicker, or darker) than the other lines. No vertical 
lines. You want this. Believe it.

=head2 CUSTOM THEMES

Custom themes can be defined with an array reference containing all options
(explained later):

    # a very ugly theme...
    my $themes = { 
                'Leipzig' => {
                    'HEADER_FONT_STYLE'  => 'sc',
                    'HEADER_FONT_COLOR'  => 'white',
                    'HEADER_BG_COLOR'    => 'blue',
                    'HEADER_CENTERED'    => 1,
                    'DATA_BG_COLOR_ODD'  => 'blue!30',
                    'DATA_BG_COLOR_EVEN' => 'blue!10',
                    'CAPTION_FONT_STYLE' => 'sc',
                    'VERTICAL_LINES'     => [ 1, 2, 1 ],
                    'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
                    'BOOKTABS'           => 0,
                },
            };

    $table->set_custom_themes($themes);

=over 

=item Fonts

C<HEADER_FONT_STYLE>, C<CAPTION_FONT_STYLE>. Valid values are I<bf> (bold),
I<it> (italics), I<sc> (caps) and I<tt> (typewriter). When this option is
undef, then header (or caption, respectively) is written in normal font.

=item Colors

C<HEADER_FONT_COLOR> can be used to specify a different font color for the
header. Requires the C<color> LaTeX package.

Set C<HEADER_BG_COLOR> to use a background color in the header,
C<DATA_BG_COLOR_EVEN> and C<DATA_BG_COLOR_ODD> for even and odd data rows. 
Requires the C<colortbl> and the C<xcolor> LaTeX package. 

You can define colors with C<DEFINE_COLORS>, for example:

 'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',

=item Lines

C<VERTICAL_LINES>, C<HORIZONTAL_LINES>. A reference to an array with three
integers, e.g. C<[ 1, 2, 0 ]>. The first integer defines the number of outer
lines. The second the number of lines after the header and after the first
column. The third is the number of inner lines. For example L<"DRESDEN"> is
defined as:

            'Dresden' => {
                ...  
                'VERTICAL_LINES'     => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
            }

The first integers define one outer line - vertical and horizontal. So a box 
is drawn around the table. The second integers define two lines between header
and table and two vertical lines between first and second column. And finally
the third integers define that columns are separated by a single vertical line
whereas rows are not separated by horizontal lines.
            
=item Misc

=over 

=item C<HEADER_CENTERED>

Valid values are 0 (not centered) or 1 (centered).

=item C<BOOKTABS>

Use the Booktabs package for "Publication quality tables". Instead of
C<\hline>, C<LaTeX::Table> then uses C<\toprule>, C<\midrule> and C<\bottomrule>. 
0 (don't use this package) or 1 (use it).

=back

=back

=head1 EXAMPLES

See I<examples/examples.pdf> in this distribution for examples for most of the
features of this module. This document was generated with
I<examples/generate_examples.pl>.

=head1 DIAGNOSTICS

If you get a LaTeX error message, please check whether you have included all
required packages. The packages we use are C<booktabs>, C<color>, C<colortbl>,
C<graphicx>, C<rotating>, C<tabularx>, C<xcolor> and C<xtab>. 

C<LaTeX::Table> may throw one of these errors:

=over

=item C<callback> is not a code reference 

The return value of get_callback() is not a code reference. See 
L<"TABULAR ENVIRONMENT">.

=item C<columns_like_header> is not an array reference 

The return value of get_columns_like_header() is not an array reference.
See L<"THEMES">.

=item C<data/header> is not an array reference 

get_data() (or get_header(), respectively) does not return a 
reference to an array. See L<"BASIC OPTIONS">.

=item C<data[$i]/header[$i]> is not an array reference

The ith element of get_data() (or get_header()) is not an array reference. See
L<"BASIC OPTIONS">.

=item C<data[$i][$j]/header[$i][$j]> is not a scalar

The jth column in the ith row is not a scalar. See L<"BASIC OPTIONS">.

=item DEPRECATED. ...  

There were some minor API changes in C<LaTeX::Table> 0.1.0 and 0.8.0.  Just
apply the changes to the script and/or contact its author.

=item Family not known: ... . Valid families are: ...

You have set a font family to an invalid value. See L<"CUSTOM THEMES">.

=item Size not known: ... . Valid sizes are: ...

You have set a font size to an invalid value. See L<"CUSTOM THEMES">.

=item C<coldef_strategy> not a hash reference.

The return value of get_coldef_strategy() is not a hash reference. See 
L<"TABULAR ENVIRONMENT">.

=item C<resizebox> is not an array reference

The return value of get_resizebox() is not a reference to an array. See 
L<"TABULAR ENVIRONMENT">.

=item Theme not known: ...

You have set the option C<theme> to an invalid value. See L<"THEMES">.

=item Undefined value in C<data[$i][$j]/header[$i][$j]>

The value in this cell is C<undef>. See L<"BASIC OPTIONS">.

=item Width not known: ...

You have set option C<width_environment> to an invalid value. See 
L<"TABULAR ENVIRONMENT">.

=item width_environment is C<tabularx> and C<width> is unset.

You have to specify a width when using the tabularx package. See
L<"TABULAR ENVIRONMENT">.

=item C<xentrystretch> not a number

You have set the option C<xentrystretch> to an invalid value. This option
requires a number. See L<"MULTIPAGE TABLES">.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<LaTeX::Table> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<Class::Std>, L<English>,
L<Fatal>, L<Readonly>, L<Scalar::Util>, L<Text::Wrap>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported. 

Please report any bugs or feature requests to
C<bug-latex-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head1 SEE ALSO

L<Data::Table>, L<LaTeX::Encode>

=head1 CREDITS

Andrew Ford (ANDREWF): many great suggestions.

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2008, Markus Riester C<< <mriester@gmx.de> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
