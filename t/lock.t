use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Path;

#use a tmp dir for testing
my $games_dir = `mktemp -d`;
my $t = Test::Mojo->new(HotSeat => {
    games_dir => $games_dir,
});

#try to get lock status for a nonexistent game
$t->get_ok('/game/420/lock')
    ->status_is(200)
    ->json_has('/locked')
    ->json_has('/locked_by')
    ->json_has('/rom_name')
    ->json_has('/system')
    
    ->json_is('/locked' => \0)
    ->json_is('/locked_by' => undef)
    ->json_is('/rom_name', 'pokemon_blue.gb') #default ROM
    ->json_is('/system', 'gameboy'); #default system

#create a lock for the game
$t->post_ok('/game/420/lock' => form => {user => 'cam'})
    ->status_is(200)
    ->json_has('/locked')
    ->json_has('/locked_by')
    ->json_has('/rom_name')
    ->json_has('/system')
    
    ->json_is('/locked' => \1)
    ->json_is('/locked_by' => 'cam');

#delete the lock
$t->delete_ok('/game/420/lock')
    ->status_is(200)
    ->json_has('/locked')
    ->json_has('/locked_by')
    ->json_has('/rom_name')
    ->json_has('/system')
    
    ->json_is('/locked' => \0);

#get the lock again to make sure its still locked
$t->get_ok('/game/420/lock')
    ->status_is(200)
    ->json_has('/locked')
    ->json_has('/locked_by')
    ->json_has('/rom_name')
    ->json_has('/system')
    
    ->json_is('/locked_by' => undef)
    ->json_is('/locked' => \0);

#clean up tmp games_dir
rmtree($games_dir); 
done_testing();
