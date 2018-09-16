#lang racket

;; HotSeat Client Copyright (C) 2018 Cameron Tindall 
;; This program is distributed under the GNU General Public License
;; v3.0.  Please see the LICENSE file in the root of this repository
;; for the full terms and conditions of this license.

(require net/url
	 net/uri-codec
	 json)

(provide create-game
	 read-game
	 set-game-server-password!
	 set-game-server-url!)

(define game-server-password "goodpass")
(define (set-game-server-password! pass)
  (set! game-server-password pass))

(define game-server-url "http://localhost:3000")
(define (set-game-server-url! url)
  (set! game-server-url url))

(define (game-server-request method path params)
  (let*-values ([(status headers port) (http-sendrecv/url (string->url (string-append game-server-url path))
							  #:method method
							  #:headers '("Content-Type: application/x-www-form-urlencoded")
							  #:data (alist->form-urlencoded params))])
    (read-json port)))

(define (create-game rom-name system owner password)
  (game-server-request "POST" "/game" `((rom_name . ,rom-name)
					(system . ,system)
					(owned_by . ,owner)
					(password . ,password))))

(define (read-game id)
  (game-server-request "GET" (format "/game/~a" id) `((password . ,game-server-password))))

(define (build-update-params #:new-password [new-password #f]
			     #:owned-by     [owned-by #f]
			     #:rom-name     [rom-name #f]
			     #:system       [system #f]
			     #:save-state   [save-state #f])
  
  (let ([dict `((password . ,game-server-password))])
    (cond [new-password (set! dict (dict-set dict 'new_password new-password))])
    (cond [owned-by     (set! dict (dict-set dict 'owned_by     owned-by))])
    (cond [rom-name     (set! dict (dict-set dict 'rom_name     rom-name))])
    (cond [system       (set! dict (dict-set dict 'system       system))])
    (cond [save-state   (set! dict (dict-set dict 'save_state   save-state))])
    dict))


(define (update-game id
		     #:new-password [new-password #f]
		     #:owned-by     [owned-by #f]
		     #:rom-name     [rom-name #f]
		     #:system       [system #f]
		     #:save-state   [save-state #f])
    (game-server-request "PATCH" (format "/game/~a" id) (build-update-params #:new-password new-password
									     #:owned-by     owned-by
									     #:rom-name     rom-name
									     #:system       system
									     #:save-state   save-state)))

(define (delete-game id)
  (game-server-request "DELETE" (format "/game/~a" id) `((password . ,game-server-password))))

(module+ test
	 (require rackunit)

	 (define game-id 1234)
	 
	 (define (set-tests)
	   (let ([old-pass game-server-password]
		 [old-url game-server-url])
	     
	     (test-not-exn "setting password doesn't raise exception"
			   (thunk
			    (set-game-server-password! "badpass")))

	     (test-not-exn "setting url doesn't raise exception"
			   (thunk
			    (set-game-server-url! "https://google.org/hotseat.gif")))

	     ;;set them back to where we found them
	     (set-game-server-password! old-pass)
	     (set-game-server-url! old-url)))

	 (define (create-tests)
	   (test-not-exn "creating game doesn't raise exception"
			 (thunk
			  (set! game-id (dict-ref (create-game "pokemon_burnt_umber.gb"
							       "intellivision"
							       "tony"
							       "bestpass") 'game_id))
			  (set-game-server-password! "bestpass"))))
	 
	 (define (read-tests)
	   (test-not-exn "read-game doesn't raise exception"
	   		 (thunk (read-game game-id)))
	   
	   (test-pred "read-game returns a hash"
		      hash? (read-game game-id)))

	 (define (update-tests)
	   (test-not-exn "update game doesn't raise exception"
			 (thunk (update-game game-id
					     #:rom-name "excitebike.nes.rom"
					     #:owned-by "goodowner"
					     #:system "genesis"
					     #:save-state  "123499292929")))
	   (let ([game (read-game game-id)]
		 [oldpass game-server-password]
		 [newpass "justabetterpass"])
	     
	     (test-equal? "update successfully changes rom_name"
			  (hash-ref game 'rom_name) "excitebike.nes.rom")
		 
	     (test-equal? "update successfully changes owner"
			  (hash-ref game 'owned_by) "goodowner")
	     
	     (test-equal? "update successfully changes system"
			  (hash-ref game 'system) "genesis")

	     (test-equal? "update successfully changes save_state"
			  (hash-ref game 'save_state) "123499292929")

	     (update-game game-id #:new-password newpass)
	     (set-game-server-password! newpass)
	     
	     (test-not-exn "can read-game after setting password"
			   (thunk (read-game game-id)))

	     (update-game game-id #:new-password oldpass)
	     (set-game-server-password! oldpass)))

	 (define (delete-tests)
	   (test-not-exn "no exception deleting game"
			 (thunk (delete-game game-id)))

	   (test-equal? "no such game after delete"
	   		(dict-ref (dict-ref (read-game game-id) 'errors) 'detail)
	   		"No such game."))

	 
	 (set-tests)
	 (create-tests)
	 (read-tests)
	 (update-tests)
	 (delete-tests))
