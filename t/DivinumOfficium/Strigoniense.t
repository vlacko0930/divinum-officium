use strict;
use warnings;
use utf8;

use Encode qw(decode);
use FindBin qw($RealBin);
use Test2::V0;

# These tests exercise the day-hour CGI end to end.  The Strigoniense office is
# temporarily an ordinary-time overlay, so the checks focus on its invariant
# texts rather than on a proper or calendar that does not exist yet.
chdir "$RealBin/../.." or die "Cannot chdir to repository root: $!";

sub strig_page {
  my ($date, $command, $lang) = @_;

  my $query = join '&',
    "date1=$date",
    'version=Strigoniense%20Tridentinum%201570',
    "lang1=$lang",
    "lang2=$lang",
    'votive=Hodie',
    'dioecesis=Generale',
    "command=$command";

  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{QUERY_STRING}   = $query;

  my $html = qx{perl web/cgi-bin/horas/Pofficium.pl 2>/dev/null};
  is($? >> 8, 0, "CGI succeeds for $date $command $lang");
  $html = decode('UTF-8', $html);

  # Strip markup for text assertions.  The renderer splits small capitals
  # such as the initial of an oration into separate elements.
  $html =~ s/<[^>]*>//g;
  $html =~ s/&nbsp;/ /g;
  $html =~ s/&amp;/&/g;
  $html =~ s/\s+/ /g;

  return $html;
}

my $ferial_lauds = strig_page('11-02-2026', 'prayLaudes', 'Magyar');
like($ferial_lauds, qr/Könyörülj rajtam\./, 'Hungarian ferial Lauds uses the short antiphon before the psalm');
like($ferial_lauds, qr/Könyörülj rajtam, Isten!/, 'Hungarian ferial Lauds uses the full antiphon after the psalm');
like($ferial_lauds, qr/Lásd meg, Urunk, a mi gyöngeségeinket/, 'Hungarian ferial Lauds uses the Strigoniense oration');

my $little_hour = strig_page('11-02-2026', 'prayTertia', 'Magyar');
like($little_hour, qr/Vezess engem, Uram\./, 'Hungarian ferial Terce uses the short antiphon');
like($little_hour, qr/Vezess engem, Uram, a te parancsolataid ösvényén!/, 'Hungarian ferial Terce uses the full antiphon');

my $first_vespers = strig_page('11-07-2026', 'prayVespera', 'Magyar');
like($first_vespers, qr/Ülj az én jobbomra\./, 'Saturday first Vespers uses the short Sunday antiphon');
like($first_vespers, qr/Ülj az én jobbomra, mondá az Úr az én Uramnak\./, 'Saturday first Vespers uses the full Sunday antiphon');
unlike($first_vespers, qr/Áldott az Úr, az én kősziklám/, 'Saturday first Vespers does not use the Saturday psalter');

my $sunday_vespers = strig_page('11-08-2026', 'prayVespera', 'Latin');
like($sunday_vespers, qr/Sede a dextris meis/, 'Sunday Vespers uses the Strigoniense Sunday psalter');
unlike($sunday_vespers, qr/ferial psalm sets agree/, 'Sunday Vespers does not render source comments as antiphons');

my $christmas = strig_page('12-25-2026', 'prayLaudes', 'Latin');
like($christmas, qr/Oculi nostri ad te, Dómine/, 'Christmas uses the ordinary ferial oration');
unlike($christmas, qr/Christus natus est nobis/, 'Christmas does not use the Tridentine Christmas proper');

my $christmas_terce = strig_page('12-25-2026', 'prayTertia', 'Latin');
like($christmas_terce, qr/Deduc me, Dómine/, 'Christmas Terce uses the Strigoniense ferial psalter');
unlike($christmas_terce, qr/Génuit puérpera/, 'Christmas Terce does not use the Tridentine proper antiphon');

my $all_saints = strig_page('11-01-2026', 'prayLaudes', 'Latin');
like($all_saints, qr/Vox nostra te, Dómine, semper deprecétur/, 'All Saints uses the ordinary Sunday oration');
unlike($all_saints, qr/Vidi turbam magnam/, 'All Saints does not use the Tridentine proper');

my $compline = strig_page('11-02-2026', 'prayCompletorium', 'Magyar');
like($compline, qr/Védj meg minket\./, 'Hungarian Compline uses the short Nunc dimittis antiphon');
like($compline, qr/Védj meg minket, Uram, amikor virrasztunk, őrizz minket, amikor alszunk, hogy Krisztusban virrasszunk és békességben nyugodjunk\./, 'Hungarian Compline uses the full Nunc dimittis antiphon');
unlike($compline, qr/Salva nos, Dómine/, 'Hungarian Compline does not use the Latin antiphon');

my $matins = strig_page('11-02-2026', 'prayMatutinum', 'Latin');
like($matins, qr/Matins is not yet available/, 'Strigoniense Matins shows an explicit notice');
unlike($matins, qr/Veníte, exsultémus/, 'Strigoniense Matins does not fall back to the Tridentine invitatory');

done_testing;
