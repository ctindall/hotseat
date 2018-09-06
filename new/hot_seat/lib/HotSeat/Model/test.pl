#!/usr/bin/env perl

use strict;
use warnings;
use v5.18;

sub free_id {
    my $dh
    opendir $dh shift;

    my @dirs = sort { $a <=> $b } 
               grep { -d $dir.$_ && ! /^.{1,2}$/ } readdir($dh);

    return $dirs[-1] + 1;	
}


say free_id "/home/cam/git/homestead-server.git/games"
