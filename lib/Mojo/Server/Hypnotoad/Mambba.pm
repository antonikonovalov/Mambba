package Mojo::Server::Hypnotoad::Mambba;
use Mojo::Base 'Mojo::Server::Hypnotoad';

use Data::Dump qw/dump/;
use Mojo::Util 'steady_time';
use Scalar::Util 'weaken';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Mojo::Loader;

sub run {
    my ($self,$app_name,$config) = @_;
    warn __PACKAGE__,"Run: ",$app_name,dump($config);
    # Remember executable and application for later
    $ENV{HYPNOTOAD_EXE} ||= abs_path 'script/mambba';
#    $0 = $ENV{HYPNOTOAD_APP} ||= abs_path $app_name;

    # This is a production server
    $ENV{MOJO_MODE} ||= $config->{mode}||'development';

    $ENV{HYPNOTOAD_REV}++;
    # Clean start (to make sure everything works)
#    die "Can't exec: $!" if !$ENV{HYPNOTOAD_REV}++;

    # Preload application and configure server
    my $prefork = $self->prefork;

    my $app = $app_name->new(config => $config) unless my $e = Mojo::Loader->new->load($app_name);
    #set app to prefork
    $prefork->app($app);
    $config->{hypnotoad}->{pid_file}
        //= catfile dirname($ENV{MOJO_HOME}), 'hypnotoad.pid';

    $self->configure('hypnotoad');
    weaken $self;
    $prefork->on(wait   => sub { $self->_manage });
    $prefork->on(reap   => sub { $self->_reap(pop) });
    $prefork->on(finish => sub { $self->{finished} = 1 });

    # Testing
    _exit('Everything looks good!') if $ENV{HYPNOTOAD_TEST};

    # Stop running server
    $self->_stop if $ENV{HYPNOTOAD_STOP};

    # Initiate hot deployment
    $self->_hot_deploy unless $ENV{HYPNOTOAD_PID};

    # Daemonize as early as possible (but not for restarts)
    $prefork->daemonize
    if !$ENV{HYPNOTOAD_FOREGROUND} && $ENV{HYPNOTOAD_REV} < 3;

    # Start accepting connections
    local $SIG{USR2} = sub { $self->{upgrade} ||= steady_time };
    $prefork->run;
}

1;
