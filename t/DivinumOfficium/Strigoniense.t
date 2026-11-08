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
like($ferial_lauds, qr/Hétköznap ~ Rendes/, 'Hungarian ferial Lauds uses the generic ordinary heading');
like($ferial_lauds, qr/Kérjük, vegye figyelembe/, 'Hungarian pages show a localized Strigoniense warning');
unlike($ferial_lauds, qr/Please note that the database for this version/, 'Hungarian pages do not show the English Strigoniense warning');
unlike($ferial_lauds, qr/Per Annum/, 'Hungarian ferial Lauds does not use a Per Annum source label');

my $little_hour = strig_page('11-02-2026', 'prayTertia', 'Magyar');
like($little_hour, qr/Vezess engem, Uram\./, 'Hungarian ferial Terce uses the short antiphon');
like($little_hour, qr/Vezess engem, Uram, a te parancsolataid ösvényén!/, 'Hungarian ferial Terce uses the full antiphon');
like($little_hour, qr/Olvasmány, válaszos ének, vers \{a zsoltáros részből az adott napra\}/, 'Hungarian ferial Terce labels the capitulum as ordinary psalter text');
unlike($little_hour, qr/Per Annum/, 'Hungarian ferial Terce does not use a Per Annum source label');

my $ferial_prime = strig_page('11-02-2026', 'prayPrima', 'Latin');
like($ferial_prime, qr/Capitulum Responsorium Versus \{ex Psalterio secundum diem\}/, 'Prime labels the capitulum as ordinary psalter text');
like($ferial_prime, qr/Lectio brevis \{ex Psalterio secundum diem\}/, 'Prime labels the short reading as ordinary psalter text');
unlike($ferial_prime, qr/Per Annum/, 'Prime does not use a Per Annum source label');

my $first_vespers = strig_page('11-07-2026', 'prayVespera', 'Magyar');
like($first_vespers, qr/Ülj az én jobbomra\./, 'Saturday first Vespers uses the short Sunday antiphon');
like($first_vespers, qr/Ülj az én jobbomra, mondá az Úr az én Uramnak\./, 'Saturday first Vespers uses the full Sunday antiphon');
unlike($first_vespers, qr/Áldott az Úr, az én kősziklám/, 'Saturday first Vespers does not use the Saturday psalter');
like($first_vespers, qr/Vasárnap ~ Rendes/, 'Saturday first Vespers has the ordinary Sunday heading and rank');
unlike($first_vespers, qr/Szombat ~ Rendes/, 'Saturday first Vespers does not use the Saturday heading and rank');

my $sunday_vespers = strig_page('11-08-2026', 'prayVespera', 'Latin');
like($sunday_vespers, qr/Sede a dextris meis/, 'Sunday Vespers uses the Strigoniense Sunday psalter');
unlike($sunday_vespers, qr/ferial psalm sets agree/, 'Sunday Vespers does not render source comments as antiphons');
like($sunday_vespers, qr/Dominica ~ Ordinarium/, 'Sunday Vespers uses the generic ordinary heading');
like($sunday_vespers, qr/Please note that the database for this version/, 'Latin pages show the Strigoniense warning');
unlike($sunday_vespers, qr/Per Annum/, 'Sunday Vespers does not use a Per Annum source label');

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

my $hungarian_matins = strig_page('11-02-2026', 'prayMatutinum', 'Magyar');
like($hungarian_matins, qr/a matutinum ebben a verzióban még nem érhető el/, 'Hungarian Matins shows a localized notice');
unlike($hungarian_matins, qr/Matins is not yet available/, 'Hungarian Matins does not show the English notice');

