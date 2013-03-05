package MJD::GitUtil::Patch::File;
use Moo;

has path => ( is => 'ro' );
has shas => ( is => 'ro' );
has dpaths => ( is => 'ro' );
has mode => ( is => 'ro' );
has chunks => ( is => 'ro',
                default => sub { [] }
              );

sub num_chunks {
  my ($self) = @_;
  return 0 + @{$self->{chunks}};
}

1;
