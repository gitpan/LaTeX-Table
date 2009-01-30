#############################################################################
#   $Author: markus $
#     $Date: 2009-01-30 15:18:13 +0100 (Fri, 30 Jan 2009) $
# $Revision: 1278 $
#############################################################################

package LaTeX::Table::Types::Std;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1278 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
[% COLORDEF_CODE %][% IF ENVIRONMENT %]\begin{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %]
[% FONTSIZE_CODE %][% FONTFAMILY_CODE %][% RULES_WIDTH_GLOBAL %][% IF CENTER %]\centering
[% END %][% IF LEFT %]\raggedright
[% END %][% IF RIGHT %]\raggedleft
[% END %][% IF CAPTION_TOP %][% IF CAPTION %]\[% CAPTION_CMD %][% IF SHORTCAPTION %][[% SHORTCAPTION %]][% END %]{[% CAPTION %]}
[% END %][% END %][% END %][% EXTRA_ROW_HEIGHT %][% BEGIN_RESIZEBOX%]\begin{[% TABULAR_ENVIRONMENT %]}[% IF WIDTH %]{[% WIDTH %]}[% END %]{[% COLDEF %]}
[% RULES_COLOR_GLOBAL %][% HEADER_CODE %][% DATA_CODE %]\end{[% TABULAR_ENVIRONMENT %]}[% END_RESIZEBOX %][% IF ENVIRONMENT %][% UNLESS CAPTION_TOP %][% IF CAPTION %]
\[% CAPTION_CMD %][% IF SHORTCAPTION %][[% SHORTCAPTION %]][% END %]{[% CAPTION %]}[% END %][% END %][%IF LABEL %]
\label{[% LABEL %]}[% END %]
\end{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% END %]
EOT
;

has '+_tabular_environment' => (default => 'tabular');
has '+_template'    => (default => $template);

1;

__END__

=head1 NAME

LaTeX::Table::Types::Std - Create standard LaTeX tables.

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
