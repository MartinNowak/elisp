;;; pgo-kill.el --- Setup Kill Ring and Copy Operations.
;; Author: Per Nordlöw

;;; Copying Whole Lines
;;; See: http://www.emacswiki.org/emacs-en/CopyingWholeLines

(defun copy-line-alt (arg)
  "Copy lines (as many as prefix argument) in the kill ring"
  (interactive "p")
  (kill-ring-save (line-beginning-position)
                  (line-beginning-position (+ 1 arg)))
  (message "%d line%s copied" arg (if (= 1 arg) "" "s")))

(defun copy-line (&optional arg)
  "Do a `kill-line' but copy rather than kill.  This function
directly calls kill-line, so see documentation of kill-line for
how to use it including prefix argument and relevant variables.
This function works by temporarily making the buffer read-only,
so I suggest setting kill-read-only-ok to t."
  (interactive "P")
  (toggle-read-only 1)
  (kill-line arg)
  (toggle-read-only 0)
  )
(setq-default kill-read-only-ok t)
(global-set-key "\C-c\C-k" 'copy-line)

(defun copy-whole-line ()
  "Copy the whole line that point is on and move to the beginning
of the next line.  Consecutive calls to this command append each
line to the kill-ring."
  (interactive)
  (let ((beg (line-beginning-position 1))
        (end (line-beginning-position 2)))
    (if (eq last-command 'quick-copy-line)
        (kill-append (buffer-substring beg end) (< end beg))
      (kill-new (buffer-substring beg end))))
  (beginning-of-line 2)
  )
(global-set-key "\C-c\C-k" 'copy-whole-line)

;; I too always wondered why stock Emacs didn’t have a convenient line
;; copying keybinding, or even a function. There are C-w (kill-region)
;; and M-w (kill-ring-save), but C-k (kill-line) doesn’t seem to have
;; a counterpart that just saves the lines into the kill ring.
;;
;; This one behaves the same way as kill-line, expect that it doesn’t
;; move point at all, because I felt that it suits me the best this
;; way. What I’d like to expand it with is the possibillity to be able
;; to call it consecutively and copy multiple lines one for one, as
;; quick-copy-line does, and let this behaviour depend on a variable
;; or a prefix. When I find time for that. As of now I use both
;; functions with different keys, depending on the situation i need
;; them.
(defun avi-kill-line-save (&optional arg)
  "Copy to the kill ring from point to the end of the current line.
With a prefix argument, copy that many lines from point. Negative
arguments copy lines backward. With zero argument, copies the
text before point to the beginning of the current line."
  (interactive "p")
  (save-excursion                       ;Note: leave point untouched
    (copy-region-as-kill
     (point)
     (progn (if arg (forward-visible-line arg)
              (end-of-visible-line))
            (point)))))
(defalias 'avi-copy-line-save 'avi-kill-line-save)
(global-set-key "\C-c\C-k" 'avi-copy-line-save)

;; ---------------------------------------------------------------------------

(defun my-kill-line (arg)
  "Delete the linefeed and carriage return of the previous line when point is at the beginning of the current line"
  (interactive "p")
  (let ((prev-char (char-before (point)))
        (at-beginning-of-line nil))
    (while (and (characterp prev-char)
                (or (char-equal prev-char 10)
                    (char-equal prev-char 13)))
      (setq at-beginning-of-line t)
      (backward-delete-char 1)
      (setq prev-char (char-before (point))))
    (if (and (characterp prev-char)
             (not at-beginning-of-line))
        (kill-line arg))))

;; ---------------------------------------------------------------------------

(provide 'pgo-kill)
