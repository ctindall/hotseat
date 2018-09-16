# HotSeat Server Copyright (C) 2018 Cameron Tindall 
# This program is distributed under the GNU General Public License
# v3.0.  Please see the LICENSE file in the root of this repository
# for the full terms and conditions of this license.

use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::GameManager;

use Mojo::Util qw(b64_encode b64_decode);

chomp(my $tmpdir = `mktemp -d`);
my $g = HotSeat::Model::GameManager->new($tmpdir);
isa_ok($g, "HotSeat::Model::GameManager");
is($g->games_dir , $tmpdir, 'can set games directory on creation');

my ($rom, $system, $owner, $pass) = ("final_fantasy.nes.rom", "nes", "tobin", "goodpass2");
    
ok(my $game_id = $g->create_game($tmpdir, $rom, $system, $owner, $pass), 'create a game without errors');
ok(my %game = $g->get_game($tmpdir, $game_id), 'create gamge without errors');
is($game{'exists'}, 1, 'game exists after creation');
is($game{'rom_name'}, $rom, 'rom_name created correctly');
is($game{'system'}, $system, 'system name created correctly');
is($game{'owned_by'}, $owner, 'owned_by created correctly');
is($game{'password'}, $pass, 'game password created correctly');

#get a nonexistent game
eval {
    %game = $g->get_game($tmpdir, 432112333222222);
};
ok(defined $@, 'fetching a nonexistent game_id raises error');

#lock a game
%game = $g->lock_game($tmpdir, $game_id, 'bill');
is($game{'locked'}, 1, 'game locking works');
is($game{'locked_by'}, 'bill', 'properly store who locked the game');

#unlock a game
%game = $g->unlock_game($tmpdir, $game_id, 'bill');
is($game{'locked'}, 0, 'game unlocking works');
is($game{'locked_by'}, undef, 'locked_by undef after unlocking');    

#update some stuff
my %updates = (
    owned_by => 'chuck',
    rom_name => 'burgertime.a2600.rom',
    system => 'atari2600',
    password => 'nicepass',
    );

foreach my $key (keys %updates) {
    ok(%game = $g->update_game_field($tmpdir, $game_id, $key, $updates{$key}), "can update '$key' without errors");
    is($game{$key}, $updates{$key},"'$key' is correct after setting");
}

my $randstring = "";
foreach my $i (0..(1024)) {
    $randstring .= chr(int(rand(255)));
}
my $b64_string = b64_encode($randstring, '');
ok(%game = $g->update_game_field($tmpdir, $game_id, "save_state", $b64_string), 'can update save_state without errors');
is(b64_decode($game{'save_state'}), $randstring, 'save_state b64 round trip works'); 

done_testing();
