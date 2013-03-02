use Test::More;
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil::Patch;
use Scalar::Util qw(reftype);

my $file = "t.dat/split/t1/patch";

has p => (
  is => 'ro',
  default => sub {
    MJD::GitUtil::ParsePatch->new({
      file => $file,
    });
  },
);

test "basic" => sub {
  my ($self) = @_;
  ok($self->p, "built patch object");
  is(reftype($self->p->data), "ARRAY", "got data lines");
  is(@{$self->p->data}, 52, "data line count");
};

run_me;
done_testing;

1;
