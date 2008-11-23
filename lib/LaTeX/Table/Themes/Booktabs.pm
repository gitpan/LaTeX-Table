#############################################################################
#   $Author: markus $
#     $Date: 2008-11-23 01:38:40 +0100 (Sun, 23 Nov 2008) $
# $Revision: 1238 $
#############################################################################

package LaTeX::Table::Themes::Booktabs;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1238 $' =~ m{ \$Revision: \s+ (\S+) }xms;

sub _definition {
    my $themes = {
        'Zurich' => {
            'HEADER_FONT_STYLE' => 'bf',
            'HEADER_CENTERED'   => 1,
            'VERTICAL_LINES'    => [ 0, 0, 0 ],
            'HORIZONTAL_LINES'  => [ 1, 1, 0 ],
            'BOOKTABS'          => 1,
        },
        'Meyrin' => {
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

LaTeX::Table::Themes::Booktabs - Publication quality tables.

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

Copyright (c) 2006-2008, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
