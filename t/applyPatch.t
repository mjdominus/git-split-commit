
use Cwd;
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use MJD::GitUtil qw(apply_patch);

my $HOME = "t.dat/apply";
__PACKAGE__->safe_chdir($HOME);

has _files => (
  is => 'ro',
  default => sub { [] },
);

sub files { @{$_[0]->_files} }

has reponame => (
  is => 'ro',
  default => sub { "testrepo$$" },
);

sub safe_chdir {
  my ($self, $dir) = @_;
  chdir($dir) or die "chdir '$dir': $!";
}

sub git_command {
  my ($self, $cmd, @args) = @_;
  $self->run_command("git", $cmd, @args);
}

sub run_command {
  my ($self, $cmd, @args) = @_;
  my $pid = fork();
  die "Couldn't fork: $!" unless defined $pid;
  if ($pid) {
    wait;
    $? == 0
      or die sprintf "Execution of '$cmd @args' failed with status %d",
        ($? >> 8);
  } else {
    open STDERR, "|-", "perl", "-lpe", "s/^/#2# /";
    open STDOUT, "|-", "perl", "-lpe", "s/^/#1# /";
    $| = 1;
    print STDERR "Running: $cmd @args\n";
    exec $cmd, @args;
    exit $?;
  }
}

sub add_file {
  my ($self, $path, $lines) = @_;
  open my($fh), ">", $path
    or die "Couldn't write file '$path': $!";
  print $fh join("\n", @$lines, "");
  close $fh;
  $self->git_command("add", $path);
  push @{$self->_files}, $path;
}

sub scrub_files {
  my ($self) = @_;
  my @files = $self->files;
  note sprintf "deleting %d files", scalar(@files);
  unlink $self->files;
}

sub commit {
  my ($self, $message) = @_;
  $self->git_command("commit", "-m", $message);
}

sub setup_repo {
  my ($self) = @_;
  note "initializing repo\n";
  $self->git_command("init", $self->reponame);
  $self->safe_chdir($self->reponame);
  $self->add_file("a", [ 1 .. 30 ]);
  $self->add_file("b", [ 1 .. 5 ]);
  $self->commit("initial commit");
  note "repo initialized\n";
}

sub cleanup_repo {
  my ($self) = @_;
  note "cleaning up\n";
  $self->safe_chdir("..");
  return if $ENV{DO_NOT_CLEAN_UP};
  $self->run_command("rm", "-rf", $self->reponame);
}

sub count_lines {
  my ($file) = @_;
  open my ($f), "<", $file
    or die "Couldn't open file '$file': $!";
  my $n = 0;
  ++$n while <$f>;
  return $n;
}

before run_test => sub {
  my ($self) = @_;
  $self->setup_repo;
};

after run_test => sub {
  my ($self) = @_;
  $self->cleanup_repo;
};

test "null" => sub {
  pass("okay");
};

test "apply" => sub {
  my ($self) = @_;
  apply_patch("patch");
  is(count_lines("a"), 15, "removed 15 lines from file a");
  is(count_lines("b"), 10, "added 5 lines to file b");
};

run_me;
done_testing;

1;
