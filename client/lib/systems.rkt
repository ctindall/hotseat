#lang racket

;; HotSeat Client Copyright (C) 2018 Cameron Tindall 
;; This program is distributed under the GNU General Public License v3
;; Please see the LICENSE file in the root of this repository
;; for the full terms and conditions of this license.

(provide system%)

(require "util.rkt"
	 json)

;; This needs to account for:
;; 1) the case where the main hotseat-client.rkt (or exe) is run but also
;; 2) just running the "systems.rkt" module in place (e.g. when running 'raco test')
(define system-dir (if (string-suffix? (path->string (find-system-path 'orig-dir))
				       "lib/")
		       (build-path (find-system-path 'orig-dir) 'up "systems")
		       (build-path (find-system-path 'orig-dir) "systems")))

(define (read-system name)
  (define conf-file-path (build-path system-dir (symbol->string name) "system.json"))
  (if (file-exists? conf-file-path)
      (let ([port (open-input-file (build-path system-dir (symbol->string name) "system.json"))])
	(read-json port))
      #f))

(define system%
  (class object%
	 (super-new)
	 (init system-name)
	 
	 (define system (maybe-string->symbol system-name))
	 (define emulator-proc #f)
	   
	 (define/public (get-system-dir)
	   (build-path system-dir (symbol->string system)))

	 (define/public (get-config-hash)
	   (read-system system))
	   
	 (define/public (get-emulator-path)
	   (build-path (send this get-system-dir)
		       (string->path (dict-ref (send this get-config-hash)
					       'emulator))))
	 
	 (define/public (get-save-file-flag)
	   (dict-ref (send this get-config-hash)
		     'save-file-flag))

	 (define/public (get-post-play-state-args)
	   (dict-ref (send this get-config-hash)
		     'post-play-state-args))

	 (define/public (get-rom-file-flag)
	   (dict-ref (send this get-config-hash)
		     'rom-file-flag))
	 
	 (define/public (get-post-play-state-file-path)
	   (build-path (dict-ref (send this get-config-hash)
				 'post-play-state-path)))
	 
	 (define/public (start-emulator rom-name [save-file-path #f])
	   (define-values (subproc stdout stdin stderr) (apply subprocess `(#f #f #f 
									       ,(send this get-emulator-path)
									       ,(send this get-rom-file-flag) ,rom-name
									       ,@(send this get-post-play-state-args)
									       ,@(if save-file-path
										     (send this get-save-file-args)
										     '()))))
	   (set! emulator-proc subproc))

	 (define/public (kill-emulator)
	   (cond [emulator-proc (subprocess-kill emulator-proc #t) #t]
		 [else #f]))

	 (define/public (emulator-wait)
	   (subprocess-wait emulator-proc)
	   (send this emulator-exit-code))

	 (define/public (emulator-exit-code)
	   (subprocess-status emulator-proc))
  
	 (define/public (emulator-running?)
	   (let ([status (subprocess-status emulator-proc)])
		 (cond [(eq? status 'running) #t]
		       [else #f])))))

(module+ test
	 (require rackunit)

	 (test-not-exn "can create new %system without exception"
		       (thunk (new system% [system-name 'gameboy])))
	 
	 (define gb (new system% [system-name 'gameboy]))
	 
	 (test-true "gameboy emulator path is good"
		    (string-suffix? (path->string
				     (send gb get-emulator-path)) "bgb.exe"))
	 
	 (test-equal? "gameboy save-file-flag reads correctly"
		      (send gb get-save-file-flag)
		      "-rom")

	 (test-equal? "gameboy post-play-state-args reads correctly"
		      (send gb get-post-play-state-args)
		      `("-stateonexit" "post_play_state.sna"))

	 (test-equal? "gameboy post-play-state-file reads correctly"
		      (send gb get-post-play-state-file-path)
		      (string->path "post_play_state.sna"))

	 (define mock-system (new system% [system-name 'test_system]))

	 (test-not-exn "start emulator without exception"
		       (thunk (send mock-system start-emulator "pokemon_blue.rom")
			      (sleep 0.1)))
	 
	 (test-equal? "emulator running after start"
		      (send mock-system emulator-running?)
		      #t)

	 (test-not-exn "kill emulator without exception"
	 	       (thunk (send mock-system kill-emulator)
	 		      (sleep 0.01)))

	 (test-equal? "emulator not running after kill"
	 	      (send mock-system emulator-running?)
	 	      #f)

	 (send mock-system start-emulator "pokemon_yellow.rom")
	 (test-equal? "emulator exit status is 0"
		      (send mock-system emulator-wait)
		      0))


		      
