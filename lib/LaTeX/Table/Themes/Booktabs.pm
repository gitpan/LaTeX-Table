#############################################################################
#   $Author: markus $
#     $Date: 2009-01-03 12:55:57 +0100 (Sat, 03 Jan 2009) $
# $Revision: 1258 $
#############################################################################

package LaTeX::Table::Themes::Booktabs;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1258 $' =~ m{ \$Revision: \s+ (\S+) }xms;

sub _definition {
    my $themes = {
        'Zurich' => {
            'HEADER_FONT_STYLE' => 'bf',
            'HEADER_CENTERED'   => 1,
            'STUB_ALIGN'        => 'l',
            'VERTICAL_LINES'    => [ 0, 0, 0 ],
            'HORIZONTAL_LINES'  => [ 1, 1, 0 ],
            'BOOKTABS'          => 1,
        },
        'Meyrin' => {
            'STUB_ALIGN'        => 'l',
            'VERTICAL_LINES'   => [ 0, 0, 0 ],
            'HORIZONTAL_LINES' => [ 1, 1, 0 ],
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

  Zurich   # header centered and in bold font
  Meyrin   # as described in the booktabs documentation

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
