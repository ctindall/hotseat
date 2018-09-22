# HotSeat Server Copyright (C) 2018 Cameron Tindall 
# This program is distributed under the GNU General Public License
# v3.0.  Please see the LICENSE file in the root of this repository
# for the full terms and conditions of this license.

package HotSeat::Model::Game;
use strict;
use warnings;
use v5.18;

use HotSeat::Model::GameManager;
use Mojo::Util qw(secure_compare);

my $gm = HotSeat::Model::GameManager->new;

sub new {
    my ($class, $dir, $id) = @_;

    return bless { 
	game_id => $id,
	games_dir => $dir,
    }, $class;

}

sub find_by_id {
    my ($class, $dir, $id) = @_;
    die '$game_dir required argument' unless defined $dir;
    die '$game_id required argument' unless defined $id;

    eval {
	$gm->get_game($dir, $id);
    };

    if ($@) {
	return undef;
    }

    return new($class, $dir, $id);
}
 

sub create {
    my ($class, $dir, $rom_name, $system, $owned_by, $password)  = @_;
    my $id = $gm->create_game($dir, $rom_name, $system, $owned_by, $password);

    return new($class, $dir, $id);
}


sub delete {
    my ($self) = @_;

    if ($gm->get_game($self->{'games_dir'}, $self->game_id)) {
	return $gm->delete_game($self->{'games_dir'}, $self->game_id);
    }
 
    undef $self;
   
    return undef;
}

sub lock {
    my ($self, $locked_by) = @_;
    die "Who's doing the locking?" unless defined $locked_by;

    my %game = $gm->lock_game($self->{'games_dir'}, $self->game_id, $locked_by);

    return $game{'locked'};
}

sub unlock {
    my ($self) = @_;

    my %game = $gm->unlock_game($self->{'games_dir'}, $self->game_id);

    return $game{'locked'};
}

sub password_ok {
    my ($self, $pass) = @_;

    return secure_compare $pass, $self->password if defined $pass;
    return undef;
}

# ACCESSORS
sub locked_by {
    my ($self) = @_;    
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'locked_by'};
}

sub rom {
    my ($self, $new) = @_;

    if (defined $new) {
	$gm->update_game_field($self->{'games_dir'}, $self->game_id, "rom_name", $new);
    }

    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'rom_name'};
}

sub system {
    my ($self, $new) = @_;

    if (defined $new) {
	$gm->update_game_field($self->{'games_dir'}, $self->game_id, "system", $new);
    }
    
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'system'};
}

sub owner {
    my ($self, $new) = @_;

    if (defined $new) {
	$gm->update_game_field($self->{'games_dir'}, $self->game_id, "owned_by", $new);
    }
    
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'owned_by'};
}

sub password {
    my ($self, $new) = @_;

    if (defined $new) {
	$gm->update_game_field($self->{'games_dir'}, $self->game_id, "password", $new);
    }
    
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'password'};
}

sub game_id {
    my ($self) = @_;
    return $self->{'game_id'};
}

sub locked {
    my ($self) = @_;
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);
    
    return $game{'locked'} ? 1 : undef;
}

sub save_state {
    my ($self, $new) = @_;

    if (defined $new) {
	$gm->update_game_field($self->{'games_dir'}, $self->game_id, "save_state", $new);
    }
    
    my %game = $gm->get_game($self->{'games_dir'}, $self->game_id);

    return $game{'save_state'};
}

1;
