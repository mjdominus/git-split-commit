package MJD::GitUtil::SplitPatch;
use base 'Exporter';
our @EXPORT = qw(split_patch);

sub new {
  my $class = shift;
  my $patch = shift;
  my $self = bless {} => $class;
  $self->set_patch($patch);
  return $self;
}

sub set_patch {
  my ($self, $patch) = @_;
  $self->{ORIG_PATCH} = $patch;
  $self->{D} = [ @$patch ];
  return $self;
}

sub split_patch {
  my $self = shift;
  $self->parse_commit_line;
  $self->parse_header;
  $self->parse_commit_message;
  $self->parse_multiple_files;
}

sub peek {
  return $_[0]{D}[0];
}

sub pull {
  shift @{$_[0]{D}};
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
