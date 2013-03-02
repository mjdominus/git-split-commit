use Test::More;
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil::Patch;
use Scalar::Util qw(reftype);

my $file = "t.dat/split/t1/patch";

has p => (
  is => 'ro',
  lazy => 1,
  clearer => 'reset_p',
  default => sub {
    MJD::GitUtil::ParsePatch->new({
      file => $file,
    });
  },
);

sub setup_p {
};

after run_test => sub {
  $_[0]->reset_p;
};

test "basic" => sub {
  my ($self) = @_;
  ok($self->p, "built patch object");
  is(reftype($self->p->data), "ARRAY", "got data lines");
  is(@{$self->p->data}, 52, "data line count");

  is($self->p->peek,
     "commit b9648f3e0f3f6fbddb9332e6dfcc5b6c57d8bf33",
     "peek");

  is($self->p->pull,
     "commit b9648f3e0f3f6fbddb9332e6dfcc5b6c57d8bf33",
     "pull");

  is($self->p->peek,
     'Author: Mark Dominus <mjd@icgroup.com>',
     "peek");
};

test "parsing" => sub {
  my ($self) = @_;

  subtest "commit line" => sub {
    is($self->p->commit_line,
       "commit b9648f3e0f3f6fbddb9332e6dfcc5b6c57d8bf33",
       "commit line literal text");
    is($self->p->commit,
       "b9648f3e0f3f6fbddb9332e6dfcc5b6c57d8bf33",
       "commit hash");
  };
};


run_me;
done_testing;

1;
