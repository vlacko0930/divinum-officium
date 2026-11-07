# use strict;
# use warnings;
use utf8;

# Helpers for the Esztergom (Strigoniense) office.
#
# The 2014 Psalterium Strigoniense supplies the weekly psalter and the
# ordinary of the day hours.  Until the proper and calendar are integrated,
# every day and season uses this ordinary office; Tridentine proper and
# seasonal texts are deliberately not consulted for the Strigoniense day
# hours.

#*** strig_special($name, $lang)
# Return a section from Psalterium/Strigoniense/Special.txt, or ''.
sub strig_special {
  my ($name, $lang) = @_;
  our $version;
  return '' unless $version =~ /Strigoniense/;

  my %special = %{ setupstring($lang, 'Psalterium/Strigoniense/Special.txt') };
  return exists($special{$name}) ? $special{$name} : '';
}

#*** strig_merge_special(\%target, $lang, $regex)
# Merge Strigoniense sections into an already loaded psalter hash.
sub strig_merge_special {
  my ($target, $lang, $regex) = @_;
  our $version;
  return unless $version =~ /Strigoniense/;

  my %special = %{ setupstring($lang, 'Psalterium/Strigoniense/Special.txt') };
  foreach my $key (keys %special) {
    next if $regex && $key !~ $regex;
    $target->{$key} = $special{$key};
  }
}

#*** strig_day_key($dayofweek)
# Name of the day in the Strigoniense psalter.
sub strig_day_key {
  my $day = shift;
  return 'Dominica' if defined $day && $day == 0;
  return 'Sabbato'  if defined $day && $day == 6;
  return ''         unless defined $day && $day > 0 && $day < 6;
  return 'Feria' . ($day + 1);
}

#*** strig_office_day_key($dayofweek, $hora, $vespera)
# The day whose ordinary is used.  First Vespers belong to the following
# liturgical day, even when the calendar day is still Saturday.
sub strig_office_day_key {
  my ($day, $hora, $vespera) = @_;
  return '' unless defined $day && $day >= 0 && $day <= 6;

  $day = ($day + 1) % 7 if defined $hora && $hora eq 'Vespera' && $vespera == 1;
  return strig_day_key($day);
}

#*** strig_base_applicable($lang, @hours)
# Common test for the Strigoniense ordinary office.  It applies to every day
# and season while the proper is not yet available.
sub strig_base_applicable {
  my ($lang, @hours) = @_;
  our ($version, $hora, $dayofweek);

  return 0 unless $version =~ /Strigoniense/;
  return 0 unless defined $dayofweek && $dayofweek >= 0 && $dayofweek <= 6;
  return 0 if @hours && !grep { $_ eq $hora } @hours;

  return 1;
}

#*** strig_psalter_applicable($lang, @hours)
# True where the Strigoniense psalter supplies its own psalm texts.
sub strig_psalter_applicable {
  return strig_base_applicable(@_);
}

sub strig_major_applicable {
  my $lang = shift;
  our ($hora, $vespera);

  return 0 unless $hora =~ /^(?:Laudes|Vespera)$/;
  return strig_psalter_applicable($lang, 'Laudes', 'Vespera');
}

#*** strig_canticle_ant($lang)
# Return the Strigoniense antiphon for the Benedictus or Magnificat.
sub strig_canticle_ant {
  my $lang = shift;
  our ($hora, $version, $dayofweek, $vespera);

  return '' unless $version =~ /Strigoniense/;
  return '' unless $hora =~ /^(?:Laudes|Vespera)$/;
  return '' unless strig_major_applicable($lang);

  my $day = strig_office_day_key($dayofweek, $hora, $vespera);
  my $key = $day eq 'Dominica'
    ? ($hora eq 'Laudes' ? 'Dominica Ant Laudes' : 'Dominica Ant Vespera')
    : "$day Ant " . ($hora eq 'Laudes' ? '2' : '3');
  return strig_special($key, $lang);
}

#*** strig_psalmi_major($lang)
# Five antiphon/psalm groups for Sunday Lauds or Vespers, and the ferial sets
# for the ordinary office of the year.
sub strig_psalmi_major {
  my $lang = shift;
  our ($hora, $label, $dayofweek, $vespera);

  my $day = strig_office_day_key($dayofweek, $hora, $vespera);
  return undef if $day eq '';

  my %psalmi = %{ setupstring($lang, 'Psalterium/Strigoniense/Psalmi major.txt') };
  my $key = "$day $hora";
  return undef unless defined $psalmi{$key} && $psalmi{$key} ne '';

  my @psalmi = split("\n", $psalmi{$key});
  setbuild('Psalterium/Strigoniense/Psalmi major', $key, 'Psalmi ord');
  setcomment($label, 'Source', 0, $lang);

  return \@psalmi;
}

#*** strig_psalmi_minor($lang)
# Return the Strigoniense psalm set for Prime, the little hours, and Compline
# on every day.  Return undef when the hour is not one of these.
sub strig_psalmi_minor {
  my $lang = shift;
  our (
    $version, $hora, $dayofweek, $label,
  );

  return undef unless $version =~ /Strigoniense/;

  my $key;
  if ($hora eq 'Completorium') {
    $key = 'Completorium';
  } elsif ($hora eq 'Prima') {
    $key = $dayofweek == 0 ? 'Prima Dominica' : 'Feria Prima';
  } elsif ($hora =~ /^(?:Tertia|Sexta|Nona)$/) {
    $key = $dayofweek == 0 ? "$hora Dominica" : "Feria $hora";
  } else {
    return undef;
  }

  my %psalmi = %{ setupstring($lang, 'Psalterium/Strigoniense/Psalmi minor.txt') };
  return undef unless defined $psalmi{$key} && $psalmi{$key} ne '';

  my @psalmi = split("\n", $psalmi{$key});
  setbuild('Psalterium/Strigoniense/Psalmi minor', $key, 'Psalmi ord');
  setcomment($label, 'Source', 0, $lang);

  return \@psalmi;
}

#*** strig_oratio_key($lang)
# Return the Strigoniense oration key for the current hour, or ''.
sub strig_oratio_key {
  my $lang = shift;
  our ($version, $hora, $dayofweek, $vespera);

  return '' unless $version =~ /Strigoniense/;

  if ($hora eq 'Completorium') {
    return 'Oratio Completorium';
  }

  return ''
    unless $hora =~ /^(?:Laudes|Vespera|Prima|Tertia|Sexta|Nona)$/
    && strig_base_applicable($lang, 'Laudes', 'Vespera', 'Prima', 'Tertia', 'Sexta', 'Nona');

  my $day = strig_office_day_key($dayofweek, $hora, $vespera);
  return "Oratio Dominica $hora" if $day eq 'Dominica';
  return "Oratio $day $hora"     if $hora =~ /^(?:Laudes|Vespera)$/;
  return "Oratio Feria $hora";
}

1;
