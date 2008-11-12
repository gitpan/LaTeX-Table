#############################################################################
#   $Author: markus $
#     $Date: 2008-11-11 04:38:01 +0100 (Tue, 11 Nov 2008) $
# $Revision: 1226 $
#############################################################################

package LaTeX::Table::Themes::Beamer;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1226 $' =~ m{ \$Revision: \s+ (\S+) }xms;

sub _definition {
    my $themes = {
        NYC => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_LINES'     => [ 1, 0, 0 ],
            'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
        },
        NYC2 => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_LINES'     => [ 1, 0, 0 ],
            'HORIZONTAL_LINES'   => [ 1, 0, 0 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Beamer - Colorful themes optimized for presentations.

=head1 PROVIDES

This module provides following themes:

  NYC
  NYC2  # same, but without midline after header

=head1 REQUIRES

The themes defined in this module require following LaTeX packages:

  \usepackage{array}
  \usepackage{colortbl}
  \usepackage{xcolor}

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
