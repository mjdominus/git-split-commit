package MJD::GitUtil;
use base 'Exporter';
our @EXPORT_OK = qw(split_patch apply_patch);
use MJD::GitUtil::Patch;

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
  system(qw(git apply --index), $patch);
}

1;
