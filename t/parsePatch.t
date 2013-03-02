use Test::More 'no_plan';
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil::ParsePatch qw(split_patch);

my $file = "../t.dat/split/t1/patch";

test "basic" => sub {
  my $parser = MJD::GitUtil::ParsePatch->new({
    patch => $file,
  });
  ok($parser, "built object");
};

run_me;
done_testing;

1;
