package Mojolicious::Mambba;

use Mojo::Base 'Mojolicious';
use Mambba;

sub startup {

    my $self = shift;

    $self->plugin(Config => { file => $ENV{MOJO_CONFIG} } )
            unless defined $self->config();

    $self->plugin(Minion => { 'Mango::Mambba' => $self->config->{plugins}->{minion} });

#    $self->app->log(Mojo::Log->new(%{$self->config->{log}}));

#    my $r = $self->routes;

#    $self->minion->add_task(task_runner => sub {
#
#        return
#            unless ref $_[1] eq  'HASH';
#
#        warn "Run task: ", $_[1]->{name};
#
#        my $eval_job = eval $_[1]->{code};
#
#        $_[0]->app->log->info(dump($data_log))
#            if scalar @{$data_log};
#    });

#    $self->minion->add_task(slow_log => sub {
#      my ($job, $msg) = @_;
#      warn "task";
#      sleep 5;
#      $job->app->log->debug(qq{Received message "$msg".});
#    });


#    $self->minion->add_task(start => sub {
#        my ($job, $service ) = @_;
#
#        my $app_name = $service->{lib};
#        my $config = $service->{config};
#
#        $job->app->log->info(qq{Launch service "$app_name"});
#        $ENV{PEREVEDEM_SERVICE} = $app_name;
#
#        require Mojo::Server::Hypnotoad::ALS;
#        Mojo::Server::Hypnotoad::ALS->new->run($app_name,$config);
#    });

#    $self->minion->add_task(stop => sub {
#        my ($job, $service) = @_;
#        my $app_name = $service->{lib};
#        my $config = $service->{config};
#
#        $job->app->log->info(qq{Stop service "$app_name"});
#
#        $ENV{PEREVEDEM_SERVICE} = $app_name;
#        $ENV{HYPNOTOAD_STOP} = 1;
#
#        require Mojo::Server::Hypnotoad::ALS;
#        Mojo::Server::Hypnotoad::ALS->new->run($app_name,$config);
#    });

#    $self->minion->add_task( add_worker =>  sub {
#        my $job = shift;
#
#        my $commands = $job->app->commands;
#        my $name = 'minion';
#        #warn dump @{$commands->namespaces};
#        require Mojo::Loader;
#        my $e = Mojo::Loader->new->load('Minion::Command::minion');
#        my $module = 'Minion::Command::minion';
#        my $command = $module->new(app => $job->app);
#        $command->run('worker');
#    });

#    $self->plugin(MangoAPI => {
#        uri => $uri,
#        rest_name => 'api',
#        router => $r
#    });

=pod

    commands:

    POST ->
        _install
        _run
        _cancel

    {
        name => 'My Task',
        lib => 'My::Task',

        meta => {
            type => 'cpan'|'pinto'|'git',
            current_version => '0.0.2' | 'werq342sdf',
            last_update => 2014-02-12T22:00:00,
        },

        allow_host => []
    }

=cut

#    $r->post('api/task/:oid/:command' => sub {
#        my $self = shift;
#        my $oid = bson_oid( $self->stash('oid') );
#        $self->res->headers->content_type('application/json;charset=UTF-8');
#
#        $self->render_later;
#
#        my $c = $self->app->mango->db->collection('task');
#        $c->find_one($oid => sub {
#            my ($cursor, $err, $doc) = @_;
#
#            return
#                $self->render(json => {
#                    ok => 0,
#                    msg => $err
#                })
#                    if $err;
#
#            $self->minion->enqueue(task_runner => [$doc,$self->param('msg')] => sub {
#                my ($minion, $err, $oid) = @_;
#
#                return
#                    $self->render(json => {
#                        ok => 0,
#                        msg => $err
#                    })
#                        if $err;
#
#                $self->render(json => {
#                    ok => 1,
#                    msg => "Success run!"
#                });
#            });
#        });
#    });

#    $r->get('api/workers' => sub {
#          my $self = shift;
#          $self->res->headers->content_type('application/json;charset=UTF-8');
#          $self->render_later;
#
#          $self->minion->backend->workers->find->all(sub{
#                my ($cursor, $err, $docs) = @_;
#
#                if ($err) {
#                    $self->render(json => {
#                        ok => 0,
#                        msg => $err
#                    });
#                } else {
#                    $self->render(json => {
#                        ok => 1,
#                        data => $docs,
#                        total => scalar (@$docs)
#                    });
#                }
#          });
#
#    });

#    $r->post('api/workers' => sub {
#          my $self = shift;
#          $self->render_later;
#
#          $self->minion->enqueue(add_worker => sub {
#              my ($minion,$err,$oid) = @_;
#
#              warn "Add worker: ",$minion,($err // 'undef err'),$oid;
#
#              $self->render(json => {
#                    ok => 1,
#                    msg => "ok"
#              });
#          });
#    });

#    $r->get('api/jobs' => sub {
#          my $self = shift;
#          $self->res->headers->content_type('application/json;charset=UTF-8');
#          $self->render_later;
#          my $page = $self->param('page') // 1;
#          my $limit = $self->param('limit') // 10;
#          my $skip = ($page-1)*$limit;
#          my $c = $self->minion->backend->jobs->find->skip($skip)->limit($limit)->sort({started => -1});
#
#          my $clone = $c->clone;
#          $c->all(sub{
#                my ($cursor, $err, $docs) = @_;
#
#                if ($err) {
#                    $self->render(json => {
#                        ok => 0,
#                        msg => $err
#                    });
#                } else {
#                    $self->render(json => {
#                        ok => 1,
#                        data => $docs
#                    });
#                }
#          });
#
#    });

#    $r->get('api/log' => sub {
#        my $c = shift;
#
#        Mojo::IOLoop->stream($c->tx->connection)->timeout(300);
#
#        $c->res->headers->content_type('text/event-stream');
#
#        my $cb = $c->app->log->on(message => sub {
#            my ($log, $level, @lines) = @_;
#            $c->write("event:log\ndata: [$level] @lines\n\n");
#        });
#
#        $c->on(finish => sub {
#            my $c = shift;
#            $c->app->log->unsubscribe(message => $cb);
#        });
#    });

#    $r->get('api/service/:oid/log' => sub {
#        my $c = shift;
#        # Increase inactivity timeout for connection a bit
#        Mojo::IOLoop->stream($c->tx->connection)->timeout(300);
#        $c->render_later;
#        # Change content type
#        $c->res->headers->content_type('text/event-stream');
#        my $service = $c->service->find_one(bson_oid($c->stash('oid')));
#        $c->app->log->debug("read log from ".$service->{config}->{log}->{path});
#        #$c->app->log->debug("($service));
##        my $pid = open(my $fh, "-|", 'tail -f -n -15 '.$service->{config}->{log}->{path});
#        my $pid = open(my $fh, "-|", 'tail -f -n -15 log/listen.log');
#        defined($pid) || die "can't fork: $!";
#        # Create stream
#
#        my $stream = Mojo::IOLoop::Stream->new($fh);
#        $stream->timeout(0);
#
#        Mojo::IOLoop->singleton->stream($stream);
#
#        $stream->on(read => sub {
#             my ($stream, $chunk) = @_;
#             say "chunk: $chunk";
#             $c->write("event:log\ndata:".join('_*_',split("\n",$chunk))."\n\n");
#        });
#
#        $stream->on(close => sub {
#             my $stream = shift;
#             say "Close";
#             $c->write("event:log\ndata:Closed\n\n") if $c;
#             $c->finish;
#        });
#        $stream->on(error => sub {
#            my ($stream, $err) = @_;
#            say "MY Error: $err";
#            kill("TERM", $pid) if $pid;
#            undef $pid;
#            $c->finish if $c;
#         # Do we need this?
#
#            Mojo::IOLoop->singleton->drop($fh);
#        });
#        # Unsubscribe from "message" event again once we are done
#
#
#        $c->on(finish => sub {
#            my $c = shift;
#            say "Finishing";
#            kill("TERM", $pid) if $pid;
#            undef $pid;
#            # This appears not to be needed?
#
##            Mojo::IOLoop->singleton->drop($fh);
#        });
#    });

#    $r->post('/api/launch' => sub {
#        my $self = shift;
#        my $service = $self->req->json;
#        $self->render_later;
#        $self->minion->enqueue(launch => [$service // {}] => sub {
#            my ($minion, $err, $oid) = @_;
#            warn "Test: ",$minion,$err,$oid;
#            my $job = $minion->job($oid);
#            warn "Job", $job->state;
#            $job->on(finished => sub {
#                my $job = shift;
#                my $oid = $job->id;
#                $job->app->log->debug("Job $oid is finished.");
#            });
#
#            $job->on(failed => sub {
#              my ($job, $err) = @_;
#              $job->app->log->debug("Something went wrong: $err");
#            });
#        });
#
#        $self->minion->worker->on(dequeue => sub {
#           my ($worker, $job) = @_;
#           $job->app->log->debug("finished launched");
#        });
#
#        $self->render(json => {
#            ok => 1,
#            msg => 'wait…'
#        });
#    });

#    $r->post('/api/stop' => sub {
#        my $self = shift;
#        my $service = $self->req->json;
#        $self->minion->enqueue(stop => [$service // {}]);
#        $self->render(json => {
#            ok => 1,
#            msg => 'wait…'
#        });
#    });

}