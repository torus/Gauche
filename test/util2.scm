;; testing util.* that depend on extension modules

(use gauche.test)
(test-start "util.* modules extra")

;;;========================================================================
(test-section "util.levenshtein")
(use util.levenshtein)
(test-module 'util.levenshtein)

(let1 datasets
    '((""
       (""                          0   0   0)
       ("a"                         1   1   1)   ;1i
       ("abc"                       3   3   3))  ;3i
      ("abc"
       (""                          3   3   3)
       ("ab"                        1   1   1)   ;1d
       ("ac"                        1   1   1)   ;1d
       ("bc"                        1   1   1)   ;1d
       ("acb"                       2   1   1)   ;1t
       ("ca"                        3   3   2)   ;1d, 1t
       ("bdac"                      3   3   2))
      ("ca"
       ("abc"                       3   3   2))
      ("rcik"
       ("rick"                      2   1   1)
       ("irkc"                      4   4   3))
      )
  (define (test-algo name distances result-selector)
    (dolist [set datasets]
      (test* #"~|name| distance with \"~(car set)\""
             (map result-selector (cdr set))
             (distances (car set) (map car (cdr set)))))
    (dolist [set datasets]
      (test* #"~|name| distance with \"~(car set)\", cutoff 2"
             (map (^x (let1 r (result-selector x)
                        (and (<= r 2) r)))
                  (cdr set))
             (distances (car set) (map car (cdr set)) :cutoff 2))))

  (test-algo "Levenshtein" l-distances cadr)
  (test-algo "Restricted edit" re-distances caddr)
  (test-algo "Damerau-Levenshtein" dl-distances cadddr))


(test-end)