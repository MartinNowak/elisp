;;; thingatpt-syntax.el --- Syntactic context thing at point.)
;; Copyright (C) 2008 Per Nordlöw)
;; TODO: Merge with `semantic-ctxt'.

(require 'cc-utils)
(require 'pnw-regexps)
(require 'rx)
(require 'thingatpt-pnw)
(require 'cc-patterns)

;; TODO: Use `defenum' alias for `define-enumeration' in defenum.el.
(defconst tag-ctx-function-definition 1)
(defconst tag-ctx-function-declaration 2)

(defconst tag-ctx-function-call 3)
(defconst tag-ctx-member-function-call 4)

(defconst tag-ctx-variable-declaration 5)
(defconst tag-ctx-variable-definition 6)
(defconst tag-ctx-variable-assignment 7)

(defconst tag-ctx-symbol-reference 8)
(defconst tag-ctx-member-reference 9)
(defconst tag-ctx-constant 10)

(defconst tag-ctx-type-definition 11)
(defconst tag-ctx-type-reference 12)
(defconst tag-ctx-struct-reference 13)
(defconst tag-ctx-union-reference 14)
(defconst tag-ctx-enum-reference 15)

(defconst tag-ctx-class-declaration 16)
(defconst tag-ctx-class-definition 17)
(defconst tag-ctx-class-reference 18)
(defconst tag-ctx-class-ctor-call 19)
(defconst tag-ctx-class-dtor-call 20)

(defconst tag-ctx-scope 21)
(defconst tag-ctx-include 22)

(defconst tag-ctx-function-macro 23)
(defconst tag-ctx-constant-macro 24)
(defconst tag-ctx-macro-reference 25)

(defun thing-at-point-syntax-context (&optional mode pos)
  "Determine Syntactic Context and its possible tag kinds (things) at a point.
Return it as a (CONTEXT . LIST-OF-TAG-KIND-CHARS).
If there is no plausible default, return nil. MODE is the major
mode to use for syntactic analysis that defaults to
`major-mode'."
  (unless mode (setq mode major-mode))
  (cond
   ((cc-derived-mode-p mode)
    (let ((p (point)))                  ;save point
      (when pos (goto-char pos))        ;if position given go to it
      (let* ((sym (symbol-at-point)))   ;get symbol if any
        (when sym                         ;if symbol
          (progn
            (beginning-of-symbol-next-to-point)
            (prog1
                (cond
                 ;; C++ ctor/dtor function call
                 ((and (eq mode 'c++-mode)
                       (looking-back (concat Y<
                                             "\\("
                                             "new" "\\|"
                                             "delete" "\\(?:" L* "\\[]" "\\)?"
                                             "\\)"
                                             L+))
                       (looking-at (concat ID L* "(?")) ;CLASS WS (
                       )
                  (if (string-equal (match-string 1) "new")
                      tag-ctx-class-ctor-call
                    tag-ctx-class-dtor-call) ;TODO: Lookup class of `sym' and go to its dtor
                  )

                 ;; class declaration (must be before variable declaration) or definition
                 ((and (eq mode 'c++-mode)
                       (looking-back (concat Y<
                                             "\\("
                                             "class" "\\|"
                                             "public" "\\|"
                                             "protected" "\\|"
                                             "private"
                                             "\\)"
                                             L*)))
                  (if (string-equal (match-string 1) "class")
                      (if (looking-at (concat ID L* ";" ;TYPE WS
                                              ))
                          tag-ctx-class-declaration
                        tag-ctx-class-definition)
                    tag-ctx-class-reference)
                  )

                 ;; TODO: function argument of type function pointer. See argument
                 ;; to pPatt for details on syntax.

                 ;; cpp macro definition or reference
                 ((looking-back (concat "^" _* "#" _*
                                        "\\("
                                        "include" _* "\"" "\\|"
                                        "define" _+ "\\|"
                                        "ifn?def" _+
                                        "\\)"))
                  (let ((str (match-string 1)))
                    (if (string-match "^include" str)
                        tag-ctx-include
                      (if (string-match "^define" str)
                          (if (looking-at (concat ID "("))
                              tag-ctx-function-macro
                            tag-ctx-constant-macro
                            tag-ctx-macro-reference)
                        ))))

                 ;; class/function/macro call
                 ((looking-at (concat ID L* "(")) ;FUN WS (
                  (if (looking-back (concat "\\(" "\\." "\\|" "->" "\\)" L*))
                      tag-ctx-member-function-call ;member function call

                    tag-ctx-function-call)) ;prefer ctors over functions over macros

                 ;; type reference
                 ((looking-at (concat ID L*            ;TYPE WS
                                      "[*[:space:]]*"  ;WS or PTR-OP
                                      "&?"             ;REF-OP
                                      L*               ;WS
                                      "\\(?:"
                                      ID L* "[([;,]" ;VAR DECL
                                      "\\|"
                                      ID L* "=" ;VAR DEF
                                      "\\|"
                                      "\\(?:" ID "\\)" L* "[;,)]" ;VAR WS
                                      "\\|"
                                      ID L* "\\(?:" "::" L* ID L* "\\)*" "(" ;FUN CALL
                                      "\\)"))
                  (cond ((looking-back (concat Y< "struct" L+)) ;struct STRUCT-NAME
                         tag-ctx-struct-reference)
                        ((looking-back (concat Y< "union" L+)) ;union UNION-NAME
                         tag-ctx-union-reference)
                        ((looking-back (concat Y< "enum" L+)) ;enum ENUM-NAME
                         tag-ctx-enum-reference)
                        (t
                         tag-ctx-type-reference))
                  )

                 ;; variable assignment
                 ((looking-at (concat ID L*
                                      (regexp-opt (c-op-assignment)) "[^=]" ;VAR WS
                                      ))
                  tag-ctx-variable-assignment)

                 ;; variable declaration
                 ((and
                   (looking-at (concat ID L*  ;WS or PTR-OPs
                                       "\\(?:" ":" L* D+ "\\)?" ;optional bit-field size
                                       ";"))
                   (looking-back (concat Y< "extern" L* ID "[*[:space:]]*" "&?" L*)))
                  tag-ctx-variable-declaration)

                 ;; variable definition
                 ((and
                   (looking-at (concat ID
                                       L*  ;WS or PTR-OPs
                                       ";"
                                       ))
                   (looking-back (concat "\\(" ID "\\)" "[*[:space:]]*" "&?" L*))
                   (not (member (match-string-no-properties 1)
                                '("return" "throw")))
                   )
                  tag-ctx-variable-definition)

                 ;; class/namespace scope
                 ((looking-at (concat ID L*   ;TYPE WS
                                      "::" L* ;SCOPE-OP WS
                                      ;;ID            ;MEMBER-NAME
                                      ))
                  tag-ctx-scope
                  )

                 ;; symbol reference
                 ((looking-at (concat ID L* ;VAR WS
                                      "\\(?:" (rx (| "+" "-" "/" "%" "," ";" ")" "]" "." "->")) "\\)" ;OP
                                      ))
                  tag-ctx-symbol-reference) ;Note: in last case reference to function (pointer)
                 )
              (goto-char p)))
          )))
    )))
;; Use: (car (thing-at-point-syntax-context))

(provide 'thingatpt-syntax)
