#############################################################################
#   $Author: markus $
#     $Date: 2009-01-03 12:55:22 +0100 (Sat, 03 Jan 2009) $
# $Revision: 1257 $
#############################################################################

package LaTeX::Table::Types::Ctable;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1257 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
{[% COLORDEF %][% SIZE %][% EXTRA_ROW_HEIGHT %][% BEGIN_RESIZEBOX%]
\ctable[[% IF CAPTION %]caption = {[% CAPTION %]},
[% IF CAPTION_SHORT %]cap = {[% CAPTION_SHORT %]},
[% END %][% UNLESS CAPTION_TOP %]botcap,
[% END %][% END %][% IF POSITION %]pos = [% POSITION %],
[% END %][% IF LABEL %]label = {[% LABEL %]},
[% END %][% IF MAXWIDTH %]maxwidth = {[% MAXWIDTH %]},
[% END %][% IF WIDTH %]width = {[% WIDTH %]},
[% END %][% IF CENTER %]center,
[% END %][% IF LEFT %]left,
[% END %][% IF RIGHT %]right,
[% END %][% IF SIDEWAYS %]sideways,
[% END %][% IF STAR %]star,
[% END %]]{[% COLDEF %]}{[% FOOTTABLE %]}{
[% HEADER_CODE %][% BODY %]}
[% END_RESIZEBOX %]}
EOT
;

has '+_tabular_environment' => (default => 'tabular');
has '+_template'    => (default => $template);

1;

__END__

=head1 NAME

LaTeX::Table::Types::Ctable - Create LaTeX tables with the ctable package.

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
