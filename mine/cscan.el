;;; cscan.el --- Match Contents of strings, buffers and files with strings and regexps. Supports clustered sorting of hits used by package `tscan'.
;;
;; Author: Per Nordlöw

;; TODO: Fails: (cscan-file "~/cognia/semnet/know_dfmts.cpp" "file" nil t t 'unbox-txt 'clust nil nil t)

;; TODO: `cscan-directory', `cscan-file-tree'.
;; TODO: Remove use of hardcoded fcache formats (when comparing to `bcache') in `cscan-file-uncached'.

;; TODO: Do preliminary literal scanning of literal components of pattern before
;; continuing with syntactic analysis `syntax-ppss'.
;;
;; TODO: This errors: (fcache-chase-links (fcache-of "~/cognia/boost/smart_enum.hpp"))

(require 'thingatpt-syntax)
(require 'file-utils)
(require 'fcache)
(require 'jka-compr)
(eval-when-compile (require 'cl))

;; ---------------------------------------------------------------------------

(defun match-at-symbol-context-p (mnum ctx)
  "Return non-nil if match number MNUM has context CTX."
  (let ((mbeg (match-beginning mnum)))
    (when mbeg                          ;assure that match MNUM is defined
      (case ctx
        (beg                             ;at beginning of buffer (offset 0)
         (= (match-beginning mnum) (point-min)))
        (end                             ;at end of buffer
         (= (match-end mnum) (point-max)))
        (bol                             ;at beginning of line
         (= (match-beginning mnum) (save-excursion (beginning-of-line) (point)))) ;NOTE: or use (save-match-data (looking-back "^"))
        (eol                             ;at end of line
         (= (match-end mnum) (save-excursion (end-of-line) (point)))) ;NOTE: or use (save-match-data (looking-at "$"))
        ((full t)                        ;from beginning exactly to end
         (and (= (match-beginning mnum) (point-min))
              (= (match-end mnum) (point-max))))

        ;; syntax contexts. TODO: Reuse my own logic for this.
        (code
         (and (at-syntax-code-p (match-beginning mnum))
              (at-syntax-code-p (match-end mnum))))
        (comment
         (and (at-syntax-comment-p (match-beginning mnum))
              (at-syntax-comment-p (match-end mnum))))
        (string
         (and (at-syntax-string-p (match-beginning mnum))
              (at-syntax-string-p (match-end mnum))))

        ;; multi
        (t                            ;otherwise if no context
         t)))))                       ;always true
;; Use: (match-at-symbol-context-p 0 'end)
;; Use: (match-at-symbol-context-p 10 'end)

(defun match-at-single-context-p (mnum ctx)
  "Return non-nil if match number MNUM has context CTX."
  (cond ((symbolp ctx)                           ;context is a symbol
         (match-at-symbol-context-p mnum ctx))   ;Note: Recurse to all contexts.
        ((numberp ctx)                           ;context is simply an offset
         (= ctx (match-beginning mnum)))
        ))

(defun match-at-context-p (mnum ctx)
  "Return non-nil if match number MNUM has context CTX.
CTX can be a symbol, number or a list of these."
  (cond ((listp ctx)
         (let ((result
                (mapcar `(lambda (s-ctx)
                           (match-at-single-context-p ,mnum s-ctx)) ctx)))
           (eval `(every-p ',result))))
        (t
         (match-at-single-context-p mnum ctx))))

;; ---------------------------------------------------------------------------

;; TODO: Optimize this by using file-type-hash to check if current-buffer is binary.
(defun cscan-beginning-of-hit-context ()
  "Goto beginning of scan hit context. Return if beginning of
line, otherwise nil (binary data was found)."
  (ignore-errors
    (re-search-backward "^\\|[^\t[:print:]]")) ;find non-printable or beginning of line
  (if (not (looking-at "[^\t[:print:]]"))
      t
    (forward-char) nil))
;; Use:(cscan-beginning-of-hit-context)

;; TODO: Optimize this by using file-type-hash to check if current-buffer is binary.
(defun cscan-end-of-hit-context ()
  "Goto end of scan hit context. Return t if end of line was
found, otherwise nil (binary data was found)."
  (ignore-errors
    (re-search-forward "$\\|[^\t[:print:]]"))
  (if (not (looking-back "[^\t[:print:]]"))
      t
    (backward-char) nil))
;; Use: (cscan-end-of-hit-context)

;; ---------------------------------------------------------------------------

;; Syntax
(defconst cscan-syntax-shift 0)
(defconst cscan-syntax-width 4)
(defconst cscan-syntax-mask (lsh #xf cscan-syntax-shift))
(defconst cscan-syntax-code-group (lsh #x1 cscan-syntax-shift))
(defconst cscan-syntax-string-group (lsh #x2 cscan-syntax-shift))
(defconst cscan-syntax-comment-group (lsh #x3 cscan-syntax-shift))

;; Case
(defconst cscan-case-shift (+ cscan-syntax-shift cscan-syntax-width))
(defconst cscan-case-width 4)
(defconst cscan-case-mask (lsh (1- (lsh 1 cscan-case-width)) cscan-case-shift))
(defconst cscan-case-lower-group (lsh 1 cscan-case-shift))
(defconst cscan-case-upper-group (lsh 2 cscan-case-shift))
(defconst cscan-case-mixed-group (lsh 3 cscan-case-shift))

;; Delim
(defconst cscan-delim-shift (+ cscan-case-shift cscan-case-width)) ;Bit Offset
(defconst cscan-delim-width 4)          ;Bit Count
(defconst cscan-delim-mask (lsh (1- (lsh 1 cscan-delim-width)) cscan-delim-shift))
(defconst cscan-delim-symbol-group (lsh 1 cscan-delim-shift))
(defconst cscan-delim-symbol-prefix-group (lsh 2 cscan-delim-shift))
(defconst cscan-delim-symbol-suffix-group (lsh 3 cscan-delim-shift))
(defconst cscan-delim-word-group (lsh 4 cscan-delim-shift))
(defconst cscan-delim-word-prefix-group (lsh 5 cscan-delim-shift))
(defconst cscan-delim-word-suffix-group (lsh 6 cscan-delim-shift))
(defconst cscan-delim-inword-group (lsh 7 cscan-delim-shift))

(require 'thingatpt-syntax)

;; Syntax Ctx

(defconst cscan-lex-shift (+ cscan-delim-shift cscan-delim-width))
(defconst cscan-lex-width 6)
(defconst cscan-lex-mask (lsh (1- (lsh 1 cscan-lex-width)) cscan-lex-shift))

(defconst cscan-lex-function-definition-group (lsh tag-ctx-function-definition cscan-lex-shift))
(defconst cscan-lex-function-call-group (lsh tag-ctx-function-call cscan-lex-shift))
(defconst cscan-lex-member-function-call-group (lsh tag-ctx-member-function-call cscan-lex-shift))

(defconst cscan-lex-variable-declaration-group (lsh tag-ctx-variable-declaration cscan-lex-shift))
(defconst cscan-lex-variable-definition-group (lsh tag-ctx-variable-definition cscan-lex-shift))
(defconst cscan-lex-variable-assignment-group (lsh tag-ctx-variable-assignment cscan-lex-shift))
(defconst cscan-lex-symbol-reference-group (lsh tag-ctx-symbol-reference cscan-lex-shift))
(defconst cscan-lex-member-reference-group (lsh tag-ctx-member-reference cscan-lex-shift))
(defconst cscan-lex-constant-group (lsh tag-ctx-constant cscan-lex-shift))

(defconst cscan-lex-type-definition-group (lsh tag-ctx-type-definition cscan-lex-shift))
(defconst cscan-lex-type-reference-group (lsh tag-ctx-type-reference cscan-lex-shift))
(defconst cscan-lex-struct-reference-group (lsh tag-ctx-struct-reference cscan-lex-shift))
(defconst cscan-lex-union-reference-group (lsh tag-ctx-union-reference cscan-lex-shift))
(defconst cscan-lex-enum-reference-group (lsh tag-ctx-enum-reference cscan-lex-shift))

(defconst cscan-lex-class-declaration-group (lsh tag-ctx-class-declaration cscan-lex-shift))
(defconst cscan-lex-class-definition-group (lsh tag-ctx-class-definition cscan-lex-shift))
(defconst cscan-lex-class-reference-group (lsh tag-ctx-class-reference cscan-lex-shift))
(defconst cscan-lex-class-ctor-call-group (lsh tag-ctx-class-ctor-call cscan-lex-shift))
(defconst cscan-lex-class-dtor-call-group (lsh tag-ctx-class-dtor-call cscan-lex-shift))

(defconst cscan-lex-scope-group (lsh tag-ctx-scope cscan-lex-shift))
(defconst cscan-lex-include-group (lsh tag-ctx-include cscan-lex-shift))

(defconst cscan-lex-function-macro-group (lsh tag-ctx-function-macro cscan-lex-shift))
(defconst cscan-lex-constant-macro-group (lsh tag-ctx-constant-macro cscan-lex-shift))
(defconst cscan-lex-macro-reference-group (lsh tag-ctx-macro-reference cscan-lex-shift))

;; Regexp Match Number (Sub-Expression (Sub-Exp)
(defconst cscan-matchnr-shift (+ cscan-lex-shift cscan-lex-width))
(defconst cscan-matchnr-width 8)      ;Maximum Number of Sub-Expression allowed.
(defconst cscan-matchnr-mask (lsh (1- (lsh 1 cscan-matchnr-width)) cscan-matchnr-shift))

(defconst cscan-last-shift (+ cscan-matchnr-shift cscan-matchnr-width))

(defun cscan-lex-from-thing-at-point-syntax-context (tag-ctx)
  (lsh tag-ctx cscan-lex-shift))
;; Use: (cscan-lex-from-thing-at-point-syntax-context 0)
;; Use: (cscan-lex-from-thing-at-point-syntax-context tag-ctx-function-definition-group)

(defconst cscan-syntax-group-names
  `(
    (,cscan-syntax-code-group . "Code")
    (,cscan-syntax-string-group . "String")
    (,cscan-syntax-comment-group . "Comment")
    ))

