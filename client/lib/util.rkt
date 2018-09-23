#lang racket

(provide maybe-symbol->string
	 maybe-string->symbol)	


(define (maybe-symbol->string wut)
  (if (string? wut)
      wut
      (symbol->string wut)))

(define (maybe-string->symbol wut)
  (if (symbol? wut)
      wut
      (string->symbol wut)))


(module+ test
	 (require rackunit)
	 (test-equal? "coerce symbol to string"
		      (maybe-symbol->string 'whatever)
		      "whatever")
	 
	 (test-equal? "keep a string a string"
		      (maybe-symbol->string "whatever")
		      "whatever")

	 (test-equal? "coerce string to symbol"
		      (maybe-string->symbol "whatever")
		      'whatever)
	 
	 (test-equal? "keep a symbol a symbol"
		      (maybe-string->symbol 'whatever)
		      'whatever))

