package Module::Install::SchemaCheck;

=head1 NAME

Module::Install::SchemaCheck - Veryify that a database schema meets expectations

=head1 SYNOPSIS

Add statements like these to your Module::Install generated Makefile.PL:

  schemacheck( 
     refresher  => 'Model/omnihub/refresh_Schema.pl', 
     diff_cmd   => 'svn diff Model/omnihub/Schema',
  );

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
      $fatal++;
   }
   close $in;
   return $fatal;
}


sub _run_diff {
   my ($self, $args) = @_;
  
   my $cmd = "$args->{diff_cmd} $args->{schema_dir}";
   print "running '$cmd'\n";
   my $diff = `$cmd`;

   my $parser = Text::Diff::Parser->new(
      Simplify => 1,
      Diff     => $diff,
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
      #$msg .= sprintf("   File1: %s\n", $change->filename1);
      #$msg .= sprintf("   Line1: %s\n", $change->line1);
      #$msg .= sprintf("   File2: %s\n", $change->filename2);
      #$msg .= sprintf("   Line2: %s\n", $change->line2);
      #$msg .= sprintf("   Type:  %s\n", $change->type);
      #$msg .= sprintf("   Size:  %s\n", $change->size);
      my $size = $change->size;
      my $show_change = 0;
      foreach my $line ( 0..($size-1) ) {
         $msg .= sprintf("      %s\n", $change->text( $line ));
         next if ($change->text( $line ) =~ / *#/);    # Ignore comment changes
         $show_change = 1;
         $fatal = 1;
      }
      if ($show_change) {
         print $msg;
      }
   }
   return $fatal;
}



=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS

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

L<http://github.com/jhannah/module-install-schemacheck>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jay Hannah, all rights reserved.

=cut

1; # End of Module::Install::SchemaCheck

