;;; fill-dwim.el --- Fill Do What I Mean.

;; TODO: Enbale and merge with definitions in nxhtml/util/ourcomments-util.el

;; See: http://www.emacswiki.org/emacs-en/UnfillRegion
(defun unfill-region (from to)
  "Takes a region containing multi-line paragraphs and makes them into a single line of text.
The opposite of `fill-region'."
  (interactive (progn
                 (barf-if-buffer-read-only)
                 (list (region-beginning) (region-end))))
  (let ((fill-column (point-max)))
    (fill-region from to)))

;; See: http://www.emacswiki.org/emacs-en/UnfillParagraph
;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph ()
  "Takes a multi-line paragraph and makes it into a single line of text.
The opposite of `fill-paragraph'."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil)))

(defun unfill-dwim ()
  "Unfill Do What I Mean (DWIM).
If the region is active and `transient-mark-mode' is on, call
`unfill-region', otherwise call `unfill-paragraph'."
  (interactive)
  (if (use-region-p)
      (unfill-region (region-beginning) (region-end))
    (unfill-paragraph)))

(defun fill-dwim (&optional arg)
  "Fill Do What I Mean (DWIM).
If the region is active and `transient-mark-mode' is on, call
`fill-region', otherwise call `fill-paragraph'."
  (interactive "P")
  (if (use-region-p)
      (fill-region (region-beginning) (region-end))
    (fill-paragraph arg)))

(defun fill-or-unfill-dwim (&optional arg)
  (interactive "P")
  (if arg
      (call-interactively 'unfill-dwim)
    (call-interactively 'fill-dwim)))
(global-set-key [(meta q)] 'fill-or-unfill-dwim)
(global-set-key [(meta shift q)] 'unfill-dwim)

;; See: http://www.emacswiki.org/emacs-en/UnwrapLine
(defun unwrap-line ()
  "Remove all newlines until we get to two consecutive ones.
Or until we reach the end of the buffer.  Great for unwrapping
quotes before sending them on IRC."
  (interactive)
  (let ((start (point))
        (end (copy-marker (or (search-forward "\n\n" nil t)
                              (point-max))))
        (fill-column (point-max)))
    (fill-region start end)
    (goto-char end)
    (newline)
    (goto-char start)))
;;(define-key erc-mode-map (kbd "M-q") 'unwrap-line) ;to replace the useless binding for fill-paragraph in ERC:

;; helper defun to unfill lines that have been cut from elsewhere
(defun erc-unfill ()
  "Unfill the region after the prompt.
Intended to be called just before you send a line"
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (goto-char (previous-single-property-change (point) 'erc-prompt))
    (while (search-forward "\n" nil t)
      (delete-backward-char 1)
      (just-one-space))))

(provide 'fill-dwim)