(defconst cscan-case-group-names
  `(
    (,cscan-case-lower-group . "Lower-Case")
    (,cscan-case-upper-group . "Upper-Case")
    (,cscan-case-mixed-group . "Mixed-Case")
    ))

(defconst cscan-delim-group-names
  `(
    (,cscan-delim-symbol-group . "Symbol")
    (,cscan-delim-symbol-prefix-group . "Symbol-Prefix")
    (,cscan-delim-symbol-suffix-group . "Symbol-Suffix")

    (,cscan-delim-word-group . "Word")
    (,cscan-delim-word-prefix-group . "Word-Prefix")
    (,cscan-delim-word-suffix-group . "Word-Suffix")

    (,cscan-delim-inword-group . "Inword")
    ))

(defconst cscan-lex-group-names
  `(
    ;; Lex
    (,cscan-lex-function-definition-group . "Function-Definition")
    (,cscan-lex-function-call-group . "Function-Call")
    (,cscan-lex-member-function-call-group . "Member-Function-Call")

    (,cscan-lex-variable-declaration-group . "Variable-Declaration")
    (,cscan-lex-variable-definition-group . "Variable-Definition")
    (,cscan-lex-variable-assignment-group . "Variable-Assignment")
    (,cscan-lex-symbol-reference-group . "Symbol-Reference")
    (,cscan-lex-member-reference-group . "Symbol-Member-Reference")

    (,cscan-lex-constant-group . "Constant")

    (,cscan-lex-type-definition-group . "Type-Definition")
    (,cscan-lex-type-reference-group . "Type-Reference")
    (,cscan-lex-struct-reference-group . "Structure-Reference")
    (,cscan-lex-union-reference-group . "Union-Reference")
    (,cscan-lex-enum-reference-group . "Enumeration-Reference")

    (,cscan-lex-function-macro-group . "Function-Macro")
    (,cscan-lex-constant-macro-group . "Constant-Macro")
    (,cscan-lex-macro-reference-group . "Macro-Reference")

    (,cscan-lex-class-declaration-group . "Class-Declaration")
    (,cscan-lex-class-definition-group . "Class-Defintion")
    (,cscan-lex-class-reference-group . "Class-Reference")
    (,cscan-lex-class-ctor-call-group . "Class-Constructor-Call")
    (,cscan-lex-class-dtor-call-group . "Class-Destructor-Call")

    (,cscan-lex-scope-group . "Scope")
    (,cscan-lex-include-group . "Include")
    ))

(defun cscan-cluster-title (cluster-code)
  "Return title of CLUSTER-CODE."
  (mapconcat
   'identity
   (append
    (let ((name (logand cluster-code cscan-syntax-mask)))
      (when (neq name 0)
        (list (cdr (assoc name cscan-syntax-group-names)))))
    (let ((name (logand cluster-code cscan-case-mask)))
      (when (neq name 0)
        (list (cdr (assoc name cscan-case-group-names)))))
    (let ((name (logand cluster-code cscan-delim-mask)))
      (when (neq name 0)
        (list (cdr (assoc name cscan-delim-group-names)))))
    (let ((name (logand cluster-code cscan-lex-mask)))
      (when (neq name 0)
        ;; TODO: Specialize `cscan-lex-symbol-reference-group' to C/C++ Keywords.
        (list (cdr (assoc name cscan-lex-group-names)))))
    ) ","))
;; Use: (cscan-cluster-title (logior cscan-syntax-code-group cscan-case-lower-group cscan-delim-word-group))
;; Use: (cscan-cluster-title (logior cscan-syntax-comment-group cscan-case-upper-group cscan-delim-symbol-suffix-group cscan-lex-function-call-group))

