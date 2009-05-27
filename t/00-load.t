#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Module::Install::SchemaCheck' );
}

diag( "Testing Module::Install::SchemaCheck $Module::Install::SchemaCheck::VERSION, Perl $], $^X" );
