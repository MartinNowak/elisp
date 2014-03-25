;;; debugger-xrefs.el
;; ToDo: Move this into my own Emacs tree...
;; Highlight functions and sub-routines.
;; ToDo: Make subr clickable: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/9c2713059d73260b#

(require 'debug)

(defun debugger-make-xrefs (&optional buffer)
  "Attach cross-references to function names in the `*Backtrace*' buffer."
  (interactive "b")
  (save-excursion
    (set-buffer (or buffer (current-buffer)))
    (setq buffer (current-buffer))
    (let ((inhibit-read-only t)
          (old-end (point-min)) (new-end (point-min)))
      ;; If we saved an old backtrace, find the common part
      ;; between the new and the old.
      ;; Compare line by line, starting from the end,
      ;; because that's the part that is likely to be unchanged.
      (if debugger-previous-backtrace
          (let (old-start new-start (all-match t))
            (goto-char (point-max))
            (with-temp-buffer
              (insert debugger-previous-backtrace)
              (while (and all-match (not (bobp)))
                (setq old-end (point))
                (forward-line -1)
                (setq old-start (point))
                (with-current-buffer buffer
                  (setq new-end (point))
                  (forward-line -1)
                  (setq new-start (point)))
                (if (not (zerop
                          (let ((case-fold-search nil))
                            (compare-buffer-substrings
                             (current-buffer) old-start old-end
                             buffer new-start new-end))))
                    (setq all-match nil))))
            ;; Now new-end is the position of the start of the
            ;; unchanged part in the current buffer, and old-end is
            ;; the position of that same text in the saved old
            ;; backtrace.  But we must subtract (point-min) since strings are
            ;; indexed in origin 0.

            ;; Replace the unchanged part of the backtrace
            ;; with the text from debugger-previous-backtrace,
            ;; since that already has the proper xrefs.
            ;; With this optimization, we only need to scan
            ;; the changed part of the backtrace.
            (delete-region new-end (point-max))
            (goto-char (point-max))
            (insert (substring debugger-previous-backtrace
                               (- old-end (point-min))))
            ;; Make the unchanged part of the backtrace inaccessible
            ;; so it won't be scanned.
            (narrow-to-region (point-min) new-end)))

      ;; Scan the new part of the backtrace, inserting xrefs.
      (goto-char (point-min))
      (while (progn
               (goto-char (+ (point) 2))
               (skip-syntax-forward "^w_")
               (not (eobp)))
        (let* ((beg (point))
               (end (progn (skip-syntax-forward "w_") (point)))
               (sym (intern-soft (buffer-substring-no-properties
                                  beg end)))
               (file (and sym (symbol-file sym 'defun)))
               (subr (and sym (subrp (symbol-function sym))))
               )
          (when file
            (goto-char beg)
            ;; help-xref-button needs to operate on something matched
            ;; by a regexp, so set that up for it.
            (re-search-forward "\\(?:\\sw\\|\\s_\\)+")
            (add-text-properties (match-beginning 0) (match-end 0)
                                 (list 'face 'font-lock-function-call-face :underline t))
            (help-xref-button 0 'help-function-def sym file))
          (when subr
            (goto-char beg)
            ;; help-xref-button needs to operate on something matched
            ;; by a regexp, so set that up for it.
            (re-search-forward "\\(?:\\sw\\|\\s_\\)+")
            (add-text-properties (match-beginning 0) (match-end 0)
                                 (list 'face 'font-lock-builtin-face))
            ))
        (forward-line 1))
      (widen))
    (setq debugger-previous-backtrace (buffer-string))))

(provide 'debugger-xrefs)
