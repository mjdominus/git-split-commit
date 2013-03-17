git-split-commit
================

Break a git commit into multiple smaller commits

The idea here is that you have a bunch of changes and you want to turn
the various changes into commits.  Some of the changes should go into
one commit, some into another, perhaps some other changes into a
third.  A few additional changes are not ready for committing and
should stay in the working tree for further work.

One way to do this is to make some `git-add -p` passes until one
commit-worth of changes have been staged in the index, then commit the
index, and repeat.  This is the workflow I described in my blog
article [my git habits](http://blog.plover.com/prog/git-habits.html).

This project, `git-split-commit`, will be an alternative, one I hope
is more convenient.

`git-split-commit` will take the current set of diffs, break it into
chunks, and write each chunk into a file in a special directory.  You
will create some subdirectories and sort the chunks into the
subdirectories.  When you run `git-split-commit` again, it will
examine the subdirectories and turn each one into a commit that
includes the changes given by just the chunk files in that directory.
If a directory contains a file called `MESSAGE`, that file will be
used as the log message for the commit; otherwise you will be prompted
as usual.

To discard a change, delete its patch file.  To leave a change
uncommitted in the working tree, leave its patch file alone.

For further thoughts and notes, see [the NOTES file in the
repository](https://github.com/mjdominus/git-split-commit/blob/master/NOTES).
