;;; gcalc.el --- A Google calculator interface

;; Copyright (C) 2007 Daniel Jensen

;; Author: Daniel Jensen <dan...@bigwalter.net>
;; Created: 2007-05-27
;; Updated: 2007-05-28
;; Version: 2
;; Keywords: google calculator

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

;;; Commentary:

;; Installation -- Put the file in your load path and use the
;; following in your init file.
;;
;; (autoload 'gcalc "gcalc" "A Google calculator interface." t)
;;
;; To use the Google calculator, enter `M-x gcalc RET expression RET'.
;; See <http://www.google.com/help/calculator.html> for instructions
;; on how to formulate expressions for the calculator. See also
;; <http://www.google.com/help/features.html#currency> for help with
;; currency conversion.
;;
;; Note that this interface does not use a Google API. Therefore you
;; don't need a license from Google to use it, but it's vulnerable to
;; changes in Google's HTML code. If you find that something is
;; broken, please report it to the author.
;;
;; This program uses the url package distributed with Emacs 22.

;;; Code:

(require 'url)

(defgroup gcalc nil
  "A Google calculator interface."
  :group 'external)

(defcustom gcalc-thousands-separator ","
  "Thousands separator for Google calculator results."
  :type 'string
  :group 'gcalc)

(defcustom gcalc-strip-expressions nil
  "Non-nil means expressions will be stripped from results.
The default is to show Google's interpretation of the original
expression together with the result."
  :type 'boolean
  :group 'gcalc)

(defcustom gcalc-copy-results-to-kill-ring nil
  "Non-nil means results will be copied to the kill ring."
  :type 'boolean
  :group 'gcalc)

(defun gcalc-calculate-expression (expression)
  "Parse and return the Google calculator result for EXPRESSION."
  (with-current-buffer (let ((url-show-status nil))
                         (url-retrieve-synchronously
                          (concat "http://www.google.com/search?q="
                                  (url-hexify-string expression))))
    (goto-char (point-min))
    (when (re-search-forward "<font size=\\+1><b>\\(.*?\\)</b>" nil t)
      (let ((result (match-string 1)))
        (setq result (replace-regexp-in-string "&#215;" "*" result))
        (setq result (replace-regexp-in-string "<sup>\\(.+?\\)</sup>"
                                               "^(\\1)" result))
        (setq result
              (replace-regexp-in-string "<font size=-2>\\s +?</font>"
                                        gcalc-thousands-separator result))
        (when gcalc-strip-expressions
          (setq result (cadr (split-string result "\\s +=\\s +"))))
        (kill-buffer (current-buffer))
        result))))

(defvar gcalc-history nil
  "History list of Google calculator expressions.")

;;;###autoload
(defun gcalc (expression &optional insert-result-p)
  "Ask the Google calculator for the answer to an expression.
With prefix argument, insert the result at point.
With `gcalc-copy-results-to-kill-ring' set to true, copy the
result to the kill ring."
  (interactive
   (list (read-string "Google calculator: " nil 'gcalc-history)
         current-prefix-arg))
  (let ((result (gcalc-calculate-expression expression)))
    (if (null result)
        (message "No result for `%s'." expression)
      (when gcalc-copy-results-to-kill-ring
        (kill-new result))
      (if (not insert-result-p)
          (message "%s" result)
        (push-mark)
        (insert result)))))

(provide 'gcalc)

;;; gcalc.el ends here
