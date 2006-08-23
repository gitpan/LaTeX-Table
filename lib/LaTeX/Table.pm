package LaTeX::Table;

use version; $VERSION = qv('0.0.1');

use warnings;
use strict;
use Carp;
use Fatal qw( open close );

use English qw( -no_match_vars );
use Regexp::Common;

use Class::Std;
{

    my %filename : ATTR( :name<filename> :default('latextable.tex') );
    my %label : ATTR( :name<label> :default('latextableperl') );
    my %type : ATTR( :name<type> :default('std') );
    my %maincaption : ATTR( :name<maincaption> :default (0) );
    my %caption : ATTR( :name<caption> :default('') );
    my %tabledef : ATTR( :name<tabledef> :default(0) );
    my %theme : ATTR( :name<theme> :default('Dresden') );
    my %predef_themes : ATTR( :get<predef_themes> );
    my %custom_themes : ATTR( :get<custom_themes> :set<custom_themes> );
    my %tablepos : ATTR( :name<tablepos> :default(0) );
    my %center : ATTR( :name<center> :default(1) );
    my %size : ATTR( :name<size> :default(0) );
    my %tabletailmsg : ATTR( :name<tabletailmsg> :default('Continued on next page') );
    my %tabletail : ATTR( :name<tabletail> :default(0) );
    my %xentrystretch : ATTR( :name<xentrystretch> :default(0) );

    ###########################################################################
    # Usage      : $table->generate_string(\@header, \@data);
    # Purpose    : generates LaTex data
    # Returns    : code
    # Parameters : data columns
    # Throws     : 
    # Comments   : n/a
    # See also   :

    sub generate_string {
        my ( $self, $header, $data ) = @_;
        my $code = '';
        $code = $self->_header($header, $data);
        
        my $theme  = $self->_get_theme_settings;
        my $hlines = $theme->{'HORIZONTAL_LINES'};
        my $h0     = "\\hline\n" x $hlines->[0];
        my $h2     = "\\hline\n" x $hlines->[2];
        my $i      = 0;
    ROW:
        foreach my $row (@$data) {
            $i++;
            my @cols = @$row;
            if ( !@cols ) {
                $code .= "\\hline\n";
                next ROW;
            }
            else {
                $code .= join( '&', @cols ) . "\\\\ \n";
                if ( $i == scalar(@$data) ) {
                    $code .= $h0;
                }
                else {
                    $code .= $h2;
                }
            }
        }
        $code .= $self->_footer();
        return $code;
    }
    
    sub generate {
        my ( $self, $header, $data ) = @_;
        my $code = $self->generate_string($header, $data);
        open my $LATEX, '>', $self->get_filename;
        print $LATEX $code;
        close $LATEX;
        return 1;
    }

    ###########################################################################
    # Usage      : $self->_header(\@header,\@data);
    # Purpose    : create the LaTeX header  
    # Returns    : LaTeX code
    # Parameters : header and data columns
    # Throws     : 
    # Comments   : n/a
    # See also   : _footer
    
    sub _header {
        my ( $self, $header, $data ) = @_;
        my $table_def = $self->_get_tabledef_code($data);
        $table_def = $self->get_tabledef if $self->get_tabledef;
        my $pos    = $self->_get_tablepos_code();
        my $code   = $self->_get_header_columns_code($header);

        my $center = '';
        $center = '\center' if $self->get_center;
        my $size = $self->_get_size_code();
        my $caption = $self->_get_caption_code();
        my $label   = $self->get_label;

        my $tabletail = $self->_get_tabletail_code($data, 0);
        my $tabletaillast = $self->_get_tabletail_code($data, 1);
        
        my $xentrystretch = '';
        if ($self->get_xentrystretch) {
            my $xs = $self->get_xentrystretch();
            croak("xentrystretch not a number") if $xs !~ $RE{num}{real};
            $xentrystretch = "\\xentrystretch{$xs}";
        }    

        if ($self->get_type eq 'xtab') {
            return <<EOXT
        {
        $size
        $center
        $caption
        $xentrystretch
        \\label{$label}
          \\tablehead{$code}
          $tabletail
          $tabletaillast
         \\begin{xtabular}{$table_def}
EOXT
        }
        else {
            return <<EOST
    \\begin{table}$pos
    $size
	$center
    \\begin{tabular}{$table_def}
    $code
EOST
            ;
        }        
    }

    ###########################################################################
    # Usage      : $self->_footer();
    # Purpose    : create the LaTeX footer
    # Returns    : LaTeX code
    # Parameters : none
    # See also   : _header
    
    sub _footer {
        my ($self)  = @_;
        my $label   = $self->get_label;
        my $caption = $self->_get_caption_code();
        if ($self->get_type eq 'xtab') {
            return <<EOXT
    \\end{xtabular}
    } 
EOXT
        }
        else {
            return <<EOST
\\end{tabular}
 $caption
  \\label{$label}
\\end{table} 
EOST
            ;
        }        
    }
    
    ###########################################################################
    # Usage      : $self->_get_data_summary(\@data);
    # Purpose    : find out how many columns we need and if column consists of
    #              numbers only 
    # Returns    : an array with one entry for every column. Entry is either 1
    #              (column is numerical) or 0. 
    # Parameters : data columns
    # Throws     : 
    # Comments   : n/a
    # See also   :

    sub _get_data_summary {
        my ( $self, $data ) = @_;
        my @max_row;
        my %is_a_number;
        my %not_a_number;
        foreach my $row (@$data) {
            if (scalar(@$row) > scalar(@max_row)) {
                @max_row = @$row;
            }
            my $i = 0;
            foreach my $col (@$row) {
                if ($col =~ $RE{num}{real}) {
                    $is_a_number{$i}++;
                } 
                else {
                    $not_a_number{$i}++;
                }
                $i++;
            }
        }
        my @summary;
        for my $i ( 0 .. $#max_row ) {
            my $number = 0;
            if (defined $is_a_number{$i} && !defined $not_a_number{$i}) {
                $number = 1;
            }
            push @summary, $number;
        }
        return @summary;
    }
    
    ###########################################################################
    # Usage      : $self->_get_header_columns_code(\@header);
    # Purpose    : generate the header LaTeX code
    # Returns    : LaTeX code
    # Parameters : header columns
    # Throws     : 
    # Comments   : n/a
    # See also   : _get_row_code

    sub _get_header_columns_code {
        my ( $self, $header ) = @_;
        my $code   = '';
        my $theme  = $self->_get_theme_settings;
        my $hlines = $theme->{'HORIZONTAL_LINES'};
        $code .= "\\hline\n" x $hlines->[0];

        foreach my $row (@$header) {
            my @cols = @$row;

            if ( defined $theme->{'HEADER_CENTERED'}
                && $theme->{'HEADER_CENTERED'} )
            {
                my $vlines = $theme->{'VERTICAL_LINES'};

                my $v0 = '|' x $vlines->[0];
                my $v1 = '|' x $vlines->[1];
                my $v2 = '|' x $vlines->[2];

                my $i = 0;
                foreach my $col (@cols) {
                    my $align;
                    if ( $i == 0 ) {
                        $align = $v0 . 'c' . $v1;
                    }
                    elsif ( $i == ( scalar(@cols) - 1 ) ) {
                        $align = 'c' . $v0;
                    }
                    else {
                        $align = 'c' . $v2;
                    }
                    $col = $self->_add_mc_def(
                        { value => $col, align => $align, cols => '1' } );
                    $i++;
                }
            }

            if ( defined $theme->{'HEADER_FONT_STYLE'} ) {
                foreach my $col (@cols) {
                    $col = $self->_add_font_family( $col,
                        $theme->{'HEADER_FONT_STYLE'} );
                }
            }

            $code .= $self->_get_row_code(@cols);
        }
        $code .= "\\hline\n" x $hlines->[1];
        return $code;
    }
    
    ###########################################################################
    # Usage      : $self->_get_row_code(@cols);
    # Purpose    : generate the LaTeX code of a row
    # Returns    : LaTeX code
    # Parameters : the columns
    # Throws     : 
    # Comments   : n/a
    # See also   :

    sub _get_row_code {
        my ( $self, @cols ) = @_;
        my @cols_defs = map { $self->_get_mc_def($_) } @cols;
        @cols = ();
        foreach my $col_def (@cols_defs) {
            if ( defined $col_def->{cols} ) {
                push @cols,
                    '\\multicolumn{'
                    . $col_def->{cols} . '}{'
                    . $col_def->{align} . '}{'
                    . $col_def->{value} . '}';
            }
            else {
                push @cols, $col_def->{value};
            }
        }
        return join( ' & ', @cols ) . "\\\\ \n";
    }

    sub _add_mc_def {
        my ( $self, $arg_ref ) = @_;
        my $def = $self->_get_mc_def( $arg_ref->{value} );
        if ( defined $def->{cols} ) {
            return $arg_ref->{value};
        }
        else {
            return $self->_get_mc_value($arg_ref);
        }
    }

    sub _get_mc_value {
        my ( $self, $def ) = @_;
        if ( defined $def->{cols} ) {
            return $def->{value} . ':' . $def->{cols} . $def->{align};
        }
        else {
            return $def->{value};
        }
    }

    sub _get_mc_def {
        my ( $self, $value ) = @_;
        if ( $value =~ m{ \A (.*)\:(\d)([|clr]+) \z }xms ) {
            return { value => $1, cols => $2, align => $3 };
        }
        else {
            return { value => $value };
        }
    }

    ###############################################################################
    # Usage      : $self->_add_font_family($col_def, 'bf');
    # Purpose    : add font family to value of column definition
    # Returns    : new column definition
    # Parameters : column definition and family (tt, bf, it, sc)
    # Throws     : exception when familiy is not known
    # Comments   : n/a
    # See also   :

    sub _add_font_family {
        my ( $self, $col, $family ) = @_;
        my %know_families = ( tt => 1, bf => 1, it => 1, sc => 1 );
        if ( !defined $know_families{$family} ) {
            croak( "Family not known: $family. Valid families are: "
                    . join( ', ', sort keys %know_families ) );
        }
        my $col_def = $self->_get_mc_def($col);
        $col_def->{value}
            = '\\text' . $family . '{' . $col_def->{value} . '}';
        return $self->_get_mc_value($col_def);
    }
    
    ###########################################################################
    # Usage      : $self->_get_tabledef_code(\@data);
    # Purpose    : generate the LaTeX code of the table definition (e.g.
    #              |l|r|r|r|)
    # Returns    : LaTeX code
    # Parameters : the data columns
    # Throws     : 
    # Comments   : Tries to be intelligent. Hope it is ;)
    # See also   :

    sub _get_tabledef_code {
        my ( $self, $data ) = @_;
        my @cols = $self->_get_data_summary($data);
        my $vlines = $self->_get_theme_settings->{'VERTICAL_LINES'};

        my $v0        = '|' x $vlines->[0];
        my $v1        = '|' x $vlines->[1];
        my $v2        = '|' x $vlines->[2];
        my $table_def = '';
        my $i         = 0;
        foreach my $col (@cols) {

            # align text right, numbers left, first col always left
            my $align = 'l';
            $align = 'r' if $col;

            if ( $i == 0 ) {
                $table_def .= $v0 . 'l' . $v1;
            }
            elsif ( $i == ( scalar(@cols) - 1 ) ) {
                $table_def .= $align . $v0;
            }
            else {
                $table_def .= $align . $v2;
            }
            $i++;
        }
        return $table_def;
    }

    
    ###########################################################################
    # Usage      : $self->_get_tabletail_code(\@data, $last);
    # Purpose    : generates the LaTeX code of the xtab tabletail
    # Returns    : LaTeX code
    # Parameters : the data columns and a flag indicating whether it is the  
    #              code for the last tail (1). 
    # Throws     : 
    # Comments   : n/a
    # See also   :
    
    sub _get_tabletail_code {
        my ( $self, $data, $last ) = @_;

        # if custom table tail is defined, then return it
        if ( $self->get_tabletail ) {
            return $self->get_tabletail;
        }
        
        # else generate default table tail
        
        my @cols = $self->_get_data_summary($data);
        my $nu_cols = scalar @cols;
        my $hlines = $self->_get_theme_settings->{'HORIZONTAL_LINES'};
        my $vlines = $self->_get_theme_settings->{'VERTICAL_LINES'};
        my $linecode .= "\\hline\n" x $hlines->[0];

        my $v0 = '|' x $vlines->[0];
        
        if ( $last ) {
            return "\\tablelasttail{$linecode}";
        }
        return "\\tabletail{$linecode \\multicolumn{$nu_cols}{${v0}r$v0}{{" .
        $self->get_tabletailmsg . "}} \\\\ \n $linecode }"; 
    }

    ###########################################################################
    # Usage      : $self->_get_caption_code();
    # Purpose    : generates the LaTeX code of the caption
    # Returns    : LaTeX code
    # Parameters : none
    # Throws     : 
    # Comments   : n/a
    # See also   :

    sub _get_caption_code {
        my ($self)    = @_;
        my $f_caption = '';
        my $s_caption = '';
        my $theme     = $self->_get_theme_settings;

        if ( $self->get_maincaption ) {
            $f_caption = '[' . $self->get_maincaption . ']';
        }
        my $tmp = $self->get_maincaption . '. ';
        if ( defined $theme->{CAPTION_FONT_STYLE} ) {
            $tmp = $self->_add_font_family( $tmp,
                $theme->{CAPTION_FONT_STYLE} );
        }
        $s_caption = '{' . $tmp . $self->get_caption . '}';
        my $c_caption = 'caption';

        if ( $self->get_type eq 'xtab' ) {
            $c_caption = 'bottomcaption';
        }

        return '\\' . $c_caption . $f_caption . $s_caption;
    }
    
    ###########################################################################
    # Usage      : $self->_get_size_code();
    # Purpose    : generates the LaTeX code of the size (e.g. \small, \large)
    # Returns    : LaTeX code
    # Parameters : none 
    # Throws     : exception if size is not valid
    # Comments   : n/a
    # See also   :
    
    sub _get_size_code {
        my ( $self ) = @_;
        my %valid = ( 'tiny' => 1, 
                      'scriptsize' => 1, 
                      'footnotesize' => 1, 
                      'small' => 1,
                      'normal' => 1,
                      'large' => 1,
                      'Large' => 1,
                      'LARGE' => 1,
                      'huge' => 1,
                      'Huge' => 1,
                     );
        my $size = $self->get_size;             
        return '' if !$size;
        
        if (!defined $valid{$size}) {
            croak( "Size not known: $size. Valid sizes are: "
                    . join( ', ', sort keys %valid ) );
        }  
        return "\\$size";
    }

    ###########################################################################
    # Usage      : $self->_get_tablepos_code();
    # Purpose    : generates the LaTeX code of the table position (e.g. [htb])
    # Returns    : LaTeX code
    # Parameters : none 
    # Throws     : 
    # Comments   : n/a
    # See also   :

    sub _get_tablepos_code {
        my ($self) = @_;
        if ( $self->get_tablepos ) {
            return '[' . $self->get_tablepos . ']';
        }
        else {
            return '';
        }

    }
    
    ###########################################################################
    # Usage      : $self->_get_theme_settings();
    # Purpose    : return an hash reference with all settings of the current
    #              theme 
    # Returns    : see purpose
    # Parameters : none 
    # Throws     : exception if theme is unknown
    # Comments   : n/a
    # See also   : get_available_themes();

    sub _get_theme_settings {
        my ($self) = @_;
        my $themes = $self->get_available_themes;
        if ( defined $themes->{ $self->get_theme } ) {
            return $themes->{ $self->get_theme };
        } 
        else {
            croak('Unknown theme: ' . $self->get_theme);
        }
    }
    
    ###########################################################################
    # Usage      : called by Class::Std
    # Purpose    : initializing themes
    # Parameters : none 
    # See also   : perldoc Class::Std

    sub BUILD {
        my ( $self, $ident, $arg_ref ) = @_;
        $custom_themes{$ident} = {};
        $predef_themes{$ident} = {
            'Dresden' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'     => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'      => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'    => [ 1, 2, 0 ],
            },
            'Houston' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'     => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'      => [ 1, 2, 1 ],
                'HORIZONTAL_LINES'    => [ 1, 2, 1 ],
            },
            'Miami' => {
                'HEADER_FONT_STYLE'  => 'bf',
                'HEADER_CENTERED'     => 1,
                'CAPTION_FONT_STYLE' => 'bf',
                'VERTICAL_LINES'      => [ 0, 0, 0 ],
                'HORIZONTAL_LINES'    => [ 0, 1, 0 ],
            },
        };
        return;
    }
    
    ###########################################################################
    # Usage      : $self->get_available_themes();
    # Purpose    : return an hash reference with all available themes
    #              (predefined and custom)
    # Returns    : see purpose
    # Parameters : none 
    # Throws     : no exceptions
    # Comments   : n/a
    # See also   : _get_theme_settings()

    sub get_available_themes {
        my ($self) = @_;
        return { %{ $self->get_predef_themes },
            %{ $self->get_custom_themes } };
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

LaTeX::Table - Perl extension for the automatic generation of LaTeX tables.


=head1 VERSION

This document describes LaTeX::Table version 0.0.1


=head1 SYNOPSIS

  use LaTeX::Table;
  
  my $data = [
  	[ 'Lisa',   '0', '0' ],
  	[ 'Marge',  '0', '1' ],
  	[ 'Homer',  '2', '6' ],
  	[],  # horizontal line
  	[ 'Wiggum', '0', '5' ],
  	[ 'Otto',   '1', '3' ],
  	[ 'Barney', '8', '16' ],
  ];
  
  my $header
  	= [ [ 'Name', 'Beers:2|c|' ], [ '', 'before 4pm', 'after 4pm' ] ];
  
  my $table = LaTeX::Table->new(
  	{   
  	   filename    => 'counter.tex',
  	   caption     => 'Number of beers before and after 4pm.',
  	   maincaption => 'Beer Counter',
  	   label       => 'table_beercounter',
  	   theme       => 'Houston',
	   tablepos    => 'htb',
  	}
  );
  
  # write LaTeX code in counter.tex
  $table->generate( $header, $data );
  
  
=head1 DESCRIPTION

LaTeX::Table provides functionality for an intuitive and easy generation of
LaTeX tables for reports or theses. It ships with some predefined good looking
table styles. Supports multipage tables via the xtab package. 

=head1 INTERFACE 

=over

=item C<my $table = LaTeX::Table-E<gt>new($arg_ref)>

Constructs a LaTeX::Table object. The parameter is an hash reference with
options (see below).

=item C<$table-E<gt>generate($header, $data)>

Generates the LaTeX table code. The two parameters are references to an array
(the rows) of array references (the columns), once for the header and once for
the data. An empty columns array produces an horizontal line (the '\hline' LaTeX
command). The generated LaTeX table can be included in a LaTeX document with
the C<\input> command:
  
  % include counter.tex, generated by LaTeX::Table 
  \input{counter}

=item C<$table-E<gt>generate_string($header, $data)>

Same as generate() but does not create a LaTeX file but returns the LaTex code
as string.

  my $latexcode = $table->generate_string($header, $data);

=item C<$table-E<gt>get_available_themes()>


Returns an hash reference to all available (predefined and customs) themes. 
See L<THEMES> for details.

	foreach my $theme ( keys %{ $table->get_available_themes } ) {
		...
	}


=back

=head2 Options

Options can be defined in the constructor hash reference or with the setter
set_<optionname>. Additionally, getters of the form get_<optionname> are
created.

=over

=item C<filename>

The name of the LaTeX output file. Default is
'latextable.tex'.

=item C<label>

The label of the table. Default is 'latextableperl'. In Latex,
you can then create a reference to the table with \ref{label}.

=item C<type>

Can be either 'std' for the standard LaTeX table or 'xtab' for
a xtabular table for multipage tables. The later requires the xtab
latex-package (\usepackage{xtab} in your LaTeX document). Default is 'std'.

=item C<caption>

The caption of the table. Default is ''.

=item C<maincaption>

If set, then this caption will be displayed in the Table
Listing (\listoftables) and before the C<caption>. Default unset.

=item C<theme>

The name of the theme. Default is 'Dresden'.

=item C<tablepos>

The position of the table, e.g. 'htb'. Default unset.

=item C<center>

Defines whether the table is centered. Default 1 (centered).

=item C<size>

Font size. Valid values are 'tiny', 'scriptsize', 'footnotesize', 'small',
'normal', 'large', 'Large', 'LARGE', 'huge', 'Huge' and 0. Default is 0 (does
not define a font size).

=item C<tabledef>

The table definition, e.g. '|l|r|c|r|'. If unset, LaTeX table tries to guess a
good definition. Columns containing only numbers are right-justified, others
left-justified. Default unset (guess good definition).

=item C<tabletailmsg>

Message at the end of a multipage table. 
Default is 'Continued on next page'. 'xtab' only.

=item C<tabletail>

Custom table tail. 
Default is multicolumn with the tabletailmsg (see above) right-justified. 'xtab' only.

=item C<xentrystretch>

Option for xtab. Play with this option if the number of rows per page is not 
optimal. Requires a number as parameter. Default is 0 (does not use this option).
'xtab' only.

    $table->set_xentrystretch(-0.1);

=item C<predef_themes>

All predefined themes. Getter only.

=item C<custom_themes>

All custom themes. Getter and setter only.


=back

=head1 MULTICOLUMNS 

Multicolumns can be defined in LaTeX with
\multicolumn{#cols}{definition}{text}. Because multicolumn are often needed
and this is way too much code to type, a shortcut was implemented. Now,
text:#colsdefinition is equivalent to original LaTeX code. For example,
Beers:2|c| is equivalent to \multicolumn{2}{|c|}{Beers}. Note that |c|
overrides the LINES settings in the theme (See Custom Themes).

=head1 THEMES

The theme can be selected with $table->set_theme($themename). Currently,
following predefined themes are available: Dresden, Miami, Houston. The
script generate_examples.pl in the examples directory of this distributions
generates some examples for all available themes.

=head2 Custom Themes

Custom themes can be defined with an array reference containing all options
(explained later):

    my $themes = { 
                'Leipzig' => {
                    'HEADER_FONT_STYLE'  => 'sc',
                    'HEADER_CENTERED'     => 1,
                    'CAPTION_FONT_STYLE' => 'sc',
                    'VERTICAL_LINES'      => [ 1, 2, 1 ],
                    'HORIZONTAL_LINES'    => [ 1, 2, 0 ],
                },
            };

    $table->set_custom_themes($themes);

=over 

=item Fonts

C<HEADER_FONT_STYLE>, C<CAPTION_FONT_STYLE>. Valid values are 'bf' (bold),
it (italics), sc (caps) and tt (typewriter).

=item Lines

C<VERTICAL_LINES>, C<HORIZONTAL_LINES>. A reference to an array with three
integers, e.g. [ 1, 2, 0 ]. The first integer defines the number of outer
lines. The second the number of lines after the header and after the first
column. The third is the number of inner lines.

=item Misc

C<HEADER_CENTERED>. Valid values are 0 (not centered) or 1 (centered).

=back

=head1 CONFIGURATION AND ENVIRONMENT

LaTeX::Table requires no configuration files or environment variables.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported. 

Please report any bugs or feature requests to
C<bug-latex-table@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. 

=head2 SPECIAL NOTE FOR FEATURE REQUESTS

There are many limitations. This module does not want to provide 
thousands of useless options. However, if a particular - good looking - 
LaTeX table is not possible to generate with LaTeX::Table, it is 
considered as a bug. Please sent appropriate example LaTeX code to me.
If you think your table theme looks better than the default ones, then 
please let me know your theme settings.

=head1 AUTHOR

Markus Riester  C<< <mriester@gmx.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Markus Riester C<< <mriester@gmx.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
