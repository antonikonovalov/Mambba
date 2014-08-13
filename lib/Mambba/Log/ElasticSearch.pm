package Mambba::Log::ElasticSearch;

use Mojo::UserAgent;
use Mojo::IOLoop;
use Mojo::Base -base;

has 'uri';

has ua =>  sub {
    return new Mojo::UserAgent;
};

sub print {
    my ($self,$msg) = @_;
    warn "MSG for log",Data::Dumper::Dumper($msg);

    $self->ua->post( $self->uri => {DNT => 1} => json => $msg ,sub {
        print "set new log msg\n@_";
#         Mojo::IOLoop->stop;
    });
}

1;
