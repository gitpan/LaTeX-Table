#############################################################################
#   $Author: markus $
#     $Date: 2007-11-07 14:51:34 +0100 (Wed, 07 Nov 2007) $
# $Revision: 31 $
#############################################################################

package LaTeX::Table;

use warnings;
use strict;

use version; our $VERSION = qv('0.6.0');

use Carp;
use Fatal qw( open close );
use Scalar::Util qw(reftype);
use English qw( -no_match_vars );

use Text::Wrap qw(wrap);

use Class::Std;
{

    my %filename : ATTR( :name<filename> :default('latextable.tex') );
    my %label : ATTR( :name<label> :default(0) );
    my %type : ATTR( :name<type> :default('std') );
    my %maincaption : ATTR( :name<maincaption> :default(0) );
    my %header : ATTR( :name<header> :default(0));
    my %data : ATTR( :name<data> :default(0) );
    my %table_environment : ATTR( :name<table_environment> :default(1) );
    my %caption : ATTR( :name<caption> :default(0) );
    my %tabledef : ATTR( :name<tabledef> :default(0) );
    my %tabledef_strategy : ATTR( :name<tabledef_strategy> :default(0) );
    my %theme : ATTR( :name<theme> :default('Zurich') );
    my %predef_themes : ATTR( :get<predef_themes> );
    my %custom_themes : ATTR( :name<custom_themes> :default(0) );
    my %text_wrap : ATTR( :name<text_wrap> :default(0) );
    my %width : ATTR( :name<width> :default(0) );
    my %tablepos : ATTR( :name<tablepos> :default(0) );
    my %center : ATTR( :name<center> :default(1) );
    my %size : ATTR( :name<size> :default(0) );
    my %callback : ATTR( :name<callback> :default(0) );
    my %tabletailmsg :
        ATTR( :name<tabletailmsg> :default('Continued on next page') );
    my %tabletail : ATTR( :name<tabletail> :default(0) );
    my %xentrystretch : ATTR( :name<xentrystretch> :default(0) );

    sub _compatibility_layer {
        my ( $self, @args ) = @_;
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
    # Usage      : $table->generate_string(\@header, \@data);
    # Purpose    : generates LaTex data
    # Returns    : code
    # Parameters : data columns
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub generate_string {
        my ( $self, @args ) = @_;

        # support for < 0.1.0 API
        $self->_compatibility_layer(@args);

        # check header and data
        $self->_check_2d_array( $self->get_header, 'header' );
        $self->_check_2d_array( $self->get_data,   'data' );

        my $code = q{};
        $code = $self->_header( $self->get_header, $self->get_data );

        my $theme = $self->_get_theme_settings;
        my $i     = 0;
        my @data  = $self->_examine_data;
    ROW:
        for my $row (@data) {
            $i++;
            if ( !@{$row} ) {
                $code .= "\\hline\n";
                next ROW;
            }
            else {
                $code .= join( q{&}, @{$row} ) . "\\\\ \n";
                if ( $i == scalar @data ) {
                    $code .= $self->_get_hline_code(3);
                }
                else {
                    $code .= $self->_get_hline_code(2);
                }
            }
        }
        $code .= $self->_footer();
        return $code;
    }

    sub _check_callback {
        my ($self) = @_;
        if ( reftype $self->get_callback ne 'CODE' ) {
            croak 'callback is not a code reference.';
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
        return;
    }

    sub _check_2d_array {
        my ( $self, $arr_ref_2d, $desc ) = @_;
        if ( !defined reftype $arr_ref_2d || reftype $arr_ref_2d ne 'ARRAY' )
        {
            croak "$desc is not an array reference.";
        }
        my $i = 0;
        for my $arr_ref ( @{$arr_ref_2d} ) {
            if ( !defined reftype $arr_ref || reftype $arr_ref ne 'ARRAY' ) {
                croak "$desc\[$i\] is not an array reference.";
            }
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

    sub _examine_data {
        my ($self)    = @_;
        my $text_wrap = $self->get_text_wrap;
        my @data      = @{ $self->get_data };
        if ( $self->get_callback ) {
            $self->_check_callback;
            for my $i ( 0 .. $#data ) {
                for my $j ( 0 .. ( scalar @{ $data[$i] } - 1 ) ) {
                    $data[$i][$j]
                        = &{ $self->get_callback }( $i, $j, $data[$i][$j],
                        0 );
                }
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
        print {$LATEX} $code;
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

        # if specified, use tabledef, otherwise guess a good definition
        my $table_def;
        if ( $self->get_tabledef ) {
            $table_def = $self->get_tabledef;
        }
        else {
            $table_def = $self->_get_tabledef_code($data);
        }

        my $pos  = $self->_get_tablepos_code() . "\n";
        my $code = $self->_get_header_columns_code($header);

        my $begin_center = q{};
        if ( $self->get_center ) {
            $begin_center = "\\begin{center}\n";
        }
        my $width = q{};
        my $asterisk = q{};
        if ( $self->get_width ) {
            $width = '{' . $self->get_width . '}';
            ## no critic
            $table_def = '@{\extracolsep{\fill}} ' . $table_def;
            ## use critic
            $asterisk = q{*};
        }
        my $size    = $self->_get_size_code();
        my $caption = $self->_get_caption_code();
        my $label   = $self->_get_label_code;

        my $tabletail     = $self->_get_tabletail_code( $data, 0 );
        my $tabletaillast = $self->_get_tabletail_code( $data, 1 );

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
$size$caption$xentrystretch$label
\\tablehead{$code}
$tabletail
$tabletaillast
$begin_center\\begin{xtabular$asterisk}${width}{$table_def}
EOXT
        }
        else {
            my $table_environment = q{};
            if ( $self->get_table_environment ) {
                $table_environment = join q{}, "\\begin{table}$pos", $size,
                    $begin_center;
            }
            return <<"EOST"
$table_environment\\begin{tabular$asterisk}${width}{$table_def}
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
        my $caption = $self->_get_caption_code();
        my $end_center   = q{};
        if ( $self->get_center ) {
            $end_center = "\\end{center}\n";
        }
        my $asterisk = q{};
        if ( $self->get_width ) {
            $asterisk = q{*};
        }
        if ( $self->get_type eq 'xtab' ) {
            return <<"EOXT"
\\end{xtabular$asterisk}
$end_center} 
EOXT
        }
        else {
            my $table_environment = q{};
            if ( $self->get_table_environment ) {
                $table_environment = join q{}, $caption, $label, $end_center,
                    "\\end{table}";

            }
            return <<"EOST"
\\end{tabular$asterisk}
$table_environment
EOST
                ;
        }
    }

    sub _default_tabledef_strategy {
        my ($self) = @_;
        my $STRATEGY = {
            #IS_A_NUMBER => $RE{num}{real},
            IS_A_NUMBER =>
                qr{\A([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z}xms,
            IS_LONG     => 50,
            NUMBER_COL  => 'r',
            LONG_COL    => 'p{5cm}',
            DEFAULT     => 'l',
        };
        $self->set_tabledef_strategy($STRATEGY);
        return $STRATEGY;
    }

    sub _check_tabledef_strategy {
        my ( $self , $strategy ) = @_;
        my $rt_strategy = reftype $strategy;
        if (!defined $rt_strategy || $rt_strategy ne 'HASH') {
            croak 'tabledef_strategy not a hash reference.';
        }
        my $default = $self->_default_tabledef_strategy;
        for my $key (keys %{$default}) {
            if (!defined $strategy->{$key}) {
                $strategy->{$key} = $default->{$key};
            }
        }
        $self->set_tabledef_strategy($strategy);
        return;
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
        my $strategy = $self->get_tabledef_strategy;
        if ( !$strategy ) {
            $strategy = $self->_default_tabledef_strategy;
        } else {
            $self->_check_tabledef_strategy($strategy);
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
                $i++;
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
        if ($id == 3) {
            $id = 0;
        }
        return "\\$line\n" x $hlines->[$id];
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
        $code .= $self->_get_hline_code(0);

        my $i = 0;

        if ( $self->get_callback ) {
            $self->_check_callback;
        }

        foreach my $row ( @{$header} ) {
            my @cols = @{$row};

            if ( defined $theme->{'HEADER_CENTERED'}
                && $theme->{'HEADER_CENTERED'} )
            {
                my $vlines = $theme->{'VERTICAL_LINES'};

                my $v0 = q{|} x $vlines->[0];
                my $v1 = q{|} x $vlines->[1];
                my $v2 = q{|} x $vlines->[2];

                my $j = 0;
                foreach my $col (@cols) {
                    my $align;
                    if ( $self->get_callback ) {
                        $col = &{ $self->get_callback }( $i, $j, $col, 1 );
                    }
                    if ( $j == 0 ) {
                        $align = $v0 . 'c' . $v1;
                    }
                    elsif ( $j == ( scalar(@cols) - 1 ) ) {
                        $align = 'c' . $v0;
                    }
                    else {
                        $align = 'c' . $v2;
                    }
                    $col = $self->_add_mc_def(
                        { value => $col, align => $align, cols => '1' } );
                    $j++;
                }
            }

            if ( defined $theme->{'HEADER_FONT_STYLE'} ) {
                foreach my $col (@cols) {
                    $col = $self->_add_font_family( $col,
                        $theme->{'HEADER_FONT_STYLE'} );
                }
            }

            $code .= $self->_get_row_code(@cols);
            $i++;
        }
        $code .= $self->_get_hline_code(1);
        return $code;
    }

    ###########################################################################
    # Usage      : $self->_get_row_code(@cols);
    # Purpose    : generate the LaTeX code of a row
    # Returns    : LaTeX code
    # Parameters : the columns
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub _get_row_code {
        my ( $self, @cols ) = @_;
        my @cols_defs = map { $self->_get_mc_def($_) } @cols;
        @cols = ();
        foreach my $col_def (@cols_defs) {
            if ( defined $col_def->{cols} ) {
                push @cols,
                    '\\multicolumn{'
                    . $col_def->{cols} . '}{'
                    . $col_def->{align} . '}{'
                    . $col_def->{value} . '}';
            }
            else {
                push @cols, $col_def->{value};
            }
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
        if ( $value =~ m{ \A (.*)\:(\d)([|clr]+) \z }xms ) {
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
    # Throws     : exception when familiy is not known
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

    ###########################################################################
    # Usage      : $self->_get_tabledef_code(\@data);
    # Purpose    : generate the LaTeX code of the table definition (e.g.
    #              |l|r|r|r|)
    # Returns    : LaTeX code
    # Parameters : the data columns
    # Throws     :
    # Comments   : Tries to be intelligent. Hope it is ;)
    # See also   :

    sub _get_tabledef_code {
        my ( $self, $data ) = @_;
        my @cols   = $self->_get_data_summary($data);
        my $vlines = $self->_get_theme_settings->{'VERTICAL_LINES'};

        my $v0 = q{|} x $vlines->[0];
        my $v1 = q{|} x $vlines->[1];
        my $v2 = q{|} x $vlines->[2];

        my $table_def = q{};
        my $i         = 0;
        my $strategy  = $self->get_tabledef_strategy();

        foreach my $col (@cols) {

            # align text right, numbers left, first col always left
            my $align = $strategy->{DEFAULT};
            if ( $col == 1 ) {
                $align = $strategy->{NUMBER_COL};
            }
            elsif ( $col == 2 ) {
                $align = $strategy->{LONG_COL};
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
        my $linecode .= "\\hline\n" x $hlines->[0];

        # if custom table tail is defined, then return it
        if ( $self->get_tabletail ) {
            $code = $self->get_tabletail;
        }
        elsif (!$final_tabletail) {
            my @cols    = $self->_get_data_summary($data);
            my $nu_cols = scalar @cols;

            my $v0 = q{|} x $vlines->[0];
            $code = "$linecode\\multicolumn{$nu_cols}{${v0}r$v0}{{" .
                $self->get_tabletailmsg. "}} \\\\ \n";
        }
        if ($final_tabletail) {
            return "\\tablelasttail{$linecode}";
        }
        return "\\tabletail{$code$linecode}";
    }

    ###########################################################################
    # Usage      : $self->_get_caption_code();
    # Purpose    : generates the LaTeX code of the caption
    # Returns    : LaTeX code
    # Parameters : none
    # Throws     :
    # Comments   : n/a
    # See also   :

    sub _get_caption_code {
        my ($self)    = @_;
        my $f_caption = q{};
        my $s_caption = q{};
        my $theme     = $self->_get_theme_settings;

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
        my $c_caption = 'caption';

        if ( $self->get_type eq 'xtab' ) {
            $c_caption = 'bottomcaption';
        }

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
    # Usage      : $self->_get_tablepos_code();
    # Purpose    : generates the LaTeX code of the table position (e.g. [htb])
    # Returns    : LaTeX code
    # Parameters : none

    sub _get_tablepos_code {
        my ($self) = @_;
        if ( $self->get_tablepos ) {
            return '[' . $self->get_tablepos . ']';
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
            'Zurich' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'CAPTION_FONT_STYLE' => 'bf',
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

This document describes LaTeX::Table version 0.6.0

=head1 SYNOPSIS

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
  $table->generate();

  # callback functions
  $table->set_callback(sub { 
       my ($row, $col, $value, $is_header ) = @_;
       if ($col == 1) {
           $value = uc $value;
       }
       return $value;
  });     

Now in your LaTeX document:

    \documentclass{article}

    % for multipage tables
    \usepackage{xtab}
    % for publication quality tables
    \usepackage{booktabs}

    \begin{document}
    \input{counter}
    \end{document}
  
=head1 DESCRIPTION

LaTeX::Table provides functionality for an intuitive and easy generation of
LaTeX tables for reports or theses. It ships with some predefined good looking
table styles. Supports multipage tables via the xtab package. 

=head1 INTERFACE 

=over

=item C<my $table = LaTeX::Table-E<gt>new($arg_ref)>

Constructs a LaTeX::Table object. The parameter is an hash reference with
options (see below).

=item C<$table-E<gt>generate()>

Generates the LaTeX table code. The generated LaTeX table can be included in
a LaTeX document with the C<\input> command:
  
  % include counter.tex, generated by LaTeX::Table 
  \input{counter}

=item C<$table-E<gt>generate_string()>

Same as generate() but does not create a LaTeX file but returns the LaTeX code
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

The name of the LaTeX output file. Default is
'latextable.tex'.

=item C<type>

Can be either I<std> for the standard LaTeX table or I<xtab> for
a xtabular table for multipage tables. The later requires the C<xtab>
latex-package (C<\usepackage{xtab}> in your LaTeX document). Default is 
I<std>.

=item C<header>

The header. It is a reference to an array (the rows) of array references (the
columns).

  $table->set_header([ [ 'Name', 'Beers' ] ]);

will produce following header:

  +------+-------+
  | Name | Beers |
  +------+-------+

Here an example for a multirow header:

  $table->set_header([ [ 'Name', 'Beers' ], ['', '(roughly)' ] ]);

This code will produce this header:

  +------+-----------+
  | Name |   Beers   |
  |      | (roughly) |
  +------+-----------+

=item C<data>

The data. Once again a reference to an array (rows) of array references
(columns). 

  $table->set_data([ [ 'Marge', '1' ], [ 'Homer', '4' ] ]);

And you will get a table like this:

 +-------+---------+
 | Marge |       1 |
 | Homer |       4 |
 +-------+---------+

An empty column array will produce a horizontal line:

  $table->set_data([ [ 'Marge', '1' ], [], [ 'Homer', '4' ] ]);

And you will get a table like this:

 +-------+---------+
 | Marge |       1 |
 +-------+---------+
 | Homer |       4 |
 +-------+---------+

=back

=head2 TABLE ENVIRONMENT

=over

=item C<table_environment>

If 1, then a table environment will be generated. Default 1. This option only
affects tables of C<type> I<std>.

    \begin{table}[htb]
        \center
        \begin{tabular}{|l||r|r|}
        ...
        \end{tabular}
        \caption{Number of beers}
        \label{table_beercounter}
    \end{table} 

=item C<caption>

The caption of the table. Only generated if get_caption() returns a true value. 
Default is 0. Requires C<table_environment>.

=item C<center>

Defines whether the table is centered. Default 1 (centered). Requires 
C<table_environment>.

=item C<label>

The label of the table. Only generated if get_label() returns a true value.
In Latex you can create a reference to the table with C<\ref{label}>.
Default is 0. Requires C<table_environment>.

=item C<maincaption>

If get_maincaption() returns a true value, then this value will be displayed 
in the Table Listing (C<\listoftables>) and before the C<caption>. Default
0. Requires C<table_environment>.

=item C<size>

Font size. Valid values are 'tiny', 'scriptsize', 'footnotesize', 'small',
'normal', 'large', 'Large', 'LARGE', 'huge', 'Huge' and 0. Default is 0 
(does not define a font size). Requires C<table_environment>.

=item C<tablepos>

The position of the table, e.g. C<htb>. Only generated if get_tablepos()
returns a true value. Requires C<table_environment>.

=back

=head2 TABULAR ENVIRONMENT

=over 

=item C<callback>

If get_callback() returns a true value and the return value is a code reference,
then this callback function will be called for every column. The passed
arguments are C<$row>, C<$col> (both starting with 0), C<$value> and 
C<$is_header>.

   use LaTeX::Encode;
   ...
   
   # use LaTeX::Encode to encode LaTeX special characters,
   # lowercase the third column (only the data)
   my $table = LaTeX::Table->new(
       {   header   => $header,
           data     => $data,
           callback => sub {
               my ( $row, $col, $value, $is_header ) = @_;
               if ( $col == 2 && !$is_header ) {
                   $value = lc $value;
               }
               return latex_encode($value);
           },
       }
   );

=item C<tabledef>

The table definition, e.g. C<|l|r|c|r|>. If unset, C<LaTeX::Table> tries to 
guess a good definition. Columns containing only numbers are right-justified,
others left-justified. Columns with cells longer than 50 characters are
I<paragraph> columns of size 5 cm. These rules can be changed with
set_tabledef_strategy(). Default is 0 (guess good definition).

=item C<tabledef_strategy>

Controls the behaviour of the C<tabledef> calculation when get_tabledef()
does not return a true value. Is a reference to a hash with following keys:

=over

=item IS_A_NUMBER =E<gt> $regex

Defines a column as I<NUMBER> when B<all> cells in this column match the
specified regular expression. Default is
C<qr{\A([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z}xms>.

=item IS_LONG =E<gt> $n

Defines a column as I<LONG> when B<one> cell is equal or larger than C<$n> 
characters (default 50).

=item NUMBER_COL =E<gt> $attribute

The C<tabledef> attribute for I<NUMBER> columns. Default 'r' (right-justified).

=item LONG_COL =E<gt> $attribute

The C<tabledef> attribute for I<LONG> columns. Default 'p{5cm}' (paragraph
column with text vertically aligned at the top, width 5cm). Note that this
requires that get_text_wrap() returns 0.

=item DEFAULT =E<gt> $attribute

The C<tabledef> attribute for columns that are neither I<NUMBER> nor I<LONG>.
Default 'l' (left-justified).

=back

Example:

  $table->set_tabledef_strategy({
    IS_A_NUMBER => qr{\A \d+ \z}xms, # integers only;
    IS_LONG     => 60, # min. 60 characters
    LONG_COL    => 'm{7cm}', # vertically aligned at the middle, 7cm
  });

=item C<text_wrap>

If get_text_wrap() returns a true value and if the return value is a reference
to an array of integer values, then L<Text::Wrap> is used to wrap the column
after the specified number of characters. More precisely, L<Text::Wrap>
ensures that no column will have a length longer than C<$characters - 1>.

  # wrap first and last column after 10 characters, second column after 60
  $table->set_text_wrap([ 10, 60, 10 ]);

Be aware that C<text_wrap> wraps the content of the columns and does not try 
to filter out LaTeX commands - thus your formatted LaTeX document may display
less characters than desired. It also turns off the automatic I<p> attribute
in the table definition.  

=item C<width>

If get_width() returns a true value, then
C<{tabular*}{width}{@{\extracolsep{\fill}} ... }> (or
C<{xtabular*}{width}{ ... }>, respectively) is used.

  # use 75% of textwidth 
  $table->set_width('0.75\textwidth');

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

=back

=head1 MULTICOLUMNS 

Multicolumns can be defined in LaTeX with
C<\multicolumn{#cols}{definition}{text}>. Because multicolumns are often 
needed and this is way too much code to type, a shortcut was implemented. Now,
C<text:#colsdefinition> is equivalent to original LaTeX code. For example,
C<Beers:2|c|> is equivalent to C<\multicolumn{2}{|c|}{Beers}>. Note that 
C<|c|> overrides the LINES settings in the theme (See L<"CUSTOM THEMES">).

=head1 THEMES

The theme can be selected with $table->set_theme($themename). Currently,
following predefined themes are available: I<Zurich>, I<Dresden>, I<Berlin>, I<Miami> and
I<Houston>. The script F<generate_examples.pl> in the I<examples> directory 
of this distributions generates some examples for all available themes.

=head2 ZURICH

The default theme. Requires C<\usepackage{booktabs}> in your LaTeX document.
The top and bottom lines are slightly heavier (ie thicker, or darker) than the
other lines. No vertical lines.

  ------------------------
    Name     Beer   Wine  
  ------------------------
    Marge       1      0  
    Homer       4      0  
  ------------------------

=head2 DRESDEN

Nice and clean, with a centered header written in bold text. Header
and first column are separated by a double line.

  +-------++------+------+
  | Name  || Beer | Wine |
  +-------++------+------+
  +-------++------+------+
  | Marge ||    1 |    0 |
  | Homer ||    4 |    0 |
  +-------++------+------+

=head2 BERLIN

First column separated by only one line.

  +-------+------+------+
  | Name  | Beer | Wine |
  +-------+------+------+
  +-------+------+------+
  | Marge |    1 |    0 |
  | Homer |    4 |    0 |
  +-------+------+------+
 
=head2 HOUSTON

Very similar to I<Dresden>, but columns are separated (one inner line).

  +-------++------+------+
  | Name  || Beer | Wine |
  +-------++------+------+
  +-------++------+------+
  | Marge ||    1 |    0 |
  +-------++------+------+
  | Homer ||    4 |    0 |
  +-------++------+------+

=head2 MIAMI

A very simple theme. Header once again written in bold text.

    Name    Beer   Wine
  -----------------------
    Marge      1      0
    Homer      4      0


=head2 CUSTOM THEMES

Custom themes can be defined with an array reference containing all options
(explained later):

    my $themes = { 
                'Leipzig' => {
                    'HEADER_FONT_STYLE'  => 'sc',
                    'HEADER_CENTERED'    => 1,
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
I<it> (italics), I<sc> (caps) and I<tt> (typewriter).

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

Use the Booktabs package for "Publication quality tables". 0 (don't use this
package) or 1 (use it).

=back

=back

=head1 DIAGNOSTICS

=over

=item callback is not a code reference 

The return value of get_callback() is not a code reference. See 
L<"TABULAR ENVIRONMENT">.

=item data/header is not an array reference 

get_data() (or get_header(), respectively) does not return a 
reference to an array. See L<"BASIC OPTIONS">.

=item data[$i]/header[$i] is not an array reference

The ith element of get_data() (or get_header()) is not an array reference. See L<"BASIC OPTIONS">.


=item data[$i][$j]/header[$i][$j] is not a scalar

The jth column in the ith row is not a scalar. See L<"BASIC OPTIONS">.


=item DEPRECATED. Use options header and data instead.

You have called either generate() or generate_string() with header and data as
parameters. This is deprecated since C<LaTeX::Table> 0.1.0.  See L<"BASIC OPTIONS">.


=item Family not known: ... . Valid families are: ...

You have set a font family to an invalid value. See L<"CUSTOM THEMES">.

=item Size not known: ... . Valid sizes are: ...

You have set a font size to an invalid value. See L<"CUSTOM THEMES">.

=item tabledef_strategy not a hash reference.

The return value of get_tabledef_strategy() is not a hash reference. See 
L<"TABULAR ENVIRONMENT">.

=item text_wrap is not an array reference

The return value of get_text_wrap() is not an array reference. See
L<"TABULAR ENVIRONMENT">.

=item Theme not known: ...

You have set the option C<theme> to an invalid value. See L<"THEMES">.

=item Undefined value in data[$i][$j]/header[$i][$j]

The value in this cell is C<undef>. See L<"BASIC OPTIONS">.

=item Value in text_wrap not an integer: ...

All values in the text_wrap array reference must either be C<undef> or must 
match the regular expression C<m{\A \d+ \z}xms>. See 
L<"TABULAR ENVIRONMENT">.


=item xentrystretch not a number

You have set the option C<xentrystretch> to an invalid value. This option
requires a number. See L<"MULTIPAGE TABLES">.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<LaTeX::Table> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<Class::Std>, L<English>,
L<Fatal>, L<Scalar::Util>, L<Text::Wrap>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported. 

Please report any bugs or feature requests to
C<bug-latex-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head1 SEE ALSO

L<Data::Table>, L<LaTeX::Encode>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2007, Markus Riester C<< <mriester@gmx.de> >>. 
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
