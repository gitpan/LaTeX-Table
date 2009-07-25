#############################################################################
#   $Author: markus $
#     $Date: 2009-07-25 23:29:40 +0200 (Sat, 25 Jul 2009) $
# $Revision: 1792 $
#############################################################################

package LaTeX::Table::Types::TypeI;

use strict;
use warnings;

use Moose::Role;
use Template;

use version;
our ($VERSION) = '$Revision: 1792 $' =~ m{ \$Revision: \s+ (\S+) }xms;

use Scalar::Util qw(reftype);

use Carp;

has '_table_obj' => ( is => 'rw', isa => 'LaTeX::Table', required => 1 );
has '_tabular_environment' => ( is => 'ro', required => 1 );
has '_template'            => ( is => 'ro', required => 1 );

has '_RULE_TOP_ID'   => ( is => 'ro', default => 0 );
has '_RULE_MID_ID'   => ( is => 'ro', default => 1 );
has '_RULE_INNER_ID' => ( is => 'ro', default => 2 );
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
has '_RULE_BOTTOM_ID' => ( is => 'ro', default => 3 );
## use critic

###########################################################################
# Usage      : $self->_header(\@header,\@data);
# Purpose    : create the LaTeX header
# Returns    : LaTeX code
# Parameters : header and data columns
# Throws     :
# Comments   : n/a
# See also   : _footer

sub generate_latex_code {
    my ( $self, $header, $data ) = @_;

    my $tbl   = $self->_table_obj;
    my $theme = $tbl->get_theme_settings;

    if ( !$tbl->get_tabletail() ) {
        $tbl->set_tabletail( $self->_get_default_tabletail_code() );
    }

    my $template_vars = {
        'CENTER' => $tbl->get__default_align ? 1 : $tbl->get_center,
        'LEFT'   => $tbl->get_left(),
        'RIGHT'  => $tbl->get_right(),
        'ENVIRONMENT'  => $tbl->get_environment,
        'FONTFAMILY'   => $tbl->get_fontfamily(),
        'FONTSIZE'     => $tbl->get_fontsize(),
        'FOOTTABLE'    => $tbl->get_foottable(),
        'POSITION'     => $tbl->get_position(),
        'CAPTION_TOP'  => $tbl->get_caption_top(),
        'CAPTION'      => $self->_get_caption(),
        'CAPTION_CMD'  => $self->_get_caption_command(),
        'CONTINUED'    => $tbl->get_continued(),
        'CONTINUEDMSG' => $tbl->get_continuedmsg(),
        'SHORTCAPTION' => $self->_get_shortcaption(),
        'SIDEWAYS'     => $tbl->get_sideways(),
        'STAR'         => $tbl->get_star(),
        'WIDTH'        => $tbl->get_width(),
        'MAXWIDTH'     => $tbl->get_maxwidth(),
        'COLDEF'       => $tbl->get_coldef ? $tbl->get_coldef
        : $tbl->_get_coldef_code($data),
        'LABEL'                 => $tbl->get_label(),
        'HEADER_CODE'           => $self->_get_header_columns_code($header),
        'TABLEHEADMSG'          => $tbl->get_tableheadmsg(),
        'TABLETAIL'             => $tbl->get_tabletail(),
        'TABLELASTTAIL'         => $tbl->get_tablelasttail(),
        'XENTRYSTRETCH'         => $tbl->get_xentrystretch(),
        'DATA_CODE'             => $self->_get_data_code(),
        'TABULAR_ENVIRONMENT'   => $self->_get_tabular_environment(),
        'EXTRA_ROW_HEIGHT_CODE' => (
            defined $theme->{EXTRA_ROW_HEIGHT}
            ? '\setlength{\extrarowheight}{'
                . $theme->{EXTRA_ROW_HEIGHT} . "}\n"
            : q{}
        ),
        'RULES_COLOR_GLOBAL_CODE' => (
            defined $theme->{RULES_COLOR_GLOBAL}
            ? $theme->{RULES_COLOR_GLOBAL} . "\n"
            : q{}
        ),
        'RULES_WIDTH_GLOBAL_CODE' => (
            defined $theme->{RULES_WIDTH_GLOBAL}
            ? $theme->{RULES_WIDTH_GLOBAL} . "\n"
            : q{}
        ),
        'RESIZEBOX_BEGIN_CODE' => $self->_get_begin_resizebox_code(),
        'RESIZEBOX_END_CODE'   => (
            $self->_table_obj->get_resizebox ? "}\n"
            : q{}
        ),
        'DEFINE_COLORS_CODE' => (
            defined $tbl->get_theme_settings->{DEFINE_COLORS}
            ? $tbl->get_theme_settings->{DEFINE_COLORS} . "\n"
            : q{}
        ),
        'LT_NUM_COLUMNS' => scalar( $tbl->_get_data_summary() ),
        'LT_BOTTOM_RULE_CODE' =>
            $self->_get_hline_code( $self->_RULE_BOTTOM_ID ),
    };

    my $template_obj = Template->new();
    my $template
        = $tbl->get_custom_template
        ? $tbl->get_custom_template
        : $self->_template;

    my $template_output;

    $template_obj->process( \$template, $template_vars, \$template_output )
        or croak $template_obj->error();
    return $template_output;
}

