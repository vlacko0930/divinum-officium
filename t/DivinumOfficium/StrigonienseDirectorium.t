use strict;
use warnings;
use utf8;

BEGIN {
  # Use the real Tabulae data here: this test checks that the Strigoniense
  # row in data.txt and its empty stub files do not fall back to the
  # Tridentine calendar or transfer tables.
  $ENV{DIRECTORIUM_DATA_PATH} = 'web/www/Tabulae';
}

use lib 'web/cgi-bin';
use DivinumOfficium::Directorium qw(get_from_directorium transfered);
use Test2::V0;

my $version = 'Strigoniense Tridentinum 1570';

is(
  get_from_directorium('kalendar', $version, '11-01', 2026), '',
  'Strigoniense has no inherited calendar entry',
);
is(
  get_from_directorium('tempora', $version, '11-11', 2026), '',
  'Strigoniense has no inherited tempora transfer entry',
);
is(
  get_from_directorium('transfer', $version, '11-11', 2026), '',
  'Strigoniense has no inherited transfer entry',
);
is(
  get_from_directorium('stransfer', $version, '11-11', 2026), '',
  'Strigoniense has no inherited scriptura transfer entry',
);
is(
  transfered('Sancti/11-11', 2026, $version), '',
  'Strigoniense does not transfer a Tridentine saint',
);

done_testing;
