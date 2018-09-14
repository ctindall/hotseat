#lang racket

(require net/http-client
	 net/uri-codec
	 json)

(provide read-game)

(define game-server-password "goodpass")
(define game-server-port 3000)
(define game-server-hostname "localhost")
(define game-server-use-ssl #f)

(define (game-server-request method path params)
  (let*-values ([(status headers port) (http-sendrecv game-server-hostname
						      path
						      #:method method
						      #:ssl? game-server-use-ssl
						      #:port game-server-port
						      #:headers '("Content-Type: application/x-www-form-urlencoded")
						      #:data (alist->form-urlencoded
							      (dict-set params 'password game-server-password)))])
	       (read-json port)))
		 
		      
(define  (read-game id)
  (game-server-request "GET" (format "/game/~a" id) '()))

(module+ test
	 (require rackunit)
	 (require mock)
	 
	 (define (read-tests)
	   (let ([id 1234]
		 [http-sendrecv (mock #:behavior (const (make-hash '((game_id . "1234")
								     (locked . #f)
								     (locked_by . null)
								     (rom_name . "pokemon_red.gb")(system . "gameboy")))))])
	     
	     (test-not-exn "read-game doesn't raise exception"
	     		   (lambda () read-game id))
	     
	     (test-pred "read-game returns a hash"
			hash? (read-game id))))

	 (read-tests))
