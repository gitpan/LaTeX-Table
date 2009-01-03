#############################################################################
#   $Author: markus $
#     $Date: 2009-01-03 12:55:22 +0100 (Sat, 03 Jan 2009) $
# $Revision: 1257 $
#############################################################################

package LaTeX::Table::Themes::ThemeI;

use strict;
use warnings;

use Moose::Role;

use version;
our ($VERSION) = '$Revision: 1257 $' =~ m{ \$Revision: \s+ (\S+) }xms;

requires '_definition';

1;

__END__

=head1 NAME

LaTeX::Table::Themes::ThemeI - Interface for LaTeX table themes.

=head1 SYNOPSIS

  package MyThemes::Custom;
  use Moose;
  
  with 'LaTeX::Table::Themes::ThemeI';
  
  sub _definition {
      return { CENTRALPARK =>
       {
          'HEADER_FONT_STYLE'  => 'bf',
          'HEADER_FONT_COLOR'  => 'white',
          'HEADER_BG_COLOR'    => 'latextbl',
          'DATA_BG_COLOR_ODD'  => 'latextbl!25',
          'DATA_BG_COLOR_EVEN' => 'latextbl!10',
          'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{93,127,114}',
          'HEADER_CENTERED'    => 1,
          'VERTICAL_LINES'     => [ 1, 0, 0 ],
          'HORIZONTAL_LINES'   => [ 1, 1, 0 ],
          'BOOKTABS'           => 0,
          'EXTRA_ROW_HEIGHT'   => '1pt',
      }};
  }
  
  1;

  ..
  $table->search_path( add => 'MyThemes');

=head1 DESCRIPTION

This is the theme interface (or L<Moose> role), that all theme objects must use. 

=head1 CREATING THEMES

A theme is defined as an hash reference containing all options:

  # a very ugly theme...
  my $theme = { 
              'Duisburg' => {
                  'HEADER_FONT_STYLE'  => 'sc',
                  'HEADER_FONT_COLOR'  => 'white',
                  'HEADER_BG_COLOR'    => 'blue',
                  'HEADER_CENTERED'    => 1,
                  'DATA_BG_COLOR_ODD'  => 'blue!30',
                  'DATA_BG_COLOR_EVEN' => 'blue!10',
                  'CAPTION_FONT_STYLE' => 'sc',
                  'VERTICAL_LINES'     => [ 1, 2, 1 ],
                  'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
                  'EXTRA_ROW_HEIGHT'   => '2pt',
                  'BOOKTABS'           => 0,
              },
          };


=over 

=item Fonts

C<HEADER_FONT_STYLE>, C<CAPTION_FONT_STYLE>. Valid values are I<bf> (bold),
I<it> (italics), I<sc> (caps) and I<tt> (typewriter). When this option is
undef, then header (or caption, respectively) is written in normal font.

=item Colors

C<HEADER_FONT_COLOR> can be used to specify a different font color for the
header. Requires the C<xcolor> LaTeX package.

Set C<HEADER_BG_COLOR> to use a background color in the header,
C<DATA_BG_COLOR_EVEN> and C<DATA_BG_COLOR_ODD> for even and odd data rows. 
Requires the C<colortbl> and the C<xcolor> LaTeX package. 

You can define colors with C<DEFINE_COLORS>, for example:

  'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',

=item Lines

C<VERTICAL_LINES>, C<HORIZONTAL_LINES>. A reference to an array with three
integers, e.g. C<[ 1, 2, 0 ]>. The first integer defines the number of outer
lines. The second the number of lines after the header and after the first
column. The third is the number of inner lines. For example I<Dresden> is
defined as:

  'Dresden' => {
      ...  
      'VERTICAL_LINES'     => [ 1, 2, 1 ],
      'HORIZONTAL_LINES'   => [ 1, 2, 0 ],
  }

The first integers define one outer line - vertical and horizontal. So a box
is drawn around the table. The second integers define two lines between header
and table and two vertical lines between first and second column. And finally
the third integers define that columns are separated by a single vertical line
whereas rows are not separated by horizontal lines.
            
=item Misc

=over 

=item C<EXTRA_ROW_HEIGHT>

Will set C<\extrarowheight> in the floating environment. Requires the C<array>
LaTeX package.

=item C<STUB_ALIGN> 

Defines how the left-hand column, the stub, is aligned. Default is 'l' (left
aligned).

=item C<HEADER_CENTERED>

This controls the alignment of the header columns, excluding the stub when
C<STUB_ALIGN> is defined. Valid values are 0 (not centered) or 1 (centered).
Typically, it is recommended to center headers, but sometimes this does not
look right. In this case, (left) align the header manually.

=item C<BOOKTABS>

Use the C<booktabs> LaTeX package for "Publication quality tables". Instead of
C<\hline>, C<LaTeX::Table> then uses C<\toprule>, C<\midrule> and
C<\bottomrule>.  0 (don't use this package) or 1 (use it).

=back

=back

You can either quickly add themes after initiation of an L<LaTeX::Table>:
          
  $table->set_custom_themes($theme);

Or, you can build a L<"THEME MODULE"> and extend the list of predefined themes. 

=head1 THEME MODULE 

Now, to build a theme that you can easily load, take the L<"SYNOPSIS">
template, change it and then make it accessible in C<LaTeX::Table> by saving
it under the C<LaTeX::Table::Themes::*> namespace. Alternatively, you can use
the search_path() method to add custom paths. See L<"SYNOPSIS">. If your theme
looks nice, please contribute it.

=head1 SEE ALSO

L<LaTeX::Table>

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2009, Markus Riester C<< <mriester@gmx.de> >>. 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
