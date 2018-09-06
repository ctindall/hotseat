use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Path;

#use a tmp dir for testing
my $games_dir = `mktemp -d`;
my $t = Test::Mojo->new(HotSeat => {
    games_dir => $games_dir,
});

#create a new game and set a password
$t->put_ok('/game/321' => form => { owned_by => "bill",
				    password => "goodpass",
				    rom_name => "animaniacs",
				    system => "genesis"})
    ->status_is(201);

#try to get a lock without a bad password
$t->post_ok('/game/321/lock' => form => { user => 'tom',
					  password => "badpass"})
    ->status_is(403);


#same with a password
$t->post_ok('/game/321/lock' => form => { user => 'tom',
					  password => "goodpass"})
    ->status_is(201)
    ->json_is('/owned_by', 'bill')
    ->json_is('/locked_by', 'tom')
    ->json_is('/locked', \1);


#clean up tmp games_dir
rmtree($games_dir); 
done_testing();
