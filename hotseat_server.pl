#!/usr/bin/env perl
use Mojolicious::Lite;
use File::Basename;
use Cwd;

my $basedir = Cwd::abs_path(dirname($0)); 

sub get_game {
    my $gameid = shift;
    my $lock_file = "$basedir/games/$gameid/lock";
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
	game_id => $gameid,
	locked => $locked,
	locked_by => $locked_by,
	lock_file => $lock_file,
    );
}

get '/game/:gameid/lock' => sub { 
    my $c = shift;
    my $gameid = $c->stash('gameid');
    my %game = get_game($gameid);
     
    $c->render(json => {
	game_id => $game{'game_id'},
	locked => $game{'locked'} ? \1 : \0,
	locked_by => $game{'locked_by'},
    });
};

post '/game/:gameid/lock' => sub {
    my $c = shift;
    my $gameid = $c->stash('gameid');
    my $user = $c->param('user');
    my %game = get_game($gameid);

    unless ($game{'locked'}) {
	open(my $fh, '>', $game{'lock_file'});
	print STDOUT "Writing '$user' to '$game{'lock_file'}'.\n";
	print $fh $user; 
	close $fh;
	%game = get_game($gameid);
    }
    
    $c->render(json => {
	game_id => $game{'game_id'},
	locked => $game{'locked'} ? \1 : \0,
	locked_by => $game{'locked_by'},
    });
};

app->start('daemon');
