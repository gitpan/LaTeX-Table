#############################################################################
#   $Author: markus $
#     $Date: 2010-03-02 11:55:05 +0100 (Tue, 02 Mar 2010) $
# $Revision: 1948 $
#############################################################################

package LaTeX::Table::Themes::Booktabs;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version; our $VERSION = qv('1.0.1');

sub _definition {
    my $themes = {
        'Zurich' => {
            'HEADER_FONT_STYLE' => 'bf',
            'HEADER_CENTERED'   => 1,
            'STUB_ALIGN'        => 'l',
            'VERTICAL_RULES'    => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
            'BOOKTABS'          => 1,
        },
        'Meyrin' => {
            'STUB_ALIGN'       => 'l',
            'VERTICAL_RULES'   => [ 0, 0, 0 ],
            'HORIZONTAL_RULES' => [ 1, 1, 0 ],
            'BOOKTABS'         => 1,
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Booktabs - Publication quality LaTeX table themes.

=head1 PROVIDES

This module provides following themes:

  Meyrin   # as described in the booktabs documentation
  Zurich   # header centered and in bold font

=head1 REQUIRES

The themes defined in this module require following LaTeX packages:

  \usepackage{booktabs}

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Themes::ThemeI>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
