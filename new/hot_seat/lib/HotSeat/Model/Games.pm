package HotSeat::Model::Games;
our @EXPORT = qw( new set_games_dir create_game get_game lock_game unlock_game );

use strict;
use warnings;

use File::Basename;
use File::Path qw( make_path ); 
use Cwd;

# UTIL (not exported)
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

# API
my $games_dir = Cwd::abs_path(dirname($0))."/games";

sub new {
    my $class = shift;
    my $self = bless {
	games_dir => $games_dir,
    }, $class;

    return $self;
}

sub games_dir {
    my $self = shift;

    if (@_) {
	$self->{games_dir} = shift;
    }

    return $self->{games_dir};
}

sub get_game {
    my $self = shift;
    
    my $game_id = shift;
    my $game_dir = $self->games_dir()."/$game_id";
    my $exists = (-d $game_dir);
    
    my $locked = 0;
    my $locked_by;
    my $rom_name;
    my $system;
    my $password;
    my $owned_by;
    my $state_file = "";

    if (!$exists) {
	return ( exists => 0 );
    }
    
    $locked = (-e "$game_dir/lock") ? 1 : 0;

    if (-e "$game_dir/rom_name") {
	$rom_name = slurp_file "$game_dir/rom_name";
    }    

    if (-e "$game_dir/system") {
	$system = slurp_file "$game_dir/system";
    }    

    if (-e "$game_dir/password") {
	$password = slurp_file "$game_dir/password";
    }

    if (-e "$game_dir/owned_by") {
	$owned_by = slurp_file "$game_dir/owned_by";
    }        
    
    if ($exists && $locked) {
	$locked_by = slurp_file "$game_dir/lock";
    }
    
    unless (wantarray) {
	return $locked; #just return a bool in scalar context
    }

    return (
	exists => 1,
	game_id => $game_id,
	locked => $locked,
	locked_by => $locked_by,
	lock_file => "$game_dir/lock",
	state_file => "$game_dir/save.sna",
	rom_name => $rom_name,
	system => $system,
	owned_by => $owned_by,
	password => $password,
    );
}

sub create_game {
    my $self = shift;
    
    my $game_id = shift;
    my $rom_name = shift;
    my $system = shift;
    my $owned_by = shift;
    my $password = shift;

    #double check game doesn't already exist so we don't clobber it
    my %game = $self->get_game($game_id);
    return 0 if $game{'exists'};

    my $game_dir = $self->games_dir."/$game_id";

    unless (defined $rom_name) {
	$rom_name = "pokemon_blue.gb";
    }

    unless (defined $system) {
	$system = "gameboy";
    }

    unless (defined $owned_by) {
	$owned_by = "cam";
    }

    unless (defined $password) {
	$password = "weakpassword";
    }

    unless (-e $game_dir) {
	make_path $game_dir;
    }

    unless (-e "$game_dir/rom_name") {
	puke_file "$game_dir/rom_name", $rom_name;
    }

    unless (-e "$game_dir/system") {
	puke_file "$game_dir/system", $system;
    }

    unless (-e "$game_dir/owned_by") {
	puke_file "$game_dir/owned_by", $owned_by;
    }

    unless (-e "$game_dir/password") {
	puke_file "$game_dir/password", $password;
    }

    return 1;
}

sub lock_game {
    my $self = shift;
    
    my $game_id = shift;
    my $user = shift; 
    my %game = $self->get_game($game_id);

    puke_file $game{'lock_file'}, $user;
    
    return $self->get_game($game_id);
}

sub unlock_game {
    my $self = shift;
    
    my $game_id = shift;
    my %game = $self->get_game($game_id);

    if ($game{'locked'}) {	
	unlink $game{'lock_file'};
    }
    
    return $self->get_game($game_id);
}


1;
