package HotSeat;
use lib 'lib';
use Mojo::Base 'Mojolicious';
use Mojo::Upload;
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

	if (!$game{'exists'}) {
	    $c->render(json => {
		game_id => $game_id,
		exists => \0,
		error => "No such game",
	    }, status => 404);
	}
	
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    rom_name => $game{'rom_name'},
	    system => $game{'system'},
	});
    });

    $r->put('/game/:game_id' => sub { 
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my $rom_name = $c->param('rom_name');
	my $system = $c->param('system');
	my $owned_by = $c->param('owned_by');
	my $password = $c->param('password');
	my %game = get_game($game_id);
	my $success = 0;

	unless (defined $rom_name && defined $system && defined $owned_by && defined $password) {
	    $c->render(json => {
		game_id => $game_id,
		error => "Could not create game: password, owned_by, rom_name, & system are required.",
		       }, status => 400);

	    return;
	}
	
	if (!$game{'exists'}) {
	    $success  = create_game $game_id, $rom_name, $system, $owned_by, $password;
	    %game = get_game $game_id;
	}

	if ($success) {
	    $c->render(json => {
		game_id => $game{'game_id'},
		locked => $game{'locked'} ? \1 : \0,
		locked_by => $game{'locked_by'},
		rom_name => $game{'rom_name'},
		system => $game{'system'},
		owned_by => $game{'owned_by'}
	     }, status => 201);

	    return;
	}
	    
	$c->render(json => {
	    game_id => $game_id,
	    error => "Could not create game.",
	}, status => 400);
    });
    
    $r->post('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my $user = $c->param('user');
	my %game = get_game($game_id);

	unless ($game{'exists'}) {
	    $c->render(json => {
		game_id => $game_id,
		error => "No such game",	    
	    }, status => 404);

	    return;
	}
	
	%game = lock_game $game_id, $user;
	
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    rom_name => $game{'rom_name'},
	    system => $game{'system'},
        }, status => 201);
    });

    $r->delete('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0; #ensure game_id is a number
	my %game = unlock_game($game_id);

	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    rom_name => $game{'rom_name'},
	    system => $game{'system'},
        });
   });


    #savestate upload

    $r->post('/game/:game_id/state' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0;
	my $user = $c->param('user');
	my %game = get_game($game_id);

	my $state_file = Mojo::Upload->new;
	$state_file->asset($c->req->upload('save_state'));
	$state_file->filename('state.sna');
	$state_file->move_to($game{'state_file'});

	if($game{'locked'} && $game{'locked_by'} ne $user) {
	    $c->render(json => {
		game_id => $game{'game_id'},
		locked => $game{'locked'} ? \1 : \0,
		locked_by => $game{'locked_by'},
		rom_name => $game{'rom_name'},
		system => $game{'system'},
	     }, status => 403);

	    return;
	}
	
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	    rom_name => $game{'rom_name'},
	    system => $game{'system'},
	});
    });
    
    $r->get('/game/:game_id/state' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id') + 0;
	my %game = get_game($game_id);
		
	$c->render_file( filepath => $game{'state_file'},
			 filename => "state.sna");
    });
};

1;