sub _get_data_code {
    my ($self) = @_;
    my $code   = q{};
    my $tbl    = $self->_table_obj;

    my $theme  = $tbl->get_theme_settings;
    my $i      = 0;
    my $row_id = 0;

    # check the data and apply callback function
    my @data = $tbl->_examine_data;
    my @code;
ROW:
    for my $row (@data) {
        $i++;

        # empty rows produce a horizontal line
        if ( !@{$row} ) {
            push @code, $self->_get_hline_code( $self->_RULE_INNER_ID, 1 );
            next ROW;
        }
        else {

            # single column rows that start with a backslash are just
            # printed out
            if ( $tbl->_row_is_latex_command($row) ) {
                push @code, $row->[0] . "\n";
                next ROW;
            }

            $row_id++;

            # now print the row LaTeX code
            my $bgcolor = $theme->{'DATA_BG_COLOR_EVEN'};
            if ( ( $row_id % 2 ) == 1 ) {
                $bgcolor = $theme->{'DATA_BG_COLOR_ODD'};
            }
            push @code, $tbl->_get_row_array( $row, $bgcolor, 0 );

            # do we have to draw a horizontal line?
            if ( $i == scalar @data ) {
                push @code, $self->_get_hline_code( $self->_RULE_BOTTOM_ID );
            }
            else {
                push @code, $self->_get_hline_code( $self->_RULE_INNER_ID );
            }
        }
    }

    return $self->_align_code( \@code );
}

sub _align_code {
    my ( $self, $code_ref ) = @_;
    my %max;
    for my $row ( @{$code_ref} ) {
        next if ( !defined reftype $row);
        for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
            $row->[$i] =~ s{^\s+|\s+$}{}gxms;
            my $l = length $row->[$i];
            if ( !defined $max{$i} || $max{$i} < $l ) {
                $max{$i} = $l;
            }
        }
    }

    my $code = q{};
ROW:
    for my $row ( @{$code_ref} ) {
        if ( !defined reftype $row) {
            $code .= $row;
            next ROW;
        }
        for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
            $row->[$i] = sprintf '%-*s', $max{$i}, $row->[$i];
        }
        $code .= join( ' & ', @{$row} ) . " \\\\\n";
    }
    return $code;
}

sub _get_caption_command {
    my ($self)    = @_;
    my $tbl       = $self->_table_obj;
    my $c_caption = 'caption';
    if ( $tbl->get_caption_top ) {
        $c_caption = $tbl->get_caption_top;
        $c_caption =~ s{ \A \\ }{}xms;
        if ( $c_caption eq '1' ) {
            $c_caption = 'caption';
        }
    }
    return $c_caption;
}

sub _get_begin_resizebox_code {
    my ($self) = @_;
    if ( $self->_table_obj->get_resizebox ) {
        my $rb_width  = $self->_table_obj->get_resizebox->[0];
        my $rb_height = q{!};
        if ( defined $self->_table_obj->get_resizebox->[1] ) {
            $rb_height = $self->_table_obj->get_resizebox->[1];
        }
        return "\\resizebox{$rb_width}{$rb_height}{\n";
    }
    return q{};
}

