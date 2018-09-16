# HotSeat Server Copyright (C) 2018 Cameron Tindall 
# This program is distributed under the GNU General Public License
# v3.0.  Please see the LICENSE file in the root of this repository
# for the full terms and conditions of this license.

package HotSeat::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    my $user = $self->param('user') || '';
    my $pass = $self->param('pass') || '';
    return $self->render unless $self->users->check($user, $pass);

    $self->session(user => $user);
    $self->flash(message => 'Thanks for logging in.');
    $self->redirect_to('protected');
}

sub logged_in {
    my $self = shift;

    return 1 if $self->session('user');
    $self->redirect_to('index');
    return undef;
}

sub logout {
    my $self = shift;

    $self->session(expires => 1);
    $self->redirect_to('index');
}

1;
