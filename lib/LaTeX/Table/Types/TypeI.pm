#############################################################################
#   $Author: markus $
#     $Date: 2008-11-23 07:22:06 +0100 (Sun, 23 Nov 2008) $
# $Revision: 1243 $
#############################################################################

package LaTeX::Table::Types::TypeI;

use strict;
use warnings;

use Moose::Role;
use Template;

use version;
our ($VERSION) = '$Revision: 1243 $' =~ m{ \$Revision: \s+ (\S+) }xms;

use Scalar::Util qw(reftype);

use Carp;

has '_table_obj' => ( is => 'rw', isa => 'LaTeX::Table', required => 1 );
has '_tabular_environment' => ( is => 'ro', required => 1 );
has '_template'            => ( is => 'ro', required => 1 );

has '_RULE_TOP_ID'   => ( is => 'ro', default => 0 );
has '_RULE_MID_ID'   => ( is => 'ro', default => 1 );
has '_RULE_INNER_ID' => ( is => 'ro', default => 2 );
## no critic
has '_RULE_BOTTOM_ID' => ( is => 'ro', default => 3 );
## use critic

1;

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

    my $tbl = $self->_table_obj;

    # if specified, use coldef, otherwise guess a good definition
    my $table_def;
    if ( $tbl->get_coldef ) {
        $table_def = $tbl->get_coldef;
    }
    else {
        $table_def = $tbl->_get_coldef_code($data);
    }

    my $center = $tbl->get_center;

    if ( $tbl->get__default_align ) {
        $center = 1;
    }
    
    my $header_code = $self->_get_header_columns_code($header);

    my $template_vars = {
        'COLORDEF'            => $self->_get_colordef_code,
        'ENVIRONMENT'         => $tbl->get_environment,
        'POSITION'            => $tbl->get_position(),
        'SIZE'                => $self->_get_size_code(),
        'CENTER'              => $center,
        'LEFT'                => $tbl->get_left(),
        'RIGHT'               => $tbl->get_right(),
        'CAPTION_TOP'         => $tbl->get_caption_top(),
        'CAPTION'             => $self->_get_caption(),
        'CAPTION_CMD'         => $self->_get_caption_command_code(),
        'CAPTION_SHORT'       => $self->_get_shortcaption(),
        'SIDEWAYS'            => $tbl->get_sideways(),
        'STAR'                => $tbl->get_star(),
        'EXTRA_ROW_HEIGHT'    => $self->_get_extra_row_height_code(),
        'BEGIN_RESIZEBOX'     => $self->_get_begin_resizebox_code(),
        'WIDTH'               => $tbl->get_width(),
        'MAXWIDTH'            => $tbl->get_maxwidth(),
        'COLDEF'              => $table_def,
        'HEADER_CODE'         => $header_code,
        'TABLEHEAD'           => $self->_get_tablehead_code( $header_code ),
        'TABLETAIL'           => $self->_get_tabletail_code( $data, 0 ),
        'TABLETAIL_LAST'      => $self->_get_tabletail_code( $data, 1 ),
        'XENTRYSTRETCH'       => $self->_get_xentrystretch_code(),
        'LABEL'               => $tbl->get_label(),
        'BODY'                => $self->_body(),
        'END_RESIZEBOX'       => $self->_get_end_resizebox_code(),
        'TABULAR_ENVIRONMENT' => $self->_get_tabular_environment(),
        'FOOTTABLE'           => $tbl->get_foottable(),
    };

    my $template_obj = Template->new();
    my $template     = $self->_template;
    my $template_output;

    $template_obj->process( \$template, $template_vars, \$template_output )
        or croak $template_obj->error();
    return $template_output;
}

sub _body {
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
            push @code, $self->_get_single_hline_code();
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

    return $self->_align_code(\@code);
}

sub _align_code {
    my ( $self, $code_ref ) = @_;
    my %max;
    for my $row (@{$code_ref}) {
       next if (!defined reftype $row);
       for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
           $row->[$i] =~ s{^\s+|\s+$}{}gxms;
           my $l = length $row->[$i];
           if (!defined $max{$i} || $max{$i} < $l) {
               $max{$i} = $l;
           }
       }
    }

    my $code = q{};
    ROW:
    for my $row (@{$code_ref}) {
       if (!defined reftype $row) {
           $code .= $row;
           next ROW;
       }
       for my $i ( 0 .. scalar( @{$row} ) - 1 ) {
            $row->[$i] = sprintf '%-*s', $max{$i}, $row->[$i];
       }
       $code .=  join( ' & ', @{$row} ) . " \\\\\n";
    }
    return $code;
}

