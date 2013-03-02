package MJD::GitUtil::ParsePatch;
use base 'Exporter';
our @EXPORT = qw(split_patch);

use Carp qw(croak);
use Date::Parse ();
use DateTime;
use File::Slurp;
use Moo;
use Scalar::Util qw(reftype);

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

sub split_patch {
  my $self = shift;
  $self->parse_commit_line;
  $self->parse_header;
  $self->parse_commit_message;
  $self->parse_multiple_files;
}

################################################################
#
# Generic parsing utilities

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
  my $res = $self->match_regex($next, $pat, $exception);
  $self->pull;
  return $res;
}

# If this text matches that pattern good
# other
sub match_regex {
  my ($self, $text, $pat, $exception) = @_;
  if (my @a = ($text =~ $pat)) {
    return \@a;
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
    $self->parse_next(qr/\A commit [ ] ([0-9a-f]{40}) \z /x)->[0];
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
      $self->parse_next(qr/ \A (\w+) : \s+ (.*) \z /x);
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
  my ($subj) = $self->parse_next(qr/ \A [ ]{4} (.*) \z /x)->[0];
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

sub parse_multiple_files {
  my $self = shift;
  $self->parse_file || $self->parse_eof || $self->error();
}

sub parse_file {
}

sub parse_eof {
  return @{$_[0]{D}} == 0;
}

1;
