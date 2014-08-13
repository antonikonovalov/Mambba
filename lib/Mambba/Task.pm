package Mambba::Task;

use Mojo::Base 'Mojolicious::Command';
use Mambba::Log;

has 'job';

1;

=pod

=head1 Attributes - all it's for create order task


=head1 Methods

=head2 cancel

It's call before kill process - last action if you want cancel task

=head2 run

 $t->run()

 Run your task with current attributes

=cut