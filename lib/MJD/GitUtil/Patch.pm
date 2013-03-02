package MJD::GitUtil::ParsePatch;
use base 'Exporter';
our @EXPORT = qw(split_patch);

use Carp qw(croak);
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
  isa => sub { reftype $_[0] eq "ARRAY" },
  lazy => 1,
  default => sub { [ read_file($_[0]->file, chomp => 1) ] },
);

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
    $self->pull;
    return \@a;
  } elsif ($exception) {
    die $exception;
  } else {
    croak "Text '$text' didn't match /$pat/";
  }
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

sub parse_header {
}

sub parse_commit_message {
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
