#lang racket

;; HotSeat Client Copyright (C) 2018 Cameron Tindall 
;; This program is distributed under the GNU General Public License
;; v3.0.  Please see the LICENSE file in the root of this repository
;; for the full terms and conditions of this license.

(require "lib/network.rkt")

(read-game 1234)
(create-game "pokemon_burnt_umber.gb" "incelivision" "tony" "bestpass")
