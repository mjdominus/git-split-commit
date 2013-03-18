package MJD::GitUtil::Patch::Chunk;
use Moo;

has lines => ( is => 'ro' );
has loc => ( is => 'ro' );
has apos => ( is => 'ro' );
has bpos => ( is => 'ro' );
has alen => ( is => 'ro' );
has blen => ( is => 'ro' );

sub descriptor {
  my ($c) = @_;
  my $desc = sprintf "\@\@ -%d,%d +%d,%d \@\@",
    $c->apos, $c->alen,
    $c->bpos, $c->blen;
  $desc .= " " . $c->loc
    if defined $c->loc;
  return $desc;
}

1;
