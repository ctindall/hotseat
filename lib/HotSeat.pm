package HotSeat;
use Mojo::Base 'Mojolicious';

use File::Basename;
use File::Path qw( make_path ); 
use Cwd;

my $basedir = dirname($0);
$basedir = Cwd::abs_path("$basedir/..");

sub get_game {
    my $game_id = shift;
    my $lock_file = "$basedir/games/$game_id/lock";
    my $locked = (-e $lock_file) ? 1 : 0;
    my $locked_by;
    
    if ($locked) {
	open(my $lockhandle, '<', $lock_file);
	$locked_by = <$lockhandle>;
	close($lockhandle);
    }

    unless (wantarray) {
	return $locked; #just return a bool in scalar context
    }

    return (
	game_id => $game_id,
	locked => $locked,
	locked_by => $locked_by,
	lock_file => $lock_file,
    );
}

sub lock_game {
    my $game_id = shift;
    my $user = shift; 
    my %game = get_game($game_id);

    if ($game{'locked'}) {
	return 0;
    }

    if ( !-e dirname($game{'lock_file'})) {
	make_path(dirname($game{'lock_file'}));	
    }
    
    open(my $fh, '>', $game{'lock_file'});
    print $fh $user; 
    close $fh;

    return get_game($game_id);
}

sub unlock_game {
    my $game_id = shift;
    my %game = get_game($game_id);

    if ($game{'locked'}) {	
	unlink $game{'lock_file'};
    }
    
    return get_game($game_id);
}

sub startup {
    my $self = shift;

    $self->secrets(['-1109089652486567240']);
    my $r = $self->routes;

    $r->get('/game/:game_id/lock' => sub { 
	my $c = shift;
	my $game_id = $c->stash('game_id');
	my %game = get_game($game_id);
	
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
	});
    });

    $r->post('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id');
	my $user = $c->param('user');
	my %game = get_game($game_id);
	
	if ( !$game{'locked'} ) {
	    %game = lock_game($game_id, $user);
	}
    
	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
        });
    });

    $r->delete('/game/:game_id/lock' => sub {
	my $c = shift;
	my $game_id = $c->stash('game_id');
	my %game = unlock_game($game_id);

	$c->render(json => {
	    game_id => $game{'game_id'},
	    locked => $game{'locked'} ? \1 : \0,
	    locked_by => $game{'locked_by'},
        });
   });
};

1;
