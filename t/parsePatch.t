use Test::More;
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil::ParsePatch qw(split_patch);
use Scalar::Util qw(reftype);

my $file = "t.dat/split/t1/patch";

has pp => (
  is => 'ro',
  default => sub {
    MJD::GitUtil::ParsePatch->new({
      patch => $file,
    });
  },
);

test "basic" => sub {
  my ($self) = @_;
  ok($self->pp, "built object");
  is(reftype($self->pp->data), "ARRAY", "got data lines");
  is(@{$self->pp->data}, 52, "data line count");
};

run_me;
done_testing;

1;
