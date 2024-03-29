use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'    => 'Maypole::Redirect',
    'VERSION_FROM'  => 'lib/Maypole/Redirect.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Apache::Request' => 0,
                        'Maypole' => 1.7,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Maypole/Redirect.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),

    clean => { FILES => 'Maypole-Redirect-*' },
);

# Now check whether we can create the synopsis inline tests
use vars qw($have_test_inline);
BEGIN {
  eval { require Test::Inline;
         $have_test_inline = $Test::Inline::VERSION ge '0.15_001'; };
  undef $@;
  if ($have_test_inline) {
    print "Good - you have a patched Test::Inline\n";
  } else {
    print "Test::Inline 0.15_001 is nice for testing the examples, but not necessary\n"
  };
};

# Synopsis tests are disabled. This is a hack release.
__END__
# Autocreate the synopsis test from the pod of every module
# (if we have Test::Inline)
{
    package MY;
    use strict;
    sub top_targets {

        my($self) = @_;
        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        return $out unless $main::have_test_inline;

        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        $out .= "\n\ntestifypods : \n";

        foreach my $pod (keys %{$self->{MAN1PODS}},
                         keys %{$self->{MAN3PODS}})
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s|/|-|g;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "embedded-$test.t";
            $out .= "\t$self->{NOECHO}\$(POD2TEST_EXE) ".
                    "$pod t/$test\n";
        }

        return $out;
    }
}
