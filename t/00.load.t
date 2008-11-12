use Test::More tests => 10;
use Test::NoWarnings;

BEGIN {
use_ok( 'LaTeX::Table' );
use_ok( 'LaTeX::Table::Themes::ThemeI' );
use_ok( 'LaTeX::Table::Themes::Beamer' );
use_ok( 'LaTeX::Table::Themes::Classic' );
use_ok( 'LaTeX::Table::Themes::Modern' );
use_ok( 'LaTeX::Table::Types::TypeI' );
use_ok( 'LaTeX::Table::Types::Ctable' );
use_ok( 'LaTeX::Table::Types::Xtab' );
use_ok( 'LaTeX::Table::Types::Std' );
}

diag( "Testing LaTeX::Table $LaTeX::Table::VERSION" );
