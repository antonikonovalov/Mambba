package Minion::Backend::Mango::Mambba;

use Mojo::Base 'Minion::Backend::Mango';

use Mango::BSON qw(bson_oid bson_time);
use Scalar::Util 'weaken';
use Sys::Hostname 'hostname';

has hosts =>
  sub { $_[0]->mango->db->collection('hosts') };

sub dequeue {
  my ($self, $oid, $timeout) = @_;

  # Capped collection for notifications
  $self->_notifications;

  # Await notifications
  my $host = hostname;
  my $end = bson_time->to_epoch + $timeout;
  my $job;
  do { $self->_await and $job = $self->_try($oid,$host) }
    while !$job && bson_time->to_epoch < $end;

  return undef unless $self->_job_info($job ||= $self->_try($oid,$host));
  return {args => $job->{args}, id => $job->{_id}, task => $job->{task}};
}

sub enqueue {
  my ($self, $task, $host) = (shift, shift, shift);
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $args    = shift // [];
  my $options = shift // {};

  # Capped collection for notifications
  $self->_notifications;

  my $doc = {
    args    => $args,
    created => bson_time,
    delayed =>
      bson_time($options->{delay} ? (time + $options->{delay}) * 1000 : 1),
    priority => $options->{priority} // 0,
    state    => 'inactive',
    task     => $task,
    host     => $host,
  };

  # Non-blocking
  return Mojo::IOLoop->delay(
    sub { $self->jobs->insert($doc => shift->begin) },
    sub {
      my ($delay, $err, $oid) = @_;
      return $self->pass($oid, $err) if $err;
      $delay->pass($oid);
      $self->notifications->insert({c => 'created'} => $delay->begin);
    },
    sub {
      my ($delay, $oid, $err) = @_;
      $self->$cb($err, $oid);
    }
  ) if $cb;

  # Blocking
  my $oid = $self->jobs->insert($doc);
  $self->notifications->insert({c => 'created'});
  return $oid;
}

sub _try {
  my ($self, $oid,$host) = @_;

  my $doc = {
    query => {
      delayed => {'$lt' => bson_time},
      state   => 'inactive',
      task    => {'$in' => [keys %{$self->minion->tasks}]},
      host    => (ref $host eq 'ARRAY' ? {'$in' => $host } : $host ) ,
    },
    fields => {args     => 1, task => 1},
    sort   => {priority => -1},
    update =>
      {'$set' => {started => bson_time, state => 'active', worker => $oid}},
    new => 1
  };

  return $self->jobs->find_and_modify($doc);
}

sub _host {
	my $self = shift;
	my $host = $self->hosts->find_one({original_name => hostname});

  $host = $self->hosts->create({
      original_name => hostname,
      name => hostname,
      dsc => 'created when start workers'
    })
      unless $host;

	return $host;

}
sub register_worker {
	my $self = shift;

  $self->workers->insert({
    host => hostname,
    pid => $$,
    started => bson_time,
    host_id => $self->_host->{_id}
  });
}

1;
