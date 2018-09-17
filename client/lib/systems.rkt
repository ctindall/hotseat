#lang racket

;; HotSeat Client Copyright (C) 2018 Cameron Tindall 
;; This program is distributed under the GNU General Public License v3
;; Please see the LICENSE file in the root of this repository
;; for the full terms and conditions of this license.

(provide system%)

(require json)

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
	 
	 (define system system-name)

	 (define/public (get-system-dir)
	   (build-path system-dir (symbol->string system)))

	 (define/public (get-emulator-path)
	   (build-path (send this get-system-dir)
		       (dict-ref (read-system system)
				 'emulator)))))

(module+ test
	 (require rackunit)
	 
	 (define gb (new system% [system-name 'gameboy]))
	 
	 (test-true "gameboy emulator path is good"
		    (string-suffix? (path->string
				     (send gb get-emulator-path)) "bgb.exe")))
