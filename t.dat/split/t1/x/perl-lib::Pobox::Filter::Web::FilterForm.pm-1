--- a/perl-lib/Pobox/Filter/Web/FilterForm.pm
+++ b/perl-lib/Pobox/Filter/Web/FilterForm.pm
@@ -25,6 +25,13 @@ sub new {
 sub form { $_[0]{f} }
 sub set_form { $_[0]{f} = $_[1] }
 
+sub handler_action {
+  my $self = shift;
+  return "delete" if $self->form->{'delete_action'};
+  return $self->form->{'handler_action'} ||
+    die "no handler_action";
+}
+
 sub form_to_filter {
   my $self = shift;
 
