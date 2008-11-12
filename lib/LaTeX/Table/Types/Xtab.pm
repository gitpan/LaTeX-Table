#############################################################################
#   $Author: markus $
#     $Date: 2008-11-11 23:56:16 +0100 (Tue, 11 Nov 2008) $
# $Revision: 1230 $
#############################################################################

package LaTeX::Table::Types::Xtab;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1230 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
{
[% COLORDEF %][% EXTRA_ROW_HEIGHT %][% SIZE %][% IF CAPTION %][%IF CAPTION_TOP
%]\topcaption[% ELSE %]\bottomcaption[% END %][%IF CAPTION_SHORT %][[% CAPTION_SHORT %]][% END %]{[% CAPTION %]}
[% END %][% XENTRYSTRETCH %][% IF LABEL %]\label{[% LABEL %]}
[% END %]
[% TABLEHEAD %]
[% TABLETAIL %]
[% TABLETAIL_LAST %]
[% IF CENTER %]\begin{center}
[% END %][% IF LEFT %]\begin{flushleft}
[% END %][% IF RIGHT %]\begin{flushright}
[% END %][% BEGIN_RESIZEBOX %]\begin{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}[% IF WIDTH %]{[%WIDTH %]}[% END %]{[% COL_DEF %]}
[% BODY %]\end{[% TABULAR_ENVIRONMENT %][% IF STAR %]*[% END %]}
[% END_RESIZEBOX %][% IF CENTER %]\end{center}[% END %][% IF LEFT %]\end{flushleft}[% END %][% IF RIGHT %]\end{flushright}[% END %]
} 
EOT
;

has '+_tabular_environment' => (default => 'xtabular');
has '+_template'    => (default => $template);

sub _get_tablehead_code {
    my ($self, $code) =@_;
    my $tbl = $self->_table_obj;

    my $tablehead = q{};
    my @summary   = $tbl->_get_data_summary();

    if ( $tbl->get_caption_top && $tbl->get_tableheadmsg ) {
        my $continued_caption = '\\multicolumn{'
            . scalar(@summary)
            . '}{c}{{ \normalsize \tablename\ \thetable: '
            . $tbl->get_tableheadmsg
            . "}}\\\\[\\abovecaptionskip]\n";
        $tablehead
            = "\\tablefirsthead{$code}\n\\tablehead{$continued_caption$code}\n";

        #                $tablehead = "\\tablehead{$code}";
    }
    else {
        $tablehead = "\\tablehead{$code}";
    }
    return $tablehead;
}

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
    my $hlines    = $tbl->get_theme_settings->{'HORIZONTAL_LINES'};
    my $vlines    = $tbl->get_theme_settings->{'VERTICAL_LINES'};
    my $linecode1 = $self->_get_hline_code($self->_RULE_MID_ID);
    my $linecode2 = $self->_get_hline_code($self->_RULE_BOTTOM_ID);

    # if custom table tail is defined, then return it
    if ( $tbl->get_tabletail ) {
        $code = $tbl->get_tabletail;
    }
    elsif ( !$final_tabletail ) {
        my @cols    = $tbl->_get_data_summary();
        my $nu_cols = scalar @cols;

        my $v0 = q{|} x $vlines->[0];
        $code = "$linecode1\\multicolumn{$nu_cols}{${v0}r$v0}{{"
            . $tbl->get_tabletailmsg
            . "}} \\\\ \n";
    }
    if ($final_tabletail) {
        return "\\tablelasttail{}";
    }
    return "\\tabletail{$code$linecode2}";
}

sub _get_xentrystretch_code {
    my ($self) = @_;
    my $tbl = $self->_table_obj;
    if ( $tbl->get_xentrystretch ) {
        my $xs = $tbl->get_xentrystretch();
        if ( $xs !~ /\A-?(?:\d+(?:\.\d*)?|\.\d+)\z/xms ) {
            $tbl->invalid_option_usage( 'xentrystretch',
                'Not a number: ' . $tbl->get_xentrystretch );
        }
        return "\\xentrystretch{$xs}\n";
    }
    return q{};
}


1;
__END__

=head1 NAME

LaTeX::Table::Types::Xtab - Create multi-page tables with the xtabular package.

=head1 INTERFACE

=over

=item C<generate_latex_code>

=back

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Types::TypesI>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2008, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
