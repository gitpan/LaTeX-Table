#############################################################################
#   $Author: markus $
#     $Date: 2009-02-04 11:52:54 +0100 (Wed, 04 Feb 2009) $
# $Revision: 1304 $
#############################################################################

package LaTeX::Table;

use strict;
use warnings;

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;

use version; our $VERSION = qv('0.9.13');

use LaTeX::Table::Types::Std;
use LaTeX::Table::Types::Xtab;
use LaTeX::Table::Types::Ctable;

use Carp;
use Scalar::Util qw(reftype);
use English qw( -no_match_vars );

use Module::Pluggable
    search_path => 'LaTeX::Table::Themes',
    sub_name    => 'themes',
    except      => 'LaTeX::Table::Themes::ThemeI',
    instantiate => 'new';

use Text::Wrap qw(wrap);

for my $attr (
    qw(label maincaption shortcaption caption caption_top coldef coldef_strategy
    columns_like_header continued text_wrap header_sideways width maxwidth width_environment
    custom_tabular_environment position fontsize fontfamily callback tabletail xentrystretch
    resizebox sideways star _data_summary)
    )
{
    has $attr => ( is => 'rw', default => 0 );
}

has 'custom_template' => ( is => 'rw', isa => 'Str', default => 0 );
has 'filename'  => ( is => 'rw', isa => 'Str', default => 'latextable.tex' );
has 'foottable' => ( is => 'rw', isa => 'Str', default => q{} );
has 'type' => ( is => 'rw', default => 'std' );
has '_type_obj' => ( is => 'rw' );
has 'header' => ( is => 'rw', default => sub { [] } );
has 'data'   => ( is => 'rw', default => sub { [] } );
has 'environment'   => ( is => 'rw', default => 1 );
has 'theme'         => ( is => 'rw', default => 'Zurich' );
has 'predef_themes' => ( is => 'rw', default => sub { {} } );
has 'custom_themes' => ( is => 'rw', default => sub { {} } );

for my $attr (qw(center left right _default_align)) {
    has $attr => ( is => 'rw', isa => 'Bool', predicate => "has_$attr" );
}

has 'continuedmsg' => ( is => 'rw', default => '(continued)' );
has 'tabletailmsg' => ( is => 'rw', default => 'Continued on next page' );
has 'tableheadmsg' =>
    ( is => 'rw', default => 'Continued from previous page' );

# deprecated
has 'table_environment' => ( is => 'rw', default => 'deprecated' );
has 'tabledef'          => ( is => 'rw', default => 'deprecated' );
has 'tabledef_strategy' => ( is => 'rw', default => 'deprecated' );
has 'tablepos'          => ( is => 'rw', default => 'deprecated' );
has 'size'              => ( is => 'rw', default => 'deprecated' );

__PACKAGE__->meta->make_immutable;

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

    # support for < 0.9.3 API
    $self->_compatibility_layer(@args);

    # are the user provided options ok?
    $self->_check_options();

    # analyze the data
    $self->_calc_data_summary( $self->get_data );

    if ( $self->get_type eq 'xtab' ) {
        $self->set__type_obj(
            LaTeX::Table::Types::Xtab->new( _table_obj => $self ) );
    }
    elsif ( $self->get_type eq 'ctable' ) {
        $self->set__type_obj(
            LaTeX::Table::Types::Ctable->new( _table_obj => $self ) );
    }
    else {
        $self->set__type_obj(
            LaTeX::Table::Types::Std->new( _table_obj => $self ) );
    }

    my $code = $self->get__type_obj->generate_latex_code( $self->get_header,
        $self->get_data );

    return $code;
}

sub _load_themes {
    my ($self) = @_;
    my %defs;

    for my $theme_obj ( $self->themes ) {
        %defs = ( %defs, %{ $theme_obj->_definition } );
    }
    $self->set_predef_themes( \%defs );
    return;
}

