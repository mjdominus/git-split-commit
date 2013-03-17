package MJD::GitUtil;
use base 'Exporter';
our @EXPORT_OK = qw(split_patch);
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
      write_chunk_file($file, $orig_path, $chunk,
                       { fake_header => 1 },
                      );
      push @result_files, $file;
    }
  }
  return @result_files;
}

sub write_chunk_file {
  my ($file, $path, $chunk, $opt) = @_;
  open my($f), ">", $file
    or die "Couldn't open '$file' for writing: $!";

  if ($opt->{fake_header}) {
    # Write the header
    print $f "diff --git a/$path b/$path\n";
    print $f "index 0000000..000000 100644\n";
  }

  # or maybe use the dpaths here?
  print $f "--- a/$path\n";
  print $f "+++ b/$path\n";

  print $f $chunk->descriptor, "\n";

  print $f map "$_\n", @{$chunk->lines};
}

1;
