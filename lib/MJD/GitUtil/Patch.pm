package MJD::GitUtil::ParsePatch;
use base 'Exporter';
our @EXPORT = qw(split_patch);

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

sub match_regex {
  my ($self, $pat) = @_;
  if (my @a = ($self->peek =~ /$pat/)) {
  }
}

sub parse_commit_line {
  
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
