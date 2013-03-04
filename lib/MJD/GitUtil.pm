package MJD::GitUtil;
use base 'Exporter';
our @EXPORT_OK = qw(split_patch);
use MJD::GitUtil::Patch;

sub split_patch {
  my ($file) = @_;
  my $patch = MJD::GitUtil::Patch->new({ file => $file });
  for my $file ($patch->files) {
    my $orig_path = $file->path;
    (my $chunk_path = $orig_path) =~ s{/}{::}g;
    my $seqno = 1;
    for my $chunk ($file->chunks) {
      write_chunk("$chunk_path-$seqno", $orig_path, $chunk);
      $seqno++;
    }
  }
}

sub write_chunk {
  my ($file, $path, $chunk) = @_;
  open my($f), ">", $file
    or die "Couldn't open '$file' for writing: $!";

  # or maybe use the dpaths here?
  print $f "--- a/$path\n";
  print $f "+++ b/$path\n";

  print $f map("$_\n", @{$chunk});
}

1;
