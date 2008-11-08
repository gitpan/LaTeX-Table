#############################################################################
#   $Author: markus $
#     $Date: 2008-11-08 01:43:44 +0100 (Sat, 08 Nov 2008) $
# $Revision: 1197 $
#############################################################################

package LaTeX::Table::Types::Std;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1197 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
[% COLORDEF %][% IF ENVIRONMENT %]\begin{[% IF SIDEWAYS %]sidewaystable[% ELSE
%][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% POS %][% SIZE %][% BEGIN_CENTER %][% HEADER_CAPTION %][% END %][% EXTRA_ROW_HEIGHT %][% BEGIN_RESIZEBOX%]\begin{[% TABULAR_ENVIRONMENT %]}[% WIDTH %]{[% COL_DEF %]}
    [% HEADER_CODE %]
[% BODY %]\end{[% TABULAR_ENVIRONMENT %]}
[% END_RESIZEBOX %][% IF ENVIRONMENT %][% CAPTION %][% LABEL %]\end{[% IF SIDEWAYS %]sidewaystable[% ELSE %][% ENVIRONMENT %][% END %][% IF STAR %]*[% END %]}[% END %]
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

L<LaTeX::Table>, L<LaTeX::Table::Types::TypesI>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2008, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
