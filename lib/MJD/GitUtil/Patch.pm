package MJD::GitUtil::Patch;
use base 'Exporter';
our @EXPORT = qw(split_patch);

use Carp qw(croak);
use Date::Parse ();
use DateTime;
use File::Slurp;
use Moo;
use Scalar::Util qw(reftype);
use MJD::GitUtil::Patch::File;
use MJD::GitUtil::Patch::Chunk;

has file => (
  is => 'ro',
  required => 1,
  isa => sub { defined $_[0] },
);

has data => (
  is => 'rw',
  isa => ref_of_type("array"),
  lazy => 1,
  default => sub { [ read_file($_[0]->file, chomp => 1) ] },
);

sub ref_of_type {
  my ($reftype) = @_;
  return sub { reftype $_[0] eq uc($reftype) };
}

has no_parse => (
  is => 'ro',
);

sub BUILD {
  my ($self) = @_;
  $self->parse_patch unless $self->no_parse;
}

sub parse_patch {
  my ($self) = @_;

  $self->commit_line;
  $self->header_hash;
  $self->message;
  $self->files;
}

################################################################
#
# Generic parsing utilities
#
# Put these in a module maybe?

sub peek {
  return $_[0]->data->[0];
}

sub pull {
  shift @{$_[0]->data};
}

# if the next line matches the specified regex, return the result
# otherwise die.
sub parse_next {
  my ($self, $pat, $exception) = @_;
  my $next = $self->peek;
  $exception //= qq{Next line '$next' didn't match /$pat/};
  my @res = $self->match_regex($next, $pat, $exception);

  $self->pull;
  if (wantarray()) {
    return @res;
  } elsif (@res == 1) {
    return $res[0];
  } else {
    croak "Pattern /$pat/ in scalar context";
  }
}

# If this text matches that pattern good
# other
sub match_regex {
  my ($self, $text, $pat, $exception) = @_;
  if (my @a = ($text =~ $pat)) {
    return @a;
  } elsif ($exception) {
    die $exception;
  } else {
    croak "Text '$text' didn't match /$pat/";
  }
}

sub next_line_is_blank {
  my ($self) = @_;
  $self->peek =~ /\A \s* \z/x;
}

sub pull_blank_line {
  my $self = shift;
  my ($msg) = shift // "Expected blank line";
  croak sprintf($msg, $self->peek)
    unless $self->next_line_is_blank;
  $self->pull;
  return 1;
}

sub at_eof {
  my ($self) = @_;
  @{$self->data} == 0;
}

################################################################
#
# commit lines

sub commit_line {
  join " ", "commit", $_[0]->commit;
}

has commit => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    $self->parse_next(qr/\A commit [ ] ([0-9a-f]{40}) \z /x);
  },
);

sub parse_commit_line {
  my ($self) = @_;
  return $self->commit;
}

################################################################
#
# headers

has header_array => (
  is => 'rw',
  isa => ref_of_type("array"),
  lazy => 1,
  builder => 'parse_header',
);

sub parse_header {
  my ($self) = @_;
  my @lines;
  until ($self->next_line_is_blank) {
    push @lines,
      [ $self->parse_next(qr/ \A (\w+) : \s+ (.*) \z /x) ];
  }
  $self->pull; # Discard the blank line that follows the header
  return \@lines;
}

has header_hash => (
  is => 'rw',
  isa => ref_of_type("hash"),
  lazy => 1,
  builder => 'header_to_hash',
);

sub header_to_hash {
  my ($self) = @_;
  my %h;
  for my $field (@{$self->header_array}) {
    my ($k, $v) = @$field;
    $h{lc $k} = $v;
  }
  return \%h;
}

has date => (
  is => 'rw',
#  isa => DateTime
  lazy => 1,
  builder => '_build_date',
);

sub _build_date {
  my $z = $_[0]->header_hash->{date};
  return DateTime->from_epoch(
    epoch =>
      Date::Parse::str2time( $_[0]->header_hash->{date} )) ;
}

################################################################
#
# commit message

has subject => (
  is => 'rw',
  lazy => 1,
  builder => '_build_subject',
);

sub _build_subject {
  my ($self) = @_;
  my ($subj) = $self->parse_next(qr/ \A [ ]{4} (.*) \z /x);
  $self->pull_blank_line("Saw '%s' instead of blank line after commit subject line");
  return $subj;
}

has body => (
  is => 'rw',
  isa => ref_of_type('array'),
  lazy => 1,
  builder => '_build_body',
);

sub _build_body {
  my ($self) = @_;
  my @body;
  while ($self->peek =~ /^[ ]{4}/) {
    push @body, $self->pull;
  }
  $self->pull_blank_line("Saw '%s' instead of blank line after commit message body");
  s/^[ ]{4}// for @body;
  return \@body;
}

