#lang racket

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

(module+ test
	 (require rackunit)
	 
	 (define (set-tests)
	   (let ([old-pass game-server-password]
		 [old-url game-server-url])
	     
	     (test-not-exn "setting password doesn't raise exception"
			   (lambda () (set-game-server-password! "badpass")))

	     (test-not-exn "setting url doesn't raise exception"
			   (lambda () (set-game-server-url! "https://google.org/hotseat.gif")))

	     ;;set them back to where we found them
	     (set-game-server-password! old-pass)
	     (set-game-server-url! old-url)))

	 (set-tests)

	 (define (create-tests)
	   (test-not-exn "creating game doesn't raise exception"
			 (lambda () (create-game "pokemon_burnt_umber.gb" "intellivision" "tony" "bestpass"))))
	 (create-tests)
	 
	 (define (read-tests)
	   (define id 1234)

	   (test-not-exn "read-game doesn't raise exception"
	   		 (lambda () (read-game id)))
	   
	   (test-pred "read-game returns a hash"
		      hash? (read-game id)))

	 (read-tests))
