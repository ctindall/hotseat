package HotSeat::Model::Users;

use strict;
use warnings;

use Mojo::Util 'secure_compare';

my $USERS = {
    cam => "goodpass",
    tobin => "betterpass",
};

sub new { bless {}, shift }

sub check {
    my ($self, $user, $pass) = @_;

    return 1 if $USERS->{$user} && secure_compare $USERS->{$user}, $pass;

    return undef;
}

1;
