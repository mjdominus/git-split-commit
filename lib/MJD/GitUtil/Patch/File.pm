package MJD::GitUtil::Patch::File;
use Moo;

sub num_chunks {
  my ($self) = @_;
  return 0 + @{$self->{chunks}};
}

1;