sub message {
  my ($self) = @_;
  return join "\n", $self->subject, "", @{$self->body}, "";
}

sub parse_commit_message {
  my ($self) = @_;
  my @lines;
  until ($self->next_line_is_blank) {
    push @lines,
      $self->parse_next(qr/ \A (\w+) : \s+ (.*) \z /x);
  }
  $self->pull; # Discard the blank line that follows the header
  return \@lines;
}

################################################################
#
# diffs to a bunch of files

has _file_array => (
  is => 'rw',
  isa => ref_of_type('array'),
  lazy => 1,
  builder => '_build_files',
);

sub files {
  my ($self) = @_;
  my $files = $self->_file_array;
  return wantarray() ? @$files : $files;
}

sub _build_files {
  my ($self) = @_;
  my @files;
  until ($self->at_eof) {
    push @files, $self->parse_file;
  }
  return \@files;
}

################################################################
#
# diffs to a single file

sub parse_file {
  my ($self) = @_;

  my ($p1, $p2, $path) = $self->parse_diff_line;
  my ($h1, $h2, $mode) = $self->parse_index_line;
  $self->check_mmmppp($p1, $p2);

  my @chunk;
  while (! $self->at_eof && $self->peek =~ /^\@\@ /) {
    push @chunk, $self->parse_chunk();
  }

  return $self->file_factory->new({
    path => $path,
    shas => [ $h1, $h2 ],
    dpaths => [ $p1, $p2 ],
    mode => $mode,
    chunks => \@chunk,
  });
}

has file_factory => (
  is => 'ro',
  default => sub { "MJD::GitUtil::Patch::File" },
);

sub parse_diff_line {
  my ($self) = @_;

  my ($from, $to) = $self->parse_next(qr/ \A diff [ ] --git [ ]
                                          (\S+) [ ] (\S+) \z /x);
  my $path;

  if (my ($pa) = $from =~ m{^a/(.*)} and
      my ($pb) = $to   =~ m{^b/(.*)}) {
    $path = $pa if $pa eq $pb;
  }

  return ($from, $to, $path);
}

sub parse_index_line {
  my ($self) = @_;
  my ($h1, $h2, $mode) =
    $self->parse_next(qr/ \A index [ ]
                          ([0-9a-f]{7}) \.\. ([0-9a-f]{7}) [ ]
                          (\d{6}) \z
                        /x);

  return ($h1, $h2, $mode);
}

sub check_mmmppp {
    my ($self, $p1, $p2) = @_;

    my ($q1) = $self->parse_next(qr/ \A ---    [ ] (.*) \z /x);
    $q1 eq $p1
	or die sprintf "expected '--- %s', saw '%s' instead", $p1, $self->peek;

    my ($q2) = $self->parse_next(qr/ \A \+\+\+ [ ] (.*) \z /x);
    $q2 eq $p2
	or die sprintf "expected '--- %s', saw '%s' instead", $p2, $self->peek;

    return 1;
}

has chunk_factory => (
  is => 'ro',
  default => sub { "MJD::GitUtil::Patch::Chunk" },
);

sub parse_chunk {
  my ($self) = @_;
  # l1 is the location of this chunk in the original file
  # q1 is the length of the chunk in the original file
  # l2 is the location of the chunk in the resulting file
  # q2 is the length of the chunk in the resulting file
  my ($l1, $q1, $l2, $q2, $loc) =
    $self->parse_next(qr/ \A \@\@               [ ]
                           - (\d+) , (\d+)      [ ]
                          \+ (\d+) , (\d+)      [ ]
                             \@\@          (?:  [ ] (.*) )? \z
                        /x);

  # Number of total lines we have seen so far from original and resulting
  # files, respectively; when $r1 == $q1 and $r2 == $q2, we have them all.
  my ($r1, $r2) = (0, 0);

  my @lines;
  while ($r1 < $q1 || $r2 < $q2) {
    my $line = $self->pull;
    my ($init) = substr($line, 0, 1);
    if ($init eq " ") {
      $r1++; $r2++;
    } elsif ($init eq "+") {
      $r2++;
    } elsif ($init eq "-") {
      $r1++;
    }
    if ($r1 > $q1 || $r2 > $q2) {
      die sprintf "Couldn't parse patch; line '%s' made %s file too long",
        $line, $r1 > $q1 ? "original" : "resulting";
    }
    push @lines, $line;
  }

  return $self->chunk_factory->new(
    lines => \@lines,
    loc => $loc,
    apos => $l1,
    bpos => $l2,
    alen => $q1,
    blen => $q2,
  );
}

1;
