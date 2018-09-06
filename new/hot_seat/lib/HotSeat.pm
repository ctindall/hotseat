package HotSeat;
use Mojo::Base 'Mojolicious';

use HotSeat::Model::Users;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->helper( users => sub { state $users = HotSeat::Model::Users->new },
		 games => sub { state $games = HotSeat::Model::Games->new });
  
  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');
  
  # Router
  my $r = $self->routes;
  $r->any('/')
      ->to('login#index')
      ->name('index');

  my $logged_in = $r->under('/')->to('login#logged_in');
  $logged_in->get('/protected')->to('login#protected');

  $r->get('/logout')->to('login#logout');
  
}

1;
