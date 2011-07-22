;;
;; Test for characters and strings, involving case mapping and
;; multibytes
;;

(use gauche.test)

(add-load-path "../test")

(test-start "case mappings and multibytes")

(test-section "char cases")

(let ()
  ;; Case stuff
  (define (t ch up down title fold)
    (test* (format "case mapping ~a -> (upcase, downcase, titlecase, foldcase)" ch)
           (list up down title fold)
           (list (char-upcase ch)
                 (char-downcase ch)
                 (char-titlecase ch)
                 (char-foldcase ch))))

  ;; ch       up       down     title    fold
  (t #\i      #\I      #\i      #\I      #\i)
  (t #\u00df  #\u00df  #\u00df  #\u00df  #\u00df) ; eszett
  (when (memv (gauche-character-encoding) '(utf-8 euc-jp sjis))
    (t #\u03a3  #\u03a3  #\u03c3  #\u03a3  #\u03c3) ; sigma
    (t #\u03c3  #\u03a3  #\u03c3  #\u03a3  #\u03c3) ; sigma
    (t #\u03c2  #\u03a3  #\u03c2  #\u03a3  #\u03c3) ; final sigma
    )
  
  (case (gauche-character-encoding)
    [(none) 
     (t #\u00b5  #\u00b5  #\u00b5  #\u00b5  #\u00b5) ; micro sign
     (t #\u00ff  #\u00ff  #\u00ff  #\u00ff  #\u00ff) ; y with diaeresis
     ]
    [(utf-8)
     (t #\u00b5  #\u039c  #\u00b5  #\u039c  #\u03bc) ; micro sign
     (t #\u00ff  #\u0178  #\u00ff  #\u0178  #\u00ff) ; y with diaeresis
     ])

  (when (eq? (gauche-character-encoding) 'utf-8)
    (t #\u01f1  #\u01f1  #\u01f3  #\u01f2  #\u01f3) ; DZ -> DZ dz Dz dz
    (t #\u01f2  #\u01f1  #\u01f3  #\u01f2  #\u01f3) ; Dz -> DZ dz Dz dz
    (t #\u01f3  #\u01f1  #\u01f3  #\u01f2  #\u01f3) ; dz -> DZ dz Dz dz
    )

  ;; These characters are in JISX0213 but not in Unicode.
  (when (eq? (gauche-character-encoding) 'eucjp)
    (t #\xa4f7  #\xa4f7  #\xa4f7  #\xa4f7  #\xa4f7) ; Ka + semi voice mark
    (t #\xabc4  #\xabc4  #\xabc4  #\xabc4  #\xabc4) ; ae + accent grave
    (t #\xabe6  #\xabe6  #\xabe6  #\xabe6  #\xabe6) ; modifier
    )
  (when (eq? (gauche-character-encoding) 'sjis)
    (t #\x82f5  #\x82f5  #\x82f5  #\x82f5  #\x82f5) ; Ka + semi voice mark
    (t #\x8663  #\x8663  #\x8663  #\x8663  #\x8663) ; ae + accent grave
    (t #\x8686  #\x8686  #\x8686  #\x8686  #\x8686) ; modifier
    )
  )

;; In the following tests, we check if the character is supported in
;; the running platform by comparing the literal character with #\? or
;; #\u3013 --- these are alternative characters replaced if the given
;; literal character isn't supported on the platform.  When adding tests,
;; be careful not to test with #\? or #\u3013, for such tests won't be
;; executed.

(let ()
  (define (unsupported? ch) (or (eqv? ch #\?) (eqv? ch #\u3013)))

  (let-syntax ([test2 (syntax-rules ()
                        [(_ fn c0 c1 expected)
                         (let ([t0 c0] [t1 c1])
                           (unless (or (unsupported? t0) (unsupported? t1))
                             (test* '(fn c0 c1) expected (fn t0 t1))))])]
               [test1 (syntax-rules ()
                        [(_ fn c0 expected)
                         (let ([t0 c0])
                           (unless (unsupported? t0)
                             (test* '(fn c0) expected (fn t0))))])])

    (test2 char-ci<? #\z #\Z #f)
    (test2 char-ci<? #\Z #\z #f)
    (test2 char-ci<? #\a #\Z #t)
    (test2 char-ci<? #\Z #\a #f)
    (test2 char-ci<=? #\z #\Z #t)
    (test2 char-ci<=? #\Z #\z #t)
    (test2 char-ci<=? #\a #\Z #t)
    (test2 char-ci<=? #\Z #\a #f)
    (test2 char-ci=? #\z #\a #f)
    (test2 char-ci=? #\z #\Z #t)
    (test2 char-ci=? #\u03c2 #\u03c3 #t)   ; downcase sigma
    (test2 char-ci>? #\z #\Z #f)
    (test2 char-ci>? #\Z #\z #f)
    (test2 char-ci>? #\a #\Z #f)
    (test2 char-ci>? #\Z #\a #t)
    (test2 char-ci>=? #\Z #\z #t)
    (test2 char-ci>=? #\z #\Z #t)
    (test2 char-ci>=? #\z #\Z #t)
    (test2 char-ci>=? #\a #\z #f)

    (test1 char-alphabetic? #\a #t)
    (test1 char-alphabetic? #\1 #f)
    (test1 char-numeric? #\1 #t)
    (test1 char-numeric? #\a #f)
    (test1 char-whitespace? #\space #t)
    (test1 char-whitespace? #\u00A0 #t)
    (test1 char-whitespace? #\a #f)
    (test1 char-upper-case? #\a #f)
    (test1 char-upper-case? #\A #t)
    (test1 char-upper-case? #\u03a3 #t)     ; large sigma
    (test1 char-lower-case? #\a #t)
    (test1 char-lower-case? #\A #f)
    (test1 char-lower-case? #\u03c3 #t)     ; small sigma
    (test1 char-lower-case? #\u00AA #t)     ; feminine ordinal indicator
    (test1 char-title-case? #\a #f)
    (test1 char-title-case? #\A #f)
    (test1 char-title-case? #\I #f)
    (test1 char-title-case? #\u3004 #f)    ; JIS mark
    (test1 char-title-case? #\u01C5 #t)    ; Dz with caron

    (test1 char-general-category #\a 'Ll)
    (test1 char-general-category #\space 'Zs)
    (test1 char-general-category #\u10FFFF 'Cn)
    ))

(let ()
  (let-syntax ([t0
                (syntax-rules ()
                  [(_ ch fn exp)
                   (test* (format "~a #\\~4,'0x" 'fn (char->integer ch))
                          exp (fn ch))])])
    (define (t ch alpha? upper? lower? cat)
      (t0 ch char-alphabetic? alpha?)
      (t0 ch char-upper-case? upper?)
      (t0 ch char-lower-case? lower?)
      (t0 ch char-general-category cat))
    
    ;; Test characters that are in JISX0213 but not in Unicode 6.0.
    (when (eq? (gauche-character-encoding) 'euc-jp)
      (t #\xa4f7 #t #f #f 'Lo)
      (t #\xabc4 #t #f #t 'Ll)
      (t #\xabe6 #f #f #f 'Sk))
    (when (eq? (gauche-character-encoding) 'sjis)
      (t #\x82f5 #t #f #f 'Lo)
      (t #\x8663 #t #f #t 'Ll)
      (t #\x8686 #f #f #f 'Sk))
    ))

(test-end)

;; Encode-specific stuff
(case (gauche-character-encoding)
  [(euc-jp) (load "euc-jp")]
  [(sjis)   (load "sjis")]
  [(utf-8)  (load "utf-8")]
  [(none)   #f]
  [else (format #t "No test provided for the character encoding ~s"
                (gauche-character-encoding))])


