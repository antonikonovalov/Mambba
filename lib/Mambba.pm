package Mambba;
use Mojo::Base 'Mojo::EventEmitter';

use Carp 'croak';
use Scalar::Util 'weaken';

use Mambba::Task;
use Mambba::Host;
use Mambba::Service;
use Mambba::Requires;



use Data::Dump qw/dump/;

use Mango::BSON  qw/bson_oid/;
use Mojo::Collection qw/c/;

our $VERSION = '0.0.1';

has [qw(app)];

# db's
has mongodb => 'mongodb://127.0.0.1:27017/';
has elasticsearch => 'http://localhost:9200/';
has redis  => '127.0.0.1:27017';

has base_url => '/';
has prefix => 'mambba';

sub _mongodb { $_[0]->mongodb.$_[0]->prefix }

sub new {
  my $self = shift->SUPER::new(@_);

  my $mongodb_uri = $self->_mongodb;

  $self->app->plugin(
    Minion => { 'Mango::Mambba' => $mongodb_uri }
  );

  $self->app->plugin('MangoAPI',{
    uri => $mongodb_uri,
    rest_name => $self->prefix,
  });

  $self->_router;

  return $self;
}

sub _task {
	my $self = shift;
	$self->app->minion->add_task(task_runner => sub {

#		my ($job, $msg) = @_;
		my $args = c(@_);

		warn "task runner => $args";
	});

	$self->app->minion->add_task(task_installer => sub {

  #		my ($job, $msg) = @_;
  		my $args = c(@_);

  		warn "task runner => $args";
  });
}

sub _router {
	my $self = shift;

	my $r = $self->app->routes;

	$self->app->hook( before_dispatch => sub {
    my $c = shift;
		$c->res->headers->header( 'Access-Control-Allow-Origin' => '*' );
		$c->res->headers->header( 'Access-Control-Allow-Methods' => 'GET, PUT, POST, DELETE, OPTIONS' );
		$c->res->headers->header( 'Access-Control-Max-Age' => 3600 );
		$c->res->headers->header( 'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With' );
  });

=pod

	require => {
		lib => 'My::Lib'
    intaller => 'cpanm'
    install_from => 'cpan'||'mirror'||'git'
		mirror => 'develop.als.local:3001'
		git => 'git://src-tms.als.local/tms/mymodule'
    lang => 'perl'
    is_task => 0 || 1
    hosts => [
      {
        host_id => '12wer',
        host    => 'antoniko.local',
        version => "v0.0.3",
        status: 'install' || 'broken' || 'not install yet' || 'uninstall'
        last_update => 123123 # date update or install
      }
    ]
	}

=cut

	$r->mango_api('requires');
  $r->mango_api('services');
  $r->mango_api('hosts');

=pod

	task => {
		label => 'dev_test_task',
		require_id => 'asdasdasd234',
		params => ['first_args','second_arg']
	}

=cut

  $r->mango_api('tasks');

	# host
	$r->post( $self->prefix.'/requires/:oid/hosts' => sub {
		my $c = shift;
    my $oid = bson_oid( $c->stash('oid') );
    $c->render_later;

    $c->requires->find_one($oid => sub {
			my ($cursor, $err, $doc) = @_;

			my $hosts = c(@{$doc->{hosts}});
			return
				$c->render(json => { ok => 0, msg => $err})
					if $err or !c(@{$doc->{hosts}});


			$hosts->map(sub { $c->minion->enqueue(task_installer => [$_->{host}] => [$doc]) });

			$c->render(json => {
				ok => 1,
				msg => 'start install'
			});
    });
	});
  # workers
  # get workers for hosts
  $r->get( $self->prefix.'/hosts/:oid/workers'  => sub {
    my $c = shift;
    my $oid = bson_oid( $c->stash('oid') );
    $c->render_later;

    $c->minion->backend->workers->find({host_id => $oid})->all(sub {
      my ($cursor, $err, $docs) = @_;
      my $msg;
      $msg = { ok => 0, msg => $err} if $err;

      $msg = {
        ok => 1,
        data => $docs,
        total => scalar (@$docs),
      };

      $c->res->headers->content_type('application/json;charset=UTF-8');
      return $c->render(json => $msg);
    });

  });
  # create workers for hosts
  $r->post( $self->prefix.'/hosts/:oid/workers' => sub {

    my $c = shift;
    my $oid = bson_oid( $c->stash('oid') );
    $c->render_later;

		warn "hosts ->".$c->hosts;

    $c->hosts->find_one( $oid => sub {
        my ($cursor, $err, $doc) = @_;

        return
          $c->render(json => { ok => 0, msg => $err})
            if $err;

        $c->minion->backend->workers->update(
          { host    => $doc->{original_name} },
          { '$set' => {host_id => $oid } },
          { multi => 1 } => sub {
            my ($cursor, $err, $docs) = @_;
            my $msg;

            $msg = { ok => 0, msg => $err} if $err;
						warn "docs:".Data::Dumper::Dumper($docs);

            $msg = {
              ok => 1,
              data => $docs,
            };

            $c->res->headers->content_type('application/json;charset=UTF-8');
            return $c->render(json => $msg);
          });
		});
  });
  $r->get( $self->prefix.'/workers' => sub {
    my $c = shift;
    $c->render_later;

    $c->minion->backend->workers->find->all(sub{
      my ($cursor, $err, $docs) = @_;

      my $msg;

      $msg = { ok => 0, msg => $err} if $err;
      $msg = {
          ok => 1,
          data => $docs,
          total => scalar (@$docs),
      };

      $c->res->headers->content_type('application/json;charset=UTF-8');
      return $c->render(json => $msg);
    });
  });

    # jobs
    $r->get( $self->prefix.'/jobs' => sub {
        my $c = shift;
        $c->render_later;

        my $page = $c->param('page') // 1;
        my $limit = $c->param('limit') // 10;
        my $skip = ($page-1)*$limit;
        my $cur = $c->minion->backend->jobs->find
            ->skip($skip)
            ->limit($limit)
            ->sort({started => -1});

        my $clone = $cur->clone;
        $cur->all(sub{
            my ($cursor, $err, $docs) = @_;
            my $msg;

            $msg = { ok => 0, msg => $err} if $err;
            $msg = {
                ok => 1,
                data => $docs,
            };

            $c->res->headers->content_type('application/json;charset=UTF-8');
            return $c->render(json => $msg);
        });
    });

}

1;
