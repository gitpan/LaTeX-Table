#############################################################################
#   $Author: markus $
#     $Date: 2008-11-08 03:31:37 +0100 (Sat, 08 Nov 2008) $
# $Revision: 1199 $
#############################################################################

package LaTeX::Table::Types::Ctable;
use Moose;

with 'LaTeX::Table::Types::TypeI';

use version;
our ($VERSION) = '$Revision: 1199 $' =~ m{ \$Revision: \s+ (\S+) }xms;

my $template =<<'EOT'
{[% COLORDEF %][% SIZE %][% EXTRA_ROW_HEIGHT %][% BEGIN_RESIZEBOX%]
\ctable[[% CAPTION %][% POS %][% LABEL %][% WIDTH %][% BEGIN_CENTER %][% IF SIDEWAYS %]sideways,
[% END %][% IF STAR %]star,
[% END %]]{[% COL_DEF %]}{[% FOOTTABLE %]}{
[% HEADER_CODE %][% BODY %]}
[% END_RESIZEBOX %]
}
EOT
;

has '+_tabular_environment' => (default => 'tabular');
has '+_template'    => (default => $template);

sub _get_caption_code {
    my ( $self, $header ) = @_;
    my $f_caption = q{};
    my $s_caption = q{};
    my $tbl       = $self->_table_obj;
    my $theme     = $tbl->get_theme_settings;
    my $tmp = q{};
    if ( $tbl->get_maincaption ) {
        $f_caption = 'cap = {' . $tbl->get_maincaption . "},\n";
        $tmp       = $tbl->get_maincaption . '. ';
        if ( defined $theme->{CAPTION_FONT_STYLE} ) {
            $tmp = $tbl->_add_font_family( $tmp,
                $theme->{CAPTION_FONT_STYLE} );
        }
    }
    else {
        return q{} if !$tbl->get_caption;
    }
    
    my $b_caption = q{};

    if (!$tbl->get_caption_top) {
        $b_caption = "botcap,\n";
    }

    $s_caption = 'caption = {' . $tmp . $tbl->get_caption . "},\n";

    return $f_caption . $s_caption . $b_caption;
}

sub _get_pos_code {
    my ($self) = @_;
    if ( $self->_table_obj->get_position ) {
        return 'pos = ' . $self->_table_obj->get_position . ",\n";
    }
    else {
        return q{};
    }

}

sub _get_label_code {
    my ($self) = @_;
    my $label = $self->_table_obj->get_label;
    if ($label) {
        return "label = {$label},\n";
    }
    return q{};
}

sub _get_width_code {
    my ($self) =@_;
    my $tbl = $self->_table_obj;

    if ( $tbl->get_width ) {
        return 'width = {' . $tbl->get_width . "},\n";
    }
    return q{};
}

sub _get_begin_center_code {
    my ($self) =@_;
    if ( $self->_table_obj->get_center ) {
        return "center,\n";
    }
    return q{};
}

1;

__END__

=head1 NAME

LaTeX::Table::Types::Ctable - Create tables with the ctable package

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
