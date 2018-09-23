#lang racket
(require "util.rkt"
	 "network.rkt"
	 "systems.rkt")

(define game%
  (class object%
	 (super-new)
	 (init-field (id #f) (password #f) (new? #f) (rom-name #f) (system #f) (owner #f))
	 (define-values (game-id
			 game-password
			 game-owner
			 game-rom-name
			 game-system)
	   (values id
		   password
		   owner
		   rom-name
		   system))
	 
	 (cond [(and new? rom-name system owner password) ;;creating a new game from scratch
		(define game-hash (create-game rom-name (symbol->string system) owner password))
		(set! game-id       (dict-ref game-hash 'game_id))
		(set! game-password password)
		(set! game-owner    (dict-ref game-hash 'owned_by))
		(set! game-rom-name (dict-ref game-hash 'rom_name))
		(set! game-system   (new system% [system-name (dict-ref game-hash 'system)]))]
 

	       [(and id password) ;;reading an existing game from the server
		(set-game-server-password! password)
		(define game-hash (read-game id))
		(set! game-owner    (dict-ref game-hash 'owned_by))
		(set! game-rom-name (dict-ref game-hash 'rom_name))
		(set! game-system   (new system% [system-name (dict-ref game-hash 'system)]))]

	       [else (raise-arguments-error 'game% "Incorrect usage of (new game%). Need either enough arguments to create a new game from scratch (new? rom-name system owner pass) or a game-id and password.")])

	 (define/public (lock locked-by)
	   (set-game-server-password! game-password)
	   (update-game game-id #:locked-by locked-by))

	 (define/public (locked?)
	   (set-game-server-password! game-password)
	   (let ([game-hash (read-game game-id)])
	     (dict-ref game-hash 'locked)))
	 
	 (define/public (get-locked-by)
	   (set-game-server-password! game-password)
	   (let ([game-hash (read-game game-id)])
	     (dict-ref game-hash 'locked_by)))

	 (define/public (unlock)
	   (set-game-server-password! game-password)
	   (unlock-game game-id))

	 ;; TODO: define public methods to:	 
	 ;; play the game
	 (define/public (play-game)
	   (send game-system start-emulator game-rom-name))
	 
	 ;; upload state
	 ))


(module+ test
	 (require rackunit)

	 (define game-id (dict-ref (create-game "pokemon_burnt_umber.gb"
						"test_system"
						"tony"
						"goodpass")
				   'game_id))
	 
	 (test-not-exn "can create game with id and password argument without exception"
		       (thunk (new game% [id game-id] [password "goodpass"])))

	 (test-not-exn "can create game from scratch without exception"
		       (thunk (new game%
				   [new? #t]
				   [rom-name "test_game.rom"]
				   [system 'test_system]
				   [owner "cam"]
				   [password "camspass"])))


	 (define g (new game% [id game-id] [password "goodpass"]))
	 
	 (test-not-exn "lock game without exception"
		       (thunk (send g lock "steve")))

	 (test-equal? "game is actually locked after locking"
		      (send g locked?)
		      #t)
	 
	 (test-equal? "game is locked by the right name after locking"
	 	      (send g get-locked-by)
	 	      "steve")

	 (test-not-exn "unlock game without exception"
	 	       (thunk (send g unlock)))

	 (test-equal? "game is unlocked after unlocking"
	 	      (send g locked?)
	 	      #f)

	 (test-not-exn "can open emulator without exception"
		       (thunk (send g play-game))))