# One combined request per day and language exercises every day hour from the
# same office.  The expected orations and canticle antiphons follow the
# Strigoniense ferial cycle; Saturday Vespers is already the first Vespers of
# Sunday, so it must use the Sunday texts.
my @matrix = (
  {
    date => '11-08-2026',
    latin => {
      laudes     => 'Vox nostra te, Dómine, semper deprecétur',
      vespera    => 'Víncula, Dómine, quǽsumus, humánæ pravitátis abrúmpe',
      ant_laudes => 'Allelúia, allelúia, allelúia.',
      ant_vespera => 'Tua est poténtia, tuum regnum, Dómine',
    },
    magyar => {
      laudes     => 'A mi hangunk, Urunk, mindig hozzád fohászkodjék',
      vespera    => 'Törd le, kérünk, Urunk, az emberi hitványság bilincseit',
      ant_laudes => 'Alleluja, alleluja, alleluja.',
      ant_vespera => 'Tiéd a hatalom, tiéd az ország, Urunk',
    },
    forbidden => [qr/Famíliam tuam/],
  },
  {
    date => '11-09-2026',
    latin => {
      laudes     => 'Vide, Dómine, infirmitátes nostras',
      vespera    => 'Esto nobis propítius, Deus',
      ant_laudes => 'Benedíctus Deus Israel.',
      ant_vespera => 'Magníficat ánima mea Dóminum',
    },
    magyar => {
      laudes     => 'Lásd meg, Urunk, a mi gyöngeségeinket',
      vespera    => 'Légy kegyelmes hozzánk, Isten',
      ant_laudes => 'Áldott az Úr, Izráel Istene.',
      ant_vespera => 'Magasztalja az én lelkem az Urat',
    },
    forbidden => [
      qr/Domum tuam, Dómine/,
      qr/Bene fundáta est/,
      qr/O quam metuéndus est/,
    ],
  },
  {
    date => '11-10-2026',
    latin => {
      laudes     => 'Céléri nobis, quǽsumus, Dómine',
      vespera    => 'Absólve, Dómine, quǽsumus, nostrórum víncula peccatórum',
      ant_laudes => 'Eréxit Dóminus nobis cornu salútis',
      ant_vespera => 'Exsúltet spíritus meus in Dómino',
    },
    magyar => {
      laudes     => 'Siess, kérünk, Urunk, kegyességeddel megsegíteni minket',
      vespera    => 'Oldd föl, Urunk, kérünk, a mi vétkeink bilincseit',
      ant_laudes => 'Fölemelte nékünk az Isten az üdvösség erejét',
      ant_vespera => 'Örvendezik az én lelkem üdvözítő Istenemben.',
    },
    forbidden => [],
  },
  {
    date => '11-11-2026',
    latin => {
      laudes     => 'Clamántes ad te, Deus, dignánter exáudi',
      vespera    => 'Tua nos, quǽsumus, grátia semper et prævéniat et sequátur',
      ant_laudes => 'Salútem ex inimícis nostris',
      ant_vespera => 'Respéxit Dóminus humilitátem meam',
    },
    magyar => {
      laudes     => 'Méltóztassál, Isten, meghallani a hozzád kiáltók szavát',
      vespera    => 'Járjon előttünk, kérjük, Urunk, és kísérjen a te malasztod',
      ant_laudes => 'Adj szabadulást ellenségeinktől',
      ant_vespera => 'Megláttad kicsinységemet, Uram.',
    },
    forbidden => [qr/beát[ui] Martín/, qr/Martínus Ábrahæ/],
  },
  {
    date => '11-12-2026',
    latin => {
      laudes     => 'Tuére nos, supérne moderátor',
      vespera    => 'Aufer a nobis, quǽsumus, Dómine, pravitátes',
      ant_laudes => 'In sanctitáte servíámus Dómino',
      ant_vespera => 'Fac, Deus, poténtiam in bráchio tuo',
    },
    magyar => {
      laudes     => 'Vigyázz reánk, mennyei parancsolónk',
      vespera    => 'Vedd el tőlünk, kérjük, Urunk, a hitványságot',
      ant_laudes => 'Szolgáljunk az Úrnak szentségben',
      ant_vespera => 'Cselekedjél, Isten, hatalmasságot',
    },
    forbidden => [qr/beáti Martíni Mártyris/, qr/Volo Pater/],
  },
  {
    date => '11-13-2026',
    latin => {
      laudes     => 'Oculi nostri ad te, Dómine, semper inténdant',
      vespera    => 'Pórrige nobis, Deus, déxteram tuam',
      ant_laudes => 'Per víscera misericórdiæ Dei nostri',
      ant_vespera => 'Depósuit poténtes, sanctos persequéntes',
    },
    magyar => {
      laudes     => 'Szemeink, Urunk, mindig terád figyelmezzenek',
      vespera    => 'Nyújtsd ki nekünk, Isten, a te jobbodat',
      ant_laudes => 'Irgalmának mélységei által',
      ant_vespera => 'Letette a kevélyeket, szentek üldözőit',
    },
    forbidden => [qr/Beáta Mater et intácta Virgo/],
  },
  {
    date => '11-14-2026',
    latin => {
      laudes     => 'Inténde, Dómine, quǽsumus, súpplices tuos',
      vespera    => 'Víncula, Dómine, quǽsumus, humánæ pravitátis abrúmpe',
      ant_laudes => 'Illumináre, Dómine, his, qui in ténebris sedent',
      ant_vespera => 'Tua est poténtia, tuum regnum, Dómine',
    },
    magyar => {
      laudes     => 'Figyelmezz, kérjük, Urunk, a hozzád esdeklőkre',
      vespera    => 'Törd le, kérünk, Urunk, az emberi hitványság bilincseit',
      ant_laudes => 'Világosítsd meg azokat, Urunk',
      ant_vespera => 'Tiéd a hatalom, tiéd az ország, Urunk',
    },
    forbidden => [
      qr/semper rationabília meditántes/,
      qr/Iniquitátes nostras ne respícias/,
    ],
  },
);

