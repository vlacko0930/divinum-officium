use strict;
use warnings;
use utf8;

use FindBin qw($RealBin);
use Test2::V0;

# These checks keep the Strigoniense day-hour data self-contained while the
# proper and calendar are still missing.  The office is allowed to borrow the
# regular Psalterium and the ordinary of the day hours, but it must not reach
# into the Tridentine proper or seasonal files.
chdir "$RealBin/../.." or die "Cannot chdir to repository root: $!";

use lib "$RealBin/../../web/cgi-bin";

{
  no warnings 'once';    # read by SetupString.pl, not by this test
  $main::version     = 'Strigoniense Tridentinum 1570';
  $main::datafolder  = 'web/www/horas';
  $main::langfb      = 'English';
  $main::missa       = 0;
  $main::dayname     = ['Pent01'];
  $main::monthday    = '11-07-2026';
  $main::dayofweek   = 5;
  $main::month       = 11;
  $main::day         = 7;
  $main::year        = 2026;
  $main::hora        = 'Vespera';
  $main::winner      = '';
  $main::dioecesis   = 'Generale';
  $main::votive      = 'Hodie';
}

require './web/cgi-bin/DivinumOfficium/SetupString.pl';

my @langs = qw(Latin Magyar);
my @files = ('Psalmi major', 'Psalmi minor', 'Special');

# Sections the Strigoniense office dispatches to directly.  The Hungarian
# minor-hour hymns are checked separately: Latin deliberately uses the shared
# ordinary for those, while Hungarian carries the 2014 text in Special.txt.
my @major_keys = (
  'Dominica Laudes', 'Dominica Vespera',
  (map { ("Feria$_ Laudes", "Feria$_ Vespera") } 2 .. 6),
  'Sabbato Laudes', 'Sabbato Vespera',
);
my @minor_keys = (
  'Prima Dominica', 'Tertia Dominica', 'Sexta Dominica', 'Nona Dominica',
  'Completorium', 'Feria Prima', 'Feria Tertia', 'Feria Sexta', 'Feria Nona',
);
my @special_keys = (
  'Dominica Laudes', 'Dominica Vespera',
  'Dominica Ant Laudes', 'Dominica Ant Vespera',
  'Dominica Versum 2', 'Dominica Versum 3',
  'Oratio Dominica Laudes', 'Oratio Dominica Vespera',
  'Oratio Dominica Prima', 'Oratio Dominica Tertia',
  'Oratio Dominica Sexta', 'Oratio Dominica Nona',
  'Oratio Completorium',
  'Capitulum Dominica Prima',
  'Dominica Tertia', 'Dominica Sexta', 'Dominica Nona',
  'Completorium', 'Ant 4',
  'Responsory breve Dominica Tertia',
  'Responsory breve Dominica Sexta',
  'Responsory breve Dominica Nona',
  'Versum Dominica Tertia', 'Versum Dominica Sexta', 'Versum Dominica Nona',
  'Feria Laudes', 'Feria Vespera', 'Feria Versum 2', 'Feria Versum 3',
  (map { ("Feria$_ Ant 2", "Feria$_ Ant 3") } 2 .. 6),
  'Sabbato Ant 2', 'Sabbato Ant 3',
  (map { ("Oratio Feria$_ Laudes", "Oratio Feria$_ Vespera") } 2 .. 6),
  'Oratio Sabbato Laudes', 'Oratio Sabbato Vespera',
  'Capitulum Feria Prima',
  'Feria Tertia', 'Feria Sexta', 'Feria Nona',
  'Responsory breve Feria Tertia',
  'Responsory breve Feria Sexta',
  'Responsory breve Feria Nona',
  'Versum Feria Tertia', 'Versum Feria Sexta', 'Versum Feria Nona',
  'Oratio Feria Prima', 'Oratio Feria Tertia',
  'Oratio Feria Sexta', 'Oratio Feria Nona',
  (map { ("Hymnus Day$_ Laudes", "Hymnus Day$_ Vespera") } 0 .. 6),
);
my @hungarian_minor_hymns = (
  'Hymnus Prima', 'Hymnus Tertia', 'Hymnus Sexta', 'Hymnus Nona',
  'Hymnus Completorium',
);

