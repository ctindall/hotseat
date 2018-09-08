use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Path;

chomp(my $tmpdir = `mktemp -d`);

my $t = Test::Mojo->new('HotSeat', {
    games_dir => $tmpdir,
});

is($t->app->config('games_dir'), $tmpdir);

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

my $game_id = $t->tx->res->json('/game_id');

#this one shouldn't exist unless this is way more popular than I would predict
$t->post_ok('/game/9999999999999999999999999999')
    ->status_is(404);

#this one should exist because we just created it
$t->post_ok("/game/$game_id")
    ->status_is(409);

$t->get_ok("/game/$game_id")
    ->status_is(403);

$t->get_ok("/game/$game_id" => form => { password => "goodpass" })
    ->status_is(200)
    ->json_is('/game_id', $game_id);

$t->get_ok("/game/9999999999999999999999999999")
    ->status_is(404);

rmtree($tmpdir) unless $tmpdir eq '/var/hotseat/games'; #don't delete production data if I'm using it for a test
done_testing();
