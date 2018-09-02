use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $games_dir = `mktemp -d`;

my $t = Test::Mojo->new(HotSeat => {
    games_dir => $games_dir,
});

$t->get_ok('/game/420/lock')->status_is(200);

unlink $games_dir;
done_testing();
