package Mambba::Log;

use Mojo::Base 'Mojo::Log';

use Mambba::Log::ElasticSearch;

use Carp 'croak';
use Fcntl ':flock';
use Mojo::Util 'encode';

has 'elasticsearch';

has prefix => 'mambba';
has 'meta';


has format => sub { \&_format };
has handle => sub {
    my $self = shift;

    if (my $uri = $self->elasticsearch) {
        return new Mambba::Log::ElasticSearch(uri => $uri);
    }

    # File
    if (my $path = $self->path) {
        croak qq{Can't open log file "$path": $!}
            unless open my $file, '>>', $path;
        return $file;
    }

    # STDERR
    return \*STDERR;
};

sub _format {
  return {
    time => shift(),
    livel => shift(),
    data => encode('UTF-8', join("\n", @_, '')),
  };
}

sub append {
  my ($self, $msg) = @_;
  $msg->{meta} = $self->meta if $self->meta;

  return unless my $handle = $self->handle;
  $handle->print($msg) or croak "Can't write to log: $!";
}




1;

=pod

 log for
   - server $mambba->prefix.'/log'
   - servise $mambba->prefix.'/'. service_name
   - job $mambba->prefix.'/'. task_name
   - worker $mambba->prefix.'/'. worker

=cut