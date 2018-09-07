package HotSeat::Model::Game;
use strict;
use warnings;
use v5.18;

use HotSeat::Model::GameManager;
use Mojo::Util qw(secure_compare);

my $gm = HotSeat::Model::GameManager->new;

sub find_by_id {
    my ($class, $game_id) = @_;
    die '$game_id required argument' unless @_ = 2;

    unless ($gm->get_game($game_id)) {
	return undef;
    }

    return bless { game_id => $game_id }, $class;
}

sub create {
    my ($class, $rom_name, $system, $owned_by, $password)  = @_;
    my $game_id = $gm->create_game($rom_name, $system, $owned_by, $password);
    
    return bless { game_id => $game_id }, $class;
}

sub delete {
    my ($self) = @_;

    if ($gm->get_game($self->game_id)) {
	return $gm->delete_game($self->game_id);
    }
 
    undef $self;
   
    return undef;
}

sub lock {
    my ($self, $locked_by) = @_;
    die "Who's doing the locking?" unless defined $locked_by;

    my %game = $gm->lock_game($self->game_id, $locked_by);

    return $game{'locked'};
}

sub password_ok {
    my ($self, $pass) = @_;

    return secure_compare $pass, $self->password;
}

# ACCESSORS

sub rom {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'rom_name'};

}

sub system {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'system'};
}

sub owner {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'owned_by'};
}

sub password {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'password'};
}

sub game_id {
    my ($self) = @_;
    return $self->{'game_id'};
}

sub locked {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'locked'};
}

sub locked_by {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'locked_by'};
}

sub state_file {
    my ($self) = @_;
    my %game = $gm->get_game($self->game_id);

    return $game{'state_file'};
}

1;