sub _get_caption {
    my ( $self, $header ) = @_;
    my $caption   = q{};
    my $s_caption = q{};
    my $tbl       = $self->_table_obj;

    if ( !$tbl->get_caption ) {
        if ( !$tbl->get_maincaption ) {
            return 0;
        }
    }
    else {
        $caption = $tbl->get_caption;
    }

    my $theme = $tbl->get_theme_settings;

    my $tmp = q{};
    if ( $tbl->get_maincaption ) {
        $tmp = $tbl->get_maincaption . '. ';
        if ( defined $theme->{CAPTION_FONT_STYLE} ) {
            $tmp = $tbl->_add_font_family( $tmp,
                $theme->{CAPTION_FONT_STYLE} );
        }
    }

    return $tmp . $caption;
}

sub _get_shortcaption {
    my ($self) = @_;
    my $tbl = $self->_table_obj;
    if ( $tbl->get_maincaption ) {
        return $tbl->get_maincaption;
    }
    if ( $tbl->get_shortcaption ) {
        return $tbl->get_shortcaption;
    }
    return 0;
}

sub _get_hline_code {
    my ( $self, $id, $single ) = @_;
    my $tbl    = $self->_table_obj;
    my $theme  = $tbl->get_theme_settings;
    my $hlines = $theme->{'HORIZONTAL_RULES'};
    my $line   = '\hline';
    if ( defined $theme->{RULES_CMD}
        && reftype $theme->{RULES_CMD} eq 'ARRAY' )
    {
        $line = $theme->{RULES_CMD}->[$id];
    }
    if ( $id == $self->_RULE_BOTTOM_ID ) {
        $id = 0;
    }

    # just one line?
    if ( defined $single && $single ) {
        return "$line\n";
    }
    return "$line\n" x $hlines->[$id];
}

sub _get_tabular_environment {
    my ($self) = @_;
    my $tbl = $self->_table_obj;

    my $res
        = $tbl->get_custom_tabular_environment
        ? $tbl->get_custom_tabular_environment
        : $self->_tabular_environment;

    if ( $tbl->get_width ) {
        if ( !$tbl->get_width_environment ) {
            $res .= q{*};
        }
        elsif ( $tbl->get_type ne 'longtable' ) {  #want the ltxtable package?
            $res = $tbl->get_width_environment;
        }
    }
    return $res;
}

sub _get_header_columns_code {
    my ( $self, $header ) = @_;
    my $tbl   = $self->_table_obj;
    my $code  = q{};
    my $theme = $tbl->get_theme_settings;

    my $i = 0;

    my @code = ( $self->_get_hline_code( $self->_RULE_TOP_ID ) );

CENTER_ROW:
    for my $row ( @{$header} ) {
        my @cols = @{$row};
        if ( scalar @cols == 0 ) {
            push @code, $self->_get_hline_code( $self->_RULE_INNER_ID, 1 );
            next CENTER_ROW;
        }
        if ( $tbl->_row_is_latex_command($row) ) {
            push @code, $cols[0] . "\n";
            next CENTER_ROW;
        }

        my $j = 0;

        for my $col (@cols) {
            if ( $tbl->get_header_sideways() ) {
                my $col_def = $tbl->_get_mc_def($col);
                $col_def->{value}
                    = '\begin{sideways}'
                    . $col_def->{value}
                    . '\end{sideways}';
                $col = $tbl->_get_mc_value($col_def);
            }

            if ( $tbl->get_callback ) {
                $col = $tbl->_apply_callback( $i, $j, $col, 1 );
            }
            $col = $tbl->_apply_header_formatting( $col,
                ( !defined $theme->{STUB_ALIGN} || $j > 0 ) );
            $j += $tbl->_extract_number_columns($col);
        }

        push @code,
            $tbl->_get_row_array( \@cols, $theme->{'HEADER_BG_COLOR'}, 1 );
        $i++;
    }

    # without header, just draw the topline, not this midline
    if ($i) {
        push @code, $self->_get_hline_code( $self->_RULE_MID_ID );
    }
    return $self->_align_code( \@code );
}

