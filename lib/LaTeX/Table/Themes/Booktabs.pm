#############################################################################
#   $Author: markus $
#     $Date: 2009-07-13 16:29:59 +0200 (Mon, 13 Jul 2009) $
# $Revision: 1741 $
#############################################################################

package LaTeX::Table::Themes::Booktabs;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1741 $' =~ m{ \$Revision: \s+ (\S+) }xms;

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

Copyright (c) 2006-2009, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
