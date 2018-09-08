package HotSeat::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';
use HotSeat::Model::Game;

# sub create {
#     my($self) = @_;

#     $self->render(json => { text => "hi" });
# }

sub create {
    my ($self) = @_;
    my $rom_name = $self->param('rom_name');
    my $system   = $self->param('system');
    my $owned_by = $self->param('owned_by');
    my $password = $self->param('password');
    my $game;

    # try to create the game
    eval {
	$game = HotSeat::Model::Game->create($rom_name, $system, $owned_by, $password);
    };
    
    if ($@) { #something went wrong with creating the game
	return $self->render(json => {
	    errors => ( { detail => "Could not create game." } ),
	}, status => 400);
    }
    
    # everything went OK
    $self->res->headers->header('Location:' => '/game/'.$game->game_id);
    
    return $self->render(json => {
	game_id   => $game->game_id,
	locked    => $game->locked ? \1 : \0,
	locked_by => $game->locked_by,
	rom_name  => $game->rom,
	system    => $game->system,
    }, status => 201);
}

sub create_existing {
    my ($self) = @_;
    my $game = HotSeat::Model::Game->find_by_id($self->stash('game_id'));

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

    eval {
	$game = HotSeat::Model::Game->find_by_id($self->stash('game_id'));
    };

    return $self->render(json => {
	errors => ( { detail => "No such game." } ),
    }, status => 404) if $@;

    return $self->render(json => {
	errors => ( { detail => "Invalid game password." } ),
    }, status => 403) unless $game->password_ok($self->param('password'));
    
    return $self->render(json => {
	game_id   => $game->game_id,
	locked    => $game->locked ? \1 : \0,
	locked_by => $game->locked_by,
	rom_name  => $game->rom,
	system    => $game->system,	
    });
}

1;
