package Mambba::Service;

use Mojo::Server::Hypnotoad::Mambba;


sub start {
    my ($job, $service ) = @_;

    my $app_name = $service->{lib};
    my $config = $service->{config};

    $job->app->log->info(qq{Launch service "$app_name"});
    Mojo::Server::Hypnotoad::Mambba->new->run($app_name,$config);
}

sub stop {

}

1;