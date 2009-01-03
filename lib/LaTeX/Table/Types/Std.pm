#############################################################################
#   $Author: markus $
#     $Date: 2009-01-03 12:42:28 +0100 (Sat, 03 Jan 2009) $
# $Revision: 1256 $
#############################################################################

package LaTeX::Table::Types::Std;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1256 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
[% COLORDEF %][% IF ENVIRONMENT %]\begin{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% IF POSITION %][[% POSITION %]][% END %]
[% SIZE %][% IF CENTER %]\centering
[% END %][% IF LEFT %]\raggedright
[% END %][% IF RIGHT %]\raggedleft
[% END %][% IF CAPTION_TOP %][% IF CAPTION %]\[% CAPTION_CMD %][% IF CAPTION_SHORT %][[% CAPTION_SHORT %]][% END %]{[% CAPTION %]}
[% END %][% END %][% END %][% EXTRA_ROW_HEIGHT %][% BEGIN_RESIZEBOX%]\begin{[% TABULAR_ENVIRONMENT %]}[% IF WIDTH %]{[% WIDTH %]}[% END %]{[% COLDEF %]}
[% HEADER_CODE %][% BODY %]\end{[% TABULAR_ENVIRONMENT %]}[% END_RESIZEBOX %][% IF ENVIRONMENT %][% UNLESS CAPTION_TOP %][% IF CAPTION %]
\[% CAPTION_CMD %][% IF CAPTION_SHORT %][[% CAPTION_SHORT %]][% END %]{[% CAPTION %]}[% END %][% END %][%IF LABEL %]
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
