#############################################################################
#   $Author: markus $
#     $Date: 2009-07-13 16:29:59 +0200 (Mon, 13 Jul 2009) $
# $Revision$
#############################################################################

package LaTeX::Table::Types::Longtable;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1313 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template = <<'EOT'
{
[% IF CONTINUED %]\addtocounter{table}{-1}[% END 
%][% DEFINE_COLORS_CODE %][% EXTRA_ROW_HEIGHT %][% RULES_WIDTH_GLOBAL
%][% RULES_COLOR_GLOBAL %][% FONTSIZE_CODE %][% FONTFAMILY_CODE 
%][%IF SIDEWAYS %]\begin{landscape}[% END 
%][% IF CENTER %]\begin{center}
[% END %][% IF LEFT %]\begin{flushleft}
[% END %][% IF RIGHT %]\begin{flushright}
[% END %][% RESIZEBOX_BEGIN_CODE %]\begin{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF WIDTH %]{[%WIDTH %]}[% END %]{[% COLDEF %]}
[% IF CAPTION %][%IF CAPTION_TOP %]\caption[%IF SHORTCAPTION %][[%
SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][%
END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}\\
[% END %][% END %][% HEADER_CODE %]\endfirsthead
[% IF CAPTION %][% IF CAPTION_TOP %][% IF TABLEHEADMSG %]\caption[]{[% TABLEHEADMSG %]}\\
[% END %][% END %][% END %]
[% HEADER_CODE %]\endhead
[% TABLETAIL %]\endfoot
[% TABLETAIL_LAST %]
[% IF CAPTION %][% UNLESS CAPTION_TOP %]\caption[%IF SHORTCAPTION %][[%
SHORTCAPTION %]][% END %]{[% CAPTION %][% IF CONTINUED %] [% CONTINUEDMSG %][%
END %][% IF LABEL %]\label{[% LABEL %]}[% END %]}\\
[% END %][% END %]\endlastfoot
[% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}
[% RESIZEBOX_END_CODE %][% IF CENTER %]\end{center}[% END %][% IF LEFT
%]\end{flushleft}[% END %][% IF RIGHT %]\end{flushright}[% END %][% IF
SIDEWAYS %]\end{landscape}[% END %]
}
EOT
    ;

has '+_tabular_environment' => ( default => 'longtable' );
has '+_template'            => ( default => $template );

###########################################################################
# Usage      : $self->_get_tabletail_code(\@data, $final_tabletail);
# Purpose    : generates the LaTeX code of the xtab tabletail
# Returns    : LaTeX code
# Parameters : the data columns and a flag indicating whether it is the
#              code for the final tail (1).

sub _get_tabletail_code {
    my ( $self, $data, $final_tabletail ) = @_;

    my $tbl = $self->_table_obj;
    my $code;
    my $hlines    = $tbl->get_theme_settings->{'HORIZONTAL_RULES'};
    my $vlines    = $tbl->get_theme_settings->{'VERTICAL_RULES'};
    my $linecode1 = $self->_get_hline_code( $self->_RULE_MID_ID );
    my $linecode2 = $self->_get_hline_code( $self->_RULE_BOTTOM_ID );

    # if custom table tail is defined, then return it
    if ( $tbl->get_tabletail ) {
        $code = $tbl->get_tabletail;
    }
    elsif ( !$final_tabletail ) {
        my @cols    = $tbl->_get_data_summary();
        my $nu_cols = scalar @cols;

        my $v0 = q{|} x $vlines->[0];
        $code
            = "$linecode1\\multicolumn{$nu_cols}{${v0}r$v0}{{"
            . $tbl->get_tabletailmsg
            . "}} \\\\\n";
    }
    if ($final_tabletail) {
        return q{};
    }
    return "$code$linecode2";
}

1;
__END__

=head1 NAME

LaTeX::Table::Types::Longtable - Create multi-page LaTeX tables with the longtable package.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Types::TypeI>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
