--- a/perl-lib/icg2/Account/FilterManager.pm
+++ b/perl-lib/icg2/Account/FilterManager.pm
@@ -175,6 +175,7 @@ sub save_filter {
 
   return $self->txn_do(
     sub {
+      $self->delete_filter($filter);
       $self->store_rows([$filter->action_rows()], "Action");
       $self->store_rows([$filter->condition_rows()], "Condition");
       return 1;
