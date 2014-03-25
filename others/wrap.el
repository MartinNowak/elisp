;;; wrap.el --- Minor mode for simulating soft word wrap

;; Copyright (C) 2004 Chong Yidong

;; Author: Chong Yidong <cyd at stupidchicken com>
;; Version: 0.1.1
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This file is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with GNU Emacs; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA


;;; Commentary:

;; This is wrap-mode, a minor mode for simulating soft word wrap. It
;; is intended to be used in conjunction with longlines-mode, written
;; by Kai Grossjohann and Alex Schroeder.
;; (http://www.emacswiki.org/elisp/longlines.el)

;; The idea for this minor mode was taken from refill-mode, written by
;; Dave Love. However, its behavior differs significantly from
;; refill-mode. Wrap-mode handles line wrapping by itself, rather than
;; calling fill-paragraph or related filling functions. This is
;; because filling leads to behavior that breaks the illusion of line
;; wrapping. For example, whitespace inserted by the user may be
;; instantly deleted.

;; In other words, "wrapping" is treated as a separate thing from
;; "filling". One of the consequences of this is that wrapping
;; intentionally ignores fill-prefix. There is, of course, nothing to
;; prevent the user from calling fill-paragraph manually; this is a
;; useful thing to do for, say, cleaning up extraneous whitespace.

;; We assume that newlines and spaces characters are mutually
;; interchangeable. Wrap-mode only wraps lines at spaces, and not
;; other "whitespace" characters such as tabs.

;;; Code:

(defvar wrap-beg nil)
(defvar wrap-end nil)
(defvar wrap-point nil)

(defun wrap-after-change-function (beg end len)
  "Function for `after-change-functions'. This just sets `wrap-beg'."
  (unless undo-in-progress
    (setq wrap-beg (if wrap-beg (min wrap-beg beg) beg))
    (setq wrap-end (if wrap-end (max wrap-end end) end))))

(defun wrap-post-command-function ()
  "Function called by `post-command-hook' to perform line wrapping
after each command."
  (when wrap-beg ; there was a change
    (unless (or (eq this-command 'fill-paragraph)
                (eq this-command 'fill-region))
      (wrap-fill))
    (setq wrap-beg nil)
    (setq wrap-end nil)))

(defun wrap-fill ()
  "Wrap each successive line, starting with the line before point.
Stop when we get to lines that don't need wrapping."
  (setq wrap-point (point))
  (goto-char wrap-beg)
  (forward-line -1)
  ;; Two successful wrap-lines in a row imply that successive lines
  ;; don't need wrapping. However, we must stop only after wrap-end.
  (while (null (and (wrap-line)
                    (>= (point) wrap-end)
                    (null (eobp)) ;; Just checking.
                    (wrap-line))))
  (goto-char wrap-point))

(defun wrap-line ()
  "Wrap this line if necessary. If wrapping is performed, point
remains on the line. Otherwise, point advances to the next line.
Return t if the current line did not require adjusting, and nil
otherwise."
  (if (wrap-set-breakpoint)
      (progn (backward-delete-char 1)
             (insert-char ?\n 1)
             nil)
    (if (wrap-merge-lines-p)
        (progn (end-of-line)
               (delete-char 1)
               ;; This handles behavior induced by, e.g., kill-line.
               ;; Unfortunately, conservation of (spaces + newlines)
               ;; is broken, so we have to fiddle with value of point.
               (if (or (bolp) (eolp))
                   (progn (setq wrap-end (1- wrap-end))
                          (if (> wrap-point (point))
                              (setq wrap-point (1- wrap-point))))
                 (insert-char ?  1))
               nil)
      (forward-line 1)
      t)))

(defun wrap-set-breakpoint ()
  "Place point where we should break this line, and return t. If this
line should not be broken, return nil; point remains on the line."
  (move-to-column fill-column)
  (if (and (re-search-forward "[^ ]" (line-end-position) 1)
           (> (current-column) fill-column))
      ;; This line is too long. Can we break it?
      (or (wrap-find-break-backward)
          (progn (move-to-column fill-column)
                 (wrap-find-break-forward)))))

(defun wrap-find-break-backward ()
  "Move point backward to the first available breakpoint and return t.
If no breakpoint is found, return nil."
  (and (search-backward " " (line-beginning-position) 1)
       (save-excursion
         (skip-chars-backward " " (line-beginning-position))
         (null (bolp)))
       (progn (forward-char 1)
              (if (and fill-nobreak-predicate
                       (funcall fill-nobreak-predicate))
                  (progn (skip-chars-backward " " (line-beginning-position))
                         (wrap-find-break-backward))
                t))))

(defun wrap-find-break-forward ()
  "Move point forward to the first available breakpoint and return t.
If no break point is found, return nil."
  (and (search-forward " " (line-end-position) 1)
       (progn (skip-chars-forward " " (line-end-position))
              (null (eolp)))
       (if (and fill-nobreak-predicate
                (funcall fill-nobreak-predicate))
           (wrap-find-break-forward)
         t)))

(defun wrap-merge-lines-p ()
  "If some of the text on the next line can be fitted onto the current
line, return t. Otherwise, return nil. Text cannot be moved across
hard newlines."
  (save-excursion
    (end-of-line)
    (and (null (eobp))
         (null (get-text-property (point) 'hard))
         (let ((space (- fill-column (current-column))))
           (forward-line 1)
           (if (eq (char-after) ? )
               t ;; We can always merge some spaces
             (<= (if (search-forward " " (line-end-position) 1)
                     (current-column)
                   (1+ (current-column)))
                 space))))))

;;;###autoload
(define-minor-mode wrap-mode
  "Toggle Wrap minor mode.
With prefix arg, turn Wrap mode on iff arg is positive."
  nil " Wrap" nil
  (if wrap-mode
      (progn
        (set (make-local-variable 'wrap-beg) nil)
        (set (make-local-variable 'wrap-end) nil)
        (set (make-local-variable 'wrap-point) nil)
        (if (functionp 'longlines-mode)
            (longlines-mode 1)
          (use-hard-newlines 1))
        (add-hook 'after-change-functions 'wrap-after-change-function nil t)
        (add-hook 'post-command-hook 'wrap-post-command-function nil t)
        (auto-fill-mode 0))
    (if (functionp 'longlines-mode)
        (longlines-mode 0))
    (remove-hook 'after-change-functions 'wrap-after-change-function t)
    (remove-hook 'post-command-hook 'wrap-post-command-function t)))

(provide 'wrap)

;;; wrap.el ends here
