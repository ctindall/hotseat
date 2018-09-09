use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::GameManager;

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
ok(%game = $g->update_game_field($tmpdir, $game_id, 'owned_by', "chuck"));
is($game{'owned_by'}, "chuck");

done_testing();
