package MJD::GitUtil;

use base 'Exporter';
our @EXPORT_OK = qw(split_patch apply_patch hash_file);

use Carp qw(confess croak);
use MJD::GitUtil::Patch;
use Digest::SHA1 qw(sha1_hex);

sub hash_file {
  my ($file) = @_;
  open my($fh), "<", $file or return;
  my $data = do {
    local $/;
    join "", <$fh>;
  };
  return hash_data($data);
}

sub hash_data {
  my ($data) = @_;
  return sha1_hex("blob " . length($data) .  "\0" . $data)
}

sub split_patch {
  my ($file, $dir) = @_;
  my $patch = MJD::GitUtil::Patch->new({ file => $file });
  my %seqno;
  my @result_files;
  for my $file ($patch->files) {
    my $orig_path = $file->path;
    (my $chunk_path = $orig_path) =~ s{/}{::}g;
    for my $chunk (@{$file->chunks}) {
      my $seqno = ++$seqno{$chunk_path};
      my $file = "$chunk_path-$seqno";
      $file = "$dir/$file" if defined $dir;
      write_chunk($file, $orig_path, $chunk);
      push @result_files, $file;
    }
  }
  return @result_files;
}

sub write_chunk {
  my ($file, $path, $chunk) = @_;
  open my($f), ">", $file
    or die "Couldn't open '$file' for writing: $!";

  # or maybe use the dpaths here?
  print $f "--- a/$path\n";
  print $f "+++ b/$path\n";

  print $f $chunk->descriptor, "\n";

  print $f map "$_\n", @{$chunk->lines};
}

sub apply_patch {
  my ($patch) = @_;
  warn "### Applying patch '$patch'\n";
  system(qw(git apply --index), $patch) == 0
    or do {
      my $st = $? >> 8;
      croak "Couldn't apply patch '$patch': exit status $st";
    };
  system("git status -s");
}

1;
