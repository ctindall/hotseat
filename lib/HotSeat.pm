package HotSeat;
use lib 'lib';
use Mojo::Base 'Mojolicious';
use HotSeat::Model::Games;

sub startup {
    my $self = shift;
    
    $self->secrets(['-1109089652486567240']);
    $self->plugin('RenderFile');

    my $config = $self->plugin('Config');
    set_games_dir($config->{games_dir});
    
    my $r = $self->routes;

    $r->get('/game/:game_id/lock' => sub { 
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my %game = get_game($game_id);
	
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    filename => $game{'rom_name'},
	});
    });

    $r->post('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my $user = $c->param('user');
	my %game = get_game($game_id);
	
	if ( !$game{'locked'} ) {
	    %game = lock_game($game_id, $user);
	}
    
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    filename => $game{'rom_name'},
        });
    });

    $r->delete('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my %game = unlock_game($game_id);

	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    filename => $game{'rom_name'},
        });
   });
    
    $r->get('/game/:game_id/state' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0;
	my %game = get_game($game_id);

	$c->render_file(
	    filepath => $game{'state_file'},
	    filename => "$game{'rom_name'}.sna",
	);
    });
};

1;
