#############################################################################
#   $Author: markus $
#     $Date: 2008-11-04 22:44:22 +0100 (Tue, 04 Nov 2008) $
# $Revision: 1151 $
#############################################################################

package LaTeX::Table::Themes::Classic;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1151 $' =~ m{ \$Revision: \s+ (\S+) }xms;

sub _definition {
    my $themes = {
        'Dresden' => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_CENTERED'    => 1,
            'CAPTION_FONT_STYLE' => 'bf',
            'VERTICAL_LINES'     => [ 1, 2, 1 ],
            'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
            'BOOKTABS'           => 0,
        },
        'Houston' => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_CENTERED'    => 1,
            'CAPTION_FONT_STYLE' => 'bf',
            'VERTICAL_LINES'     => [ 1, 2, 1 ],
            'HORIZONTAL_LINES'   => [ 1, 2, 1 ],
            'EXTRA_ROW_HEIGHT'   => '1pt',
            'BOOKTABS'           => 0,
        },
        'Berlin' => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_CENTERED'    => 1,
            'CAPTION_FONT_STYLE' => 'bf',
            'VERTICAL_LINES'     => [ 1, 1, 1 ],
            'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
            'BOOKTABS'           => 0,
        },
        'Miami' => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_CENTERED'    => 1,
            'CAPTION_FONT_STYLE' => 'bf',
            'STUB_ALIGN'         => 'l',
            'VERTICAL_LINES'     => [ 0, 0, 0 ],
            'HORIZONTAL_LINES'   => [ 0, 1, 0 ],
            'BOOKTABS'           => 0,
        },
        'plain' => {
            'STUB_ALIGN'         => 'l',
            'VERTICAL_LINES'   => [ 0, 0, 0 ],
            'HORIZONTAL_LINES' => [ 0, 0, 0 ],
            'BOOKTABS'         => 0,
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Classic - Classic LaTeX table themes.

=head1 PROVIDES

This module provides following themes:

  Berlin
  Dresden
  Houston
  Miami
  plain

=head1 REQUIRES

The themes defined in this module require no additional LaTeX packages.

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