sub _get_default_tabletail_code {
    my ($self) = @_;

    my $tbl = $self->_table_obj;
    my $v0  = q{|} x $tbl->get_theme_settings->{'VERTICAL_RULES'}->[0];

    return
          $self->_get_hline_code( $self->_RULE_MID_ID )
        . '\multicolumn{'
        . $tbl->_get_data_summary()
        . "}{${v0}r$v0}{{"
        . $tbl->get_tabletailmsg
        . "}} \\\\\n";
}

1;
__END__

=head1 NAME

LaTeX::Table::Types::TypeI - Interface for LaTeX table types.

=head1 DESCRIPTION

This is the type interface (or L<Moose> role), that all type objects must use.
L<LaTeX::Table> delegates the boring work of building the LaTeX code to type
objects. It stores all information we have in easy to use L<"TEMPLATE
VARIABLES">. L<LaTeX::Table> ships with very flexible templates, but you can
also use the template variables defined here to build custom templates.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 TEMPLATE VARIABLES

Most options are accessable here:

=over

=item C<CENTER, LEFT, RIGHT>

Example:

  [% IF CENTER %]\centering
  [% END %]

=item C<ENVIRONMENT, STAR, POSITION, SIDEWAYS>

These options for floating environments are typically used like:

  [% IF ENVIRONMENT %]\begin{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %]
  ...
  [% END %]
  # the tabular environment here
  ...
  [% IF ENVIRONMENT %] ...
  \end{[% ENVIRONMENT %][% IF STAR %]*[% END %]}[% END %]

=item C<CAPTION_TOP, CAPTION_CMD, SHORTCAPTION, CAPTION, CONTINUED, CONTINUEDMSG>

The variables to build the caption command. Note that there is NO template for
the C<maincaption> option. C<CAPTION> already includes this maincaption if
specified.

=item C<LABEL>

The label:

 [% IF LABEL %]\label{[% LABEL %]}[% END %]

=item C<TABULAR_ENVIRONMENT, WIDTH, COLDEF>

These three options define the tabular environment:

  \begin{[% TABULAR_ENVIRONMENT %]}[% IF WIDTH %]{[% WIDTH %]}[% END %]{[% COLDEF %]}

=item C<FONTFAMILY, FONTSIZE>

Example: 

  [% IF FONTSIZE %]\[% FONTSIZE %]
  [% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
  [% END %]

=item C<TABLEHEADMSG, TABLETAIL, TABLELASTTAIL, XENTRYSTRETCH>

For the multi-page tables.

=item C<MAXWIDTH, FOOTTABLE>

Currently only used by <LaTeX::Table::Types::Ctable>.

=back

In addition, some variables already contain formatted LaTeX code:

=over 

=item C<HEADER_CODE>

The formatted header:

  \toprule
  \multicolumn{2}{c}{Item} &             \\
  \cmidrule(r){1-2}
  Animal                   & Description & Price \\
  \midrule

=item C<DATA_CODE> 

The formatted data:

  Gnat      & per gram & 13.65 \\
            & each     & 0.01  \\
  Gnu       & stuffed  & 92.59 \\
  Emu       & stuffed  & 33.33 \\
  Armadillo & frozen   & 8.99  \\
  \bottomrule

=item C<RESIZEBOX_BEGIN_CODE, RESIZEBOX_END_CODE>

Everything between these two template variables is resized according the
C<resizebox> option.

=item C<EXTRA_ROW_HEIGHT_CODE, DEFINE_COLORS_CODE, RULES_COLOR_GLOBAL_CODE, RULES_WIDTH_GLOBAL_CODE>

Specified by the theme. EXTRA_ROW_HEIGHT_CODE will contain the
corresponding LaTeX extrarowheight command, e.g for '1pt':

    \setlength{\extrarowheight}{1pt}

Otherwise it will contain the empty string. The other template variables will
contain the command specified by the corresponding theme option.

=back

Finally, some variables allow access to internal C<LaTeX::Table> variables:

=over

=item C<LT_NUM_COLUMNS>

Contains the number of columns of the table.

=item C<LT_BOTTOM_RULE_CODE>

Code that draws the rules at the bottom of the table according the theme
options.

=back 

=head1 SEE ALSO

L<LaTeX::Table>

The predefined templates: L<LaTeX::Table::Types::Std>,
L<LaTeX::Table::Types::Ctable>, L<LaTeX::Table::Types::Longtable>,
L<LaTeX::Table::Types::Xtab>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
