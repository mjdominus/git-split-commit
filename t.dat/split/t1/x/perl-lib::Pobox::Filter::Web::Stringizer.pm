--- a/perl-lib/Pobox/Filter/Web/Stringizer.pm
+++ b/perl-lib/Pobox/Filter/Web/Stringizer.pm
@@ -84,6 +84,11 @@ sub block_pattern_lines {
   return join "\n", @lines, "";
 }
 
+sub n_blocks {
+  my $self = shift;
+  return $self->condition->n_branches;
+}
+
 sub die {
   my ($self, $exn) = @_;
   die $exn if ref $exn;