my %required = (
  'Psalmi major' => \@major_keys,
  'Psalmi minor' => \@minor_keys,
  'Special'      => \@special_keys,
);

sub raw_sections {
  my ($path) = @_;

  open my $fh, '<:encoding(UTF-8)', $path
    or die "Cannot read $path: $!";
  my @lines = <$fh>;
  close $fh;

  my (@sections, @comments);
  my $current;
  my $first_section_line;

  for my $i (0 .. $#lines) {
    my $line = $lines[$i];
    chomp $line;

    if ($line =~ /^\s*\[([^\]]+)\]\s*(?:\((.*)\))?\s*$/) {
      my ($name, $condition) = ($1, $2);
      $first_section_line //= $i + 1;
      $current = {
        name      => $name,
        condition => $condition,
        line      => $i + 1,
        lines     => [],
      };
      push @sections, $current;
    } elsif (defined $current) {
      push @{$current->{lines}}, $line;
    }

    push @comments, [$i + 1, $line] if $line =~ /^\s*#/;
  }

  return {
    sections           => \@sections,
    comments           => \@comments,
    first_section_line => $first_section_line,
  };
}

sub section_text {
  my ($section) = @_;
  my $text = join "\n", @{$section->{lines}};
  $text =~ s/^\s+|\s+$//g;
  return $text;
}

sub find_unconditional {
  my ($parsed, $name) = @_;
  for my $section (@{$parsed->{sections}}) {
    return $section
      if $section->{name} eq $name && !defined $section->{condition};
  }
  return undef;
}

sub base_names {
  my ($parsed) = @_;
  my %seen;
  return [
    sort grep { !$seen{$_}++ }
    map { $_->{name} } @{$parsed->{sections}}
  ];
}

my %raw;
my %loaded;

for my $lang (@langs) {
  for my $file (@files) {
    my $path = "web/www/horas/$lang/Psalterium/Strigoniense/$file.txt";
    ok(-f $path, "$lang $file exists");

    my $parsed = raw_sections($path);
    $raw{$lang}{$file} = $parsed;

    ok(
      defined $parsed->{first_section_line},
      "$lang $file has at least one section",
    );

    my $first = $parsed->{first_section_line} // 0;
    my @late_comments =
      grep { $_->[0] > $first } @{$parsed->{comments}};
    is(
      scalar @late_comments, 0,
      "$lang $file has no comment lines inside a section",
    );

    my (%unconditional, %conditional, @duplicates);
    for my $section (@{$parsed->{sections}}) {
      if (defined $section->{condition}) {
        my $id = "$section->{name}\0$section->{condition}";
        push @duplicates, "$section->{name} ($section->{condition})"
          if $conditional{$id}++;
      } else {
        push @duplicates, $section->{name}
          if $unconditional{$section->{name}}++;
      }
    }
    is(
      \@duplicates, [],
      "$lang $file has no duplicate unconditional or conditional sections",
    );

    my @proper_references;
    my @missing_inclusions;
    for my $section (@{$parsed->{sections}}) {
      my $text = section_text($section);
      push @proper_references, "$section->{name}: $1"
        while $text =~ /^\s*\@((?:Tempora|Sancti)\/[^\n]*)/mg;
      push @missing_inclusions, $section->{name}
        if $text =~ /is missing!/;
    }
    is(
      \@proper_references, [],
      "$lang $file does not include the Tridentine proper or seasonal files",
    );
    is(
      \@missing_inclusions, [],
      "$lang $file has no unresolved inclusion markers of its own",
    );

    my $sections =
      setupstring($lang, "Psalterium/Strigoniense/$file.txt");
    ok(
      ref $sections eq 'HASH' && %$sections,
      "$lang $file loads through setupstring",
    );
    $loaded{$lang}{$file} = $sections;

    my @missing =
      sort grep { $sections->{$_} =~ /is missing!/ } keys %$sections;
    is(
      \@missing, [],
      "$lang $file resolves every @-inclusion",
    );
  }
}

