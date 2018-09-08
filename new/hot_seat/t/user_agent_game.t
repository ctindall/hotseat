use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('HotSeat');

#this should fail since there are no arguments
$t->post_ok('/game')
    ->status_is(400);

#this should succeed and return a Location: with the URL of the new game
$t->post_ok('/game'  => form => { password => "goodpass", 
				  owned_by => "scam",
				  rom_name => "pokemon_red.gb",
				  system   => "gameboy" })
    ->status_is(201)
    ->header_like(Location => qr|/game/[0-9]+|)
    ->json_has('/locked')
    ->json_has('/locked_by')
    ->json_has('/rom_name')
    ->json_has('/system');

#this one shouldn't exist unless this is way more popular than I would predict
$t->post_ok('/game/9999999999999999999999999999')
    ->status_is(404);

#this one should exist because its the lowest possible game_id and we've created one
$t->post_ok('/game/1234')
    ->status_is(409);

$t->get_ok('/game/1234')
    ->status_is(403);

done_testing();
