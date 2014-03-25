;;; edit-variable.el --- Edit the value of a variable.
;;
;; Filename: edit-variable.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: ons maj 28 08:51:10 2008 (CEST)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 0
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   None
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

(defvar edit-variable-buffer)
(defvar edit-variable-symbol)

(make-variable-buffer-local 'edit-variable-buffer)
(make-variable-buffer-local 'edit-variable-symbol)

(defun edit-variable (variable)
  "Edit the value of VARIABLE."
  (interactive (list (completing-read "Name: " obarray 'boundp)))
  (let* ((symbol (intern variable))
         (value (symbol-value symbol))
         (buffer (current-buffer)))
    (with-current-buffer (get-buffer-create (format "*var %s*" variable))
      (erase-buffer)
      (emacs-lisp-mode)
      (setq edit-variable-buffer buffer
            edit-variable-symbol symbol)
      (insert (pp-to-string value))
      (goto-char (point-min))
      (window-configuration-to-register ?V)
      (select-window (display-buffer (current-buffer)))
      (define-key (current-local-map) [(control ?c) (control ?c)]
        (function
         (lambda ()
           (interactive)
           (goto-char (point-min))
           (let ((symbol edit-variable-symbol)
                 (value (read (current-buffer))))
             (with-current-buffer edit-variable-buffer
               (set symbol value)))
           (jump-to-register ?V)))))))

(provide 'edit-variable)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; edit-variable.el ends here