;; ---------------------------------------------------------------------------

;; Cluster GROUP format is [NAME HIT-COUNT HITS], where HITS is a list
;; of HIT and HIT is of the form [LBEG LEND LSTR H1BEG H1END H2BEG H2END...],
;; where LBEG LEND are typically the beginning and end of the
;; hit line. CBEG CEND are typically the beginning and end of the
;; delim context.
(defun cscan-make-hit (lbeg lend lstr hbeg hend &optional cbeg cend fcache)
  "Return a Scan Hit of the form [LBEG LEND LSTR HBEG HEND CBEG CEND].
Where
- LBEG is line beginning,
- LEND is line end,
- LSTR is line string,
- HBEG is hit beginning,
- HEND is hit end,
- HBEG is delimiting context beginning,
- HEND is delimiting context end,
"
  `[,lbeg ,lend ,lstr ,hbeg ,hend ,cbeg ,cend ,fcache])
;; (cscan-make-hit 0 5 "alpha" 0 1)
(defsubst cscan-hit-lbeg (hit) (aref hit 0))
(defsubst cscan-hit-lend (hit) (aref hit 1))
(defsubst cscan-hit-lstr (hit) (aref hit 2))

(defsubst cscan-hit-hbeg (hit) (aref hit 3))
(defsubst cscan-hit-hend (hit) (aref hit 4))

(defsubst cscan-hit-cbeg (hit) (aref hit 5))
(defsubst cscan-hit-cend (hit) (aref hit 6))

(defsubst cscan-hit-fcache (hit) (aref hit 7))

(defun cscan-make-base-group (name)
  "Return a Base Hit Group named NAME of format [NAME HIT-COUNT HITS]."
  `[,name 0 nil])
;; (cscan-make-base-group cscan-delim-symbol-group)

(defun cscan-make-middle-group (name &rest args)
  `[,name 0 ,args])
;; (cscan-make-middle-group cscan-case-lower-group (cscan-make-base-group cscan-delim-symbol-group))

(defun cscan-make-delims (name)
  (cscan-make-middle-group name
                           (cscan-make-base-group cscan-delim-symbol-group)
                           (cscan-make-base-group cscan-delim-symbol-prefix-group)
                           (cscan-make-base-group cscan-delim-symbol-suffix-group)
                           (cscan-make-base-group cscan-delim-word-group)
                           (cscan-make-base-group cscan-delim-word-prefix-group)
                           (cscan-make-base-group cscan-delim-word-suffix-group)
                           (cscan-make-base-group cscan-delim-inword-group)
                           )
  )
;; (cscan-make-delims cscan-case-lower-group)

(defun cscan-make-cases (name)
  (cscan-make-middle-group name
                           (cscan-make-delims cscan-case-lower-group)
                           (cscan-make-delims cscan-case-upper-group)
                           (cscan-make-delims cscan-case-mixed-group))
  )
;; (cscan-make-cases cscan-syntax-comment-group)

(defun cscan-make-syntaxes (name)
  (cscan-make-middle-group name
                           (cscan-make-cases cscan-syntax-code-group)
                           (cscan-make-cases cscan-syntax-string-group)
                           (cscan-make-cases cscan-syntax-comment-group))
  )

(defun cscan-make-tree-cluster (&optional name)
  "Return a cscan tree cluster template."
  (cscan-make-syntaxes (or name 'clust)))
;; Use: (cscan-make-tree-cluster 'clust-tree)

(defun cscan-make-flat-cluster (&optional name)
  "Return a cscan flat cluster template."
  `[,name 0 nil])
