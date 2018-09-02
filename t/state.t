use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Path;

#use a tmp dir for testing
my $games_dir = `mktemp -d`;
my $t = Test::Mojo->new(HotSeat => {
    games_dir => $games_dir,
});

# upload save state
$t->post_ok('/game/420/state' 
	    => form => { save_state =>
			 { content => 'just some bytes', 
			   filename => 'post_play_state.sna'}})
    ->status_is(200);

# make sure we get back the same save state
$t->get_ok('/game/420/state')
    ->status_is(200)
    ->content_is('just some bytes');

#we can't upload a state file if we aren't the one with the lock


#clean up tmp games_dir
rmtree($games_dir); 
done_testing();
