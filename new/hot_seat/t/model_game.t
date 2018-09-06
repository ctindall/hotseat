use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::Game;

my ($rom, $system, $owner, $pass) = ("final_fantasy.nes.rom", "nes", "tobin", "goodpass2");
my $game = HotSeat::Model::Game->create($rom, $system, $owner, $pass);
isa_ok($game, "HotSeat::Model::Game");

ok(!$game->locked, 'newly created game is not locked');
is($game->locked_by, undef, 'newly created game is not locked by anyone');
is($game->rom, $rom);
is($game->system, $system);
is($game->owner, $owner);
is($game->password, $pass);

ok($game->lock('bill'), 'can lock a game without errors');
ok($game->locked, 'game is actually locked after locking');
is($game->locked_by, 'bill', 'game is locked by the right user after locking');

done_testing();
