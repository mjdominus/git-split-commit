
use Test::More 'no_plan';
use MJD::GitUtil 'split_patch';
use File::Basename 'basename';
use File::Compare;

sub crap;

my $testdir = "t.dat/split";
chdir $testdir or die "chdir $testdir: $!";
opendir D, "."
  or die "$testdir: $!";

for my $subdir (readdir D) {
  next if $subdir =~ /^\./;
  chdir "$subdir/a" or die "cd $testdir/$subdir/a: $!";
  my @r_res = split_patch("../patch");
  my @a_res = <*>;
  my @x_res = map basename($_), <../x/*>;
  is_deeply([sort @a_res], [sort @r_res], "$subdir: return from split_patch");
  is_deeply([sort @a_res], [sort @x_res], "$subdir: expected files");
  for my $file (@x_res) {
    ok(compare($file, "../x/$file") == 0, "$subdir/$file");
  }
  unlink @a_res;
  chdir ".." or die "cd ..: $!";
}

