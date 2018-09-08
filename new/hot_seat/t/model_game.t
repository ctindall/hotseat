use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::Game;
use File::Path qw(rmtree);

sub not_ok {
    my ($value, $desc) = @_;
    ok(!$value, $desc);
}

chomp(my $tmpdir = `mktemp -d`);

my ($rom, $system, $owner, $pass) = ("final_fantasy.nes.rom", "nes", "tobin", "goodpass2");
my $game = HotSeat::Model::Game->create($tmpdir, $rom, $system, $owner, $pass);
$game = HotSeat::Model::Game->create($tmpdir, $rom, $system, $owner, $pass);
$game = HotSeat::Model::Game->create($tmpdir, $rom, $system, $owner, $pass);
$game = HotSeat::Model::Game->create($tmpdir, $rom, $system, $owner, $pass);
isa_ok($game, "HotSeat::Model::Game");
is($game->{'games_dir'}, $tmpdir);

ok(my $game_id = $game->game_id);
ok(!$game->locked, 'newly created game is not locked');
is($game->locked_by, undef, 'newly created game is not locked by anyone');
is($game->rom, $rom, 'can set $game->rom at creation');
is($game->system, $system, 'can set $game->system at creation');
is($game->owner, $owner,'can set $game->owner at creation');
is($game->password, $pass, 'can set $game->pass at creation');
like($game->state_file, qr/\/save.sna$/, '$game->state_file has the right kind of filename');

ok($game->password_ok($pass), '$game->password_ok recognizes good password');
not_ok($game->password_ok('gibberish'), '$game->password_ok recognizes bad password');

ok($game->lock('bill'), 'can lock a game without errors');
ok($game->locked, 'game is actually locked after locking');
is($game->locked_by, 'bill', 'game is locked by the right user after locking');

isnt(HotSeat::Model::Game->find_by_id($tmpdir, $game_id), undef, 'find_by_id works for proper game_ids');
is(HotSeat::Model::Game->find_by_id($tmpdir, 29309002030), undef, 'find_by_id works for nonexistent game_ids');

is($game->delete, 1);
is(HotSeat::Model::Game->find_by_id($tmpdir, $game_id), undef);

rmtree($tmpdir);
done_testing();