for my $lang (@langs) {
  for my $file (@files) {
    for my $key (@{$required{$file}}) {
      my $section = find_unconditional($raw{$lang}{$file}, $key);
      ok(defined $section, "$lang $file has [$key]");

      if ($section) {
        my $text = section_text($section);
        ok(length $text, "$lang $file [$key] is not empty");
        unlike(
          $text, qr/is missing!/,
          "$lang $file [$key] is a real text, not an unresolved inclusion",
        );
      }

      my $resolved = $loaded{$lang}{$file}{$key};
      ok(
        defined $resolved && $resolved =~ /\S/,
        "$lang $file [$key] resolves to a non-empty value",
      );
      unlike(
        $resolved // '', qr/is missing!/,
        "$lang $file [$key] does not resolve to a missing inclusion",
      );
    }
  }
}

for my $key (@hungarian_minor_hymns) {
  my $section = find_unconditional($raw{Magyar}{'Special'}, $key);
  ok(defined $section, "Magyar Special has its own minor-hour hymn [$key]");
  if ($section) {
    ok(length section_text($section),
      "Magyar Special minor-hour hymn [$key] is not empty");
  }
  my $resolved = $loaded{Magyar}{'Special'}{$key};
  ok(
    defined $resolved && $resolved =~ /\S/,
    "Magyar Special minor-hour hymn [$key] resolves",
  );
}

for my $lang (@langs) {
  my $special = $raw{$lang}{'Special'};
  ok(
    (grep {
      $_->{name} eq 'Feria Vespera'
        && defined $_->{condition}
        && $_->{condition} =~ /feria\s*7/i
    } @{$special->{sections}}),
    "$lang Special keeps the Saturday Vespers capitulum",
  );
  ok(
    (grep {
      $_->{name} eq 'Hymnus Day6 Vespera'
        && defined $_->{condition}
        && $_->{condition} =~ /post Pentecosten/i
    } @{$special->{sections}}),
    "$lang Special keeps the post-Pentecost Sunday Vespers hymn",
  );
}

for my $file ('Psalmi major', 'Psalmi minor') {
  is(
    base_names($raw{Latin}{$file}),
    base_names($raw{Magyar}{$file}),
    "$file section names agree between Latin and Hungarian",
  );
}

my @latin_special = @{base_names($raw{Latin}{'Special'})};
my @hungarian_special = @{base_names($raw{Magyar}{'Special'})};
my %hungarian_special = map { $_ => 1 } @hungarian_special;
my @missing_in_hungarian =
  grep { !$hungarian_special{$_} } @latin_special;
is(
  \@missing_in_hungarian, [],
  'Hungarian Special contains every section of the Latin Special',
);

my %latin_special = map { $_ => 1 } @latin_special;
my @extra_in_hungarian =
  grep { !$latin_special{$_} } @hungarian_special;
is(
  \@extra_in_hungarian,
  [sort @hungarian_minor_hymns],
  'Hungarian Special adds only its own minor-hour hymns',
);

for my $lang (@langs) {
  for my $file ('Psalmi major', 'Psalmi minor') {
    my @bad;
    for my $section (@{$raw{$lang}{$file}{sections}}) {
      next if $section->{name} eq 'Completorium';    # no antiphon here
      my $text = section_text($section);
      next unless length $text;

      for my $line (split /\n/, $text) {
        next if $line =~ /^\s*$/;
        next if $line =~ /^\s*\@/;    # shared psalm body
        push @bad, "$section->{name}: $line"
          unless $line =~ / \* /;
      }
    }
    is(
      \@bad, [],
      "$lang $file uses the short antiphon marker before every psalm",
    );
  }

  my $ant4 = find_unconditional($raw{$lang}{'Special'}, 'Ant 4');
  ok(
    $ant4 && section_text($ant4) =~ / \* /,
    "$lang Compline uses a short Nunc dimittis antiphon marker",
  );
}

done_testing;
