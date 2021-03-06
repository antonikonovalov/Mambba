package Mojolicious::Plugin::Mambba;
use Mojo::Base 'Mojolicious::Plugin';

use Mambba;
use Scalar::Util 'weaken';

sub register {
    my ($self, $app, $conf) = @_;

    my $mambba = Mambba->new(
        app => $app,
        mongodb => $conf->{mongodb} || 'mongodb://127.0.0.1:27017/',
        elasticsearch => $conf->{elasticsearch} || 'http://localhost:9200/',
        redis  => $conf->{redis} || '127.0.0.1:27017',
        base_url => $conf->{base_url} || '/',
        prefix  => $conf->{prefix} || 'mambba',
    );

    weaken $mambba->app($app)->{app};
    $app->helper(mambba => sub { $mambba });
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Mambba - Mambba

=head1 SYNOPSIS

  # Mojolicious (choose a backend)
  $self->plugin(Minion => {File  => '/Users/sri/minion.data'});
  $self->plugin(Minion => {Mango => 'mongodb://127.0.0.1:27017'});

  # Mojolicious::Lite (choose a backend)
  plugin Minion => {File  => '/Users/sri/minion.data'};
  plugin Minion => {Mango => 'mongodb://127.0.0.1:27017'};

  # Add tasks to your application
  app->minion->add_task(slow_log => sub {
    my ($job, $msg) = @_;
    sleep 5;
    $job->app->log->debug(qq{Received message "$msg".});
  });

  # Start jobs from anywhere in your application (data gets BSON serialized)
  $c->minion->enqueue(slow_log => ['test 123']);

  # Perform jobs in your tests
  $t->get_ok('/start_slow_log_job')->status_is(200);
  $t->get_ok('/start_another_job')->status_is(200);
  $t->app->minion->perform_jobs;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Minion> is a L<Mojolicious> plugin for the L<Minion>
job queue.

=head1 HELPERS

L<Mojolicious::Plugin::Minion> implements the following helpers.

=head2 minion

  my $minion = $app->minion;
  my $minion = $c->minion;

Get L<Minion> object for application.

  # Add job to the queue
  $c->minion->enqueue(foo => ['bar', 'baz']);

  # Perform jobs for testing
  $app->minion->perform_jobs;

=head1 METHODS

L<Mojolicious::Plugin::Minion> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, {Mango => 'mongodb://127.0.0.1:27017'});

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Minion>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

