#lang racket
(require "util.rkt"
	 "network.rkt"
	 "systems.rkt"
	 net/base64)

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
	   (lock-game id locked-by))

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

	 (define/public (get-post-play-state) ;; returns it in base64
	   (set-game-server-password! game-password)
	   (define save-file-path (send game-system get-post-play-state-file-path))
	   (define base64-state (bytes->string/utf-8 (base64-encode (file->bytes save-file-path) "")))
	   base64-state)
	 
	 (define/public (play-game)
	   (set-game-server-password! game-password)
	   
	   (send game-system start-emulator game-rom-name)

	   ;;wait until user is done playing game
	   (send game-system emulator-wait)

	   ;;encode post-play-state file, upload it, and unlock the game
	   (update-game game-id
			#:save-state (send this get-post-play-state)
			#:locked #f))
	 
	 ;; TODO: define public methods to:	 	 
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
		       (thunk (send g play-game)))
	 
	 (test-equal? "get back the right bytes after syncing state"
		      (bytes->string/utf-8 (base64-decode (string->bytes/utf-8 (send g get-post-play-state))))
		      "here's some bytes")
		      )
