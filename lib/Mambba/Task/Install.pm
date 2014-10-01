package Mambba::Task::Install;

use Mojo::Base 'Mambba::Task';

has params => ['module'];

=pod

=head1 module

	"_id": "53f1ac1f5b6781bbe4040000",
  "hosts": [
  {
    "host": "antoniko.local"
  }
  ],
  "git": "git://src-tms.als.local/tms/mymodule",
  "lang": "perl",
  "mirror": "develop.als.local:3001",
  "lib": "Mambba::Task::Test",
  "intaller": "cpanm"
  }

=cut

sub run {

}

sub cancel {

}

1;