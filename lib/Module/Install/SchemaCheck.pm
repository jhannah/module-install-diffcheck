package Module::Install::SchemaCheck;

use strict;

our @ISA;
require Module::Install::Base;
@ISA = qw/Module::Install::Base/;

use FindBin;

sub schemacheck {
    my ($self, %args) = @_;
    print <<EOF;
*** Module::Install::SchemaCheck
EOF

    unless ($args{diff_cmd}) {
       $args{diff_cmd} = "svn diff";
    }
    unless ($args{database}) {
       $args{database} = "mysql";
    }
    
    my $root = $FindBin::Bin;
    print "root is $root\n";
    print "refresher is $args{refresher}\n";
    print "schema_dir is $args{schema_dir}\n";

    $self->_run_refresher(\%args);

    my $method = "_check_schema_$args{database}";
    unless ($self->can($method)) {
       die "Module::Install::SchemaCheck has not implemented $method";
    }
    $self->$method(\%args);

    print <<EOF;
*** Module::Install::SchemaCheck finished.
EOF
}


sub _run_refresher {
   my ($self, $args) = @_;
   
   my $cmd = $args->{refresher};
   print "running '$cmd'\n";
   open(my $in, "$cmd 2>&1 |");
   while (<$in>) {
      chomp;
      print "   $_\n";
   }
}


sub _check_schema_mysql {
   my ($self, $args) = @_;
   
   my $cmd = "$args->{diff_cmd} $args->{schema_dir}";
   print "running '$cmd'\n";
   open(my $in, "$cmd 2>&1 |");
   while (<$in>) {
      chomp;
      print "   $_\n";
   }
}


1;
