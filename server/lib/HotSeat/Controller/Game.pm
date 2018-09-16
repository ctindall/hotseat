package HotSeat::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';
use HotSeat::Model::Game;

sub create {
    my ($self) = @_;
    my $rom_name = $self->param('rom_name');
    my $system   = $self->param('system');
    my $owned_by = $self->param('owned_by');
    my $password = $self->param('password');
    my $game;

    # try to create the game
    eval { 
	$game = HotSeat::Model::Game->create($self->app->config('games_dir'), 
					     $rom_name, $system, $owned_by, $password);
    };
    
    if ($@) { #something went wrong with creating the game
	return $self->render(json => {
	    errors => ( { detail => "Could not create game." } ),
	}, status => 400);
    }
    
    # everything went OK
    $self->res->headers->header('Location:' => '/game/'.$game->game_id);
    
    return $self->render(json => {
	game_id    => $game->game_id,
	locked     => $game->locked ? \1 : \0,
	locked_by  => $game->locked_by,
	rom_name   => $game->rom,
	system     => $game->system,
	save_state => $game->save_state,
    }, status => 201);
}

sub create_existing {
    my ($self) = @_;
    my $game = HotSeat::Model::Game->find_by_id($self->app->config('games_dir'), $self->stash('game_id'));

    #409 if there is such a game.
    return $self->render( json => {
	errors => ( { detail => "No such game." } )
    }, status => 409) if defined $game;

    #404 if there isn't.
    return $self->render( json => {
	errors => ( { detail => "No such game." } )
    }, status => 404);
}

sub read {
    my ($self) = @_;
    my $game;

    die "\$config('games_dir') must be set" unless defined $self->app->config('games_dir');
    
    $game = HotSeat::Model::Game->find_by_id($self->app->config('games_dir'), $self->stash('game_id'));

    return $self->render(json => {
    	errors => ( { detail => "No such game." } ),
     }, status => 404) unless defined $game;

    return $self->render(json => {
    	errors => ( { detail => "Invalid game password." } ),
    }, status => 403) unless $game->password_ok($self->param('password'));
    
    return $self->render(json => {
	game_id   => $game->game_id,
	locked    => $game->locked ? \1 : \0,
	locked_by => $game->locked_by,
	rom_name  => $game->rom,
	system    => $game->system,
	owned_by   => $game->owner,
	save_state => $game->save_state,
    });
}

sub update {
    my ($self) = @_;
    my $game;
    
    die "\$config('games_dir') must be set" unless defined $self->app->config('games_dir');

    $game = HotSeat::Model::Game->find_by_id($self->app->config('games_dir'), $self->stash('game_id'));

    return $self->render(json => {
    	errors => ( { detail => "No such game." } ),
     }, status => 404) unless defined $game;

    return $self->render(json => {
    	errors => ( { detail => "Invalid game password." } ),
    }, status => 403) unless $game->password_ok($self->param('password'));
    
    #do the updating
    if (defined $self->param('new_password')) {
	$game->password($self->param('new_password'));
    }

    if (defined $self->param('owned_by')) {
	$game->owner($self->param('owned_by'));
    }

    if (defined $self->param('rom_name')) {
	$game->rom($self->param('rom_name'));
    }

    if (defined $self->param('system')) {
	$game->system($self->param('system'));
    }
    
    if (defined $self->param('save_state')) {
	$game->save_state($self->param('save_state'));
    }

    #return the new object
    return $self->render(json => {
	game_id    => $game->game_id,
	locked     => $game->locked ? \1 : \0,
	locked_by  => $game->locked_by,
	rom_name   => $game->rom,
	system     => $game->system,
	owned_by   => $game->owner,
	save_state => $game->save_state,
    });
	
}

sub delete {
    my ($self) = @_;
    my $game;
    
    die "\$config('games_dir') must be set" unless defined $self->app->config('games_dir');

    $game = HotSeat::Model::Game->find_by_id($self->app->config('games_dir'), $self->stash('game_id'));

    return $self->render(json => {
    	errors => ( { detail => "No such game." } ),
     }, status => 404) unless defined $game;

    return $self->render(json => {
    	errors => ( { detail => "Invalid game password." } ),
    }, status => 403) unless $game->password_ok($self->param('password'));

    $game->delete();

    return $self->render(json => { success => \1 }, status => 204);
}

1;
