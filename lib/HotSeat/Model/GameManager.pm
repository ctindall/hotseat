package HotSeat::Model::GameManager;
our @EXPORT = qw( new set_games_dir create_game get_game lock_game unlock_game delete_game );

use strict;
use warnings;
use v5.18;

use File::Basename;
use File::Path qw( make_path rmtree );
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
    my ($filename, $value) = @_;

    if ($value) {
	unlink $filename if (-e $filename);
	open(my $fh, '>', $filename);
	print $fh $value;
	close $fh;
    }
}

# API
sub new {
    my $class = shift;
    my $games_dir = shift || "/var/hotseat/games";
    my $self = bless {
	games_dir => $games_dir,
    }, $class;

    return $self;
}

sub games_dir {
    my ($self, $dir) = @_;
    
    if ($dir) {
	chomp($dir);
	$self->{games_dir} = $dir;
    }

    return $self->{games_dir};
}

sub get_game {
    my ($self, $dir, $game_id) = @_;
    die '$game_id required to get_game' unless defined $game_id;
    die '$dir required to get_game' unless defined $dir;
    my $game_dir = "$dir/$game_id";
    die "No such game directory $game_dir" unless (-d $game_dir);
    
    my $locked = 0;
    my $locked_by;
    my $rom_name;
    my $system;
    my $password;
    my $owned_by;
    my $save_state;
    my $exists = (-d $game_dir);

    if (!$exists && wantarray) {
	return ( exists => 0 );
    }

    if (!$exists && !wantarray) {
	return undef;
    }

    if ($exists && !wantarray) {
	return 1;
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

    if (-e "$game_dir/save_state") {
       $save_state = slurp_file "$game_dir/save_state";
    }        

    
    if ($exists && $locked) {
	$locked_by = slurp_file "$game_dir/lock";
    }

    return (
	exists => 1,
	game_id => $game_id,
	locked => $locked,
	locked_by => $locked_by,
	lock_file => "$game_dir/lock",
	rom_name => $rom_name,
	system => $system,
	owned_by => $owned_by,
	password => $password,
	save_state => $save_state,
    );
}

sub free_id {
    my $dir = shift;
    my $dh;

    if (! -d $dir && ! -e $dir) {
	`mkdir $dir`;
    }

    
    opendir($dh, $dir) or die "can't open $dir";
    
    my @dirs = sort { $a <=> $b } 
               grep { $_ ne "." && $_ ne ".." } readdir($dh);

    closedir($dh);

    return $dirs[-1] + 1 unless ! @dirs; #avoid error when games_dir is empty
    return 1234;
}

sub create_game {
    my $num_arguments = @_;
    die "arguments \$dir, \$rom_name, \$system, \$owned_by, \$password required (only given $num_arguments arguments)"  unless @_ == 6;

    foreach(@_) {
	die "undefined argument in create_game" unless defined $_;
    }
    
    my ($self, $dir, $rom_name, $system, $owned_by, $password)  = @_;
    
    my $game_id = free_id($dir);
    my $game_dir = "$dir/$game_id";

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

    return $game_id;
}

sub lock_game {
    my $numargs = @_;
    die "Not enough arguments in lock_game (given only $numargs)" unless @ == 4;
    
    my ($self, $dir, $id, $user) = @_;
    my %game = $self->get_game($dir, $id);

    puke_file $game{'lock_file'}, $user;
    
    return $self->get_game($dir, $id);
}

sub unlock_game {
    my $numargs = @_;
    die "Not enough arguments in lock_game (given only $numargs)" unless @ == 4;
    
    my ($self, $dir, $id, $user) = @_;
    my %game = $self->get_game($dir, $id);

    if ($game{'locked'}) {	
	unlink $game{'lock_file'};
    }
    
    return $self->get_game($dir, $id);
}

sub delete_game {
    my ($self, $dir, $id) = @_;

    die '$game_id required for delete_game' unless defined $id ;
    die '$game_dir required for delete_game' unless defined $dir ;

    $dir = "$dir/$id";
    if (-d $dir) {
	rmtree $dir;
	return 1;
    }

    return undef;
}

sub update_game_field {
    my ($self, $dir, $id, $field, $value) = @_;

    die "Incorrect number of arguments" unless @_ == 5;
    
    foreach (($self, $dir, $id, $field)) {
	die "undefined argument" unless defined $_;
    }
    
    puke_file("$dir/$id/$field", $value);
    
    return $self->get_game($dir, $id);
}

1;

