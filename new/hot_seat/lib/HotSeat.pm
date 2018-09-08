package HotSeat;
use Mojo::Base 'Mojolicious';

use HotSeat::Model::Game;

# This method will run once at server start
sub startup {
  my $self = shift;
  
  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');
  
  # Router
  my $r = $self->routes;
  $r->post('/game')
      ->to('game#create')
      ->name('create_game');

  $r->post('/game/:game_id')
      ->to('game#create_existing')
      ->name('create_game_existing');

  $r->get('/game/:game_id')
      ->to('game#read')
      ->name('read_game');

  $r->patch('/game/:game_id')
      ->to('game#update')
      ->name('update_game');
      
}

1;
