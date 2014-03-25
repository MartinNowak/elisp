;;; thingatpt-pnw.el --- Setup thingatpt.el
;; Author: Per Nordlöw

;;; ===========================================================================
;;; Operations on Thing at Point
;;; See: http://www.emacswiki.org/cgi-bin/wiki/ThingAtPoint

;;; thingatpt+
(eval-after-load "thingatpt" '(progn (require 'thingatpt+ nil t)))

;; Use: (thing-at-point 'line)
;; Use: (bounds-of-thing-at-point 'line)

;;; thingatpt-util.el
(when (require 'thingatpt-util nil t))

;;; thing-opt.el --- Thing at Point optional utilities
;;(when (require 'thing-opt nil t))

;;; thing-cmds.el --- Commands that use things, as defined by `thingatpt.el'.
(when (require 'thing-cmds nil t)
  ;;  Suggested key bindings (these will replace the standard bindings
  ;;  for `mark-sexp' and `mark-word'):
  ;;
  (thgcmd-bind-keys)
  (global-set-key [(meta shift \ )] 'mark-thing)
  (global-set-key [(meta ?@)] 'cycle-thing-region) ; vs `mark-word'
  (global-set-key [(control meta shift ?u)] 'mark-enclosing-sexp)
  (global-set-key [(control meta shift ?b)] ; or [(control meta ?()]
                  'mark-enclosing-sexp-backward)
  (global-set-key [(control meta shift ?f)] ; or [(control meta ?))]
                  'mark-enclosing-sexp-forward)
  (global-set-key [(control meta ? )] 'mark-sexp-safe)
  )

(defun integer-bounds-of-integer-at-point ()
  "Return the start and end points of an integer at the current point.
   The result is a paired list of character positions for an integer
   located at the current point in the current buffer.  An integer is any
   decimal digit 0 through 9 with an optional starting minus symbol
   \(\"-\")."
  (save-excursion
    (skip-chars-backward "-0123456789")
    (if (looking-at "-?[[:digit:]]+")
        (cons (point)
              (1- (match-end 0)))
      nil)))

(put 'integer 'bounds-of-thing-at-point 'integer-bounds-of-integer-at-point)

(defun integer-integer-at-point ()
  (let ((i (thing-at-point 'integer)))
    (if (numberp i) (string-to-number i)
      nil)))

(defun integer-beginning-of-integer ()
  (beginning-of-thing 'integer))

(defun integer-end-of-integer ()
  (end-of-thing 'integer))

(defun forward-integer (&optional arg)
  "Move point forward ARG (backward if ARG is negative).
  Normally returns t if integer moved, else nil."
  (interactive "p")
  (let ((arg (or arg 1)))
    (while (< arg 0)
      (integer-beginning-of-integer)
      (setq arg (1+ arg)))
    (while (> arg 0)
      (integer-end-of-integer)
      (setq arg (1- arg)))))

(defun backward-integer (&optional arg)
  "Move backward until encountering the beginning of an integer.
  With argument, do this ARG many times."
  (interactive "p")
  (let ((arg (or arg 1)))
    (forward-integer (- 0 arg))))

(defun syntax-forward-syntax (&optional arg)
  "Move ARG times to start of a set of the same syntax characters."
  (setq arg (or arg 1))
  (while (and (> arg 0)
              (not (eobp))
              (skip-syntax-forward (string (char-syntax (char-after)))))
    (setq arg (1- arg)))
  (while (and (< arg 0)
              (not (bobp))
              (skip-syntax-backward (string (char-syntax (char-before)))))
    (setq arg (1+ arg))))

(put 'syntax 'forward-op 'syntax-forward-syntax)

(defun syntax-backward-syntax (&optional arg)
  "Move ARG times to end of a set of the same syntax characters."
  (syntax-forward-syntax (- (or arg 1))))

(defun syntax-syntax-at-point ()
  (thing-at-point 'syntax))

(defun syntax-beginning-of-syntax ()
  (beginning-of-thing 'syntax))

(defun syntax-end-of-syntax ()
  (end-of-thing 'syntax))

(defun syntax-bounds-of-syntax-at-point ()
  (tap-bounds-of-thing-at-point 'syntax))

(defun kill-syntax (&optional arg)
  "Kill ARG sets of syntax characters after point."
  (interactive "p")
  (let ((opoint (point)))
    (syntax-forward-syntax arg)
    (kill-region opoint (point))))

(defun kill-syntax-backward (&optional arg)
  "Kill ARG sets of syntax characters preceding point."
  (interactive "p")
  (kill-syntax (- (or arg 1))))

;; ----------------------------------------------------------

(defun beginning-of-symbol-next-to-point (&optional syntax-table)
  "Move point to the beginning of THING next to point."
  (let* ((bounds (tap-bounds-of-thing-at-point 'symbol syntax-table))
         (pos (if bounds
                  (car bounds)
                (symbol-bfpt-beginning-position))))
    (when pos
      (goto-char pos))))

(defun end-of-symbol-next-to-point (&optional syntax-table)
  "Move point to the end of THING next to point."
  (let* ((bounds (tap-bounds-of-thing-at-point 'symbol syntax-table))
         (pos (if bounds
                  (cdr bounds)
                (symbol-bfpt-end-position))))
    (when pos
      (goto-char pos))))

(defun symbol-name-next-to-point (&optional syntax-table include-scopes)
  "Return the symbol next to point (a string).
Return nil if no such symbol is found.
SYNTAX-TABLE is a syntax table to use."
  (save-excursion
    (let ((syntax-table (or syntax-table
                            (syntax-table))))
      (or (beginning-of-symbol-next-to-point syntax-table)
          (end-of-symbol-next-to-point syntax-table))
      (tap-thing-at-point 'symbol syntax-table))))

;; ----------------------------------------------------------

(defun symbol-at-point (&optional non-nil syntax-table-flag)
  "Return the Emacs Lisp symbol under the cursor, or nil if none.
If optional arg NON-NIL is non-nil, then the nearest symbol other
  than `nil' is sought.

Some related functions:
  `symbol-nearest-point' returns the symbol nearest the cursor, or nil.
  `symbol-name-nearest-point' returns the name of
    `symbol-nearest-point' as a string, or \"\" if none.
  `symbol-name-before-point' returns the string naming the symbol at or
    before the cursor (even if it is on a previous line) or \"\" if none.
  `word-before-point' returns the word (a string) at or before cursor.
Note that these last three functions return strings, not symbols."
  ;; Needs to satisfy both: 1) symbol syntax, 2) be interned.
  (tap-form-at-point
   'symbol (if non-nil (lambda (sym) (and sym (symbolp sym))) 'symbolp)
   (or syntax-table-flag
       (syntax-table))))

(defun c-word-at-point (&optional pred)
  "Return the C symbol under the cursor, or nil if none."
  (tap-form-at-point 'word pred c-mode-syntax-table))
;; Use: (c-word-at-point)

(defun c-symbol-at-point (&optional pred)
  "Return the C symbol under the cursor, or nil if none."
  (tap-form-at-point 'symbol pred c-mode-syntax-table))
;; Use: (c-symbol-at-point)

;; ----------------------------------------------------------

(provide 'thingatpt-pnw)