sub _compatibility_layer {
    my ( $self, @args ) = @_;
    if ( $self->get_tablepos ne 'deprecated' ) {
        carp('DEPRECATED: Use position instead of tablepos.');
        $self->set_position( $self->get_tablepos );
    }
    if ( $self->get_table_environment ne 'deprecated' ) {
        carp('DEPRECATED: Use environment instead of table_environment.');
        $self->set_environment( $self->get_table_environment );
    }
    if ( $self->get_tabledef ne 'deprecated' ) {
        carp('DEPRECATED: Use coldef instead of tabledef.');
        $self->set_coldef( $self->get_tabledef );
    }
    if ( $self->get_tabledef_strategy ne 'deprecated' ) {
        carp('DEPRECATED: Use coldef_strategy instead of tabledef_strategy.');
        $self->set_coldef_strategy( $self->get_tabledef_strategy );
    }
    if ( $self->get_size ne 'deprecated' ) {
        carp('DEPRECATED: size was renamed to fontsize.');
        $self->set_fontsize( $self->get_size );
    }
    my $cs = $self->get_coldef_strategy();

    if ( $cs && defined reftype $cs && reftype $cs eq 'HASH' ) {
        if ( defined $cs->{'DEFAULT'} ) {
            carp(     'DEPRECATED: DEFAULT in coldef_strategy was renamed to '
                    . 'DEFAULT_COL.' );
            $cs->{'DEFAULT_COL'} = $cs->{'DEFAULT'};
            delete $cs->{'DEFAULT'};
        }
        if ( defined $cs->{'DEFAULT_X'} ) {
            carp( 'DEPRECATED: DEFAULT_X in coldef_strategy was renamed to '
                    . 'DEFAULT_COL_X.' );
            $cs->{'DEFAULT_COL_X'} = $cs->{'DEFAULT_X'};
            delete $cs->{'DEFAULT_X'};
        }
        if ( defined $cs->{'IS_A_NUMBER'} ) {
            carp( 'DEPRECATED: IS_A_NUMBER in coldef_strategy was renamed to '
                    . 'NUMBER.' );
            $cs->{'NUMBER'} = $cs->{'IS_A_NUMBER'};
            delete $cs->{'IS_A_NUMBER'};
        }
        if ( defined $cs->{'IS_LONG'} ) {
            carp(     'DEPRECATED: IS_LONG in coldef_strategy was renamed to '
                    . 'LONG and is now a regex. Converting it.' );
            $cs->{'LONG'} = qr{\A \s* .{$cs->{'IS_LONG'},}? \s* \z}xms;
            delete $cs->{'IS_LONG'};
        }
        $self->set_coldef_strategy($cs);
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

sub _row_is_latex_command {
    my ( $self, $row ) = @_;
    if ( scalar( @{$row} ) == 1 && $row->[0] =~ m{\A \s* \\ }xms ) {
        return 1;
    }
    return 0;
}

sub invalid_option_usage {
    my ( $self, $option, $msg ) = @_;
    croak "Invalid usage of option $option: $msg.";
}

sub _check_options {
    my ($self) = @_;

    # default floating enviromnent is table
    if ( $self->get_environment eq '1' ) {
        $self->set_environment('table');
    }

    # check header and data
    $self->_check_2d_array( $self->get_header, 'header' );
    $self->_check_2d_array( $self->get_data,   'data' );

    if ( $self->get_callback && reftype $self->get_callback ne 'CODE' ) {
        $self->invalid_option_usage( 'callback', 'Not a code reference' );
    }
    if ( $self->get_columns_like_header ) {
        $self->_check_1d_array( $self->get_columns_like_header,
            q{}, 'columns_like_header' );
    }
    if ( $self->get_resizebox ) {
        $self->_check_1d_array( $self->get_resizebox, q{}, 'resizebox' );
    }
    if ( $self->get_type eq 'xtab' && !$self->get_environment ) {
        $self->invalid_option_usage( 'environment',
            'xtab requires an environment' );
    }
    if ( $self->get_type eq 'xtab' && $self->get_position ) {
        $self->invalid_option_usage( 'position',
            'xtab does not support position' );
    }

    # handle default values by ourselves
    if ( $self->get_width_environment eq 'tabular*' ) {
        $self->set_width_environment(0);
    }

    $self->_check_align;

    if ( $self->get_maincaption && $self->get_shortcaption ) {
        $self->invalid_option_usage( 'maincaption, shortcaption',
            'only one allowed.' );
    }
    if ( !$self->get_width && $self->get_width_environment eq 'tabularx' ) {
        $self->invalid_option_usage( 'width_environment',
            'Is tabularx and width is unset' );
    }
    if ( !$self->get_width && $self->get_width_environment eq 'tabulary' ) {
        $self->invalid_option_usage( 'width_environment',
            'Is tabulary and width is unset' );
    }
    return;
}

sub _check_align {
    my ($self)              = @_;
    my $cnt_def_alignments  = 0;
    my $cnt_true_alignments = 0;

    if ( $self->has_center ) {
        $cnt_def_alignments++;
    }
    if ( $self->has_right ) {
        $cnt_def_alignments++;
    }
    if ( $self->has_left ) {
        $cnt_def_alignments++;
    }
    if ( $self->get_center ) {
        $cnt_true_alignments++;
    }
    if ( $self->get_right ) {
        $cnt_true_alignments++;
    }
    if ( $self->get_left ) {
        $cnt_true_alignments++;
    }

    if ( $cnt_true_alignments > 1 ) {
        $self->invalid_option_usage( 'center, left, right',
            'only one allowed.' );
    }
    if ( $cnt_def_alignments == 0 ) {
        $self->set__default_align(1);
    }
    else {
        $self->set__default_align(0);
    }
    return;
}

sub _check_text_wrap {
    my ($self) = @_;
    if ( reftype $self->get_text_wrap ne 'ARRAY' ) {
        $self->invalid_option_usage( 'text_wrap', 'Not an array reference' );
    }
    for my $value ( @{ $self->get_text_wrap } ) {
        if ( defined $value && $value !~ m{\A \d+ \z}xms ) {
            $self->invalid_option_usage( 'text_wrap',
                'Not an integer: ' . $value );
        }
    }
    carp('DEPRECATED: use for example tabularx instead.');
    return;
}

sub _apply_callback {
    my ( $self, $i, $j, $value, $is_header ) = @_;
    my $col_cb = $self->_get_mc_def($value);
    $col_cb->{value}
        = &{ $self->get_callback }( $i, $j, $col_cb->{value}, $is_header );
    return $self->_get_mc_value($col_cb);
}

sub _examine_data {
    my ($self)    = @_;
    my $text_wrap = $self->get_text_wrap;
    my @data      = @{ $self->get_data };
    if ( $self->get_callback ) {
        for my $i ( 0 .. $#data ) {
            my @row = @{ $data[$i] };
            my $k   = 0;
            for my $j ( 0 .. ( scalar @{ $data[$i] } - 1 ) ) {
                $row[$j] = $self->_apply_callback( $i, $k, $data[$i][$j], 0 );
                $k += $self->_extract_number_columns( $data[$i][$j] );
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
                ## no critic (Variables::ProhibitPackageVars)
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

sub _ioerror {
    my ( $self, $function, $error ) = @_;
    croak "IO error: Can't $function '" . $self->get_filename . "': $error";
}

sub generate {
    my ( $self, $header, $data ) = @_;
    my $code = $self->generate_string( $header, $data );
    open my $LATEX, '>', $self->get_filename
        or $self->_ioerror( 'open', $OS_ERROR );
    print {$LATEX} $code
        or $self->_ioerror( 'write', $OS_ERROR );
    close $LATEX
        or $self->_ioerror( 'close', $OS_ERROR );
    return 1;
}

sub _default_coldef_strategy {
    my ($self) = @_;
    my $STRATEGY = {
        NUMBER =>
            qr{\A\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*\z}xms,
        NUMBER_MUST_MATCH_ALL => 1,
        LONG                  => qr{\A \s* (?=\w+\s+\w+).{29,}? \S}xms,
        LONG_MUST_MATCH_ALL   => 0,
        NUMBER_COL            => 'r',
        NUMBER_COL_X          => 'r',
        LONG_COL              => 'p{5cm}',
        LONG_COL_X            => 'X',
        LONG_COL_Y            => 'L',
        DEFAULT_COL           => 'l',
        DEFAULT_COL_X         => 'l',
    };
    $self->set_coldef_strategy($STRATEGY);
    return $STRATEGY;
}

sub _check_coldef_strategy {
    my ( $self, $strategy ) = @_;
    my $rt_strategy = reftype $strategy;
    if ( !defined $rt_strategy || $rt_strategy ne 'HASH' ) {
        $self->invalid_option_usage( 'coldef_strategy',
            'Not a hash reference' );
    }
    my $default = $self->_default_coldef_strategy;
    for my $key ( keys %{$default} ) {
        if ( !defined $strategy->{$key} ) {
            $strategy->{$key} = $default->{$key};
        }
    }

    $self->set_coldef_strategy($strategy);

    my @coltypes = $self->_get_coldef_types();
    for my $type (@coltypes) {
        if ( !defined $strategy->{"${type}_COL"} ) {
            $self->invalid_option_usage( 'coldef_strategy',
                "Missing column attribute ${type}_COL for $type" );
        }
        if ( !defined $strategy->{"${type}_MUST_MATCH_ALL"} ) {
            $strategy->{"${type}_MUST_MATCH_ALL"} = 1;
        }
    }
    return;
}

sub _extract_number_columns {
    my ( $self, $col ) = @_;
    my $def = $self->_get_mc_def($col);
    if ( defined $def->{cols} ) {
        return $def->{cols};
    }
    else {
        return 1;
    }
}

sub _get_coldef_types {
    my ($self) = @_;

    # everything that does not contain an underscore is a coltype
    my @coltypes =
        sort grep {m{ \A [^_]+ \z }xms} keys %{ $self->get_coldef_strategy };

    return @coltypes;
}

sub _get_data_summary {
    my ($self) = @_;
    return @{ $self->get__data_summary() };
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

sub _calc_data_summary {
    my ( $self, $data ) = @_;
    my $max_col_number = 0;
    my $strategy       = $self->get_coldef_strategy;
    if ( !$strategy ) {
        $strategy = $self->_default_coldef_strategy;
    }
    else {
        $self->_check_coldef_strategy($strategy);
    }
    my %matches;
    my %cells;

    my @coltypes = $self->_get_coldef_types();

ROW:
    for my $row ( @{$data} ) {
        if ( scalar @{$row} == 0 || $self->_row_is_latex_command($row) ) {
            next ROW;
        }
        if ( scalar @{$row} > $max_col_number ) {
            $max_col_number = scalar @{$row};
        }
        my $i = 0;
        for my $col ( @{$row} ) {
            for my $coltype (@coltypes) {
                if ( $col =~ $strategy->{$coltype} ) {
                    $matches{$i}{$coltype}++;
                }
            }
            $cells{$i}++;
            $i += $self->_extract_number_columns($col);
        }
    }
    my @summary;
    for my $i ( 0 .. $max_col_number - 1 ) {
        my $type_of_this_col = 'DEFAULT';
        for my $coltype (@coltypes) {
            if (defined $matches{$i}{$coltype}
                && ( !$strategy->{"${coltype}_MUST_MATCH_ALL"}
                    || $cells{$i} == $matches{$i}{$coltype} )
                )
            {
                $type_of_this_col = $coltype;
            }
        }
        push @summary, $type_of_this_col;
    }
    $self->set__data_summary( \@summary );
    return;
}

sub _apply_header_formatting {
    my ( $self, $col, $aligning ) = @_;
    my $theme = $self->get_theme_settings;
    if (   $aligning
        && defined $theme->{'HEADER_CENTERED'}
        && $theme->{'HEADER_CENTERED'} )
    {
        $col = $self->_add_mc_def(
            { value => $col, align => 'c', cols => '1' } );
    }
    if ( length $col ) {
        if ( defined $theme->{'HEADER_FONT_STYLE'} ) {
            $col = $self->_add_font_family( $col,
                $theme->{'HEADER_FONT_STYLE'} );
        }
        if ( defined $theme->{'HEADER_FONT_COLOR'} ) {
            $col = $self->_add_font_color( $col,
                $theme->{'HEADER_FONT_COLOR'} );
        }
    }
    return $col;
}

sub _get_cell_bg_color {
    my ( $self, $row_bg_color, $col_id ) = @_;
    my $cell_bg_color = $row_bg_color;
    if ( $self->get_columns_like_header ) {
    HEADER_COLUMN:
        for my $i ( @{ $self->get_columns_like_header } ) {
            if ( $i == $col_id ) {
                $cell_bg_color
                    = $self->get_theme_settings->{'HEADER_BG_COLOR'};
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

sub _get_row_array {
    my ( $self, $cols_ref, $bgcolor, $is_header ) = @_;
    my @cols_defs = map { $self->_get_mc_def($_) } @{$cols_ref};
    my @cols      = ();
    my $theme     = $self->get_theme_settings;
    my $vlines    = $theme->{'VERTICAL_RULES'};
    my $v0        = q{|} x $vlines->[0];
    my $v1        = q{|} x $vlines->[1];
    my $v2        = q{|} x $vlines->[2];
    my $j         = 0;
    my $col_id    = 0;
    for my $col_def (@cols_defs) {
        if ( !$is_header && $self->get_columns_like_header ) {
        HEADER_COLUMN:
            for my $i ( @{ $self->get_columns_like_header } ) {
                next HEADER_COLUMN if $i != $col_id;
                $col_def = $self->_get_mc_def(
                    $self->_apply_header_formatting(
                        $self->_get_mc_value($col_def), 0
                    )
                );
                if ( !defined $col_def->{cols} ) {
                    my @summary = $self->_get_data_summary();
                    $col_def->{cols} = 1;
                    $col_def->{align}
                        = $self->get_coldef_strategy->{ $summary[$col_id]
                            . $self->_get_coldef_type_col_suffix };
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
                $vl_post = $v0;
            }
            elsif ( $j == 0 && $col_def->{cols} == 1 ) {
                $vl_post = $v1;
            }
            else {
                $vl_post = $v2;
            }

            my $color_code = q{};

            my $cell_bg_color
                = $self->_get_cell_bg_color( $bgcolor, $col_id );
            if ( defined $cell_bg_color ) {
                $color_code = '>{\columncolor{' . $cell_bg_color . '}}';
            }

            push @cols,
                '\\multicolumn{'
                . $col_def->{cols} . '}{'
                . $vl_pre
                . $color_code
                . $col_def->{align}
                . $vl_post . '}{'
                . $col_def->{value} . '}';

            $col_id += $col_def->{cols};
        }
        else {
            push @cols, $col_def->{value};
            $col_id++;
        }
        $j++;
    }
    if ( defined $bgcolor ) {

        # @cols has always at least one element, otherwise we draw a line
        $cols[0] = "\\rowcolor{$bgcolor}" . $cols[0];
    }
    return \@cols;
}

sub _get_row_code {
    my ( $self, $cols_ref, $bgcolor, $is_header ) = @_;
    my $cols = $self->_get_row_array( $cols_ref, $bgcolor, $is_header );
    return join( ' & ', @{$cols} ) . "\\\\\n";
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
# Usage      : $self->_add_font_family($col, 'bf');
# Purpose    : add font family to column value
# Returns    : new column value
# Parameters : column value and family (tt, bf, it, sc)
# Throws     : exception when family is not known

sub _add_font_family {
    my ( $self, $col, $family ) = @_;
    my %know_families = ( tt => 1, bf => 1, it => 1, sc => 1 );
    if ( !defined $know_families{$family} ) {
        $self->invalid_option_usage(
            'custom_themes',
            "Family not known: $family. Valid families are: " . join ', ',
            sort keys %know_families
        );
    }
    my $col_def = $self->_get_mc_def($col);
    $col_def->{value} = "\\text$family" . '{' . $col_def->{value} . '}';
    return $self->_get_mc_value($col_def);
}

###############################################################################
# Usage      : $self->_add_font_color($col, $color);
# Purpose    : add font color to column value
# Returns    : new column value
# Parameters : column value and color

sub _add_font_color {
    my ( $self, $col, $color ) = @_;
    my $col_def = $self->_get_mc_def($col);
    $col_def->{value} = "\\color{$color}" . $col_def->{value};
    return $self->_get_mc_value($col_def);
}

sub _get_coldef_type_col_suffix {
    my ($self) = @_;
    if (   $self->get_width_environment eq 'tabularx'
        || $self->get_type eq 'ctable' )
    {
        return '_COL_X';
    }
    if ( $self->get_width_environment eq 'tabulary' ) {
        return '_COL_Y';
    }
    return '_COL';
}

###########################################################################
# Usage      : $self->_get_coldef_code(\@data);
# Purpose    : generate the LaTeX code of the column definitions (e.g.
#              |l|r|r|r|)
# Returns    : LaTeX code
# Parameters : the data columns
# Comments   : Tries to be intelligent. Hope it is ;)

sub _get_coldef_code {
    my ( $self, $data ) = @_;
    my @cols   = $self->_get_data_summary();
    my $vlines = $self->get_theme_settings->{'VERTICAL_RULES'};

    my $v0 = q{|} x $vlines->[0];
    my $v1 = q{|} x $vlines->[1];
    my $v2 = q{|} x $vlines->[2];

    my $table_def  = q{};
    my $i          = 0;
    my $strategy   = $self->get_coldef_strategy();
    my $typesuffix = $self->_get_coldef_type_col_suffix();

    my @attributes = grep {m{ _COL }xms} keys %{$strategy};

    for my $col (@cols) {

        # align text right, numbers left, first col always left
        my $align;

        for my $attribute ( sort @attributes ) {
            if ( $attribute =~ m{ \A $col $typesuffix \z }xms ) {
                $align = $strategy->{$attribute};

                # for _X and _Y, use default if no special defs are found
            }
            elsif ( ( $typesuffix eq '_COL_X' || $typesuffix eq '_COL_Y' )
                && $attribute =~ m{ \A $col _COL \z }xms )
            {
                $align = $strategy->{$attribute};
            }
        }

        if ( $i == 0 ) {
            if ( defined $self->get_theme_settings->{'STUB_ALIGN'} ) {
                $align = $self->get_theme_settings->{'STUB_ALIGN'};
            }
            $table_def .= $v0 . $align . $v1;
        }
        elsif ( $i == ( scalar(@cols) - 1 ) ) {
            $table_def .= $align . $v0;
        }
        else {
            $table_def .= $align . $v2;
        }
        $i++;
        if (   $i == 1
            && $self->get_width
            && !$self->get_width_environment
            && $self->get_type ne 'ctable' )
        {
            $table_def .= '@{\extracolsep{\fill}}';
        }
    }
    return $table_def;
}

###########################################################################
# Usage      : $self->get_theme_settings();
# Purpose    : return an hash reference with all settings of the current
#              theme
# Returns    : see purpose
# Parameters : none
# Throws     : exception if theme is unknown
# See also   : get_available_themes();

sub get_theme_settings {
    my ($self) = @_;

    my $themes = $self->get_available_themes();
    if ( defined $themes->{ $self->get_theme } ) {
        return $themes->{ $self->get_theme };
    }
    $self->invalid_option_usage( 'theme', 'Not known: ' . $self->get_theme );
    return;
}

sub _check_1d_array {
    my ( $self, $arr_ref_1d, $desc, $option ) = @_;
    if ( !defined reftype $arr_ref_1d || reftype $arr_ref_1d ne 'ARRAY' ) {
        $self->invalid_option_usage( $option,
            "${desc}Not an array reference" );
    }
    return;
}

sub _check_2d_array {
    my ( $self, $arr_ref_2d, $desc ) = @_;
    $self->_check_1d_array( $arr_ref_2d, q{}, $desc );
    my $i = 0;
    for my $arr_ref ( @{$arr_ref_2d} ) {
        $self->_check_1d_array( $arr_ref, "$desc\[$i\] ", $desc );
        my $j = 0;
        for my $scalar ( @{$arr_ref} ) {
            my $rt_scalar = reftype $scalar;
            if ( defined $rt_scalar ) {
                $self->invalid_option_usage( $desc,
                    "$desc\[$i\]\[$j\] not a scalar" );
            }
            if ( !defined $scalar ) {
                $self->invalid_option_usage( $desc,
                    "Undefined value in $desc\[$i\]\[$j\]" );
            }
            $j++;
        }
        $i++;
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
# See also   : get_theme_settings()

sub get_available_themes {
    my ($self) = @_;
    $self->_load_themes();
    return {
        ( %{ $self->get_predef_themes }, %{ $self->get_custom_themes } ) };
}

no Moose;
1;    # Magic true value required at end of module
__END__

=head1 NAME

LaTeX::Table - Perl extension for the automatic generation of LaTeX tables.

=head1 VERSION

This document describes LaTeX::Table version 0.9.13

=head1 SYNOPSIS

  use LaTeX::Table;
  use Number::Format qw(:subs);  # use mighty CPAN to format values

  my $header = [
      [ 'Item:2c', '' ],
      [ '\cmidrule(r){1-2}' ],
      [ 'Animal', 'Description', 'Price' ],
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
  % for publication quality tables (Zurich theme, the default)
  \usepackage{booktabs}
  % for the NYC theme 
  \usepackage{array}
  \usepackage{colortbl}
  \usepackage{xcolor}
  
  \begin{document}
  \input{prices}
  \end{document}
  
=head1 DESCRIPTION

LaTeX makes professional typesetting easy. Unfortunately, this is not entirely
true for tables and the standard LaTeX table macros have a rather limited
functionality. This module supports many CTAN packages and hides the
complexity of using them behind an easy and intuitive API.

=head1 FEATURES 

This module supports multipage tables via the C<xtab> package.  For
publication quality tables, it uses the C<booktabs> package. It also supports
the C<tabularx> and C<tabulary> packages for nicer fixed-width tables.
Furthermore, it supports the C<colortbl> package for colored tables optimized
for presentations. The powerful new C<ctable> package is supported and
especially recommended when footnotes are needed. C<LaTeX::Table> ships with
some predefined, good looking L<"THEMES">. The program I<ltpretty> makes it
possible to use this module from within a text editor. 

=head1 INTERFACE 

=over

=item C<my $table = LaTeX::Table-E<gt>new($arg_ref)>

Constructs a C<LaTeX::Table> object. The parameter is an hash reference with
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

Returns an hash reference to all available themes.  See L<"THEMES"> for
details.

  for my $theme ( keys %{ $table->get_available_themes } ) {
    ...
  }

=item C<$table-E<gt>search_path( add =E<gt> "MyThemes" );> 

C<LaTeX::Table> will search under the C<LaTeX::Table::Themes::> namespace for
themes. You can add here an additional search path. Inherited from
L<Module::Pluggable>.

=back

=head1 OPTIONS

Options can be defined in the constructor hash reference or with the setter
C<set_optionname>. Additionally, getters of the form C<get_optionname> are
created.

=head2 BASIC OPTIONS

=over

=item C<filename>

The name of the LaTeX output file. Default is 'latextable.tex'.

=item C<type>

Can be 'std' for standard LaTeX tables, 'ctable' for tables using the
C<ctable> package or 'xtab' for multipage tables 
(in appendices for example, requires the C<xtab> LaTeX package). 

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
      ['\cmidrule{1-2}'],
      [ 'Animal', 'Description', 'Price' ]
  ];

will produce following LaTeX code in the default Zurich theme:

  \multicolumn{2}{c}{\textbf{Item}} &                                          \\ 
  \cmidrule{1-2}
  \textbf{Animal}                   & \multicolumn{1}{c}{\textbf{Description}} & \multicolumn{1}{c}{\textbf{Price}}\\ 

Note that there is no C<\multicolumn>, C<\textbf> or C<\\> added to the second row.

=item C<data>

The data. Once again a reference to an array (rows) of array references
(columns). 

  $table->set_data([ [ 'Gnu', '92.59' ], [ 'Emu', '33.33' ] ]);

And you will get a table like this:

  +-------+---------+
  | Gnu   |   92.59 |
  | Emu   |   33.33 |
  +-------+---------+

An empty column array will produce a horizontal rule (line):

  $table->set_data([ [ 'Gnu', '92.59' ], [], [ 'Emu', '33.33' ] ]);

Now you will get such a table:

  +-------+---------+
  | Gnu   |   92.59 |
  +-------+---------+
  | Emu   |   33.33 |
  +-------+---------+

This works also in C<header>. 

Single column rows starting with a backslash are again printed without any
formatting. So,

  $table->set_data([ [ 'Gnu', '92.59' ], ['\hline'], [ 'Emu', '33.33' ] ]);

is equivalent to the example above (except that there always the correct rule
command is used, i.e. C<\midrule> vs. C<\hline>).

=item C<custom_template> 

The table types listed above use the L<Template> toolkit internally. These
type tempates are very flexible and powerful, but you can also provide a
custom template:

  # Returns the header and data formatted in LaTeX code. Nothing else.
  $table->set_custom_template('[% HEADER_CODE %][% DATA_CODE %]');

See L<LaTeX::Table::Types::TypeI>.

=back

=head2 FLOATING TABLES

=over

=item C<environment>

If get_environment() returns a true value, then a floating environment will be 
generated. For I<std> tables, the default environment is 'table'. A true value different
from '1' will be used as environment name. Default is 1 (use a 'table'
environment).

The non-floating I<xtab> environment is mandatory (get_environment() must
return a true value here) and supports all options in this section except
for C<position>.

The I<ctable> type automatically adds an environment when any of the
following options are set.

  \begin{table}[htb]
      \centering
      \begin{tabular}{lrr}
      ...
      \end{tabular}
      \caption{Price list}
      \label{tbl:prices}
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

Default 0 (caption below the table) because the spacing in the standard LaTeX 
macros is optimized for bottom captions. At least for multipage tables, 
however, top captions are highly recommended. You can use the C<caption> 
LaTeX package to fix the spacing:

  \usepackage[tableposition=top]{caption} 

=item C<maincaption>

If get_maincaption() returns a true value, then this value will be displayed 
in the table listing (C<\listoftables>) and before the C<caption>. For example,

  maincaption => 'Price List',
  caption     => 'Try our special offer today!',

will generate

  \caption[Price List]{Price List. Try our special offer today!}

Default 0. Requires C<environment>. 

=item C<shortcaption>

Same as C<maincaption>, but does not appear in the caption, only in the table
listing. Default 0. Requires C<environment>.

=item C<continued>

If true, then the table counter will be decremented by one and the
C<continuedmsg> is appended to the caption. Useful for splitting tables. Default 0.

  $table->set_continued(1);

=item C<continuedmsg>

If get_continued() returns a true value, then this text is appended to the
caption. Default '(continued)'.

=item C<center>, C<right>, C<left>

Defines how the table is aligned in the available textwidth. Default is centered. Requires 
C<environment>. Only one of these options may return a true value.
    
  # don't generate any aligning code
  $table->set_center(0);

=item C<label>

The label of the table. Only generated if get_label() returns a true value.
Default is 0. Requires C<environment>. 

 $table->set_label('tbl:prices');

then in LaTeX:

 table~\ref{tbl:prices}

Note that many style guides (for example the CMOS) recommend a lower case
I<table> in text references.

=item C<position>

The position of the environment, e.g. 'htb'. Only generated if get_position()
returns a true value. Default 0. Requires C<environment> and tables of C<type>
I<std>.

=item C<sideways>

Rotates the environment by 90 degrees. Default 0. Requires the C<rotating>
LaTeX package.

 $table->set_sideways(1);

This does not work with I<xtab> tables - please tell me if you know how to
implement this.

=item C<star>

Use the starred versions of the environments, which place the float over two
columns when the C<twocolumn> option or the C<\twocolumn> command is active.
Default 0.

 $table->set_star(1);

=item C<fontfamily>

Valid values are 'rm' (Roman, serif), 'sf' (Sans-serif), 'tt' (Monospace or
typewriter) and 0. Default is 0 (does not define a font family).  Requires
C<environment>.

=item C<fontsize>

Valid values are 'tiny', 'scriptsize', 'footnotesize', 'small', 'normal',
'large', 'Large', 'LARGE', 'huge', 'Huge' and 0. Default is 0 (does not define
a font size). Requires C<environment>.

=back

=head2 TABULAR ENVIRONMENT

=over 

=item C<custom_tabular_environment>

If get_custom_tabular_environment() returns a true value, then this specified
environment is used instead of the standard environments 'tabular' (I<std>) or
'xtabular' (I<xtab>). For I<xtab> tables, you can also use the 'mpxtabular'
environment here if you need footnotes. See the documentation of the C<xtab>
package.

See also the documentation of C<width> below for cases when a width is
specified.

=item C<coldef>

The table column definition, e.g. 'lrcr' which would result in:

  \begin{tabular}{lrcr}
  ..

If unset, C<LaTeX::Table> tries to guess a good definition. Columns containing
only numbers are right-justified, others left-justified. Columns with cells
longer than 30 characters are I<p> (paragraph) columns of size '5cm' (I<X>
columns when the C<tabularx>, I<L> when the C<tabulary> package is selected).
These rules can be changed with set_coldef_strategy(). Default is 0 (guess
good definition). The left-hand column, the stub, is normally exculded here
and is always left aligned. See L<LaTeX::Table::Themes::ThemeI>.

=item C<coldef_strategy>

Controls the behaviour of the C<coldef> calculation when get_coldef()
does not return a true value. It is a reference to a hash that contains
regular expressions that define the I<types> of the columns. For example, 
the standard types I<NUMBER> and I<LONG> are defined as:

  {
    NUMBER                =>
       qr{\A\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*\z}xms,
    NUMBER_MUST_MATCH_ALL => 1,
    NUMBER_COL            => 'r',
    LONG                  => qr{\A\s*(?=\w+\s+\w+).{29,}?\S}xms,
    LONG_MUST_MATCH_ALL   => 0,
    LONG_COL              => 'p{5cm}',
    LONG_COL_X            => 'X',
    LONG_COL_Y            => 'L',
  };

=over

=item C<TYPE =E<gt> $regex>

New types are defined with the regular expression C<$regex>. All B<cells> that
match this regular expression have type I<TYPE>. A cell can have multiple
types. The name of a type is not allowed to contain underscores (C<_>).

=item C<TYPE_MUST_MATCH_ALL>

This defines if whether a B<column> has type I<TYPE> when all B<cells> 
are of type I<TYPE> or at least one. Default is C<1> (C<$regex> must match
all).

Note that columns can have only one type. Types are applied alphabetically, 
so for example a I<LONG> I<NUMBER> column has as final type I<NUMBER>.

=item C<TYPE_COL>

The C<coldef> attribute for I<TYPE> columns. Required (no default value).

=item C<TYPE_COL_X>, C<TYPE_COL_Y>

Same as C<TYPE_COL> but for C<tabularx> or C<tabulary> tables. If undefined,
the attribute defined in C<TYPE_COL> is used. 

=item C<DEFAULT_COL>, C<DEFAULT_COL_X>, C<DEFAULT_COL_Y>

The C<coldef> attribute for columns that do not match any specified type.
Default 'l' (left-justified).

=back

Examples:

  # change standard types
  $table->set_coldef_strategy({
    NUMBER   => qr{\A \s* \d+ \s* \z}xms, # integers only
    LONG_COL => '>{\raggedright\arraybackslash}p{7cm}', # non-justified
  });

  # add new types (here: columns that contain only URLs)
  $table->set_coldef_strategy({
    URL     => qr{\A \s* http }xms, 
    URL_COL => '>{\ttfamily}l',
  });

  

=item C<width>

If get_width() returns a true value, then C<LaTeX::Table> will use the starred
version of the environment (e.g. C<tabular*> or C<xtabular*>) and will add the
specified width as second parameter. It will also add
C<@{\extracolsep{\fill}}> to the table column definition:

  # use 75% of textwidth 
  $table->set_width('0.75\textwidth');

This will produce following LaTeX code:

  \begin{tabular*}{0.75\textwidth}{l@{\extracolsep{\fill} ... }

For tables of C<type> I<std>, it is also possible to use the C<tabularx> and
C<tabulary> LaTeX packages (see C<width_environment> below). The tables of type I<ctable>
automatically use the C<tabularx> package.

=item C<width_environment>

If get_width() (see above) returns a true value and table is of C<type> I<std>,
then this option provides the possibility to add a custom tabular environment
that supports a table width:

  \begin{environment}{width}{def}

To use for example the one provided by the C<tabularx> LaTeX package, write:

  # use the tabularx package (for a std table)
  $table->set_width('300pt');
  $table->set_width_environment('tabularx');

Note this will not add C<@{\extracolsep{\fill}}> and that this overwrites
a C<custom_tabular_environment>. Default is 0 (see C<width>).

=item C<maxwidth>

Only supported by tables of type I<ctable>. 

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

=item C<foottable>

Only supported by tables of type C<ctable>. The footnote C<\tnote> commands.
See the documentation of the C<ctable> LaTeX package.

  $table->set_foottable('\tnote{footnotes are placed under the table}');

=item C<resizebox>

If get_resizebox() returns a true value, then the resizebox command is used to
resize the table. Takes as argument a reference to an array. The first element
is the desired width. If a second element is not given, then the hight is set to
a value so that the aspect ratio is still the same. Requires the C<graphicx>
LaTeX package. Default 0.

  $table->set_resizebox([ '0.6\textwidth' ]);

  $table->set_resizebox([ '300pt', '200pt' ]);


=back

=head2 MULTIPAGE TABLES

=over

=item C<tableheadmsg>

When get_caption_top() and get_tableheadmsg() both return true values, then
additional captions are printed on the continued pages. Default caption text 
is 'Continued from previous page'.

=item C<tabletailmsg>

Message at the end of a multipage table. Default is 'Continued on next page'. 
When using C<caption_top>, this is in most cases unnecessary and it is
recommended to omit the tabletail (see below).

=item C<tabletail>

Custom table tail. Default is multicolumn with the tabletailmsg (see above) 
right-justified. 
  
  # don't add any tabletail code:
  $table->set_tabletail(q{});

=item C<xentrystretch>

Option for xtab. Play with this option if the number of rows per page is not 
optimal. Requires a number as parameter. Default is 0 (does not use this option).

  $table->set_xentrystretch(-0.1);

=back

=head2 THEMES

=over

=item C<theme>

The name of the theme. Default is I<Zurich>. See L<"THEMES">.

=item C<predef_themes>

All predefined themes. Getter only.

=item C<custom_themes>

All custom themes. See L<LaTeX::Table::Themes::ThemeI>.

=item C<columns_like_header>

Takes as argument a reference to an array with column ids (again, starting
with 0). These columns are formatted like header columns.

  # a "transposed" table ...
  my $table = LaTeX::Table->new(
      {   data     => $data,
          columns_like_header => [ 0 ], }
  );

=item C<header_sideways>

If get_header_sideways() returns a true value, then the header columns will
be rotated by 90 degrees. Requires the C<rotating> LaTeX package. Does not
affect data columns specified in columns_like_header(). If you do not want to
rotate all headers, use a callback function B<instead>:

  ...
  header_sideways => 0,
  callback => sub {  
      my ( $row, $col, $value, $is_header ) = @_;
      if ( $col != 0 && $is_header ) {
          $value = '\begin{sideways}' . $value . '\end{sideways}';
      }
      return $value;
  }
  ...
  
=back

=head1 MULTICOLUMNS 

Multicolumns are defined in LaTeX with
C<\multicolumn{$cols}{$alignment}{$text}>. This module supports a simple 
shortcut of the format C<$text:$cols$alignment>. For example, C<Item:2c> is 
equivalent to C<\multicolumn{2}{c}{Item}>. Note that vertical rules (C<|>) are
automatically added here according the rules settings in the theme. 
See L<LaTeX::Table::Themes::ThemeI>. C<LaTeX::Table> also uses this shortcut to determine
the column ids. So in this example,

  my $data = [ [' \multicolumn{2}{c}{A}', 'B' ], [ 'C:2c', 'D' ] ];

'B' would have an column id of 1 and 'D' 2 ('A' and 'C' both 0). This is important 
for callback functions and for the coldef calculation. 
See L<"TABULAR ENVIRONMENT">.

=head1 THEMES

The theme can be selected with 

  $table->set_theme($themename)

Currently, following predefined main themes are available: I<Zurich>, I<plain>
(no formatting), I<NYC> (for presentations), I<Berlin> and I<Paris>. Variants
of these themes are also available, see the theme modules below. The script
F<generate_examples.pl> in the I<examples> directory of this distributions
generates some examples for all available themes. 

The default theme, Zurich, is highly recommended. It requires
C<\usepackage{booktabs}> in your LaTeX document.

See L<LaTeX::Table::Themes::ThemeI> how to define custom themes.

L<LaTeX::Table::Themes::Beamer>, L<LaTeX::Table::Themes::Booktabs>,
L<LaTeX::Table::Themes::Classic>, L<LaTeX::Table::Themes::Modern>.

=head1 EXAMPLES

See I<examples/examples.pdf> in this distribution for a short tutorial that
covers the main features of this module. See also the example application
I<csv2pdf> for an example of the common task of converting a CSV (or Excel)
file to LaTeX or even PDF.

=head1 DIAGNOSTICS

If you get a LaTeX error message, please check whether you have included all
required packages. The packages we use are C<array>, C<booktabs>, C<colortbl>,
C<ctable>, C<graphicx>, C<rotating>, C<tabularx>, C<tabulary>, C<xcolor> and
C<xtab>. 

C<LaTeX::Table> may throw one of these errors and warnings:

=over

=item C<IO error: Can't ...>

In method generate(), it was not possible to write the LaTeX code to
C<filename>. 

=item C<Invalid usage of option ...> 

See the examples in this document and in I<examples/examples.pdf> for the correct 
usage of this option.

=item C<DEPRECATED. ...>  

There were some minor API changes in C<LaTeX::Table> 0.1.0, 0.8.0, 0.9.0,
0.9.3 and 0.9.12. Just apply the changes to the script or contact its author.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<LaTeX::Table> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<Module::Pluggable>, L<Moose>, L<English>, L<Scalar::Util>,
L<Template>, L<Text::Wrap>

=head1 BUGS AND LIMITATIONS

The width option causes problems with themes using the C<colortbl> package.
You may have to specify here the overhang arguments of the C<\columcolor>
commands manually. Patches are of course welcome.

Please report any bugs or feature requests to
C<bug-latex-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head1 SEE ALSO

L<Data::Table>, L<LaTeX::Encode>

=head1 CREDITS

=over

=item David Carlisle for the C<colortbl>, C<tabularx> and C<tabulary> LaTeX packages.

=item Wybo Dekker for the C<ctable> LaTeX package.

=item Simon Fear for the C<booktabs> LaTeX package. The L<"SYNOPSIS"> table is
the example in his documentation.

=item Andrew Ford (ANDREWF) for many great suggestions. He also wrote
L<LaTeX::Driver> and L<LaTeX::Encode> which are used by I<csv2pdf>.

=item Lapo Filippo Mori for the excellent tutorial I<Tables in LaTeX2e:
Packages and Methods>.

=item Peter Wilson for the C<xtab> LaTeX package.

=back

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009, Markus Riester C<< <mriester@gmx.de> >>. 

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
