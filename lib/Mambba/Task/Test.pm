package Mambba::Task::Test;

use Mojo::Base 'Mambba::Task';

sub run {
    warn Data::Dumper::Dumper(@_);
}


1;