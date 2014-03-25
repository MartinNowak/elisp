;;; thingatpt-util.el --- thing-at-point edit functions

;; Version: 1.5

;; Copyright (C) 2006  Andreas Roehler

;; Author: Andreas Roehler <andreas.roeh...@easy-emacs.de>
;; Keywords: convenience, lisp

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Provides thing-at-point functions with interactive
;; specs.

;; Tries to return something useful according to a
;; given THING. THING may be a well known form as
;; symbol', `list', `sexp', `defun' but also of new
;; defined and abstract things.

;; Changes to previous version: Set of functions
;; for thing before and after point: word-bfpt, word-afpt...
;; Several bugs fixed, phone-atpt rewritten

;; One major diff to thingatpt.el: core
;; function `bounds-of-thing-at-point' is replaced by a
;; new `bounds-of-thatpt' in order to make execution
;; more easy to follow and maintain.

;; `bounds-of-thatpt' now first searches backward, as
;; it's the more complicated task, thus avoiding
;; trouble later on. However, as a consequence several
;; `beginning-op' and `end-op' constructs had to be
;; rewritten. In case of trouble, please send me a bug
;; report. With `thatpt-test' you may execute and check
;; all available functions at point at once.

;; Any ideas and comments welcome.

;; How it works:

;; Thing-at-point delivers a portion of the buffer. This
;; substring is determined by two alternative ways:

;; - If a pair of move-functions is known, as forward-
;;   and backward-word, its used.
;;
;; - A move-function specified for thingatpt, called
;;   beginning-op and end-op, may exist.
;;
;; The latter case given, this forms will be used
;; preferential. The point is stored after move.
;; Beginning and end are delivered as pair: as consed
;; bounds-of-thing.

;; It's easy to write your own thing-at-point functions.
;; You need three forms:
;;
;; (defun MY-FORM-atpt (&optional arg ispec)
;;   " "
;;   (interactive "p\np")
;;   (thatpt 'MY-FORM arg ispec))
;;
;; (put 'MY-FORM 'beginning-op  (lambda () MY-FORWARD-MOVE-FUNKTION))

;; (put 'MY-FORM 'end-op
;;      (lambda () MY-BACKWARD-MOVE-FUNKTION))

;; For example if you want to pick all chars at point
;; which are written between a string "AAA" and a
;; "BBB", which may exist as

;; AAA Luckily detected a lot of things! BBB

;; After evaluation of

;; (put 'MY-FORM 'beginning-op
;;      (lambda ()
;;        (search-backward "AAA" nil t 1)
;;        ;; step chars of search expression back
;;        (forward-char 3)))
;;
;; (put 'MY-FORM 'end-op
;;      (lambda ()
;;        (search-forward "BBB" nil t 1)
;;        (forward-char -3)))

;; together with the functions definition above, it's ready.

;; M-x MY-FORM-atpt

;; (while point inside) you should see:

;; " Luckily detected a lot of things! "

;; in the minibuffer.

;;; Code:

(require 'thingatpt)

(defun phone-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'phone arg ispec))

(defun bounds-of-phone-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'phone arg ispec))

(defun phone-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'phone arg ispec))

(defun phone-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'phone arg ispec))

(defun copy-phone-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'phone arg ispec))

(defun kill-phone-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'phone))

(defun phone-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'phone arg ispec)))

(defun bounds-of-phone-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'phone arg ispec)))

(defun phone-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'phone arg ispec)))

(defun phone-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'phone arg ispec)))

(defun copy-phone-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'phone arg ispec)))

(defun kill-phone-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'phone)))

(defun phone-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'phone arg ispec)))

(defun bounds-of-phone-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'phone arg ispec)))

(defun phone-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'phone arg ispec)))

(defun phone-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'phone arg ispec)))

(defun copy-phone-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'phone arg ispec)))

(defun kill-phone-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'phone)))

;;;;

(defun ml-text-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'ml-text arg ispec))

(defun bounds-of-ml-text-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'ml-text arg ispec))

(defun ml-text-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'ml-text arg ispec))

(defun ml-text-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'ml-text arg ispec))

(defun copy-ml-text-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'ml-text arg ispec))

(defun kill-ml-text-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'ml-text))

(defun ml-text-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'ml-text arg ispec)))

(defun bounds-of-ml-text-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'ml-text arg ispec)))

(defun ml-text-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'ml-text arg ispec)))

(defun ml-text-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'ml-text arg ispec)))

(defun copy-ml-text-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'ml-text arg ispec)))

(defun kill-ml-text-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'ml-text)))

(defun ml-text-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'ml-text arg ispec)))

(defun bounds-of-ml-text-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'ml-text arg ispec)))

(defun ml-text-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'ml-text arg ispec)))

(defun ml-text-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'ml-text arg ispec)))

(defun copy-ml-text-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'ml-text arg ispec)))

(defun kill-ml-text-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'ml-text)))

;;;;

(defun email-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'email arg ispec))

(defun bounds-of-email-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'email arg ispec))

(defun email-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'email arg ispec))

(defun email-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'email arg ispec))

(defun copy-email-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'email arg ispec))

(defun kill-email-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'email))

(defun email-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'email arg ispec)))

(defun bounds-of-email-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'email arg ispec)))

(defun email-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'email arg ispec)))

(defun email-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'email arg ispec)))

(defun copy-email-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'email arg ispec)))

(defun kill-email-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'email)))

(defun email-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'email arg ispec)))

(defun bounds-of-email-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'email arg ispec)))

(defun email-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'email arg ispec)))

(defun email-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'email arg ispec)))

(defun copy-email-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'email arg ispec)))

(defun kill-email-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'email)))

;;;;

(defun graphs-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'graphs arg ispec))

(defun bounds-of-graphs-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'graphs arg ispec))

(defun graphs-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'graphs arg ispec))

(defun graphs-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'graphs arg ispec))

(defun copy-graphs-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'graphs arg ispec))

(defun kill-graphs-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'graphs))

(defun graphs-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'graphs arg ispec)))

(defun bounds-of-graphs-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'graphs arg ispec)))

(defun graphs-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'graphs arg ispec)))

(defun graphs-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'graphs arg ispec)))

(defun copy-graphs-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'graphs arg ispec)))

(defun kill-graphs-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'graphs)))

(defun graphs-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'graphs arg ispec)))

(defun bounds-of-graphs-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'graphs arg ispec)))

(defun graphs-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'graphs arg ispec)))

(defun graphs-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'graphs arg ispec)))

(defun copy-graphs-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'graphs arg ispec)))

(defun kill-graphs-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'graphs)))

;;;;

(defun string-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'string arg ispec))

(defun bounds-of-string-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'string arg ispec))

(defun string-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'string arg ispec))

(defun string-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'string arg ispec))

(defun copy-string-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'string arg ispec))

(defun kill-string-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'string))

(defun string-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'string arg ispec)))

(defun bounds-of-string-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'string arg ispec)))

(defun string-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'string arg ispec)))

(defun string-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'string arg ispec)))

(defun copy-string-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'string arg ispec)))

(defun kill-string-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'string)))

(defun string-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'string arg ispec)))

(defun bounds-of-string-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'string arg ispec)))

(defun string-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'string arg ispec)))

(defun string-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'string arg ispec)))

(defun copy-string-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'string arg ispec)))

(defun kill-string-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'string)))

;;;;

(defun list-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'list arg ispec))

(defun bounds-of-list-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'list arg ispec))

(defun list-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'list arg ispec))

(defun list-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'list arg ispec))

(defun copy-list-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'list arg ispec))

(defun kill-list-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'list))

(defun list-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'list arg ispec)))

(defun bounds-of-list-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'list arg ispec)))

(defun list-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'list arg ispec)))

(defun list-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'list arg ispec)))

(defun copy-list-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'list arg ispec)))

(defun kill-list-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'list)))

(defun list-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'list arg ispec)))

(defun bounds-of-list-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'list arg ispec)))

(defun list-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'list arg ispec)))

(defun list-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'list arg ispec)))

(defun copy-list-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'list arg ispec)))

(defun kill-list-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'list)))

;;;;

(defun symbol-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'symbol arg ispec))

(defun bounds-of-symbol-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'symbol arg ispec))

(defun symbol-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'symbol arg ispec))

(defun symbol-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'symbol arg ispec))

(defun copy-symbol-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'symbol arg ispec))

(defun kill-symbol-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'symbol))

(defun symbol-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'symbol arg ispec)))

(defun bounds-of-symbol-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'symbol arg ispec)))

(defun symbol-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'symbol arg ispec)))

(defun symbol-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'symbol arg ispec)))

(defun copy-symbol-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'symbol arg ispec)))

(defun kill-symbol-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'symbol)))

(defun symbol-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'symbol arg ispec)))

(defun bounds-of-symbol-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'symbol arg ispec)))

(defun symbol-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'symbol arg ispec)))

(defun symbol-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'symbol arg ispec)))

(defun copy-symbol-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'symbol arg ispec)))

(defun kill-symbol-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'symbol)))

;;;;

(defun line-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'line arg ispec))

(defun bounds-of-line-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'line arg ispec))

(defun line-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'line arg ispec))

(defun line-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'line arg ispec))

(defun copy-line-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'line arg ispec))

(defun kill-line-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'line))

(defun line-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'line arg ispec)))

(defun bounds-of-line-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'line arg ispec)))

(defun line-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'line arg ispec)))

(defun line-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'line arg ispec)))

(defun copy-line-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'line arg ispec)))

(defun kill-line-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'line)))

(defun line-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'line arg ispec)))

(defun bounds-of-line-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'line arg ispec)))

(defun line-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'line arg ispec)))

(defun line-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'line arg ispec)))

(defun copy-line-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'line arg ispec)))

(defun kill-line-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'line)))

;;;;

(defun word-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'word arg ispec))

(defun bounds-of-word-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'word arg ispec))

(defun word-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'word arg ispec))

(defun word-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'word arg ispec))

(defun copy-word-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'word arg ispec))

(defun kill-word-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'word))

(defun word-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'word arg ispec)))

(defun bounds-of-word-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'word arg ispec)))

(defun word-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'word arg ispec)))

(defun word-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'word arg ispec)))

(defun copy-word-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'word arg ispec)))

(defun kill-word-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'word)))

(defun word-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'word arg ispec)))

(defun bounds-of-word-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'word arg ispec)))

(defun word-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'word arg ispec)))

(defun word-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'word arg ispec)))

(defun copy-word-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'word arg ispec)))

(defun kill-word-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'word)))

;;;;

(defun sentence-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'sentence arg ispec))

(defun bounds-of-sentence-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'sentence arg ispec))

(defun sentence-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'sentence arg ispec))

(defun sentence-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'sentence arg ispec))

(defun copy-sentence-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'sentence arg ispec))

(defun kill-sentence-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'sentence))

(defun sentence-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'sentence arg ispec)))

(defun bounds-of-sentence-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'sentence arg ispec)))

(defun sentence-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'sentence arg ispec)))

(defun sentence-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'sentence arg ispec)))

(defun copy-sentence-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'sentence arg ispec)))

(defun kill-sentence-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'sentence)))

(defun sentence-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'sentence arg ispec)))

(defun bounds-of-sentence-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'sentence arg ispec)))

(defun sentence-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'sentence arg ispec)))

(defun sentence-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'sentence arg ispec)))

(defun copy-sentence-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'sentence arg ispec)))

(defun kill-sentence-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'sentence)))

;;;;

(defun defun-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'defun arg ispec))

(defun bounds-of-defun-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'defun arg ispec))

(defun defun-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'defun arg ispec))

(defun defun-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'defun arg ispec))

(defun copy-defun-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'defun arg ispec))

(defun kill-defun-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'defun))

(defun defun-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'defun arg ispec)))

(defun bounds-of-defun-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'defun arg ispec)))

(defun defun-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'defun arg ispec)))

(defun defun-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'defun arg ispec)))

(defun copy-defun-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'defun arg ispec)))

(defun kill-defun-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'defun)))

(defun defun-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'defun arg ispec)))

(defun bounds-of-defun-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'defun arg ispec)))

(defun defun-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'defun arg ispec)))

(defun defun-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'defun arg ispec)))

(defun copy-defun-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'defun arg ispec)))

(defun kill-defun-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'defun)))

;;;;

(defun filename-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'filename arg ispec))

(defun bounds-of-filename-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'filename arg ispec))

(defun filename-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'filename arg ispec))

(defun filename-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'filename arg ispec))

(defun copy-filename-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'filename arg ispec))

(defun kill-filename-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'filename))

(defun filename-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'filename arg ispec)))

(defun bounds-of-filename-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'filename arg ispec)))

(defun filename-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'filename arg ispec)))

(defun filename-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'filename arg ispec)))

(defun copy-filename-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'filename arg ispec)))

(defun kill-filename-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'filename)))

(defun filename-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'filename arg ispec)))

(defun bounds-of-filename-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'filename arg ispec)))

(defun filename-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'filename arg ispec)))

(defun filename-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'filename arg ispec)))

(defun copy-filename-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'filename arg ispec)))

(defun kill-filename-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'filename)))

;;;;

(defun whitespace-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'whitespace arg ispec))

(defun bounds-of-whitespace-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'whitespace arg ispec))

(defun whitespace-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'whitespace arg ispec))

(defun whitespace-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'whitespace arg ispec))

(defun copy-whitespace-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'whitespace arg ispec))

(defun kill-whitespace-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'whitespace))

(defun whitespace-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'whitespace arg ispec)))

(defun bounds-of-whitespace-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (thatpt-bounds 'whitespace arg ispec)))

(defun whitespace-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (thatpt-beginning 'whitespace arg ispec)))

(defun whitespace-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (thatpt-end 'whitespace arg ispec)))

(defun copy-whitespace-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (thatpt-copy 'whitespace arg ispec)))

(defun kill-whitespace-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward "^ \t\n\f")
    (thatpt-kill 'whitespace)))

(defun whitespace-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt 'whitespace arg ispec)))

(defun bounds-of-whitespace-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt-bounds 'whitespace arg ispec)))

(defun whitespace-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt-beginning 'whitespace arg ispec)))

(defun whitespace-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt-end 'whitespace arg ispec)))

(defun copy-whitespace-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt-copy 'whitespace arg ispec)))

(defun kill-whitespace-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward "^ \t\n\f")
    (thatpt-kill 'whitespace)))

;;;;

(defun url-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'url arg ispec))

(defun bounds-of-url-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'url arg ispec))

(defun url-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'url arg ispec))

(defun url-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'url arg ispec))

(defun copy-url-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'url arg ispec))

(defun kill-url-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'url))

(defun url-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'url arg ispec)))

(defun bounds-of-url-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'url arg ispec)))

(defun url-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'url arg ispec)))

(defun url-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'url arg ispec)))

(defun copy-url-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'url arg ispec)))

(defun kill-url-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'url)))

(defun url-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'url arg ispec)))

(defun bounds-of-url-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'url arg ispec)))

(defun url-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'url arg ispec)))

(defun url-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'url arg ispec)))

(defun copy-url-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'url arg ispec)))

(defun kill-url-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'url)))

;;;;

(defun number-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'number arg ispec))

(defun bounds-of-number-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'number arg ispec))

(defun number-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'number arg ispec))

(defun number-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'number arg ispec))

(defun copy-number-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'number arg ispec))

(defun kill-number-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'number))

(defun number-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'number arg ispec)))

(defun bounds-of-number-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'number arg ispec)))

(defun number-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'number arg ispec)))

(defun number-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'number arg ispec)))

(defun copy-number-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'number arg ispec)))

(defun kill-number-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'number)))

(defun number-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'number arg ispec)))

(defun bounds-of-number-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'number arg ispec)))

(defun number-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'number arg ispec)))

(defun number-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'number arg ispec)))

(defun copy-number-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'number arg ispec)))

(defun kill-number-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'number)))

;;;;

(defun float-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'float arg ispec))

(defun bounds-of-float-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'float arg ispec))

(defun float-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'float arg ispec))

(defun float-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'float arg ispec))

(defun copy-float-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'float arg ispec))

(defun kill-float-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'float))

(defun float-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'float arg ispec)))

(defun bounds-of-float-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'float arg ispec)))

(defun float-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'float arg ispec)))

(defun float-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'float arg ispec)))

(defun copy-float-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'float arg ispec)))

(defun kill-float-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'float)))

(defun float-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'float arg ispec)))

(defun bounds-of-float-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'float arg ispec)))

(defun float-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'float arg ispec)))

(defun float-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'float arg ispec)))

(defun copy-float-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'float arg ispec)))

(defun kill-float-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'float)))

;;;;

(defun page-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'page arg ispec))

(defun bounds-of-page-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'page arg ispec))

(defun page-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'page arg ispec))

(defun page-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'page arg ispec))

(defun copy-page-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'page arg ispec))

(defun kill-page-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'page))

(defun page-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'page arg ispec)))

(defun bounds-of-page-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'page arg ispec)))

(defun page-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'page arg ispec)))

(defun page-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'page arg ispec)))

(defun copy-page-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'page arg ispec)))

(defun kill-page-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'page)))

(defun page-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'page arg ispec)))

(defun bounds-of-page-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'page arg ispec)))

(defun page-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'page arg ispec)))

(defun page-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'page arg ispec)))

(defun copy-page-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'page arg ispec)))

(defun kill-page-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'page)))

;;;;

(defun sexp-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'sexp arg ispec))

(defun bounds-of-sexp-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'sexp arg ispec))

(defun sexp-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'sexp arg ispec))

(defun sexp-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'sexp arg ispec))

(defun copy-sexp-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'sexp arg ispec))

(defun kill-sexp-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'sexp))

(defun sexp-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'sexp arg ispec)))

(defun bounds-of-sexp-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'sexp arg ispec)))

(defun sexp-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'sexp arg ispec)))

(defun sexp-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'sexp arg ispec)))

(defun copy-sexp-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'sexp arg ispec)))

(defun kill-sexp-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'sexp)))

(defun sexp-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'sexp arg ispec)))

(defun bounds-of-sexp-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'sexp arg ispec)))

(defun sexp-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'sexp arg ispec)))

(defun sexp-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'sexp arg ispec)))

(defun copy-sexp-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'sexp arg ispec)))

(defun kill-sexp-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'sexp)))

;;;;

(defun paragraph-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt 'paragraph arg ispec))

(defun bounds-of-paragraph-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-bounds 'paragraph arg ispec))

(defun paragraph-atpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-beginning 'paragraph arg ispec))

(defun paragraph-atpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-end 'paragraph arg ispec))

(defun copy-paragraph-atpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (thatpt-copy 'paragraph arg ispec))

(defun kill-paragraph-atpt ()
  " "
  (interactive "*")
  (thatpt-kill 'paragraph))

(defun paragraph-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (when (eq 41 (char-before))
      (forward-char -1))
    (thatpt 'paragraph arg ispec)))

(defun bounds-of-paragraph-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-bounds 'paragraph arg ispec)))

(defun paragraph-bfpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-beginning 'paragraph arg ispec)))

(defun paragraph-bfpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-end 'paragraph arg ispec)))

(defun copy-paragraph-bfpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-copy 'paragraph arg ispec)))

(defun kill-paragraph-bfpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-backward " \t\n\f")
    (thatpt-kill 'paragraph)))

(defun paragraph-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt 'paragraph arg ispec)))

(defun bounds-of-paragraph-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-bounds 'paragraph arg ispec)))

(defun paragraph-afpt-beginning-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-beginning 'paragraph arg ispec)))

(defun paragraph-afpt-end-position (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-end 'paragraph arg ispec)))

(defun copy-paragraph-afpt (&optional arg ispec)
  " "
  (interactive "p\np")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-copy 'paragraph arg ispec)))

(defun kill-paragraph-afpt ()
  " "
  (interactive "*")
  (save-excursion
    (skip-chars-forward " \t\n\f")
    (thatpt-kill 'paragraph)))

;;;;

;; End of user-functions

;; As original bounds of things function starts with the end,
;; some functions have to be adapted in order to handle
;; beginning first

;; after thing-at-point-short-url-regexp

;; Phone

(put 'phone 'beginning-op
     (lambda ()
       (when
           (looking-at "[0-9 \t()-]")
         (re-search-backward "[^0-9 \t()-][0-9 ()\t-]+" (line-beginning-position) t 1) (forward-char 1))))

(put 'phone 'end-op
     (lambda ()
       (when
           (looking-at "[0-9;, \t()-]")
         (re-search-forward "[0-9 \t()-]+[^0-9 \t-\n]" (1+ (line-end-position)) t 1) (forward-char -1))))

;; (put 'phone 'beginning-op
;; (lambda ()
;; (when
;; (looking-at "[0-9 \t()-]")
;; (re-search-backward "\\([^0-9 \t()-]\\|^\\)[0-9 \t-]+" (line-beginning-position) t 1))))

;; (put 'phone 'end-op (lambda () (when
;; (looking-at "[0-9;, \t()-]")(re-search-forward "[0-9 \t()-]+[^0-9 \t-\n]" (1+ (line-end-position)) t 1))))

;; Text
;; Useful to extract texts between ml-tags

(put 'ml-text 'beginning-op
     (lambda ()
       (when
           (looking-at "[^>]")
         (re-search-backward ">" nil t 1)
         (forward-char 1))))

(put 'ml-text 'end-op (lambda () (re-search-forward "</" nil t 1) (forward-char -2)))

;; Email

(put 'email 'beginning-op
     (lambda ()
       (when
           (looking-at "[^ \t]")
         (re-search-backward "[,;][[:graph:]]\\|<[[:graph:]]\\|^[[:graph:]]\\|[^[:graph:]][[:graph:]]" (line-beginning-position) t 1)(when (looking-at "[[:space:];,]") (forward-char 1)))))

;; (put 'email 'end-op (lambda () (re-search-forward "[[:graph:]]+>\\|[[:graph:]]+@[[:graph:]]+[> \t\n]*" (line-end-position) t 1)))

(put 'email 'end-op (lambda () (when (looking-at "[ <]\\{0,1\\}\\([[:graph:]]+@[[:graph:]]+\\)[;,> \t\n]*")
                                 (goto-char (match-end 1)))))

;; Graphs

(put 'graphs 'beginning-op (lambda () (when (looking-at "[^ \t]") (skip-chars-backward "[:graph:]"))))

(put 'graphs 'end-op (lambda () (skip-chars-forward "[:graph:]")))

;; Whitespace

(put 'whitespace 'beginning-op (lambda () (when (looking-at "[ \t]") (skip-chars-backward " \t\n\f"))))

(put 'whitespace 'end-op (lambda () (skip-chars-forward " \t\n\f")))

;; Number

(put 'number 'beginning-op (lambda () (when (numberp (read (buffer-substring-no-properties (point) (1+ (point)))))
					(skip-chars-backward "[0-9]"))))

(put 'number 'end-op
     (lambda ()
       (skip-chars-forward "[0-9]")))

;; Floats

(put 'float 'beginning-op (lambda () (when (numberp (read (buffer-substring-no-properties (point) (1+ (point)))))
				       (skip-chars-backward "[0-9].,"))))

(put 'float 'end-op (lambda () (skip-chars-forward "[0-9.,]")))

;; Sexp

(defun beginning-of-sexp ()
  (let ((char-syntax (char-syntax (char-after (point)))))
    (if (eq char-syntax ?\))
        (backward-up-list)
      (when (and (eq char-syntax ?\") (in-string-p))
        (forward-char -1))
      (forward-sexp -1))))

;; Filename

(put 'filename 'beginning-op
     (lambda ()
       (re-search-backward (concat "[^" thing-at-point-file-name-chars "]") nil t)
       (forward-char 1)))

;; Defun

(put 'defun 'beginning-op (lambda (&optional arg) (beginning-of-defun (or arg 1))))

(put 'defun 'end-op (lambda (&optional arg)(end-of-defun (or arg 1))))

;; Lines

(put 'line 'beginning-op (lambda () (beginning-of-line)))

;; Strings

(put 'string 'beginning-op  (lambda () (goto-char (with-syntax-table (standard-syntax-table) (nth 8 (syntax-ppss)))) (forward-char 1)))

(put 'string 'end-op
     (lambda ()
       (re-search-forward (concat (list (nth 3 (with-syntax-table (standard-syntax-table) (syntax-ppss))))) nil t 1) (forward-char -1)))

;;  Lists  

(put 'list 'end-op (lambda () (forward-list 1)
                     ))

(put 'list 'beginning-op
     (lambda ()
       (or (looking-at "\\s(")
	   (when (nth 9 (syntax-ppss))
	     (goto-char (car (last (nth 9 (syntax-ppss)))))))))

(defun bounds-of-thatpt (thing &optional arg)
  "Determine the start and end buffer locations for the THING at point.
     THING is a symbol which specifies the kind of syntactic entity you want.
     Possibilities include `symbol', `list', `sexp', `defun', `filename', `url',
     `word', `sentence', `whitespace', `line', `page' and others."
  (condition-case nil
      (save-excursion
        (let ((orig (point))
              (beg (progn
                     (funcall ;; First, move to beg.
                      (or (get thing 'beginning-op)
                          (lambda ()
                            (forward-char 1)
                            (forward-thing thing -1))))
                     (point)))
              (end
               (progn (funcall ;; Then move to end.
                       (or (get thing 'end-op)
                           (lambda () (forward-thing thing 1))))
                      (point)))
              ;; jump back to see if pos is identic to beg
              (jumped-back
               (progn
                 (forward-char -1)
                 (funcall
                  (or (get thing 'beginning-op)
                      (lambda ()
                        (forward-thing thing -1))))
                 (point))))
          ;; if orig not between beg and end, failure, nil
          (when (and (= beg jumped-back) (<= beg orig) (<= orig end) (< beg end))
            (cons beg end))))
    (error nil)))

(defun thatpt-test ()
  " "
  (interactive)
  (let
      ((oldbuf (current-buffer))
       (thatpt-fnlist '(
                        phone-atpt
                        bounds-of-phone-atpt
                        phone-atpt-beginning-position
                        phone-atpt-end-position
                        copy-phone-atpt
                        phone-bfpt
                        bounds-of-phone-bfpt
                        phone-bfpt-beginning-position
                        phone-bfpt-end-position
                        copy-phone-bfpt
                        phone-afpt
                        bounds-of-phone-afpt
                        phone-afpt-beginning-position
                        phone-afpt-end-position
                        copy-phone-afpt
                        ml-text-atpt
                        bounds-of-ml-text-atpt
                        ml-text-atpt-beginning-position
                        ml-text-atpt-end-position
                        copy-ml-text-atpt
                        ml-text-bfpt
                        bounds-of-ml-text-bfpt
                        ml-text-bfpt-beginning-position
                        ml-text-bfpt-end-position
                        copy-ml-text-bfpt
                        ml-text-afpt
                        bounds-of-ml-text-afpt
                        ml-text-afpt-beginning-position
                        ml-text-afpt-end-position
                        copy-ml-text-afpt
                        email-atpt
                        bounds-of-email-atpt
                        email-atpt-beginning-position
                        email-atpt-end-position
                        copy-email-atpt
                        email-bfpt
                        bounds-of-email-bfpt
                        email-bfpt-beginning-position
                        email-bfpt-end-position
                        copy-email-bfpt
                        email-afpt
                        bounds-of-email-afpt
                        email-afpt-beginning-position
                        email-afpt-end-position
                        copy-email-afpt
                        graphs-atpt
                        bounds-of-graphs-atpt
                        graphs-atpt-beginning-position
                        graphs-atpt-end-position
                        copy-graphs-atpt
                        graphs-bfpt
                        bounds-of-graphs-bfpt
                        graphs-bfpt-beginning-position
                        graphs-bfpt-end-position
                        copy-graphs-bfpt
                        graphs-afpt
                        bounds-of-graphs-afpt
                        graphs-afpt-beginning-position
                        graphs-afpt-end-position
                        copy-graphs-afpt
                        string-atpt
                        bounds-of-string-atpt
                        string-atpt-beginning-position
                        string-atpt-end-position
                        copy-string-atpt
                        string-bfpt
                        bounds-of-string-bfpt
                        string-bfpt-beginning-position
                        string-bfpt-end-position
                        copy-string-bfpt
                        string-afpt
                        bounds-of-string-afpt
                        string-afpt-beginning-position
                        string-afpt-end-position
                        copy-string-afpt
                        list-atpt
                        bounds-of-list-atpt
                        list-atpt-beginning-position
                        list-atpt-end-position
                        copy-list-atpt
                        list-bfpt
                        bounds-of-list-bfpt
                        list-bfpt-beginning-position
                        list-bfpt-end-position
                        copy-list-bfpt
                        list-afpt
                        bounds-of-list-afpt
                        list-afpt-beginning-position
                        list-afpt-end-position
                        copy-list-afpt
                        symbol-atpt
                        bounds-of-symbol-atpt
                        symbol-atpt-beginning-position
                        symbol-atpt-end-position
                        copy-symbol-atpt
                        symbol-bfpt
                        bounds-of-symbol-bfpt
                        symbol-bfpt-beginning-position
                        symbol-bfpt-end-position
                        copy-symbol-bfpt
                        symbol-afpt
                        bounds-of-symbol-afpt
                        symbol-afpt-beginning-position
                        symbol-afpt-end-position
                        copy-symbol-afpt
                        line-atpt
                        bounds-of-line-atpt
                        line-atpt-beginning-position
                        line-atpt-end-position
                        copy-line-atpt
                        line-bfpt
                        bounds-of-line-bfpt
                        line-bfpt-beginning-position
                        line-bfpt-end-position
                        copy-line-bfpt
                        line-afpt
                        bounds-of-line-afpt
                        line-afpt-beginning-position
                        line-afpt-end-position
                        copy-line-afpt
                        word-atpt
                        bounds-of-word-atpt
                        word-atpt-beginning-position
                        word-atpt-end-position
                        copy-word-atpt
                        word-bfpt
                        bounds-of-word-bfpt
                        word-bfpt-beginning-position
                        word-bfpt-end-position
                        copy-word-bfpt
                        word-afpt
                        bounds-of-word-afpt
                        word-afpt-beginning-position
                        word-afpt-end-position
                        copy-word-afpt
                        sentence-atpt
                        bounds-of-sentence-atpt
                        sentence-atpt-beginning-position
                        sentence-atpt-end-position
                        copy-sentence-atpt
                        sentence-bfpt
                        bounds-of-sentence-bfpt
                        sentence-bfpt-beginning-position
                        sentence-bfpt-end-position
                        copy-sentence-bfpt
                        sentence-afpt
                        bounds-of-sentence-afpt
                        sentence-afpt-beginning-position
                        sentence-afpt-end-position
                        copy-sentence-afpt
                        defun-atpt
                        bounds-of-defun-atpt
                        defun-atpt-beginning-position
                        defun-atpt-end-position
                        copy-defun-atpt
                        defun-bfpt
                        bounds-of-defun-bfpt
                        defun-bfpt-beginning-position
                        defun-bfpt-end-position
                        copy-defun-bfpt
                        defun-afpt
                        bounds-of-defun-afpt
                        defun-afpt-beginning-position
                        defun-afpt-end-position
                        copy-defun-afpt
                        filename-atpt
                        bounds-of-filename-atpt
                        filename-atpt-beginning-position
                        filename-atpt-end-position
                        copy-filename-atpt
                        filename-bfpt
                        bounds-of-filename-bfpt
                        filename-bfpt-beginning-position
                        filename-bfpt-end-position
                        copy-filename-bfpt
                        filename-afpt
                        bounds-of-filename-afpt
                        filename-afpt-beginning-position
                        filename-afpt-end-position
                        copy-filename-afpt
                        whitespace-atpt
                        bounds-of-whitespace-atpt
                        whitespace-atpt-beginning-position
                        whitespace-atpt-end-position
                        copy-whitespace-atpt
                        whitespace-bfpt
                        bounds-of-whitespace-bfpt
                        whitespace-bfpt-beginning-position
                        whitespace-bfpt-end-position
                        copy-whitespace-bfpt
                        whitespace-afpt
                        bounds-of-whitespace-afpt
                        whitespace-afpt-beginning-position
                        whitespace-afpt-end-position
                        copy-whitespace-afpt
                        url-atpt
                        bounds-of-url-atpt
                        url-atpt-beginning-position
                        url-atpt-end-position
                        copy-url-atpt
                        url-bfpt
                        bounds-of-url-bfpt
                        url-bfpt-beginning-position
                        url-bfpt-end-position
                        copy-url-bfpt
                        url-afpt
                        bounds-of-url-afpt
                        url-afpt-beginning-position
                        url-afpt-end-position
                        copy-url-afpt
                        number-atpt
                        bounds-of-number-atpt
                        number-atpt-beginning-position
                        number-atpt-end-position
                        copy-number-atpt
                        number-bfpt
                        bounds-of-number-bfpt
                        number-bfpt-beginning-position
                        number-bfpt-end-position
                        copy-number-bfpt
                        number-afpt
                        bounds-of-number-afpt
                        number-afpt-beginning-position
                        number-afpt-end-position
                        copy-number-afpt
                        float-atpt
                        bounds-of-float-atpt
                        float-atpt-beginning-position
                        float-atpt-end-position
                        copy-float-atpt
                        float-bfpt
                        bounds-of-float-bfpt
                        float-bfpt-beginning-position
                        float-bfpt-end-position
                        copy-float-bfpt
                        float-afpt
                        bounds-of-float-afpt
                        float-afpt-beginning-position
                        float-afpt-end-position
                        copy-float-afpt
                        page-atpt
                        bounds-of-page-atpt
                        page-atpt-beginning-position
                        page-atpt-end-position
                        copy-page-atpt
                        page-bfpt
                        bounds-of-page-bfpt
                        page-bfpt-beginning-position
                        page-bfpt-end-position
                        copy-page-bfpt
                        page-afpt
                        bounds-of-page-afpt
                        page-afpt-beginning-position
                        page-afpt-end-position
                        copy-page-afpt
                        sexp-atpt
                        bounds-of-sexp-atpt
                        sexp-atpt-beginning-position
                        sexp-atpt-end-position
                        copy-sexp-atpt
                        sexp-bfpt
                        bounds-of-sexp-bfpt
                        sexp-bfpt-beginning-position
                        sexp-bfpt-end-position
                        copy-sexp-bfpt
                        sexp-afpt
                        bounds-of-sexp-afpt
                        sexp-afpt-beginning-position
                        sexp-afpt-end-position
                        copy-sexp-afpt
                        paragraph-atpt
                        bounds-of-paragraph-atpt
                        paragraph-atpt-beginning-position
                        paragraph-atpt-end-position
                        copy-paragraph-atpt
                        paragraph-bfpt
                        bounds-of-paragraph-bfpt
                        paragraph-bfpt-beginning-position
                        paragraph-bfpt-end-position
                        copy-paragraph-bfpt
                        paragraph-afpt
                        bounds-of-paragraph-afpt
                        paragraph-afpt-beginning-position
                        paragraph-afpt-end-position
                        copy-paragraph-afpt)))
    (save-excursion
      (set-buffer (get-buffer-create "thatpt-test"))
      (erase-buffer))
    (dolist (elt thatpt-fnlist)
      (let ((item (funcall elt)))
        (save-excursion
          (switch-to-buffer "thatpt-test")
          (when (listp item)
            (setq item (concat (format "%s" (car item))" "(format "%s" (cadr item)))))
          (insert (concat (format "%s: " elt) (format "%s \n" item))))))))

(defun thatpt (thing &optional arg ispec)
  " "
  (let* ((bounds (bounds-of-thatpt thing arg))
         (type (if bounds
                   (buffer-substring-no-properties (car bounds) (cdr bounds))
                 nil)))
    (if ispec
        (if type
            (progn
              (if (eq thing 'whitespace)
                  (kill-new type)
                (kill-new (string-strip type)))
              (message "%s" (car kill-ring)))
          (message "%s" "nil"))
      type)))

(defun thatpt-bounds (thing &optional arg ispec)
  "Returns begin and end positions of a buffer substring
according to THING.
THING may be a well known form as `symbol',
`list', `sexp', `defun'.
thatpt-bounds returns a cons (beg . end)
of them near point if any suitable - nil otherwise.
You may also define new and abstract kinds of THING.
See example given in thingatpt-util.el.
Called interactively, it always copies thing-at-point
as it's the most common use and faster than copy-thing."
  (let* ((bounds (bounds-of-thatpt thing arg))
         (start (car bounds))
         (end (cdr bounds)))
    (when ispec
      (message "%s %s" start end))
    (list start end)))

(defun thatpt-beginning (thing &optional arg ispec)
  (let* ((bounds (bounds-of-thatpt thing arg))
         (start (car bounds)))
    (when ispec
      (message "%s " start))
    start))

(defun thatpt-end (thing &optional arg ispec)
  (let* ((bounds (bounds-of-thatpt thing arg))
         (end (cdr bounds)))
    (when ispec
      (message "%s "  end))
    end))

(defun thatpt-copy (thing &optional arg ispec)
  (let ((newcopy (thatpt thing arg)))
    (if newcopy
        (progn
          (kill-new (thatpt thing arg))
          (if ispec
              (message "%s" (car kill-ring))
            (car kill-ring)))
      nil)))

(defun thatpt-kill (thing &optional arg)
  " "
  (let* ((arg (or arg 1))
         (bounds (bounds-of-thatpt thing arg))
         (start (car bounds))
         (end (cdr bounds)))
    (kill-region start end)))

(defun string-strip (str)
  "Return a copy of STR with leading and trailing chars according to regexp removed."
  (save-match-data
    (string-match
     "\\`[[:space:],;\/\n]*\\(\\(?:.\\|\n\\)*?\\)[[:space:],;\n]*\\'" str)
    (match-string 1 str)))

(provide 'thingatpt-util)

;;; thatpt-util.el ends here
