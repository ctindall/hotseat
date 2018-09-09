use warnings;
use strict;
use v5.18;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Test::More;
use HotSeat::Model::Game;

use File::Path qw(rmtree);
use Mojo::Util qw(b64_encode b64_decode);

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
isa_ok($game, "HotSeat::Model::Game", 'created the right kind of object');
is($game->{'games_dir'}, $tmpdir, '$game->games_dir is set corectly from the config');

ok(my $game_id = $game->game_id, 'can access $game->game_id without errors');
ok(!$game->locked, 'newly created game is not locked');
is($game->locked_by, undef, 'newly created game is not locked by anyone');
is($game->rom, $rom, 'can set $game->rom at creation');
is($game->system, $system, 'can set $game->system at creation');
is($game->owner, $owner,'can set $game->owner at creation');
is($game->password, $pass, 'can set $game->pass at creation');
is($game->save_state, undef, '$game->save_state initially undefined/null');

ok($game->password_ok($pass), '$game->password_ok recognizes good password');
not_ok($game->password_ok('gibberish'), '$game->password_ok recognizes bad password');

ok($game->lock('bill'), 'can lock a game without errors');
ok($game->locked, 'game is actually locked after locking');
is($game->locked_by, 'bill', 'game is locked by the right user after locking');

my $randstring = "";
foreach my $i (0..(1024)) {
    $randstring .= chr(int(rand(255)));
}
my $b64_string = b64_encode($randstring, '');

my %updates = (
    rom => "zork.c64.dimg",
    system => "commodore64",
    owner => 'jack_skellington',
    password => 'halloweenie',
    save_state => $b64_string,
    );

foreach my $key (keys %updates) {
    my ($method, $value) = ($key, $updates{$key});
    
    ok($game->$method($value), "can set '\$game->$method' without errors");
    is($game->$method, $value, "\$game->$method has right value after setting");
}


isnt(HotSeat::Model::Game->find_by_id($tmpdir, $game_id), undef, 'find_by_id works for proper game_ids');
is(HotSeat::Model::Game->find_by_id($tmpdir, 29309002030), undef, 'find_by_id works for nonexistent game_ids');

is(!!$game->delete, !!1, 'can delete without errors');
is(HotSeat::Model::Game->find_by_id($tmpdir, $game_id), undef, 'game is actually deleted');

rmtree($tmpdir);
done_testing();
