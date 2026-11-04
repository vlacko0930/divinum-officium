# use strict;
# use warnings;
use utf8;

# Helpers for the Esztergom (Strigoniense) office.
#
# The 2014 Psalterium Strigoniense supplies a weekly psalter and the ordinary
# of the day hours.  Proper texts of the Esztergom breviary are not part of
# that source, so this version deliberately falls back to the Tridentine
# proper where the Strigoniense psalter has no text of its own.

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

#*** strig_psalter_applicable($lang, @hours)
# True for the ordinary Sunday office of the year, where the Strigoniense
# psalter has its own texts.  Proper and seasonal offices keep the Tridentine
# texts.
sub strig_psalter_applicable {
  my ($lang, @hours) = @_;
  our (
    $version, $hora, $dayofweek, $winner, $rule, $antecapitulum,
    $communetype, @dayname,
  );

  return 0 unless $version =~ /Strigoniense/;
  return 0 unless $dayofweek == 0;
  return 0 unless $winner =~ /Tempora/;
  return 0 unless ($dayname[0] || '') =~ /^(?:Epi|Pent)/;
  return 0 if @hours && !grep { $_ eq $hora } @hours;
  return 0 if $antecapitulum;
  return 0 if $communetype && $communetype =~ /ex/i;
  return 0 if $rule && $rule =~ /Psalmi ex Psalterio|Psalmi Feria/i;

  my %w = columnsel($lang) ? %winner : %winner2;
  return 0 if exists $w{"Ant $hora"};

  return 1;
}

sub strig_major_applicable {
  my $lang = shift;
  our ($hora, $vespera);

  return 0 unless $hora =~ /^(?:Laudes|Vespera)$/;
  return 0 if $hora eq 'Vespera' && $vespera == 1;

  return strig_psalter_applicable($lang, 'Laudes', 'Vespera');
}

#*** strig_canticle_ant($lang)
# Return the Strigoniense Sunday antiphon for the Benedictus or Magnificat.
sub strig_canticle_ant {
  my $lang = shift;
  our ($hora, $version);

  return '' unless $version =~ /Strigoniense/;
  return '' unless $hora =~ /^(?:Laudes|Vespera)$/;
  return '' unless strig_major_applicable($lang);

  my $key = $hora eq 'Laudes' ? 'Dominica Ant Laudes' : 'Dominica Ant Vespera';
  return strig_special($key, $lang);
}

#*** strig_psalmi_major($lang)
# Five antiphon/psalm groups for Sunday Lauds or Vespers.
sub strig_psalmi_major {
  my $lang = shift;
  our ($hora, $label);

  my %psalmi = %{ setupstring($lang, 'Psalterium/Strigoniense/Psalmi major.txt') };
  my $key = "Dominica $hora";
  my @psalmi = split("\n", $psalmi{$key} || '');

  setbuild('Psalterium/Strigoniense/Psalmi major', $key, 'Psalmi ord');
  setcomment($label, 'Source', 0, $lang);

  return \@psalmi;
}

#*** strig_psalmi_minor($lang)
# Return the Strigoniense psalm set for Sunday Prime and the little hours,
# and for Compline on every day.  Return undef when the Tridentine set
# should be used.
sub strig_psalmi_minor {
  my $lang = shift;
  our (
    $version, $hora, $dayofweek, $winner, $label, @dayname,
  );

  return undef unless $version =~ /Strigoniense/;

  my $key;
  if ($hora eq 'Completorium') {
    $key = 'Completorium';
  } elsif (
    $dayofweek == 0
    && $winner =~ /Tempora/
    && ($dayname[0] || '') =~ /^(?:Epi|Pent)/
    && $hora =~ /^(?:Prima|Tertia|Sexta|Nona)$/
  ) {
    my %w = columnsel($lang) ? %winner : %winner2;
    return undef if exists $w{"Ant $hora"};
    $key = "$hora Dominica";
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
  our ($version, $hora, $dayofweek, $winner, @dayname);

  return '' unless $version =~ /Strigoniense/;

  if ($hora eq 'Completorium') {
    return 'Oratio Completorium';
  }

  return '' unless $dayofweek == 0;
  return '' unless $winner =~ /Tempora/;
  return '' unless ($dayname[0] || '') =~ /^(?:Epi|Pent)/;
  return '' unless $hora =~ /^(?:Laudes|Vespera|Prima|Tertia|Sexta|Nona)$/;

  return "Oratio Dominica $hora";
}

1;
