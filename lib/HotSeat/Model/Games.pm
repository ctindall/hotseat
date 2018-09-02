package HotSeat::Model::Games;
use Exporter 'import';
our @EXPORT = qw( set_basedir slurp_file puke_file create_game get_game lock_game unlock_game );

use strict;
use warnings;

use File::Basename;
use File::Path qw( make_path ); 
use Cwd;

my $basedir = Cwd::abs_path(dirname($0));

sub set_basedir {
    $basedir = shift;
}

sub slurp_file {
    my $filename = shift;
    open(my $fh, '<', $filename);
    my $value = <$fh>;
    close $fh;
    return $value;
}

sub puke_file {
    my $filename = shift;
    my $value = shift;

    if ($value) {
	unlink $filename;
	open(my $fh, '>', $filename);
	print $fh $value;
	close $fh;
    }
}

sub create_game {
    my $game_id = shift;
    my $rom_name = shift;
    my $system = shift;

    my $game_dir = "$basedir/games/$game_id";

    unless ($rom_name) {
	$rom_name = "pokemon_blue.gb";
    }

    unless ($system) {
	$system = "gameboy";
    }

    unless (-e $game_dir) {
	make_path $game_dir;
    }

    unless (-e "$game_dir/rom_name") {
	puke_file "$game_dir/rom_name", $rom_name;
    }

    unless (-e "$game_dir/system") {
	puke_file "$game_dir/system", $rom_name;
    }

    return 1;
}

sub get_game {
    my $game_id = shift;
    my $game_dir = "$basedir/games/$game_id";
    my $exists = (-d $game_dir);

    my $locked = 0;
    my $locked_by = "";
    my $rom = "";
    my $state_file = "";

    if (!$exists) {
	create_game $game_id;
    }
    
    $locked = (-e "$game_dir/lock");

    if (-e "$game_dir/save.sna") {
	$rom = "$game_dir/save.sna"
    }

    if (-e "$game_dir/rom_name") {
	$rom = slurp_file "$game_dir/rom_name";
    }    
    
    if ($exists && $locked) {
	$locked_by = slurp_file "$game_dir/lock";
    }
    
    unless (wantarray) {
	return $locked; #just return a bool in scalar context
    }

    return (
	game_id => $game_id,
	locked => $locked,
	locked_by => $locked_by,
	lock_file => "$game_dir/lock",
	state_file => "$game_dir/save.sna",
	rom_name => "pokemon_blue.gb",
    );
}

sub lock_game {
    my $game_id = shift;
    my $user = shift; 
    my %game = get_game($game_id);

    if ($game{'locked'}) {
	return 0;
    }
    
    puke_file $game{'lock_file'}, $user;
    
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

1;