my @headings = (
  'Ad Laudes', 'Ad Primam', 'Ad Tertiam', 'Ad Sextam', 'Ad Nonam',
  'Ad Vesperas', 'Ad Completorium',
);

my %ordinary_heading = (
  '11-08-2026' => { Latin => 'Dominica ~ Ordinarium', Magyar => 'Vasárnap ~ Rendes' },
  '11-09-2026' => { Latin => 'Feria ~ Ordinarium',    Magyar => 'Hétköznap ~ Rendes' },
  '11-10-2026' => { Latin => 'Feria ~ Ordinarium',    Magyar => 'Hétköznap ~ Rendes' },
  '11-11-2026' => { Latin => 'Feria ~ Ordinarium',    Magyar => 'Hétköznap ~ Rendes' },
  '11-12-2026' => { Latin => 'Feria ~ Ordinarium',    Magyar => 'Hétköznap ~ Rendes' },
  '11-13-2026' => { Latin => 'Feria ~ Ordinarium',    Magyar => 'Hétköznap ~ Rendes' },
  '11-14-2026' => { Latin => 'Sabbato ~ Ordinarium',  Magyar => 'Szombat ~ Rendes' },
);

my %ordinary_source = (
  Latin  => 'ex Psalterio secundum diem',
  Magyar => 'a zsoltáros részből az adott napra',
);

for my $case (@matrix) {
  for my $lang (qw(Latin Magyar)) {
    my $expected = $case->{lc $lang};
    my $page = strig_page(
      $case->{date},
      'prayLaudesPrimaTertiaSextaNonaVesperaCompletorium',
      $lang,
    );
    my $label = "$case->{date} $lang";

    for my $heading (@headings) {
      like($page, qr/\Q$heading\E/, "$label renders $heading");
    }

    like(
      $page, qr/\Q$ordinary_heading{$case->{date}}{$lang}\E/,
      "$label uses the generic ordinary heading with no inherited rank",
    );
    my $source_label = '{' . $ordinary_source{$lang} . '}';
    like(
      $page, qr/\Q$source_label\E/,
      "$label labels its ordinary text as the daily psalter",
    );
    unlike($page, qr/Per Annum/, "$label has no Per Annum source label");
    unlike(
      $page, qr/\{ex Proprio (?:de Tempore|Sanctorum)\}/,
      "$label has no Tridentine proper source label",
    );
    unlike(
      $page, qr/\{ex Commune aut Festo\}/,
      "$label has no Tridentine common source label",
    );

    like(
      $page, qr/\Q$expected->{laudes}\E/,
      "$label Lauds uses the Strigoniense ferial oration",
    );
    like(
      $page, qr/\Q$expected->{vespera}\E/,
      "$label Vespers uses the Strigoniense ferial oration"
        . ($case->{date} eq '11-14-2026' ? ' (first Vespers of Sunday)' : ''),
    );
    like(
      $page, qr/\Q$expected->{ant_laudes}\E/,
      "$label Lauds uses the Strigoniense canticle antiphon",
    );
    like(
      $page, qr/\Q$expected->{ant_vespera}\E/,
      "$label Vespers uses the Strigoniense canticle antiphon",
    );

    unlike($page, qr/Mart[íi]n/, "$label has no St Martin proper");
    unlike($page, qr/Márton/, "$label has no Hungarian St Martin proper");
    unlike(
      $page, qr/Sancta María, succúrre míseris/,
      "$label has no Tridentine Marian suffrage",
    );
    unlike(
      $page, qr/Szűz Mária \* győzd le nyomorúságunkat/,
      "$label has no Hungarian Tridentine Marian suffrage",
    );
    unlike(
      $page, qr/Suffragium \{Tridentinum\}/,
      "$label does not retain a Tridentine suffrage label",
    );
    unlike(
      $page, qr/Közbenjárás kérése \{tridenti\}/,
      "$label does not retain a Hungarian Tridentine suffrage label",
    );

    for my $forbidden (@{$case->{forbidden}}) {
      unlike(
        $page, $forbidden,
        "$label does not use the forbidden Tridentine proper text $forbidden",
      );
    }
  }
}

done_testing;