sub _get_caption_command_code {
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

sub _get_colordef_code {
    my ($self)   = @_;
    my $tbl      = $self->_table_obj;
    my $colordef = q{};
    if ( defined $tbl->get_theme_settings->{DEFINE_COLORS} ) {
        $colordef = $tbl->get_theme_settings->{DEFINE_COLORS} . "\n";
    }
    return $colordef;
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

sub _get_end_resizebox_code {
    my ($self) = @_;
    my $end_resizebox = q{};
    if ( $self->_table_obj->get_resizebox ) {
        $end_resizebox = "}\n";
    }
    return $end_resizebox;
}

###########################################################################
# Usage      : $self->_get_caption_code($header);
# Purpose    : generates the LaTeX code of the caption
# Returns    : LaTeX code
# Parameters : called from _header?
# Comments   : header specifies whether this function has been called in
#              the header or footer. ignored for xtab, because there it
#              is always placed on top

sub _get_caption {
    my ( $self, $header ) = @_;
    my $s_caption = q{};
    my $tbl       = $self->_table_obj;
    if ( !$tbl->get_caption ) {
        return 0;
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

    return $tmp . $tbl->get_caption;
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

sub _get_extra_row_height_code {
    my ($self) = @_;
    if ( defined $self->_table_obj->get_theme_settings->{EXTRA_ROW_HEIGHT} ) {
        return '\setlength{\extrarowheight}{'
            . $self->_table_obj->get_theme_settings->{EXTRA_ROW_HEIGHT}
            . "}\n";
    }
    return q{};
}

sub _get_hline_code {
    my ( $self, $id ) = @_;
    my $tbl    = $self->_table_obj;
    my $theme  = $tbl->get_theme_settings;
    my $hlines = $theme->{'HORIZONTAL_LINES'};
    my $line   = 'hline';
    if ( defined $theme->{'BOOKTABS'} && $theme->{'BOOKTABS'} ) {
        my @line_type = qw(toprule midrule midrule bottomrule);
        $line = $line_type[$id];
    }
    if ( $id == $self->_RULE_BOTTOM_ID ) {
        $id = 0;
    }
    return "\\$line\n" x $hlines->[$id];
}

sub _get_single_hline_code {
    my ( $self, $id ) = @_;
    my $theme = $self->_table_obj->get_theme_settings;
    my $line  = 'hline';
    if ( defined $theme->{'BOOKTABS'} && $theme->{'BOOKTABS'} ) {
        $line = 'midrule';
    }
    return "\\$line\n";
}

###########################################################################
# Usage      : $self->_get_size_code();
# Purpose    : generates the LaTeX code of the size (e.g. \small, \large)
# Returns    : LaTeX code
# Parameters : none
# Throws     : exception if size is not valid

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
    my $size = $self->_table_obj->get_size;
    return q{} if !$size;

    if ( !defined $valid{$size} ) {
        $self->_table_obj->invalid_option_usage(
            'custom_themes',
            "Size not known: $size. Valid sizes are: " . join ', ',
            sort keys %valid
        );
    }
    return "\\$size\n";
}

sub _get_tabular_environment {
    my ($self) = @_;
    my $res;
    my $tbl = $self->_table_obj;

    if ( $tbl->get_custom_tabular_environment ) {
        $res = $tbl->get_custom_tabular_environment;
    }
    else {
        $res = $self->_tabular_environment;
    }
    if ( $tbl->get_width ) {
        if ( !$tbl->get_width_environment ) {
            $res .= q{*};
        }
        else {
            $res = $tbl->get_width_environment;
        }
    }
    return $res;
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
    my $tbl   = $self->_table_obj;
    my $code  = q{};
    my $theme = $tbl->get_theme_settings;

    my $i = 0;

    my @code = ( $self->_get_hline_code( $self->_RULE_TOP_ID ) );

CENTER_ROW:
    for my $row ( @{$header} ) {
        my @cols = @{$row};
        if ( scalar @cols == 0 ) {
            push @code, $self->_get_single_hline_code();
            next CENTER_ROW;
        }
        if ( $tbl->_row_is_latex_command($row) ) {
            push @code, $cols[0] . "\n";
            next CENTER_ROW;
        }

        my $j = 0;

        for my $col (@cols) {

            #next if $col =~ m{\A \\ }xms;
            if ( $tbl->get_callback ) {
                $col = $tbl->_apply_callback( $i, $j, $col, 1 );
            }
            $col = $tbl->_apply_header_formatting( $col, 1 );

            $j += $tbl->_extract_number_columns($col);
        }

        push @code, $tbl->_get_row_array( \@cols, $theme->{'HEADER_BG_COLOR'}, 1 );
        $i++;
    }

    # without header, just draw the topline, not this midline
    if ($i) {
        push @code, $self->_get_hline_code( $self->_RULE_MID_ID );
    }
    return $self->_align_code(\@code);
}

sub _get_tabletail_code     { return q{}; }
sub _get_xentrystretch_code { return q{}; }
sub _get_tablehead_code     { return q{}; }

1;
__END__

=head1 NAME

LaTeX::Table::Types::TypeI - Interface for Types

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the type interface (or L<Moose> role), that all type objects must use.
L<LaTeX::Table> delegates the boring work of building the LaTeX code to type
objects.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 SEE ALSO

L<LaTeX::Table>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2008, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
