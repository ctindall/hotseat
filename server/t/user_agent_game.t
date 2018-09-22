# HotSeat Server Copyright (C) 2018 Cameron Tindall 
# This program is distributed under the GNU General Public License
# v3.0.  Please see the LICENSE file in the root of this repository
# for the full terms and conditions of this license.

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Path;

use Mojo::Util qw(b64_encode b64_decode);
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
    ->json_has('/system')
    ->json_has('/save_state')
    ->json_is('/save_state', undef);

my $game_id = $t->tx->res->json('/game_id');

#POST
#this one shouldn't exist unless this is way more popular than I would predict
$t->post_ok('/game/9999999999999999999999999999')
    ->status_is(404);

#this one should exist because we just created it
$t->post_ok("/game/$game_id")
    ->status_is(409);

#GET
$t->get_ok("/game/$game_id")
    ->status_is(403);

$t->get_ok("/game/$game_id" => form => { password => "goodpass" })
    ->status_is(200)
    ->json_is('/game_id', $game_id);

$t->get_ok("/game/9999999999999999999999999999")
    ->status_is(404);

#PATCH
my $form =  { password => "goodpass",
	      new_password => "newpass", 
	      owned_by => "revolver_ocelot",
	      rom_name => "animaniacs.rom",
	      locked_by => "jill",
	      system => "genesis" };

$t->patch_ok("/game/$game_id"  => form => $form)
    ->status_is(200)
    ->json_is('/owned_by', $form->{'owned_by'})
    ->json_is('/rom_name', $form->{'rom_name'})
    ->json_is('/locked_by', $form->{'locked_by'})
    ->json_is('/locked', \1)
    ->json_is('/system', $form->{'system'});

$t->get_ok("/game/$game_id" => form => { password => $form->{'new_password'} })
    ->status_is(200);

$t->get_ok("/game/$game_id" => form => { password => "goodpass" })
    ->status_is(403);

$t->patch_ok("/game/$game_id" => { locked => \0 })
    ->json_is('/locked', undef)
    ->json_is('/locked_by', undef);

#PATCH for save_state
my $randstring = "";
foreach my $i (0..(1024)) {
    $randstring .= chr(int(rand(255)));
}
my $b64_string = b64_encode($randstring, '');

$t->patch_ok("/game/$game_id" => form => { password => $form->{'new_password'},
					   save_state => $b64_string})
    ->status_is(200)
    ->json_is('/save_state', $b64_string);


#DELETE
$t->delete_ok("/game/$game_id" => form => { password => $form->{'new_password'}})
    ->status_is(204);

$t->get_ok("/game/$game_id" => form => { password => $form->{'new_password'}})
    ->status_is(404);

$t->delete_ok("/game/$game_id" => form => { password => $form->{'new_password'}})
    ->status_is(404);
    

#clean up
rmtree($tmpdir) unless $tmpdir eq '/var/hotseat/games'; #don't delete production data if I'm using it for a test
done_testing();
