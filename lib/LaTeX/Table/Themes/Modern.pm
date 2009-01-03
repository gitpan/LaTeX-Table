#############################################################################
#   $Author: markus $
#     $Date: 2009-01-03 12:42:28 +0100 (Sat, 03 Jan 2009) $
# $Revision: 1256 $
#############################################################################

package LaTeX::Table::Themes::Modern;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version;
our ($VERSION) = '$Revision: 1256 $' =~ m{ \$Revision: \s+ (\S+) }xms;

sub _definition {
    my $themes = {
            'Paris' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'    => 1,
                'HEADER_BG_COLOR'    => 'latextblgray',
                'DEFINE_COLORS'      =>
                '\definecolor{latextblgray}{gray}{0.7}',
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'     => [ 1, 1, 1 ],
                'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
                'BOOKTABS'           => 0,
            },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Modern - Modern LaTeX table themes.

=head1 PROVIDES

This module provides following themes:

  Paris

=head1 REQUIRES

The themes defined in this module requires following LaTeX packages:

  \usepackage{xcolor}

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
