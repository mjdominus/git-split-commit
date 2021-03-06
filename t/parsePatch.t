use DateTime;
use Scalar::Util qw();
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil::Patch;

my $file = "t.dat/split/t1/patch";

has p => (
  is => 'ro',
  lazy => 1,
  clearer => 'reset_p',
  default => sub {
    MJD::GitUtil::Patch->new({
      file => $file,
      no_parse => 1,
    });
  },
);

after run_test => sub {
  $_[0]->reset_p;
};

test "basic" => sub {
  my ($self) = @_;
  ok($self->p, "built patch object");
  is(Scalar::Util::reftype($self->p->data), "ARRAY", "got data lines");
  is(@{$self->p->data}, 56, "data line count");

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
    like($self->p->peek, qr/^Author:/, "ready to read header");
  };

  subtest "header" => sub {
    is_deeply($self->p->header_hash,
              { author => 'Mark Dominus <mjd@icgroup.com>',
                date => "Fri May 14 17:39:43 2010 -0400",
              },
              "patch header");
    TODO: {
        local $TODO = "Fucking time zones, how do they work?";
    is($self->p->date, DateTime->new( year   => 2010,
                                      month  => 5,
                                      day    => 14,
                                      hour   => 17,
                                      minute => 39,
                                      second => 32,
                                      time_zone => 'America/New_York',
                                    ),
       "date parsing");
      }

    isnt($self->p->peek, "", "ready to read commit message");
  };

  subtest "message" => sub {
    my ($s, $b) = (
      "end-of-week megapatch",
      ["all sorts of stupid changes", "",
       "including some that should not have been made"]);
    is($self->p->subject, $s, "message subject");
    is_deeply($self->p->body, $b, "message body");
    is($self->p->message,
       join("\n", $s, "", @$b, ""),
       "complete message");
    like($self->p->peek,
         qr/^diff --git a/,
         "ready to read file");
  };

  subtest "files" => sub {
    my $file1 = $self->p->parse_file;
    pass("read a file");
    my @files = $self->p->files;
    is(@files, 2, "found two more files");
  };
};

test "entire file" => sub {
  my ($self) = @_;
  $self->p->parse_patch;
  my @file = $self->p->files;
  is(@file, 3, "found three files");
  for my $i (0..2) {
    is($file[$i]->num_chunks, 1, "file $i has one chunk");
  }
};


run_me;
done_testing;

1;
