package Module::Install::SchemaCheck;

=head1 NAME

Module::Install::SchemaCheck - Verify that a database schema meets expectations

=head1 SYNOPSIS

Add statements like these to your Module::Install generated Makefile.PL:

  schemacheck( 
     refresher  => 'Model/omnihub/refresh_Schema.pl', 
     diff_cmd   => 'svn diff Model/omnihub/Schema',
  );

That's it. C<refresher> is executed, then C<diff_cmd>
is executed and any non-benign changes found cause a fatal error.

=head1 DESCRIPTION

You may find this module helpful if your application software and database schemas are 
both in a version control system that is accessible from the machine you're installing.

I'll describe the specific tools we happen to be using right now, but this module will probably
work across many versioning systems and database engines.

Our software development lifecycle revolves around SVN "tags" (actually branches). 
For any given tag, new tables may have been introduced, tables may have been 
altered, or old tables may have been removed. We needed a quick way to make sure
that every time we deploy a tag, the relevant database schema(s) are already in
place. schemacheck() lists all errors and dies if it detects problems.

We use both L<DBIx::Class::Schema::Loader> C<make_schema_at> and C<mysqldump>
to store our schemas to disk. (Either one is fine. I'm not sure why we do both.)
Our tags contain one file per database table in our SVN tag.

This module should also work if your entire schema sits in a single file.

This module will not help you if you want to manage your schema versions down to
individual "ALTER TABLE" statements which transform one tag to another tag. 
(Perhaps L<DBIx::Class::Schema::Versioned> could help you with that level of granularity?)

L<DBIx::Class::Schema::Loader> C<make_schema_at> is slick. With 5 lines of code, you can 
flush an entire database into a static Schema/ directory. Then C<svn diff> show us what, 
if anything, has changed. See the POD for that module.

Similarly, C<mysqldump> output (or whatever utility dumps C<CREATE TABLE> SQL out of your
database) added to our SVN repository lets us run C<svn diff> and see everything that changed.

So, assuming the DBA has already prepped the appropriate database changes (if any) for "sometag",
our deployment goes like this:

  svn checkout https://.../MyApp/tags/sometag MyApp
  cd MyApp
  perl Makefile.PL
  make 
  make install

All done. L<Module::Install> has installed all our CPAN dependencies for us, all other custom
log directories and what-not are ready to go, and our database schema(s) have been 
audited against the tag.

If the DBA forgot to prep the database, then perl C<Makefile.PL> dies with a report about which
part(s) of the C<diff_cmd> results were considered fatal. 

=head1 METHODS

=cut


use strict;
use Text::Diff::Parser;
our @ISA;
require Module::Install::Base;
@ISA = qw/Module::Install::Base/;

our $VERSION = '0.01';


=head2 schemacheck

See SYNOPSIS above.

=cut

sub schemacheck {
    my ($self, %args) = @_;
    print <<EOF;
*** Module::Install::SchemaCheck
EOF

    unless ($args{diff_cmd}) {
       die "schemacheck() requires a diff_cmd argument";
    }

    my $fatal = 0;
    if ($args{refresher}) {
       $fatal += $self->_run_refresher(\%args);
    }
    $fatal += $self->_run_diff(\%args);

    if ($fatal) {
       print "*** Module::Install::SchemaCheck FATAL ERRORS\n";
       exit $fatal;
    }

    print <<EOF;
*** Module::Install::SchemaCheck finished.
EOF

    return 1;     # Does Module::Install care?  
}


sub _run_refresher {
   my ($self, $args) = @_;
  
   my $fatal = 0; 
   my $cmd = $args->{refresher};
   print "running '$cmd'\n";
   open(my $in, "$cmd 2>&1 |");
   while (<$in>) {
      chomp;
      print "   $_\n";
      # $fatal++;    # hmm...
   }
   close $in;
   return $fatal;
}


sub _run_diff {
   my ($self, $args) = @_;
  
   my $cmd = $args->{diff_cmd};
   print "running '$cmd'\n";
   my $diff = `$cmd`;

   my $parser = Text::Diff::Parser->new(
      Simplify => 1,
      Diff     => $diff,
      Verbose  => 1,
   );

   my $fatal = 0;
   foreach my $change ( $parser->changes ) {
      next unless ($change->type);    # How do blanks get in here?
      my $msg = sprintf(
         "   SCHEMA CHANGE DETECTED! %s %s %s line(s) at lines %s/%s:\n",
         $change->filename1,
         $change->type, 
         $change->size,
         $change->line1,
         $change->line2,
      );
      my $size = $change->size;
      my $show_change = 0;
   
      foreach my $line ( 0..($size-1) ) {
         # Huh... Only the new is available. Not the old?
         $msg .= sprintf("      [%s]\n", $change->text( $line ));
         next if ($change->text( $line ) =~ / *#/);    # Ignore comment changes
         $show_change = 1;
         $fatal = 1;
      }
      if ($show_change) {
         # Hmm... It would be nice if we could just kick out the unidiff here. I emailed the author.
         print $msg;
      }
   }
   return $fatal;
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS

This module makes no attempt to work on Windows. Sorry. Patches welcome.

I've opened a bug report against L<Text::Diff::Parser>, which this module uses.
L<https://rt.cpan.org/Ticket/Display.html?id=46426> 
That bug stops C<mysqldump> diffs from being processed currectly. 
So, for now I'm only using this against L<DBIx::Class::Schema::Loader> schemas.

Please report any bugs or feature requests to C<bug-module-install-schemacheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-SchemaCheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Install::SchemaCheck

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Install-SchemaCheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Install-SchemaCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Install-SchemaCheck>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Install-SchemaCheck>

=item * Version control

L<http://github.com/jhannah/module-install-schemacheck>, 
L<http://svn.ali.as/cpan/trunk/Module-Install/lib/Module/Install/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jay Hannah, all rights reserved.

=cut

1; # End of Module::Install::SchemaCheck

