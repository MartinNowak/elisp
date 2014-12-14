;;; structed.el --- Structured Navigation and Operation of C-style languages where sub-structures are separated with colons or semicolons.
;; Similar to paredit.el.
;; Idea: Any edit operation should leave code in a syntactially correct (parseable) state.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

;; TODO
;; `c-arg-position-and-count' when not at end of arglist
;;
;; - Predicate Functions

;; - (y-or-n-p "Error occurred, abort all changes made by last macro call?")

;; - `read-number-with-limits' or reuse `read-decimal-digit' (look on wiki) (use `read-number' and inspire by `read-char-spec')
;; - Ask Drew if `semantic-ctxt' already provides argument navigation and operation behavior.
;; - Make use of `c-backward-syntactic-ws' to support skipping over comments inside argument list
;; - Use (setq this-command 'xxx) when needed.
;; - Respect cc-mode-local settings for intra-token whitespace in arg-modifying functions (see in-namespace.
;; - Look at `c-eldoc'.
;; - Add &optional limit
;; - c-mark-arglist
;; - c-kill-arglist (either in function dec, decl or cal) into a list
;; - c-copy-arglist into a list

(require 'cc-engine)
(require 'lex-utils)
(require 'rx)

;; Is any of these variables already defined in cc?
(defvar c-function-paren-arg-spacing 0
  "Number of spaces between parens and its arguments.")
(defvar c-function-brace-arg-spacing 1
  "Number of spaces between braces and its arguments.")
(defvar c-function-comma-arg-spacing 1
  "Number of spaces between a comma and argument.")
(defvar c-standardize-token-ws-flag t
  "If non-nil standardize whitespace between language tokens.")

(defsubst skip-ws-forward ()
  "Skip whitespace forward."
  (skip-chars-forward " \t\n"))

(defsubst skip-ws-backward ()
  "Skip whitespace forward."
  (skip-chars-backward " \t\n"))

(defun c-beginning-of-arg-p ()
  "Return non-nil if point is at the beginning of an argument."
  (looking-back (rx (in ?\{ ?\( ?\[ ?\,) (* (regexp "[[:space:]\n]")))))
(defun c-end-of-arg-p ()
  "Return non-nil if point is at the end of an argument."
  (looking-at (rx (* (regexp "[[:space:]\n]")) (in ?\} ?\) ?\] ?\,))))

(defun c-beginning-of-arglist-p ()
  "Return non-nil if point is at the beginning of an argument list."
  (looking-back (rx (in ?\{ ?\( ?\[) (* (regexp "[[:space:]\n]")))))
(defun c-end-of-arglist-p ()
  "Return non-nil if point is at the end of an argument list."
  (looking-at (rx (* (regexp "[[:space:]\n]")) (in ?\} ?\) ?\]))))

(defun c-beginning-of-stmt-p ()
  "Return non-nil if point is at the beginning of a statement."
  (looking-back (rx (in ?\{ ?\( ?\[ ?\, ?\;) (* (regexp "[[:space:]\n]")))))
(defun c-end-of-stmt-p ()
  "Return non-nil if point is at the end of a statement."
  (looking-at (rx (* (regexp "[[:space:]\n]")) (in ?\} ?\) ?\] ?\, ?\;))))

(defun c-beginning-of-arg ()
  "Move point to beginning of current argument.
Return non-nil if point changed."
  (interactive)
  (let ((ch nil))
    (while (not (c-beginning-of-arg-p))
      (if (cc-derived-mode-p)
          (c-backward-token-2 nil t)
        (backward-sexp-safe))
      (setq ch t))
    (skip-ws-forward)
    ch))

(defun c-end-of-arg ()
  "Move point to end of current argument.
Return non-nil if point changed."
  (interactive)
  (let ((ch nil))
    (while (not (c-end-of-arg-p))
      (if (cc-derived-mode-p)
          (c-forward-token-2 nil t)
        (forward-sexp-safe))
      (setq ch t))
    (skip-ws-backward)
    ch))

(defun c-forward-arg (&optional n skip-sub-flag)
  "Move N arguments forward (backward if N is negative).
Return non-nil if point changed."
  (interactive "P")
  (unless n (setq n 1))                 ;default n to 1
  (if (> n 0)
      (progn (unless skip-sub-flag
               ;; initial move to end of current argument
               (when (and (not (zerop n))
                          (c-end-of-arg))
                 (setq n (1- n))))           ;counts a one move aswell
             ;; move to next argument
             (while (and (not (zerop n))
                         (save-excursion
                           (c-end-of-arg)
                           (looking-at (rx (* (in space ?\n)) ;WS
                                           (in ",;") ;comma
                                           (* (in space ?\n)))))) ;WS
               (goto-char (match-end 0))
               (c-end-of-arg)
               (setq n (1- n))                ;decrease n
               )
             (if (= n 0) t ;if we have achieved what we wanted so signal that with `t'
               (message "At last argument")
               (ding)))
    (progn (unless skip-sub-flag
             ;; initial move to beginning of current argument
             (when (and (not (zerop n))
                        (c-beginning-of-arg))
               (setq n (1+ n))))             ;counts a one move aswell
           ;; move to previous argument
           (while (and (not (zerop n))
                       (save-excursion
                         (c-beginning-of-arg)
                         (looking-back (rx (* (in space ?\n)) ;WS
                                           (in ",;") ;comma
                                           (* (in space ?\n)))))) ;WS
             (goto-char (match-beginning 0))
             (c-beginning-of-arg)            ;go to beginning of argument
             (setq n (1+ n))                ;increase n
             )
           (if (= n 0) t ;if we have achieved what we wanted so signal that with `t'
             (message "At first argument")
             (ding)))))

(defun c-backward-arg (&optional n)
  (interactive "P")
  (unless n (setq n 1))
  (c-forward-arg (- n)))

(defun c-previous-arg (&optional n)
  "Move cursor to beginning of N:th previous argument.
Return non-nil if point changed."
  (interactive "P")
  (unless n (setq n 1))
  (c-forward-arg (- n) t))

(defun c-next-arg (&optional n)
  "Move cursor to beginning of N:th next argument.
Return non-nil if point changed."
  (interactive "P")
  (c-forward-arg n t))

(defun c-first-arg ()
  "Move cursor to beginning of first argument.
Return number of arguments moved, or nil if already at beginning
of argument list."
  (interactive)
  (let ((count 0))
    (c-end-of-arg)
    (while (not (c-beginning-of-arglist-p))
      (c-backward-arg)
      (setq count (1+ count)))
    (unless (zerop count) count)))

(defun c-last-arg ()
  "Move cursor to beginning of last argument.
Return number of arguments moved, or nil if already at last
argument."
  (interactive)
  (let ((count 0))
    (c-beginning-of-arg)
    (while (not (c-end-of-arglist-p))
      (c-forward-arg)
      (setq count (1+ count)))
    (unless (zerop count) count)))

(defun c-beginning-of-arglist ()
  "Move backward to beginning of argument list.
Return number of arguments moved, or nil if already at beginning
of argument list."
  (interactive)
  (c-first-arg))

(defun c-end-of-arglist ()
  "Move forward to end of argument list.
Return number of arguments moved, or nil if already at end of
argument list."
  (interactive)
  (let ((steps (c-last-arg)))
    (when (numberp steps)
      (+ steps
         (if (c-end-of-arg) 1 0)))))

(defun c-arg-count ()
  "Return number of arguments in argument list."
  (interactive)
  (let ((count (or (save-excursion (c-beginning-of-arglist)
                                   (c-end-of-arglist))
                   0)))
    (when (called-interactively-p 'any)
      (message "List has %s elements" count)) ;TODO Refine "List" to Function.
    count))

(defun c-arg-position ()
  "Return current position in argument list."
  (interactive)
  (let ((idx (or (save-excursion (c-beginning-of-arglist)) 0)))
    (when (called-interactively-p 'any)
      (message "Argument position is %s" idx))
    idx))

(defun c-arg-position-and-count ()
  "Return current position and count in argument list as a cons cell."
  (interactive)
  (let ((val (save-excursion (cons
                              (or (c-beginning-of-arglist) 0)
                              (or (c-end-of-arglist) 0)))))
    (when (called-interactively-p 'any)
      (message "Argument %s of %s" (car val) (cdr val)))
    val))

(defun c-arg-newline ()
  "Add newline around DWIM near command or semicolon."
  (interactive)
  (skip-chars-forward ",;")
  (unless (looking-back "[,;][[:space:]]*")
    (insert ","))
  (newline-and-indent))

(defun c-split-args ()
  (interactive)
  (while (c-arg-newline)))

(defun c-mark-arg (&optional arg allow-extend)
  "Set mark ARG arguments from point.
The place mark goes is the same place \\[c-forward-arg] would
move to with the same argument.
Interactively, if this command is repeated
or (in Transient Mark mode) if the mark is active,
it marks the next ARG sexps after the ones already marked.
This command assumes point is not in a string or comment.

Same as `mark-sexp' but with `forward-sexp-safe' replaced with
`c-forward-arg'."
  (interactive "P\np")
  (cond ((and allow-extend
              (or (and (eq last-command this-command) (mark t))
                  (and transient-mark-mode mark-active)))
         (setq arg (if arg (prefix-numeric-value arg)
                     (if (< (mark) (point)) -1 1)))
         (set-mark
          (save-excursion
            (goto-char (mark))
            (c-forward-arg arg)
            (point))))
        (t
         (push-mark
          (save-excursion
            (c-forward-arg (prefix-numeric-value arg))
            (point))
          nil t))))
(defun c-mark-arg-whole (&optional arg allow-extend)
  "Mark the argument following point."
  (interactive)
  (c-beginning-of-arg)
  (c-mark-arg arg allow-extend))

(defun c-yank-arg ()
  "Reinsert (\"paste\") the last stretch of killed text as an argument at point."
  (interactive)
  (cond ((not (save-excursion (c-beginning-of-arg))) ;if already at beginning of arg
         ;; prepend
         (let ((pre (looking-back (rx (in "({")
                                      (* (in space ?\n)))))) ;if arguments before point
           (when pre
             (when c-standardize-token-ws-flag
               (fixup-whitespace))
             (insert (make-string c-function-paren-arg-spacing ?\ )))
           (yank)
           (unless (looking-at (rx (* (in space ?\n))
                                   (in ")}"))) ;if not at end of list
             (insert "," (make-string c-function-comma-arg-spacing ?\ ))))) ;TODO Use `just-one-space' instead.
        ((not (save-excursion (c-end-of-arg))) ;if already at end of arg
         ;; append
         (let ((post (looking-at (rx (* (in space ?\n))
                                     (in ")}"))))) ;if arguments after point
           (insert "," (make-string c-function-comma-arg-spacing ?\ )) ;TODO Use `just-one-space' instead.
           (yank)
           (when c-standardize-token-ws-flag
             (fixup-whitespace))))
        (t                              ;if inside an argument
         ;; split current argument at cursor and insert there
         (insert "," (make-string c-function-comma-arg-spacing ?\ )) ;TODO Use `just-one-space' instead.
         (yank)
         (insert "," (make-string c-function-comma-arg-spacing ?\ )) ;TODO Use `just-one-space' instead.
         (when c-standardize-token-ws-flag
           (fixup-whitespace))
         )))

(defun c-backward-kill-arg-exp (&optional skip-separators)
  "Kill the argument expression following point.
If SKIP-SEPARATORS is non-nil don't delete any separators."
  (interactive "P")                     ;TODO Support prefix argument
  (skip-whitespace-forward)
  (let ((beg (point)))
    (if (or (c-beginning-of-arg)
            (c-backward-arg))
        (progn (kill-region beg (point))
               (if skip-separators
                   (c-backward-arg 1)
                 (when (c-end-of-arg-p)
                   (c-delete-arg-separators-backward))
                 ))
      (message "No previous argument")
      (ding))))

(defun c-forward-kill-arg-exp (&optional skip-separators)
  "Kill the argument expression following point.
If SKIP-SEPARATORS is non-nil don't delete any separators."
  (interactive "P")                     ;TODO Support prefix argument
  (let ((beg (point)))
    (if (or (c-end-of-arg)
            (c-forward-arg)) ;;(< beg (point))
        (progn (kill-region beg (point))
               (if skip-separators
                   (c-forward-arg 1)
                 (when (c-beginning-of-arg-p)
                   (c-delete-arg-separators-forward))))
      (message "No next argument")
      (ding))))

(defun c-backward-kill-arg (arg &optional skip-separators)
  "Kill the current argument and move backward.
If SKIP-SEPARATORS is non-nil don't delete any separators."
  (interactive "P")
  (unless arg (setq arg 1))             ;default to 1
  (cond
   ((< 0 arg)
    (dotimes (i arg (point))
      (c-backward-kill-arg-exp skip-separators)))
   ((> 0 arg)
    (dotimes (i (- arg) (point))
      (c-forward-kill-arg-exp skip-separators)))
   (t
    (point))))

(defun c-forward-kill-arg (arg &optional skip-separators)
  "Kill the current argument and move forward.
If SKIP-SEPARATORS is non-nil don't delete any separators."
  (interactive "P")
  (c-backward-kill-arg (- (or arg 1))))

(defun c-copy-arg ()
  "Copy the argument expression following point."
  (interactive)
  (c-beginning-of-arg)
  (let ((beg (point)))
    (c-end-of-arg)
    (if (< beg (point))
        (copy-region-as-kill beg (point))
      (message "No argument at point")
      (ding)
      )))

(defun c-move-arg (&optional n)
  "Move current argument N steps forwards (or backwards if N is negative).
Return non-nil if point changed."
  (interactive "*P")
  (unless n (setq n 1))                 ;default n to 1
  (cond ((> n 0)
         (c-backward-kill-arg 1 nil)
         (c-forward-arg n)
         (c-yank-arg)
         )
        ((< n 0)
         (c-backward-kill-arg 1 nil)
         (c-forward-arg (- n))
         (c-yank-arg)
         )))

(defun c-transpose-args (arg)
  "Transpose the arguments before and after point.
Return non-nil if no change occurred."
  (interactive "*p")
  (cond ((not (save-excursion (c-beginning-of-arg))) ;if already at beginning of arg
         (c-move-arg (- arg)))
        ((not (save-excursion (c-end-of-arg))) ;if already at end of arg
         (c-move-arg arg))
        (t
         (message "Can only transpose at beginning or end of argument") (ding))
        ))

(defun c-delete-arg-separators (&optional backwards)
  "Delete unused argument separators around point.
If BACKWARDS if non-nil remove separators before point instead."
  (interactive "P")
  (let* ((first (looking-back (rx (group (in "({"))
                                  (group (* (in space ?\n)))))) ;at first argument
         (first-md (match-data))
         (last (looking-at (rx (group (* (in space ?\n)))
                               (group (in ")}"))))) ;at last argument
         (last-md (match-data))
         )
    (when first    ;at first argument
      (when c-standardize-token-ws-flag
        (set-match-data first-md)
        (cond ((string-equal (match-string 1) "(")
               (replace-match (make-string c-function-paren-arg-spacing ?\ ) nil nil nil 2))
              ((string-equal (match-string 1) "{")
               (replace-match (make-string c-function-brace-arg-spacing ?\ ) nil nil nil 2))))
      (when (looking-at (rx (* (in space ?\n))
                            (in ",;")
                            (* (in space ?\n)))) ;more after
        (delete-region (match-beginning 0)
                       (match-end 0))))
    (when last    ;at last argument
      (when c-standardize-token-ws-flag
        (set-match-data last-md)
        (cond ((string-equal (match-string 2) ")")
               (replace-match (make-string c-function-paren-arg-spacing ?\ ) nil nil nil 1))
              ((string-equal (match-string 2) "}")
               (replace-match (make-string c-function-brace-arg-spacing ?\ ) nil nil nil 1))))
      (let ((end (point)))
        (when (looking-back (rx (* (in space ?\n))
                                (in ",;")
                                (* (in space ?\n)))) ;more before
          (goto-char (match-beginning 0))
          (skip-ws-backward)  ;need because looking-back sets match-beginning to the first possible hit
          (delete-region (point)
                         end))))
    (when (not (or first last))         ;at mid argument
      (if backwards
          (progn
            (skip-ws-forward)
            (let ((end (point)))
              (when (looking-back (rx (in ",;")
                                      (* (in space ?\n)))) ;more before
                (goto-char (match-beginning 0))
                (skip-ws-backward) ;need because looking-back sets match-beginning to the first possible hit
                (delete-region (point)
                               end))))
        (when (looking-at (rx (* (in space ?\n))
                              (group (in ",;"))
                              )) ;more before
          (delete-region (match-beginning 1)
                         (match-end 1)))
        (fixup-whitespace)
        (skip-ws-forward)
        ))
    ))

(defun c-delete-arg-separators-forward ()
  (c-delete-arg-separators)
  (indent-for-tab-command))

(defun c-delete-arg-separators-backward ()
  (c-delete-arg-separators t)
  (indent-for-tab-command))

(defun c-goto-arg (n)
  "Goto N:th argument.
Forward indexing from beginning starts at 1 and ascends.
Backward indexing from end begins at -1 and descends.
A zero argument stays at current argument."
  (interactive "nGoto argument (from begin at 1 or from end at -1): ")
  (if (numberp n)
      (let ((count (c-arg-count)))
        (cond ((> n 0)
               (if (<= n count)
                   (progn (c-beginning-of-arglist)
                          (c-next-arg (1- n)))
                 (message "Index %s must be less than or equal to %s" n count)))
              ((< n 0)
               (if (<= (- n) count)
                   (progn (c-end-of-arglist)
                          (c-previous-arg (1- (- n))))
                 (message "Index %s must be greater than or equal to -%s" n count)))
              ))
    (error "Argument %s is not a number" n)))
;; Use: (c-goto-arg nil)

(defun c-get-arg (n)
  "Get N:th argument.
Indexing is same as for `c-goto-arg'."
  (interactive "nGet argument (from begin at 1 or from end at -1) : ")
  (save-excursion
    (c-goto-arg n)
    (c-copy-arg)))

(defun c-backward-token (&optional count balanced limit past-ws)
  "Return number of tokens moved or nil if already at first token."
  (interactive "P")
  (let* ((p (point))
         (q (progn (skip-chars-backward " \t\n")
                   (if (cc-derived-mode-p)
                       (c-backward-token-2 count balanced limit)
                     (backward-sexp-safe count)) ;TODO Fix!
                   (unless past-ws
                     (skip-chars-forward " \t\n"))
                   (point))))
    (if (< q p)
        (- q p)
      (message "At first%s token" (if balanced " balanced"))
      (ding))))
(defun c-forward-token (&optional count balanced limit past-ws)
  "Return number of tokens moved or nil if already at last token."
  (interactive "P")
  (let* ((p (point))
         (q (progn (skip-chars-forward " \t\n")
                   (if (cc-derived-mode-p)
                       (c-forward-token-2 count balanced limit)
                     (forward-sexp-safe count)) ;TODO Fix!
                   (unless past-ws
                     (skip-chars-backward " \t\n"))
                   (point))))
    (if (< p q)
        (- q p)
      (message "At last%s token" (if balanced " balanced"))
      (ding))))

(defun c-backward-token-balanced (&optional count limit past-ws) (interactive "P")
  (if (looking-back (concat "}" L*))
      (progn (backward-sexp-safe count)      ;because `c-backward-token' fails here
             (when past-ws
               (skip-chars-backward " \t\n")))
    (c-backward-token count t limit past-ws)))
(defun c-forward-token-balanced (&optional count limit past-ws) (interactive "P")
  (if (looking-at (concat L* "{"))
      (progn (forward-sexp-safe count)            ;because `c-forward-token' fails here
             (when past-ws
               (skip-chars-forward " \t\n")))
    (c-forward-token count t limit past-ws)))

(defun c-search-forward-token-balanced (token &optional count past-ws)
  "Search TOKEN forwards."
  (interactive "s")
  (let* ((hp)                            ;hit point
         (patt (concat L* "\\(" token "\\)"))) ;pattern
    (save-excursion
      (setq hp (catch 'hit
                 (if (looking-at patt)
                     (throw 'hit (match-end 1))
                   (while (c-forward-token-balanced (or count 1))
                     (when (looking-at patt)
                       (throw 'hit (match-end 1)))
                     )))))
    (when hp
      (goto-char hp)
      (when past-ws
        (skip-chars-forward " \t\n")))))

(defun c-search-backward-token-balanced (token &optional count past-ws)
  "Search TOKEN backwards."
  (interactive "s")
  (let* ((hp)                            ;hit point
         (patt (concat "\\(" token "\\)" L*))) ;pattern
    (save-excursion
      (setq hp (catch 'hit
                 (if (looking-back patt)
                     (throw 'hit (match-beginning 1))
                   (while (c-backward-token-balanced (or count 1))
                     (if (looking-back patt)
                         (throw 'hit (match-beginning 1))
                       ))))))
    (when hp
      (goto-char hp)
      (when past-ws
        (skip-chars-backward " \t\n")))))

(defun c-backward-token-unbalanced (&optional count limit) (interactive "P") (c-backward-token count nil limit))
(defun c-forward-token-unbalanced (&optional count limit) (interactive "P") (c-forward-token count nil limit))

(defun c-kill-token (&optional count balanced limit)
  "Kill token after point. See `c-forward-token-2'.
Optional COUNT givens number of tokens to kill."
  (interactive "P")
  ;;(c-beginning-of-token-2)
  (let ((beg (point)))
    (if (cc-derived-mode-p)
        (c-forward-token-2 count balanced limit)
      (forward-sexp-safe count))
    (if (< beg (point))
        (kill-region beg (point))
      (message "No token at point")
      (ding)
      )))

(defun kill-token-balanced (&optional arg)
  (interactive "p")
  (let ((opoint (point)))
    (c-forward-token-balanced (or arg 1))
    (kill-region opoint (point))))
(defun backward-kill-token-balanced (&optional arg)
  (interactive "p")
  (kill-token-balanced (- (or arg 1))))

(defun c-mark-token (&optional arg allow-extend balanced)
  "Set mark ARG tokens from point.
The place mark goes is the same place \\[c-forward-token] would
move to with the same argument.
Interactively, if this command is repeated
or (in Transient Mark mode) if the mark is active,
it marks the next ARG sexps after the ones already marked.
This command assumes point is not in a string or comment.

Same as `mark-sexp' but with `forward-sexp-safe' replaced with
`c-forward-token'."
  (interactive "P\np")
  (cond ((and allow-extend
              (or (and (eq last-command this-command) (mark t))
                  (use-region-p)))
         (setq arg (if arg (prefix-numeric-value arg)
                     (if (< (mark) (point)) -1 1)))
         (set-mark
          (save-excursion
            (goto-char (mark))
            (c-forward-token arg balanced)
            (point))))
        (t
         (push-mark
          (save-excursion
            (c-forward-token (prefix-numeric-value arg) balanced)
            (point))
          nil t))))
(defun c-mark-token-balanced (&optional arg allow-extend balanced) (interactive "P\np") (c-mark-token arg allow-extend t))
(defun c-mark-token-unbalanced (&optional arg allow-extend balanced) (interactive "P\np") (c-mark-token arg allow-extend nil))

(defun c-first-token (&optional balanced limit)
  "Move cursor to beginning of first token.
Return number of tokens moved, or nil if already at beginning
of tokenument list."
  (interactive)
  (let ((count 0))
    (c-beginning-of-current-token)
    (while (and (not (c-beginning-of-arglist-p))
                (c-backward-token 1 balanced limit))
      (setq count (1+ count)))
    (unless (zerop count) count)))

(defun c-last-token (&optional balanced limit)
  "Move cursor to beginning of last token.
Return number of tokens moved, or nil if already at last
token."
  (interactive)
  (let ((count 0))
    (c-end-of-current-token)
    (while (and (not (c-end-of-arglist-p))
                (c-forward-token 1 balanced limit))
      (setq count (1+ count)))
    (unless (zerop count) count)))

(defun c-beginning-of-tokenlist ()
  "Move backward to beginning of token list.
Return number of arguments moved, or nil if already at beginning
of argument list."
  (interactive)
  (c-first-token t))

(defun c-end-of-tokenlist ()
  "Move forward to end of token list.
Return number of arguments moved, or nil if already at end of
argument list."
  (interactive)
  (c-last-token t)
  (c-end-of-current-token))

(defun cc-structed-setup-keybindings ()
  "Setup Keybindings for CC Structured Editing."
  (interactive)
  ;; (local-set-key [(control meta shift p)] 'c-backward-token)
  ;; (local-set-key [(control meta shift n)] 'c-forward-token)

  (local-set-key [(control meta b)] 'c-backward-token-balanced)
  (local-set-key [(control meta f)] 'c-forward-token-balanced)
  (local-set-key [(control meta shift b)] 'c-backward-token-unbalanced)
  (local-set-key [(control meta shift f)] 'c-forward-token-unbalanced)

  (local-set-key [(meta shift a)] 'c-beginning-of-tokenlist)
  (local-set-key [(meta shift e)] 'c-end-of-tokenlist)

  (local-set-key [(control meta delete)] 'kill-token-balanced)
  (local-set-key [(control meta backspace)] 'backward-kill-token-balanced)

  (local-set-key [(control shift meta delete)] 'c-kill-token)
  ;;(local-set-key [(control shift meta ? )] 'c-mark-token)
  (local-set-key [(control meta ? )] 'c-mark-token-balanced)

  ;;(local-set-key [(control meta shift b)] 'c-beginning-of-arg)
  ;;(local-set-key [(control meta shift f)] 'c-end-of-arg)

  (local-set-key [(control shift a)] 'c-beginning-of-arglist)
  (local-set-key [(control shift e)] 'c-end-of-arglist)

  (local-set-key [(control shift b)] 'c-backward-arg)
  (local-set-key [(control shift f)] 'c-forward-arg)

  (local-set-key [(control shift p)] 'c-previous-arg)
  (local-set-key [(control shift n)] 'c-next-arg)

  (local-set-key [(control shift c)] 'c-arg-position-and-count)
  (local-set-key [(control shift j)] 'c-arg-newline)

  (local-set-key [(control shift backspace)] 'c-backward-kill-arg)
  (local-set-key [(control shift d)] 'c-forward-kill-arg)
  (local-set-key [(control shift w)] 'c-copy-arg)
  (local-set-key [(control shift ?\ )] 'c-mark-arg)
  (local-set-key [(control shift y)] 'c-yank-arg)

  (local-set-key [(control shift t)] 'c-transpose-args)
  (local-set-key [(meta shift t)] 'c-transpose-args)

  (local-set-key [(control shift g)] 'c-goto-arg)
  ;;(local-set-key [(control shift n)] 'c-get-arg))
  )

(defun matlab-structed-setup-keybindings ()
  "Setup Keybindings for Matlab Structured Editing."
  (interactive)
  ;; (local-set-key [(control meta shift p)] 'c-backward-token)
  ;; (local-set-key [(control meta shift n)] 'c-forward-token)

  ;; (local-set-key [(control meta b)] 'c-backward-token-balanced)
  ;; (local-set-key [(control meta f)] 'c-forward-token-balanced)
  ;; (local-set-key [(control meta shift b)] 'c-backward-token-unbalanced)
  ;; (local-set-key [(control meta shift f)] 'c-forward-token-unbalanced)

  (local-set-key [(meta shift a)] 'c-beginning-of-tokenlist)
  (local-set-key [(meta shift e)] 'c-end-of-tokenlist)

  (local-set-key [(control shift meta delete)] 'c-kill-token)
  ;;(local-set-key [(control shift meta ? )] 'c-mark-token)
  ;;(local-set-key [(control meta ? )] 'c-mark-token-balanced)

  (local-set-key [(control ?k)] 'c-kill-token)

  ;;(local-set-key [(control meta shift b)] 'c-beginning-of-arg)
  ;;(local-set-key [(control meta shift f)] 'c-end-of-arg)

  (local-set-key [(control shift a)] 'c-beginning-of-arglist)
  (local-set-key [(control shift e)] 'c-end-of-arglist)

  (local-set-key [(control shift b)] 'c-backward-arg)
  (local-set-key [(control shift f)] 'c-forward-arg)

  (local-set-key [(control shift p)] 'c-previous-arg)
  (local-set-key [(control shift n)] 'c-next-arg)

  (local-set-key [(control shift c)] 'c-arg-position-and-count)

  (local-set-key [(control shift backspace)] 'c-backward-kill-arg)
  (local-set-key [(control shift d)] 'c-forward-kill-arg)
  (local-set-key [(control shift w)] 'c-copy-arg)
  ;;(local-set-key [(control shift ?\ )] 'c-mark-arg)
  (local-set-key [(control shift y)] 'c-yank-arg)

  (local-set-key [(control shift t)] 'c-transpose-args)
  (local-set-key [(meta shift t)] 'c-transpose-args)

  (local-set-key [(control shift g)] 'c-goto-arg)
  ;;(local-set-key [(control shift n)] 'c-get-arg))

  )

(defun cc-structed-add-key-bindings ()
  "Add hook for local keybindings for navigate and operate
function arguments in cc-modes."
  (interactive)
  (add-hook 'c-mode-common-hook 'cc-structed-setup-keybindings t)
  (add-hook 'js-mode-hook 'cc-structed-setup-keybindings t)
  (add-hook 'ada-mode-hook 'cc-structed-setup-keybindings t)
  (add-hook 'pascal-mode-hook 'cc-structed-setup-keybindings t)
  (add-hook 'python-mode-hook 'cc-structed-setup-keybindings t)
  (add-hook 'ruby-mode-hook 'cc-structed-setup-keybindings t)
  (add-hook 'comint-mode-hook 'cc-structed-setup-keybindings t)

  (add-hook 'matlab-mode-hook 'matlab-structed-setup-keybindings t)
  (add-hook 'matlab-shell-mode-hook 'matlab-structed-setup-keybindings t)
  )

(defun cc-structed-remove-key-bindings ()
  "Remove hook for local keybindings for navigate and operate
function arguments in cc-modes."
  (remove-hook 'c-mode-common-hook 'cc-structed-setup-keybindings)
  (remove-hook 'js-mode-hook 'cc-structed-setup-keybindings)
  (remove-hook 'ada-mode-hook 'cc-structed-setup-keybindings)
  (remove-hook 'pascal-mode-hook 'cc-structed-setup-keybindings)
  (remove-hook 'python-mode-hook 'cc-structed-setup-keybindings)
  (remove-hook 'ruby-mode-hook 'cc-structed-setup-keybindings)
  (remove-hook 'comint-mode-hook 'cc-structed-setup-keybindings)

  (remove-hook 'matlab-mode-hook 'matlab-structed-setup-keybindings)
  (remove-hook 'matlab-shell-mode-hook 'matlab-structed-setup-keybindings t)
  )
(eval-when-compile
  (cc-structed-remove-key-bindings)
  (cc-structed-add-key-bindings)
  )

(provide 'structed)
