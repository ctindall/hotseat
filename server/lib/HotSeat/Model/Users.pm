# HotSeat Server Copyright (C) 2018 Cameron Tindall 
# This program is distributed under the GNU General Public License
# v3.0.  Please see the LICENSE file in the root of this repository
# for the full terms and conditions of this license.

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
