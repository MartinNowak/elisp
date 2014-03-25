;;; smart-spacing.el ---
;;
;; Filename: smart-spacing.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: ons jun 10 22:11:53 2009 (+0200)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 1
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Cannot open load file: smart-spacing.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:
;; Smart spacing

;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs

;; This code is part of Aquamacs Emacs
;; http://aquamacs.org/
;; Copyright (C) 2009: David Reitter

;; (defcustom smart-spacing-when-killing-words nil
;;   "Delete extra spaces when killing words.
;; Affects commands `aquamacs-kill-word' and `aquamacs-backwards-kill-word'."
;;   :group 'convenience
;;   :group 'Aquamacs
;;   :type '(choice (const nil) (const t)))

(define-minor-mode smart-spacing-mode
  "Smart spacing: word-wise kill&yank.
When this mode is enabled, kill and yank operations support
word-wise editing.  Afer killing (copying) a word or several
words, the text will be inserted as a full phrase when
yanking. That means that spaces around the word may be inserted
during yanking, and spaces and other word delimiters are removed
during killing as necessary to leave only one space between
words.

During killing, smart-spacing-mode behaves conservatively.  It
will never delete more than one extra space at a time.

This feature is part of Aquamacs."
  :group 'convenience
  :lighter " Spc")

(defun turn-on-smart-spacing-mode ()
  (interactive)
  (smart-spacing-mode 1))

(defun turn-off-smart-spacing-mode ()
  (interactive)
  (smart-spacing-mode 0))

(define-globalized-minor-mode
  global-smart-spacing-mode smart-spacing-mode
  turn-on-smart-spacing-mode)

(defvar smart-spacing-rules
  '(("  " . (bidi . 1))
    ("--" . 1)
    (" ." . -1)
    (" )" . -1)
    ("( " . 1)
    (" :" . -1)
    (" ," . -1)
    (" ;" . -1)
    (" \"" . -1)
    ("\" " . 1)
    (" '" . -1)
    ("\n " . 1)
    (" " . 1) ; buffer boundary
    ;; ("\n\n" . "\n")
    )
  "Assoc list for smart spacing.
If key is at point after killing text, delete |value| chars to
the left or the right.  Negative value indicates deletion to the
left.  If value is a cons (xxx . num), then num characters will
be deleted either to the left or to the right, depending on where
the point is when the command is called.")

(defmacro user-buffer-p (buf)
  "Evaluate to t if buffer BUF is not an internal buffer."
  `(not (string= (substring (buffer-name ,buf) 0 1) " ")))

(defun smart-spacing-filter-buffer-substring (beg end &optional delete noprops )
  "Like `filter-buffer-substring', but add spaces around content if region is a phrase."
  (let* ((from (min beg end)) (to (max beg end))
         ;; (move-point (memq (point) (list beg end)))
         (point-at-end (eq (point) end))
         (use-smart-string
          (and
           smart-spacing-mode
           (user-buffer-p (current-buffer))
           (smart-spacing-char-is-word-boundary (1- from) from)
           (smart-spacing-char-is-word-boundary to (1+ to))))
         ;; the following is destructive (side-effect).
         ;; do after checking for word boundaries.
         (string (filter-buffer-substring beg end delete noprops)))
    (when use-smart-string
      (put-text-property 0 (length string)
                         'yank-handler
                         '(smart-spacing-yank-handler nil nil nil)
                         string)
      (when delete (smart-remove-remaining-spaces from point-at-end)))
    string))

(defun smart-delete-region (from to)
  (if (and smart-spacing-mode (memq this-command '(cua-delete-region mouse-save-then-kill)))
      (let* ((from (min from to))
             (to (max from to))
             ;; (move-point (memq (point) (list beg end)))
             (point-at-end (eq (point) to)))

        (delete-region from to)
        (smart-remove-remaining-spaces from point-at-end))
    (delete-region from to)))

(defun smart-remove-remaining-spaces (pos point-at-end)
  "Remove remaining spaces.
Adheres to `smart-spacing-rules'.
If POINT-AT-END, behaves as if point was at then end of
a previously deleted region (now at POS)."
  (let ((del (assoc (buffer-substring-no-properties
                     (max (point-min) (- pos 1))
                     (min (1- (point-max)) (1+ pos)))
                    smart-spacing-rules)))
    (when del
      (setq del (cdr del))
      ;; in some cases we want point to end up
      ;; further to the left or to the right,
      ;; depending on whether it was on the left or the right
      ;; edge of the region
      (when (consp del)
        (if point-at-end
            (setq del (cdr del))
          (setq del (- (cdr del)))))
      ;; delete either to the left or to the right
      ;; this deletion will keep point in the right place.
      (delete-region pos (+ del pos)))))

(defun smart-spacing-char-is-word-boundary (pos &optional side)
  (or (< pos (point-min))
      (>= pos (point-max))
      (not (let ((str (buffer-substring-no-properties pos (1+ pos))))
             (or (string-match "\\w" str)
                 (if (eq side 'left) (or (equal str ".") (equal str ")")))
                 (if (eq side 'right) (equal str "(")))))))


(defun smart-spacing-yank-handler (string)
  (when  (and smart-spacing-mode
              major-mode ; paranoia
              (user-buffer-p (current-buffer)))
    (or (smart-spacing-char-is-word-boundary opoint 'right) ; to the right
        (setq string (concat string " ")))
    (or (smart-spacing-char-is-word-boundary (1- opoint) 'left) ; to the left
        (setq string (concat " " string))
        ))
  (insert string))

(provide 'smart-spacing)

;; currently not advising backward-delete-char-untabity
;; or delete-char

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; smart-spacing.el ends here
