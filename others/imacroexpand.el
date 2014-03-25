;;; imacroexpand.el --- interactive Emacs lisp macro expansion

;; Copyright (C) 2007 David Hansen

;; Author:   David Hansen <david.hansen@physik.fu-berlin.de>
;; Version:  0.2
;; Keywords: lisp languages

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides interactive macro expansion for Emacs lisp code.  It
;; displays the macro expansion of the sexp at point in a seperate window and
;; allows further expansion in that buffer (similar to what SLIMEs
;; `slime-macroexpand-1' does for CL code).

;; To install this package put the file somewhere in your `load-path',
;; optionally byte compile it, and add the following lines to you ~/.emacs:

;; (autoload #'imacroexpand "imacroexpand" "interactive macro expansion" t)
;; ;; optional, same key-binding as in SLIME
;; (define-key emacs-lisp-mode-map (kbd "C-c RET") #'imacroexpand)

;;; ChangeLog:

;; 0.2:

;;  * Description of the package in the "Commentary" section.

(require 'thingatpt)

(defconst imx--buffer-name "*elisp macroexpansion*")

(defvar imx--buffer nil)

(define-derived-mode elisp-macroexpand-mode emacs-lisp-mode "Macro Expansion"
  "Major mode for displaying Emacs Lisp macro expansions."
  (setq buffer-read-only t))

(define-key elisp-macroexpand-mode-map (kbd "C-c RET") #'imacroexpand)
(define-key elisp-macroexpand-mode-map (kbd "q") #'bury-buffer)
(define-key elisp-macroexpand-mode-map (kbd "SPC") #'scroll-up)
(define-key elisp-macroexpand-mode-map (kbd "DEL") #'scroll-down)

(defun imx--set-up-buffer ()
  (unless (buffer-live-p imx--buffer)
    (setq imx--buffer (generate-new-buffer imx--buffer-name)))
  (with-current-buffer imx--buffer
    (or (eq major-mode 'elisp-macroexpand-mode) (elisp-macroexpand-mode))))

(defun imacroexpand (arg)
  "Display the macro expansion of the form at point.
The form is expanded with `macroexpand' or, if the prefix is given, with
`macroexpand-all'."
  (interactive "P")
  (imx--set-up-buffer)
  (let* ((buffer (current-buffer))
         (bounds (bounds-of-thing-at-point 'sexp))
         (sexp (if bounds
                   (funcall (if arg
                                #'macroexpand-all
                              #'macroexpand)
                            (car (read-from-string
                                  (buffer-substring (car bounds)
                                                    (cdr bounds)))))
                 (error "No expression at point"))))
    (with-current-buffer imx--buffer
      (when (eq buffer imx--buffer)
        (setq sexp (car (read-from-string
                         (concat (buffer-substring (point-min)
                                                   (car bounds))
                                 (prin1-to-string sexp)
                                 (buffer-substring (cdr bounds)
                                                   (point-max)))))))
      (let ((inhibit-read-only t))
        (delete-region (point-min) (point-max))
        (save-excursion
          (pp sexp imx--buffer)))
      (when (eq buffer imx--buffer)
        ;; when "restoring" point we assume that `pp' formats the part before
        ;; the macroexpansion the same way it did before.
        (goto-char (car bounds))
        (forward-sexp 1)
        (backward-char 1))))
  (display-buffer imx--buffer))

(provide 'imacroexpand)