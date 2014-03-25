;;; rx+.el --- Extensions to rx+.el
;; Author: Per Nordlöw
;; \see http://www.emacswiki.org/emacs/rx

(provide 'rx+)

(defmacro rx+ (&rest regexps)
  (let ((add-ins (list
                  ;; \todo Replace cdr with `rx' expressions

                  ;; Contexts
                  `(file . ,(rx (+ (or alnum digit "." "/" "-" "_"))))
                  `(boy . ,(rx symbol-start))
                  `(eoy . ,(rx symbol-end))

                  ;; Whitespace
                  `(ws0 . ,(rx (0+ (any " " "\t"))))
                  `(ws+ . ,(rx (+ (any " " "\t"))))

                  ;; Word
                  `(w+ . ,(rx (+ word)))
                  `(w* . ,(rx (* word)))
                  `(w? . ,(rx (? word)))

                  ;; Number Literals
                  `(int . ,(rx (+ digit)))
                  `(oct-int . ,(rx "0" (+ (in ?0 ?9))))
                  `(hex-int . ,(rx "0x" (+ hex-digit)))
                  
                  ;; C Identifiers
                  `(id . ,(rx (: (regexp "\\(?:")
                                  (| word
                                     (syntax symbol))
                                  (regexp "\\)"))))
                  `(c-id . ,(eval `(rx (regexp ,c-id-regexp))))
                  )))
    `(let ((rx-constituents (append ',add-ins rx-constituents nil)))
       (rx
        ,@regexps))))
;; Use: (rx+ id)
;; Use: (rx+ c-id)
;; Use: (rx+ space)
;; Use: (rx+ word)
;; Use: (rx+ int)
;; Use: (rx+ boy)
;; Use: (rx+ eoy)
;; Use: (rx+ w?)
;; Use: (rx+ hex-int)
;; Use: (rx+ oct-int)
