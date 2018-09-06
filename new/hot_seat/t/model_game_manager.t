use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::GameManager;

my $g = HotSeat::Model::GameManager->new;
isa_ok($g, "HotSeat::Model::GameManager");

like($g->games_dir, qr/games$/,'default $g->games_dir is sane');

chomp(my $tmp_games_dir = `mktemp -d`);
$g->games_dir($tmp_games_dir);
is($g->games_dir , $tmp_games_dir, 'can set $g->games_dir');


my ($rom, $system, $owner, $pass) = ("final_fantasy.nes.rom", "nes", "tobin", "goodpass2");
    
ok(my $game_id = $g->create_game($rom, $system, $owner, $pass), 'create a game without errors');
ok(my %game = $g->get_game($game_id), 'create gamge without errors');
is($game{'exists'}, 1, 'game exists after creation');
is($game{'rom_name'}, $rom, 'rom_name created correctly');
is($game{'system'}, $system, 'system name created correctly');
is($game{'owned_by'}, $owner, 'owned_by created correctly');
is($game{'password'}, $pass, 'game password created correctly');

#get a nonexistent game
%game = $g->get_game(4321);
is($game{'exists'}, 0);

#lock a game
%game = $g->lock_game($game_id, 'bill');
is($game{'locked'}, 1, 'game locking works');
is($game{'locked_by'}, 'bill', 'properly store who locked the game');

#unlock a game
%game = $g->unlock_game($game_id, 'bill');
is($game{'locked'}, 0, 'game unlocking works');
is($game{'locked_by'}, undef, 'locked_by undef after unlocking');    

done_testing();
