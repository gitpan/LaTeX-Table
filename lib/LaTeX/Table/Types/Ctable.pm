#############################################################################
#   $Author: markus $
#     $Date: 2009-09-07 17:06:22 +0200 (Mon, 07 Sep 2009) $
# $Revision: 1836 $
#############################################################################

package LaTeX::Table::Types::Ctable;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version; our $VERSION = qv('1.0.0');

my $template = <<'EOT'
{[% DEFINE_COLORS_CODE %][% IF FONTSIZE %]\[% FONTSIZE %]
[% END %][% IF FONTFAMILY %]\[% FONTFAMILY %]family
[% END %][% EXTRA_ROW_HEIGHT_CODE %][% RULES_WIDTH_GLOBAL_CODE %][% RESIZEBOX_BEGIN_CODE %]
\ctable[[% IF CAPTION %]caption = {[% CAPTION %]},
[% IF SHORTCAPTION %]cap = {[% SHORTCAPTION %]},
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
[% END %][% IF CONTINUED %]continued = {[% CONTINUEDMSG %]},
[% END %]]{[% COLDEF %]}{[% FOOTTABLE %]}{
[% RULES_COLOR_GLOBAL_CODE %][% HEADER_CODE %][% DATA_CODE %]}
[% RESIZEBOX_END_CODE %]}
EOT
    ;

has '+_tabular_environment' => ( default => 'tabular' );
has '+_template'            => ( default => $template );

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
