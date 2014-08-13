use Mambba::Log;
use Mojo::IOLoop;

my $time = time;
warn "time  - ",$time;
my $log = new Mambba::Log(elasticsearch => 'http://localhost:9200/mambba/log/');

$log->debug("Test msg Aloxa");

Mojo::IOLoop->start;

1;