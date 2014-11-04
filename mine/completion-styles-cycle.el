;;; completion-styles-cycle.el --- Cycle Completion Styles.
;; coding: mule-utf-8-unix
;; Author: Per Nordlöw

;; ---------------------------------------------------------------------------

(defun completion-subwords-try-completion (string table pred point &optional metadata)
  "See `completion-try-completion'."
  (cons (car (completion-subwords-all-completions string table pred point metadata)) 0))

(defun completion-subwords-all-completions (string table pred point &optional metadata)
  "See `completion-all-completions'."
  (let ((parts (sort (split-string string "[-_ \f	\n]+" t)
                     (lambda (s1 s2)
                       (> (length s1)
                          (length s2)))))) ;sort them length starting with largest
    (dolist (part parts)
      ;; chip of misses from `table'
      (setq table (completion-substring-all-completions part table pred 0)) ;TODO What should point be here?
      ;; use `safe-length' here?
      )
    table))
(when nil
  (completion-subwords-all-completions "find-x" '("x-find") nil 0)
  (completion-subwords-all-completions "find-x" '("x-a-find" "x-b-find") nil 0)
)

;; Test: Try with C-h f "url-ffap"
(when nil
  (add-to-list 'completion-styles-alist
               '(subwords
                 completion-subwords-try-completion
                 completion-subwords-all-completions
                 "Word-Reordering Completion
E.g. can complete M-x file-find to find-file"))
  (setq completion-styles (delete 'subwords completion-styles))
  (add-to-list 'completion-styles 'subwords t))

;; ---------------------------------------------------------------------------

;; Reuse `substring' completion as is together with
;; 1. forcing it to complete to the first candidate directly by setting `completion-cycle-threshold' to t
;; 2. define a `cycle-sort-function' that puts the most relevant candidates first.
;; So for input "X" and TAB-press we get
;; something like:
;; See: https://groups.google.com/forum/?hl=sv&pli=1#!topic/gnu.emacs.help/LFYZDE3A7dU
;; Do we need `minibuffer-force-complete'?

(defun completion-sansdir-cycle-sort-function (table)
  table)

(defun completion-sansdir-try-completion (string table pred point &optional metadata)
  "See `completion-try-completion'."
  (cons (car (completion-sansdir-all-completions string table pred point metadata)) 0))

(defun completion-sansdir-all-completions (string table pred point &optional metadata)
  "See `completion-all-completions'."
  (let ((completion-cycle-threshold t)
        (cycle-sort-function 'completion-sansdir-cycle-sort-function))
    (completion-substring-all-completions string table pred point)
    ))
(eval-when-compile
  (let ((table '("/files/foo.txt" "/bin/file")))
    (completion-sansdir-all-completions "file" table nil 0))
    ;; (assert-equal "/bin/file" (completion-sansdir-all-completions "file" table nil 0))
  )

;; Test: Try with C-h f "url-ffap"
(when nil
  (add-to-list 'completion-styles-alist
               '(sansdir
                 completion-sansdir-try-completion
                 completion-sansdir-all-completions
                 "Path-Sans-Directory Completion
E.g. can complete M-! X to /usr/bin/X"))
  (setq completion-styles (delete 'sansdir completion-styles))
  (add-to-list 'completion-styles 'sansdir t))

;; ---------------------------------------------------------------------------

(defcustom completion-styles-cycle-alist `(("Combined" ,completion-styles) ;Default
                                           ("Substring" (substring))
                                           ("Initials" (initials))
                                           ("Partial" (partial-completion))
                                           ("Basic" (basic))
                                           ;; ("Subwords" (subwords))
                                           ("Path-Sans-Directory" (sansdir))
                                           )
  "Cycled Completion Styles."
  :type 'alist
  :group 'completion)

(defvar completion-styles-cycle-pos 0
  "Current Completion Style Cycle Position.
See `completion-styles-cycle-alist'.")

(defun minibuffer-complete-cycled ()
  "Complete using cycled style."
  (interactive)
  (let ((completion-styles (cadr (nth completion-styles-cycle-pos
                                      completion-styles-cycle-alist))))
    (minibuffer-complete)))

(defun minibuffer-cycle-completion-style ()
  "Cycle completion style of minibuffer completion.
See `completion-styles' and `completion-styles-alist' for more
details."
  (interactive)
  (setq completion-styles-cycle-pos
        (1+ completion-styles-cycle-pos))
  (when (= completion-styles-cycle-pos
           (length completion-styles-cycle-alist))
    (setq completion-styles-cycle-pos 0))
  (let ((style (car (nth completion-styles-cycle-pos
                         completion-styles-cycle-alist))))
    (message "%s Completion" style))
  ;; @todo: Make hint into a minibuffer suffix instead: [style]
  )
;; Use: (minibuffer-cycle-completion-style)

(let ((map minibuffer-local-completion-map))
  (define-key map [tab] 'minibuffer-complete-cycled)
  (define-key map [backtab] 'minibuffer-cycle-completion-style)
  )

(defun minibuffer-completion-style-cycle-setup ()
  (setq completion-styles-cycle-pos 0) ;pick first which is default
  )

(add-hook 'minibuffer-setup-hook 'minibuffer-completion-style-cycle-setup t)
;; (add-hook 'minibuffer-exit-hook 'minibuffer-completion-style-restore t)

(provide 'completion-styles-cycle)
