package MyThemes::Custom;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

sub _definition {
    return { 'Erfurt' =>
     {
        'HEADER_FONT_STYLE' => 'sc',
        'HEADER_CENTERED'   => 1,
        'VERTICAL_LINES'    => [ 0, 0, 0 ],
        'HORIZONTAL_LINES'  => [ 1, 1, 0 ],
        'BOOKTABS'          => 1,
    }};
}

1;

# vim: ft=perl sw=4 ts=4 expandtab