;; Use: (cscan-make-flat-cluster 'clust)

(defun cscan-make-cluster (name)
 (if (eq name 'clust-tree)
     (cscan-make-tree-cluster name)
   (cscan-make-flat-cluster name)))
;; Use: (cscan-make-cluster 'clust)
;; Use: (cscan-make-cluster 'clust-tree)

(defun cscan-add-flat-cluster (all key hit)
  "Add HIT to KEY-cluster of ALL."
  (let ((clust (assq key all)))         ;get CLUSTER of KEY
    (if clust
        (progn (nconc clust (list hit))
               (incf (nth 1 clust))
               all)
      (nconc all (list (list key 1 hit))))))
;;; Use:
(when nil
  (let ((all))
    (setq all (cscan-add-flat-cluster all cscan-delim-symbol-group '(1 2)))
    (setq all (cscan-add-flat-cluster all cscan-delim-inword-group '(10 11)))
    (setq all (cscan-add-flat-cluster all cscan-delim-inword-group '(20 21)))
    (setq all (cscan-add-flat-cluster all cscan-delim-inword-group '(30 31)))
    (setq all (cscan-add-flat-cluster all (logior cscan-syntax-comment-group
                                                  cscan-delim-inword-group) '(30 31)))
    all
    )
  )

(defun cscan-cluster-hit-hbeg-lessp (h1 h2)
  ;; (when (string-equal h1-lstr h2-lstr)
  ;;   (message "h1-hbeg:%s h2-hbeg:%s" h1-hbeg h2-hbeg))
  (let (
        (h1-hbeg (cscan-hit-hbeg h1))   ;h1 hit beginning
        (h2-hbeg (cscan-hit-hbeg h2))   ;h2 hit beginning
        )
    (< h1-hbeg h2-hbeg)
    ))

(defun cscan-cluster-hit-lessp (h1 h2)
  "Compare hits of H1 and H2."
  (let* (
         (h1-lbeg (cscan-hit-lbeg h1))  ;h1 line beginning
         (h1-lstr (cscan-hit-lstr h1))  ;h1 line string
         (h1-cbeg (cscan-hit-cbeg h1))  ;h1 context beginning
         (h1-cend (cscan-hit-cend h1))  ;h1 context end

         (h2-lbeg (cscan-hit-lbeg h2))  ;h2 line beginning
         (h2-lstr (cscan-hit-lstr h2))  ;h2 line string
         (h2-cbeg (cscan-hit-cbeg h2))  ;h2 context beginning
         (h2-cend (cscan-hit-cend h2))  ;h2 context end

         ;; context comparison
         (ccmp (compare-strings h1-lstr (- h1-cbeg h1-lbeg) (- h1-cend h1-lbeg)
                                h2-lstr (- h2-cbeg h2-lbeg) (- h2-cend h2-lbeg))))
    (if (eq ccmp t)
        (if (string-equal h1-lstr h2-lstr) ;if same line contents
            (cscan-cluster-hit-hbeg-lessp h1 h2)
          (string-lessp h1-lstr h2-lstr)) ;return line contents difference
      (if (< 0 ccmp)
          t                             ;h1 < h2
        nil)                            ;h1 > h2
      )))

(defun cscan-gc-and-sort-tree-clustered-hits (clusters)
  "Garbage Collect and Sort Hit CLUSTERS."
  (if (> (aref clusters 1) 0)
      (mapc (lambda (syntax-c)          ;for each syntax cluster
              (if (> (aref syntax-c 1) 0)
                  (mapc (lambda (case-c) ;for each case cluster
                          (if (> (aref case-c 1) 0)
                              (mapc (lambda (delim-c) ;for each delimitation cluster
                                      (if (> (aref delim-c 1) 0)
                                          (when (memq (aref delim-c 0) `(,cscan-delim-symbol-group
                                                                         ,cscan-delim-symbol-prefix-group
                                                                         ,cscan-delim-symbol-suffix-group
                                                                         ,cscan-delim-word-group
                                                                         ,cscan-delim-word-prefix-group
                                                                         ,cscan-delim-word-suffix-group
                                                                         ,cscan-delim-inword-group))
                                            (let ((cdata (aref delim-c 2)))
                                              (when (eq (car cdata) 'hits)
                                                (setcdr cdata
                                                        (sort (cdr cdata)
                                                              'cscan-cluster-hit-lessp)))))
                                        (aset delim-c 2 nil)))
                                    (aref case-c 2))
                            (aset case-c 2 nil)))
                        (aref syntax-c 2))
                (aset syntax-c 2 nil)))
            (aref clusters 2))
    (aset clusters 2 nil))
  clusters)

(defun cscan-sort-flat-clustered-hits (clusters)
  "Sort Flat Hits CLUSTERS."
  (if (> (aref clusters 1) 0)
      (mapc (lambda (all-c) ;for each cluster
              (when (> (cadr all-c) 0) ;if it has any
                (let ((cdata (cdr all-c)))
                  (setcdr cdata
                          (sort (cdr cdata)
                                'cscan-cluster-hit-lessp)))))
            (aref clusters 2))
    (aset clusters 2 nil))
  clusters)

(defconst cscan-bos-string (string ?w ?_)
  "End-of-Symbol String")

(defun cscan-hit-delim-index-and-region (bow eow bos eos hbeg hend)
  "Return delimitation index and region of hit region (HBEG HEND)."
  (let ((cbeg hbeg)
        (cend hend))
    (cons
     (cond ((and bow eow)                ;Complete Word (WORD)
            (cond ((and bos eos)         ;Complete Symbol (SYM)
                   0)
                  (bos                   ;Symbol-Prefix (BOS)
                   (save-excursion (setq cend (progn (goto-char hend)
                                                     (skip-syntax-forward cscan-bos-string) ;end of symbol
                                                     (point)))
                                   1))
                  (eos                   ;Symbol-Suffix (EOS)
                   (save-excursion (setq cbeg (progn (goto-char hbeg)
                                                     (skip-syntax-backward cscan-bos-string) ;beginning of symbol
                                                     (point)))
                                   2))
                  (t                     ;Complete Word-Only (WORD)
                   (save-excursion (setq cbeg (progn (goto-char hbeg)
                                                     (skip-syntax-backward cscan-bos-string) ;beginning of symbol
                                                     (point))
                                         cend (progn (goto-char hend)
                                                     (skip-syntax-forward cscan-bos-string) ;end of symbol
                                                     (point)))
                                   3))
                  ))
           (bow                          ;Word-Prefix (BOW)
            (save-excursion (setq cend (progn (goto-char hend)
                                              (skip-syntax-forward cscan-bos-string) ;end of symbol
                                              (point)))
                            4))
           (eow                          ;Word-Suffix (EOW)
            (save-excursion (setq cbeg (progn (goto-char hbeg)
                                              (skip-syntax-backward cscan-bos-string) ;beginning of symbol
                                              (point)))
                            5))
           (t                            ;Inword (ANY)
            (save-excursion (setq cbeg (progn (goto-char hbeg)
                                              (skip-syntax-backward cscan-bos-string) ;beginning of symbol
                                              (point))
                                  cend (progn (goto-char hend)
                                              (skip-syntax-forward cscan-bos-string) ;end of symbol
                                              (point)))
                            6))
           )
     (cons cbeg cend))))

(defun cscan-cluster-key (key &optional regexp-flag)
  "Return clustered KEY."
  (concat "^[[:space:]]*" ;skip leading whitespace on line
          "\\("
          ".*?" ;NOTE: non-greedy because we want first line hit, instead of last

          "\\(" (if regexp-flag key (regexp-quote key)) "\\)"

          ".*?"         ;NOTE: non-greey because we don't want
                                        ;any trailing whitespace in match (this
                                        ;also prevents stack overflow in regexp
                                        ;match for some reason I don't yet
                                        ;understand)
          "\\)"
          "[[:space:]]*$" ;skip trailing whitespace on line
          ))

(defun cscan-goto-context-and-get-bound (ctx)
  (let ((bound))

   bound))

;;; Note: I got help from Google Groups here:
;;; See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/052fe53b0c1f7416?hl=sv#
(defun cscan-buffer (key &optional buffer ctx regexp-flag decoding count hit-format fcache)
  "Determine if the contents of BUFFER matches the string or
regexp PATT at position context CTX.

BUFFER defaults to `current-buffer'.

Context CTX can be either the start position as a number or a
symbol or list of these. If a symbol it can be either
`bol' (beginning of line), `eol' (end of line), `bow' (beginning of
word), `eow' (end of word), `beg' (begninning of file), `end' (end
of file), `full', `defun' for current function. or `nil' for anywhere.

If REGEXP-FLAG is non-nil the string KEY is interpreted as an
Emacs Regular Expression. Return file index (position) of
hit.

If COUNT is t then all hits will be scanned for. If COUNT is a
number find the COUNT:th hit, where 1 means first hit, etc. It
puts all the hits in standard form (BEG END) into Emacs standard
match data. See help on the function `match-data' for details.
If COUNT is equal to `clust' the scan hits are clustered. Each
hit is clustered (grouped) in an expression tree according to its

1. Syntactic Context using `syntax-ppss'. This increases the
   scan time about 5 times. FIXME: Optimize this!
2. Case-Form which can be either downcased, upcased, or other (mixcased).
3. In-Symbol Context, In-Word Context or other.

See `cscan-make-tree-cluster' for a description of the data
structure for clustered hits.

Related: `string-match'"
  (interactive "bBuffer to investigate: \nsKey (regexp or string): ")

  (with-current-buffer (or buffer (current-buffer))
    (let (bound)

      (cond ((null ctx)                ;null
             (goto-char (point-min)))
            ;; region context: (BEGIN . END)
            ((region-p ctx)
             (goto-char (car ctx))
             (setq bound (cdr ctx))
             (setq ctx nil)
             )
            ;; region context: ((BEGIN . END) SYMBOLS)
            ((and (listp ctx)
                  (region-p (car ctx)))
             (goto-char (caar ctx))
             (setq bound (cdar ctx))
             (setq ctx (cdr ctx))
             )
            ((or (and (symbolp ctx) (eq 'end ctx))
                 (and (listp ctx) (memq 'end ctx)))
             (goto-char (point-max)))  ;goto end
            (t
             (goto-char (point-min)))  ;default to beginning
            )

      ;; multi
      (let* (hits)
        (cond
         ((eq count t)                   ;standard multi-match
          (while (if regexp-flag
                     (re-search-forward key bound t)
                   (search-forward key bound t))
            (let ((mdat (butlast (match-data t)))
                  ;;(md2 (sublist (match-data t) 0 2))  ;FIXME: Why doesn't this work!
                  )
              (when (and mdat
                         (or (not ctx)
                             (match-at-context-p 0 ctx)))
                (let ((mdat (if (eq hit-format 'string) ;reformat match
                                (list (or (match-string 1) ;if regexp had a grouping use it
                                          (buffer-substring (first mdat)
                                                            (second mdat))))
                              mdat)))
                  (if hits
                      (nconc hits mdat)
                    (setq hits mdat)))))))

         ((memq count '(clust clust-tree)) ;if clustered multi-match
          ;; template
          (setq hits (cscan-make-cluster count))

          (when (or regexp-flag
                    (when (search-forward key nil t) ;Note: this is an optimization for
                                        ;the case when searching for `key' in
                                        ;very large files that doesn't contain
                                        ;`key', as `search-forward' is much
                                        ;faster than `re-search-forward'
                      (goto-char (match-beginning 0)) ;goto start of key occurrence so re-search-forward can find it.
                      (forward-line 0)  ;needed for re-search-forward to work
                      t))
            (while (re-search-forward (cscan-cluster-key key regexp-flag) nil t) ;while still hit
              (let* ((mdat (match-data t))

                     (hstr (match-string-no-properties 2)) ;hit string
                     (hbeg (match-beginning 2))            ;hit beginning
                     (hend (match-end 2))                  ;hit end
                     (pre-char (char-before hbeg))         ;char before hit
                     (post-char (char-after hend))         ;char after hit

                     (lstr (match-string-no-properties 1)) ;line string
                     (lbeg (match-beginning 1))            ;line beginning
                     (lend (match-end 1))                  ;line end
                     ;; (lbeg (save-excursion (goto-char hbeg) (beginning-of-line) (point))) ;context beginning
                     ;; (lend (save-excursion (goto-char hend) (end-of-line) (point))) ;context end
                     ;; (lstr (buffer-substring-no-properties lbeg lend)) ;context string
                     ;; (cbeg (save-excursion (goto-char hbeg) (cscan-beginning-of-hit-context) (point))) ;context beginning
                     ;; (cend (save-excursion (goto-char hend) (cscan-end-of-hit-context) (point))) ;context end
                     )
                (when (or (not ctx)                  ;either not context required
                          (match-at-context-p 1 ctx)) ;or if given it must match
                  (let* ((ppss
                          (when nil ;Note: Disabled for now because its performance sucks!
                            (let ((p (point)))
                              (prog1 (syntax-ppss hbeg) ;TODO: Reuse 'string in ctx using eq or memq. This is costly!
                                (goto-char p)))))

                         ;; See: http://www.gnu.org/software/emacs/manual/html_node/elisp/Syntax-Class-Table.html
                         ;; hit syntax index
                         (syntax-i (cond ((nth 3 ppss) 1)
                                         ((nth 4 ppss) 2)
                                         (t 0)))
                         ;; hit case index
                         (case-i (cond ((string-equal (downcase hstr) hstr) 0)
                                       ((string-equal (upcase hstr) hstr) 1)
                                       (t 2)))
                         ;; hit context predicates
                         (bow (not (and pre-char (eq (char-syntax pre-char) ?w)))) ;beginning of word
                         (eow (not (and post-char (eq (char-syntax post-char) ?w)))) ;end of word
                         (bos (and bow (not (and pre-char (eq (char-syntax pre-char) ?_))))) ;beginning of symbol
                         (eos (and eow (not (and post-char (eq (char-syntax post-char) ?_))))) ;end of symbol
                         (delim (cscan-hit-delim-index-and-region bos eos bow eow hbeg hend))
                         (delim-i (car delim))   ;delimitation index
                         (cbeg (car (cdr delim))) ;context beginning
                         (cend (cdr (cdr delim))) ;context end

                         (lex-i (thing-at-point-syntax-context 'c++-mode hbeg)) ;syntactic context index
                         )

                    ;; binary file case
                    (when (or (memq decoding '(bin unbox-bin))
                              (string-match "[\0\x7f\xff]" lstr))
                      ;; just store hit content string
                      (setq lstr (buffer-substring-no-properties cbeg cend)
                            lbeg cbeg
                            lend cend))

                    ;; append match hit to match-data list
                    (let ((c-hit (cscan-make-hit
                                  lbeg lend ;line beginning and end
                                  lstr      ;line string
                                  hbeg hend ;hit beginning end
                                  cbeg cend ;context beginning end
                                  fcache
                                  )))
                      (if (eq count 'clust-tree)
                          (let* ((syntax-c (nth syntax-i (aref hits 2))) ;hit syntax-cluster
                                 (case-c (nth case-i (aref syntax-c 2))) ;hit case-cluster
                                 (delim-c (nth delim-i (aref case-c 2))) ;hit delimitation-cluster
                                 (c-hits (aref delim-c 2))
                                 )
                            (if c-hits
                                (nconc c-hits (list c-hit)) ;append hit
                              (aset delim-c 2 (list 'hits c-hit))) ;new hit list with first element the symbol `hits'
                            ;; increase cluster counts
                            (incf (aref syntax-c 1))
                            (incf (aref case-c 1))
                            (incf (aref delim-c 1))
                            )
                        (let* ((clust-code (logior (lsh (1+ syntax-i) cscan-syntax-shift)
                                                   (lsh (1+ case-i) cscan-case-shift)
                                                   (lsh (1+ delim-i) cscan-delim-shift)
                                                   (if lex-i (cscan-lex-from-thing-at-point-syntax-context lex-i) 0)
                                                   )))
                          (aset hits 2 (cscan-add-flat-cluster (aref hits 2) clust-code c-hit))
                          ))
                      (incf (aref hits 1))
                      )))))))

         (t                     ;otherwise only count:nth match or nil:th (first)
          (when (if regexp-flag
                    (re-search-forward key nil t count)
                  (search-forward key nil t count))
            (let ((mdat (butlast (match-data t)))
                  ;;(md2 (sublist (match-data t) 0 2))  ;FIXME: Why doesn't this work!
                  )
              (when (and mdat
                         (or (not ctx)
                             (match-at-context-p 0 ctx)))
                (if hits (nconc hits mdat) (setq hits mdat)))))) ;append hit
         )

        (cond ((eq count 'clust-tree)
               (when (> (aref hits 1) 0)
                 (cscan-gc-and-sort-tree-clustered-hits hits)))
              ((eq count 'clust)
               (when (> (aref hits 1) 0)
                 (cscan-sort-flat-clustered-hits hits)))
              (t
               (unless hit-format
                 (set-match-data hits)) ;here we can se match data
               hits))))))
(defalias 'buffer-cscan 'cscan-buffer)

(when nil
  (cscan-file "~/cognia/GNUmakefile"
              (concat "^\\("
                      "[^[:space:]\n]*"
                      "\\):")
              nil t t nil t nil 'string)
  )

;; ---------------------------------------------------------------------------

(defun cscan-string (string key &optional ctx regexp-flag decoding count hit-format)
  "Same as `cscan-buffer' with the string STRING as input instead."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (cscan-buffer key nil ctx regexp-flag decoding count hit-format)
    ))
;; Use: (benchmark-run 10 (cscan-string "scan" "scan" nil nil nil 'clust))
;; Use: (benchmark-run 10 (cscan-string "scan" "scan" nil nil nil 'clust-tree))
;; Use: (benchmark-run 10 (cscan-string (buffer-string) "cscan" nil nil nil 'clust))
;; Use: (benchmark-run 10 (cscan-string (buffer-string) "cscan" nil nil nil 'clust-tree))
(defalias 'string-cscan 'cscan-string)

;; ---------------------------------------------------------------------------

;; TODO: Use `buffer-file-type' to detect file contents type.
(defun insert-file-contents-for-cscan (filename &optional visit beg end replace)
  "Like `insert-file-contents', but disables hooks not needed for cscan operations."
  (let ((format-alist nil)
        (after-insert-file-functions nil)
        ;;(coding-system-for-read 'no-conversion)
        ;;(coding-system-for-write 'no-conversion)
        (find-buffer-file-type-function
         (if (fboundp 'find-buffer-file-type)
             (symbol-function 'find-buffer-file-type)
           nil))
        (inhibit-file-name-handlers
         (append '( ;;jka-compr-handler
                   image-file-handler
                   ;;epa-file-handler
                   )
                 inhibit-file-name-handlers))
        (inhibit-file-name-operation 'insert-file-contents))
    (unwind-protect
        (progn
          (fset 'find-buffer-file-type (lambda (filename) t))
          (insert-file-contents filename visit beg end replace))
      (if find-buffer-file-type-function
          (fset 'find-buffer-file-type find-buffer-file-type-function)
        (fmakunbound 'find-buffer-file-type)))))

;; ---------------------------------------------------------------------------

;; Buffer Cache
;; TODO: Benchmark performance improvement on remote files (TRAMP).
(defvar cscan-txt-cache nil "List of format ([FILENAME MTIME FSIZE BEG END] BUFFER).")
(defvar cscan-bin-cache nil "List of format ([FILENAME MTIME FSIZE BEG END] BUFFER).")
(defvar cscan-unbox-txt-cache nil "List of format ([FILENAME MTIME FSIZE BEG END] BUFFER).")
(defvar cscan-unbox-bin-cache nil "List of format ([FILENAME MTIME FSIZE BEG END] BUFFER).")
(defun cscan-reset-cache ()
  "Reset file cache used by `cscan-file-cached'.
Uses the convention of invisible buffers
See: http://www.emacswiki.org/emacs/InvisibleBuffers."
  (setq cscan-txt-cache (cons nil nil))
  (setq cscan-bin-cache (cons nil nil))
  (setq cscan-unbox-txt-cache (cons nil nil))
  (setq cscan-unbox-bin-cache (cons nil nil)))
(cscan-reset-cache)

(defun cscan-get-cache (filename &optional decoding)
  "Return cscan cache for FILENAME decoded with DECODING."
  (let ((cache (cond ((eq decoding 'unbox-bin) cscan-unbox-bin-cache)
                     ((eq decoding 'unbox-txt) cscan-unbox-txt-cache)
                     ((eq decoding 'bin) cscan-bin-cache)
                     ((eq decoding 'txt) cscan-txt-cache)
                     (t
                      ;;(message "Decoding %s as raw when searching for %s" (faze filename 'file) key)
                      (setq decoding 'bin)    ;defaulting `decoding' to `bin'
                      cscan-bin-cache))))
    (unless (and (cdr cache)        ;either no cache
                 (buffer-live-p (cdr cache))) ;or cache buffer deleted
      (let ((buffer (get-buffer-create (concat " *cscan-" (symbol-name decoding) "*"))))
        (buffer-disable-undo buffer)
        (setcdr cache buffer)))
    cache))

;; (message "Buffer cscan-txt-cache: %s" cscan-txt-cache)
;; (message "Buffer cscan-bin-cache: %s" cscan-bin-cache)
;; (message "Buffer cscan-unbox-txt-cache: %s" cscan-unbox-txt-cache)
;; (message "Buffer cscan-unbox-bin-cache: %s" cscan-unbox-bin-cache)

;; Use: `get-file-buffer', `find-buffer-visiting', `find-file-noselect'

(defconst cscan-use-grep nil
  "Non-nil if grep should help cscan-file to do initial checking
  of first hit.")

(defun cscan-insert-file-contents (filename beg end decoding)
  (cond ((eq decoding 'unbox-bin)
         (let ((format-alist nil)
               (after-insert-file-functions nil)
               (coding-system-for-read 'no-conversion)
               (coding-system-for-write 'no-conversion)
               (inhibit-file-name-handlers
                (append '(image-file-handler epa-file-handler) ;still use jka-compr
                        inhibit-file-name-handlers))
               (inhibit-file-name-operation
                'insert-file-contents))
           (insert-file-contents (expand-file-name filename) nil beg end)))
        ((eq decoding 'unbox-txt)
         (let ((after-insert-file-functions nil)
               (inhibit-file-name-handlers
                (append '(image-file-handler epa-file-handler) ;still use jka-compr
                        inhibit-file-name-handlers))
               (inhibit-file-name-operation
                'insert-file-contents))
           (insert-file-contents (expand-file-name filename) nil beg end)))
        ((eq decoding 'bin)
         (insert-file-contents-literally (expand-file-name filename) nil beg end))
        ((eq decoding 'txt)
         (let ((after-insert-file-functions nil)
               (inhibit-file-name-handlers
                (append '(jka-compr-handler image-file-handler epa-file-handler) ;don't use jka-compr
                        inhibit-file-name-handlers))
               (inhibit-file-name-operation
                'insert-file-contents))
           (insert-file-contents (expand-file-name filename) nil beg end)))
        (t
         (insert-file-contents-literally (expand-file-name filename) nil beg end))
        ))

(when nil
  (unless (eq decoding 'box) ;if we are not matching file a boxed (compressed) type
    (file-box-p filename))) ;then check if file is compressed. Note: Recursive call!

(defun cscan-file-uncached (filename key &optional ctx regexp-flag decoding count limit hit-format fcache)
  "Same as `cscan-buffer' but for a file named
FILENAME."
  (interactive "fFile to investigate: \nsKey (regexp or string): ")
  (let* ((bcache (cscan-get-cache filename decoding)) beg end (ctx-match t))
    ;; Conditions in descending likelyness order.
    (cond
     ;; first anywhere
     ((not ctx)                         ;default to relaxed anywhere in file
      (setq beg 0
            end limit))
     ;; all matches everywhere
     ((or (eq count t)
          ;; (and (eq count t)               ;find all matches
          ;;      (number-or-marker-p count) ;if count is given and
          ;;      (>= count 1))              ;larger than 1
          (and (symbolp ctx)
               (memq ctx '(bol eol code symbol keyword string comment)))
          (and (listp ctx)
               (or (memq 'bol ctx)
                   (memq 'eol ctx)
                   (memq 'code ctx)
                   (memq 'symbol ctx)
                   (memq 'keyword ctx)
                   (memq 'string ctx)
                   (memq 'comment ctx)
                   ))
          (eq ctx t)                    ;key must equal whole file contents
          (not ctx)                     ;key could match anywhere
          )
      (setq beg 0
            end limit))
     ;; only at beginning `beg'. TODO: regexp case
     ((or (and (symbolp ctx) (eq 'beg ctx))
          (and (listp ctx) (memq 'beg ctx)))
      (setq beg 0
            end (length key))           ;insert key-beginning
      )
     ;; only at end `end'. TODO: regexp case
     ((or (and (symbolp ctx) (eq 'end ctx))
          (and (listp ctx) (memq 'end ctx)))
      (let ((fsize (fcache-or-file-fsize fcache filename))
            (keylen (length key)))
        (if (and (not regexp-flag)
                 (memq decoding '(bin txt)) ;if no compression
                 (< fsize keylen)     ;then key length must be >= than file size
                 )
            (setq ctx-match nil)
          (setq beg (max 0 (- fsize keylen))
                end fsize               ;insert key-end
                ctx 'beg))              ;start from beginning of file-region
        ))
     ;; only at number offset `ctx'. TODO: regexp case
     ((numberp ctx)    ;context is a number => search forward from that position
      (let ((fsize (fcache-or-file-fsize fcache filename))
            (keylen (length key)))
        (let ((off (if (>= ctx 0) ctx                 ;offset is simply context
                     (- fsize (min (- ctx) fsize))))) ;calculate offset from beginning
          (if (and (not regexp-flag)
                   (memq decoding '(bin txt)) ;if no compression
                   (< fsize keylen)   ;then key length must be >= than file size
                   )
              (setq ctx-match nil)
            (setq beg off end (when limit (min (+ off limit) fsize)))) ;until limit or end
          ))
      (setq ctx 'beg)             ;start from beginning of extracted file-region
      )
     ;; only whole/full/complete file
     ((eq 'full ctx)                    ;key must equal whole file contents
      (if regexp-flag
          (setq beg 0 end limit) ;TODO: Insert string prefix of regexp and search for that at beginning
        (let ((fsize (fcache-or-file-fsize fcache filename)))
          (when (= fsize (length key))
            (setq beg 0 end (length key)))))) ;Note: We let key override limit here!
     ;; default
     (t
      (setq beg 0 end limit)))

    (when (and ctx-match
               (or (not cscan-use-grep) ;flags for use of grep
                   regexp-flag          ;force `cscan-buffer' for regexps
                   (not (eq (car-safe (detect-coding-string key)) 'undecided)) ;key 7-bit clean
                   (not (file-remote-p filename)) ;file is remote
                   (= (shell-command (concat "grep -q " key " " filename)) 0))) ;and grep returns 0 meaning a hit
      (if (and nil ;TODO: Disabled for now because this is too slow. Can we make this faster?
               (eq count 'clust))
          ;; clustering needs mode-specific (syntax-table) information so
          (save-excursion
            (cscan-buffer key (find-file-noselect filename) ctx regexp-flag decoding count hit-format fcache))
        ;; no clustering means we can search faster by not having to
        ;; open files into Emacs
        (let ((insert-ok t))
          (unless (and bcache           ;if buffer cache defined
                       (equal (car bcache) `[,filename ,(fcache-or-file-timestamp fcache filename) ,beg ,end])) ;if no or obselete buffer cache
            (with-current-buffer (cdr bcache)
              (erase-buffer)
              (unless (setq insert-ok
                            (ignore-errors (cscan-insert-file-contents filename beg end decoding)))
                (kill-buffer))
              ;; (condition-case nil
              ;;     (cscan-insert-file-contents filename beg end decoding)
              ;;   (error
              ;;    (progn
              ;;      (message "cscan-file: cscan-insert-file-contents of %s failed!" filename)
              ;;      (setq insert-ok nil) ;detect jka-insert-file-contents beg end out-of-range error
              ;;      ))
              ;;   )
              )
            )
          (when insert-ok
            (if (and fcache (fcache-timestamp fcache)) ;if time-size-stamp given
                (setcar bcache `[,filename ,(fcache-or-file-timestamp fcache filename) ,beg ,end]) ;buffer cache for upcoming matches of the same buffer
              (setcar bcache nil))
            (cscan-buffer key (cdr bcache) ctx regexp-flag decoding count hit-format fcache) ;do scan
            ))))
    ))
;; Use: (cscan-file-uncached "~/tmp/dummy" "tbb" nil nil nil 'clust nil t)
;; Use: (cscan-file-cached (elsub "mine/tscan-tests/minimal.bin") "dog" nil nil nil 'bin 'clust nil t)
;; Use: (fcache-of (elsub "mine/tscan-tests/minimal.bin"))

;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/regexp.txt") "Ob" nil t 'txt 'clust)
;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/regexp.txt") "File" nil t 'txt 'clust)
;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/regexp.txt") "Dir" nil t 'txt 'clust)
;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/regexp.txt") "File\\|Dir" nil t 'txt 'clust)
;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/regexp.txt") "\\(File\\)\\|\\(Dir\\)" nil t 'txt 'clust)

;; Use: (benchmark-run 1 (cscan-file-uncached "~/cognia/semnet/ob.hpp" "pob" nil nil   'txt t nil nil nil))
;; Use: (benchmark-run 1 (cscan-file          "~/cognia/semnet/ob.hpp" "pob" nil nil t 'txt t nil t))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" 0 nil 'bin))
;; Use: (cscan-file-uncached "/etc/passwd" "x" nil nil 'txt t)
;; Use: (cscan-file-uncached "/etc/passwd" "a" nil nil 'txt 'clust)
;; Use: (benchmark-run (cscan-file-uncached "/lib/libc.so.6" "config" nil t 'bin))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" 0 nil))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "ELF" 1 nil))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" 'beg nil))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" 'beg t))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" nil t))
;; Use: (benchmark-run 1 (cscan-file-uncached "/bin/ls" "\177ELF" nil t))
;; Use: (cscan-file-uncached "/bin/ls" "[Desktop Entry]" '(beg eol) nil 'txt) => nil
;; Use: (cscan-file-uncached "/usr/share/applications/nautilus.desktop" "[Desktop Entry]" '(beg eol) nil 'txt) => t
;; Use: (cscan-file-uncached "/usr/share/applications/nautilus.desktop" "[Desktop Entry]" '(beg end) nil 'txt) => nil
;; Use: (cscan-file-uncached "/bin/zcat" "#!.*/bin/bash" 'beg t 'txt 32)

;; TODO: Make this work!
;; Use: (cscan-file-uncached (elsub "mine/tscan-tests/COPYING.gz.link") "file" nil nil 'txt 'clust)
;; Use: (cscan-file-cached (elsub "mine/tscan-tests/COPYING.gz.link") "file" nil nil nil 'txt 'clust)

;; Use: (benchmark-run 1 (cscan-file-uncached (elsub "mine/tscan-tests/COPYING.gz") "file" nil nil 'unbox-txt 'clust))
;; Use: (benchmark-run 1 (cscan-file-cached (elsub "mine/tscan-tests/COPYING.gz") "file" nil nil nil 'unbox-txt 'clust))

(defun benchmark-cscan-file-uncached (filename key)
  (cscan-reset-cache)
  `(
    "first-bin"     ,(benchmark-run 1 (cscan-file-uncached filename key nil nil 'bin 1))
    "first-txt"     ,(benchmark-run 1 (cscan-file-uncached filename key nil nil 'txt 1))

    "all-bin"       ,(benchmark-run 1 (cscan-file-uncached filename key nil nil 'bin t))
    "all-txt"       ,(benchmark-run 1 (cscan-file-uncached filename key nil nil 'txt t))

    "clust-bin"     ,(benchmark-run 1 (cscan-file-uncached filename key nil nil 'bin 'clust))))
;; Use: (benchmark-cscan-file-uncached "/usr/bin/gcc" "gcc")
;; Use: (benchmark-cscan-file-uncached "/usr/bin/gcc" "g")

;;; TODO: make hit a cons
(defun cscan-fcache (filename fcache key &optional ctx regexp-flag case-fold decoding count limit hit-format cache-empty)
  "Same as `cscan-file-uncached' but uses the package
`fcache' to cache match result (hits). If CACHE-EMPTY is non-nil
we log empty hits aswell."
  (let* ((scans (fcache-get-scans fcache))
         hit)                               ;not hit yet
    (when (and (symbolp ctx) (eq 'beg ctx)) ;`ctx' is 'beg
      (setq ctx 0))                         ;standardize `ctx' to zero offset
    (let ((akey `[,key ,ctx ,regexp-flag ,case-fold ,decoding ,count ,limit ,hit-format])) ;association key
      (if scans
          ;; scans already exist
          (let* ((chits (assoc akey scans))) ;previous hit
            (if chits
                (setq hit (cdr chits))           ;Note: reuse cached hit!
              (let ((case-fold-search case-fold)) ;temporarily set case sensitivity
                (setq hit (and (fcache-readable fcache)
                               (cscan-file-uncached filename key ctx regexp-flag decoding count limit hit-format
                                                    fcache))) ;new match
                )
              (when (or hit cache-empty) ;if we either have a hit or want to log empty hits aswell
                ;; TODO: (if scans (nconc scans hit) setq...)
                (fcache-set-scans fcache (cons `(,akey . ,hit) ;prepend new hit result
                                               scans))) ;to list of previous hits
              ))
        ;; fcache is either missing or deprecated by file change
        (let ((case-fold-search case-fold)) ;temporarily set case sensitivity
          (setq hit (and (fcache-readable fcache)
                         (cscan-file-uncached filename key ctx regexp-flag decoding count limit hit-format fcache))) ;new match
          )
        (when (or hit cache-empty) ;if we either have a hit or want to log empty hits aswell
          (fcache-set-scans fcache `((,akey . ,hit))) ;set new scans
          )))
    hit))                               ;return the hit

(defun cscan-file-cached (filename key &optional ctx regexp-flag case-fold decoding count limit hit-format cache-empty)
  (cscan-fcache filename (fcache-chase-links (fcache-of filename)) key ctx regexp-flag case-fold decoding count limit hit-format cache-empty))
(defalias 'cscan-file 'cscan-file-cached)

(defun cscan-file-maybe (filename key &optional ctx regexp-flag case-fold decoding count limit hit-format cache-empty)
  (when (file-regular-p filename)
    (cscan-file-cached filename key ctx regexp-flag case-fold decoding count limit hit-format cache-empty)))

;; (let ((fn "~/tmp/ls"))
;;   (file-elf-p fn)
;;   (cscan-file fn "x")
;;   (fcache-of fn)
;;   )

;; ---------------------------------------------------------------------------
;; Profiliing

(defun elp-benchmark-cscan-file-cached (filename key)
  "Benchmark a sample cscan of FILENAME."
  (interactive "fFile: \nsKey: ")
  (elp-instrument-package "match-at-")
  (elp-instrument-package "cscan-")
  (elp-instrument-package "fmd-")
  (elp-instrument-package "file-")
  (elp-instrument-package "plist-")
  (elp-instrument-package "expand-file-name")
  (elp-reset-all)
  (cscan-file-cached filename key nil nil nil 'bin t)
  (elp-results))
;; Use: (elp-benchmark-cscan-file-cached "/usr/bin/gcc" "gcc")

(defun elp-benchmark-cscan-file-uncached (filename key)
  "Benchmark a sample cscan of FILENAME."
  (interactive "fFile: \nsKey: ")
  (elp-instrument-package "match-at-")
  (elp-instrument-package "cscan-")
  (elp-instrument-package "fmd-")
  (elp-instrument-package "file-")
  (elp-instrument-package "plist-")
  (elp-instrument-package "expand-file-name")
  (elp-reset-all)
  (cscan-file-uncached filename key nil nil 'bin t)
  (elp-results))
;; Use: (elp-benchmark-cscan-file-uncached "/usr/bin/gcc" "gcc")

;; ---------------------------------------------------------------------------

;; Detect using FILENAME contents instead of FILENAME.
(when nil
  (defun jka-compr-get-compression-info (filename)
    "Return information about the compression scheme of FILENAME.
The determination as to which compression scheme, if any, to use is
based on the filename itself and `jka-compr-compression-info-list'."
    (catch 'info
      (let ((case-fold-search nil))
	(mapc
	 (function (lambda (x)
		     (and (cscan-file-cached filename
                                             (jka-compr-info-file-magic-bytes x)
                                             0 nil nil 'bin 1 16)
			  (throw 'info x))))
	 jka-compr-compression-info-list))
      nil))
  ;; Use: (jka-compr-get-compression-info "~/contents.bz2")
  ;; Use: (jka-compr-get-compression-info "~/contents")
  )

;; ---------------------------------------------------------------------------

(provide 'cscan)
