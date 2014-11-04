;;; regexp-utils.el --- Extensions and add-ons to package `rx'.
;; Author: Per Nordlöw

(require 'rx)

;; Use:
;; - `char-before', `char-after'
;; - `looking-at', `looking-back'
;; - `search-forward', `search-backward'
;; - `re-search-forward', `re-search-backward'
;; - `skip-chars-forward',`skip-chars-backward'
;; - `bolp', `eolp'
;; - `string-equal'
;; - `defun'
;; - `make-string', `string', `char-to-string'
;; - `make-symbol'

(defun regexp-parse-char-alt ()
  "Parse Emacs-Style Regular Expression Character Alternative to
`rx' representation."
  (let (tree)
    (while (not (eq (char-after) ?\]))
      (let ((c0 (char-after)))
        (cond ((eobp)
               (error "Incomplete Character Alternative!")
               )
              ((eq c0 ?-)
               (forward-char)
               (push (if tree
                         (let ((c1 (char-after)))
                           (if (or (eq c1 ?\]) ;`c0' is last char
                                   (consp (car tree))) ;if previous is a completed range
                               c0                      ;as is
                             (forward-char)
                             (cons (pop tree) c1))) ;ranges are given as (cons LOW HIGH)
                       c0)              ;if first character
                     tree)              ;push ?- as is
               )
              ((looking-at "\\[:\\([a-zA-Z-_]+\\):]") ;for example [:alpha:]
               (goto-char (match-end 1)) ;skip whole class specification
               (push (make-symbol (match-string-no-properties 1)) tree) ;push class as is
               )
              (t
               (push c0 tree) (forward-char) ;push character as is
               )
              )))
    (unless (eobp) (forward-char))
    ;;(uniquify-list-members tree)        ;uniquify list
    (setq tree (nreverse tree))
    (when tree (push 'any tree))
    tree))

(defun rx-simplify (tree)
  "Simplify the `rx'-expression tree TREE. See `rx` for details."
  regexp)

(defconst regexp-special-chars-list
  '(?$ ?^ ?. ?* ?+ ?? ?\[ ?\\)
  "List of characters that have a special meaning in Emacs
Regular Expression.")

(defun regexp-parse-string (regexp &optional format simplify-flag)
  "Parse the regular expression REGEXP into a lisp expression.
Expression syntax is given by FORMAT, defaulting to `rx'.  See
the package `sregex' and `rx' for details returned
structure. Note: This function is written as a state machine with
code clarity in mind, so it easily can transform it optimal. Each
state transition is typically triggered by a character read."
  (let (tree        ;expression tree (stack)
        groups      ;group arguments counts into `tree'
        )
    (with-temp-buffer
      (insert regexp)
      (goto-char (point-min))
      (display-buffer (current-buffer))
      (while (not (eobp))
        (let ((c0 (char-after)))
          (cond ((memq c0 '(?? ?* ?+))  ;special regexp operator
                 (let ((op (char-to-string c0))) ;operator string
                   (forward-char)         ;skip char
                   (when (eq (char-after) ??) ;if greedy operator
                     (setq op (concat op (char-to-string ??))) ;append to operator
                     (forward-char))    ;skip greedy operator
                   (push (if tree       ;if postfix operator has argument
                             (list (make-symbol op) (pop tree)) ;use it as operator
                           c0)          ;otherwise use as a plain characterx
                         tree))
                 )
                ((eq c0 ?.)         ;any single character except a newline
                 (push 'nonl tree) (forward-char)
                 )
                ((eq c0 ?^)            ;beginning of line
                 (push 'bol tree) (forward-char)
                 )
                ((eq c0 ?$)            ;end of line
                 (push 'eol tree) (forward-char)
                 )
                ((eq c0 ?\[)            ;opening hook: start alternative
                 (forward-char)
                 (let ((alt-tree (regexp-parse-char-alt)))
                   (when alt-tree (push alt-tree tree)))
                 )
                ((eq c0 ?\\)            ;backquoting
                 (forward-char)
                 (let ((c1 (char-after)))
                   (cond ((memq c1 regexp-special-chars-list)
                          (push c1 tree) (forward-char) ;as is
                          )
                         ((eq c1 ?_)    ;backqoute underscore
                          (forward-char)
                          (let ((c2 (char-after)))
                            (cond ((eq c2 ?<)
                                   (push 'symbol-start tree) (forward-char)
                                   )
                                  ((eq c2 ?>)
                                   (push 'symbol-end tree) (forward-char)
                                   )
                                  (t
                                   (push (string c0 c1) tree) ;backqouted character as is
                                   )))
                          )
                         ((memq c1 '(0 1 2 3 4 5 6 7 8 9)) ;same text that matched the digit:th occurrence of a grouping (‘\( ... \)’) construct.
                          (push `(backref (- c1 ?0)) tree) (forward-char)
                          )
                         ((eq c1 ?\()    ;beginning of group
                          (forward-char)
                          (push 0 groups)
                          (if (looking-at "?:")
                              (progn (forward-char 2)
                                     (push 'shy-start tree))
                            (push 'group-start tree))
                          )
                         ((eq c1 ?\))    ;end of word
                          (forward-char)
                          (if groups (pop groups) (error "Unbalanced Group End!"))
                          (let (group-tree)
                            ;; push all arguments until we find `group-start'
                            (while (and tree ;args left
                                        (not (memq (car tree) '(shy-start group-start))))
                              (push (pop tree) group-tree))
                            (if tree
                                (let ((g-sym (pop tree)))
                                  (cond ((eq 'group-start g-sym)
                                         (push `(group ,@group-tree) tree))
                                        ((eq 'shy-start g-sym)
                                         (push `(: ,@group-tree) tree))
                                        (t
                                         (error "Unbalanced Group End!"))
                                        ))
                              (error "Unbalanced Group End!"))
                            )
                          )
                         ((eq c1 ?<)    ;beginning of word
                          (push 'bow tree) (forward-char)
                          )
                         ((eq c1 ?>)    ;end of word
                          (push 'eow tree) (forward-char)
                          )
                         ((eq c1 ?`)    ;beginning of buffer/string/text
                          (push 'bot tree) (forward-char)
                          )
                         ((eq c1 ?')    ;end of buffer/string/text
                          (push 'eot tree) (forward-char)
                          )
                         ((eq c1 ?w) ;any word-constituent character. The editor syntax table determines which characters these are. See Syntax Tables.
                          (push 'wordchar tree) (forward-char)
                          )
                         ((eq c1 ?W)    ;any character that is not a word constituent.
                          (push 'not-wordchar tree) (forward-char)
                          )
                         (t             ;any other backquoted character
                          (push (string c0 c1) tree) (forward-char) ;backqouted character as is
                          )
                         )
                   )
                 )
                (c0                     ;if we have character
                 (when nil
                   (if (and (looking-at (concat regexp-ordinary-char-regexp "+")) ;one or more number of ordinary chars
                            (> (match-length 0) 0))
                       (progn
                         ;; TODO if next char c1 fullfils (memq c1 '(?? ?* ?+)) push all but last to string and push last on stack
                         (goto-char (match-end 0)) ;goto end of string
                         (push (match-string-no-properties 0) tree) ;list as is
                         )
                     (error "Unhandled regexp special character %s!" c0)))

                 (forward-char) (push c0 tree) ;regexp as is
                 )
                ))))
    (let ((len (length tree)))
      (cond ((>= len 2)                 ;if several nodes
             (setq tree (nreverse tree)) ;reverse them
             (push ': tree)
             tree                       ;return tree
             )
            ((= len 1)
             (car tree))
            (t
             nil
             )
            ))))
(defalias 're-parse 'regexp-parse-string)
(defalias 'make-rx 'regexp-parse-string)
(when nil
  (rx 97)
  (rx "a")
  (regexp-parse-string "a")
  (rx-to-string (regexp-parse-string "\\(?:a\\)"))
  (regexp-parse-string "\\(ab\\)")
  (regexp-parse-string "\\(?:ab?\\)")
  (let ((str (concat "\\([]\\)"
                     "\\([-a]\\)"
                     "\\([a-]\\)"
                     "\\([a-zA-Z-]\\)"
                     "\\`" "^" "\\_<" "\\<" "\\w" "\\W" "a\\*" "a" "\b" "\0" "\\>" "\\_>" "aa*bb*" "$" "\\'")))
    (regexp-parse-string str))
  )
;; Use: (rx-to-string (regexp-parse-string "a") t)
;; Use: (rx-to-string (regexp-parse-string "a+") t)
(let ((tree "a"))
  (equal
   tree
   (regexp-parse-string (rx-to-string tree t))
  ))
;; (regexp-parse-string (rx-to-string ?a t))

(when nil
  (let* ((re "aa.*bb.?cc.+dd")
         (rt (regexp-parse-string re)))
    ;;(eval `(rx ,re)))
    (equal re
           (when rt (eval `(rx ,rt))))))

(provide 'regexp-utils)
