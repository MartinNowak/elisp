;;; calc-util.el --- Calculator Utililites
;;
;; Filename: calc-util.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: ons maj 28 10:09:57 2008 (CEST)
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

;; Calculate sum. Mark a region containing numbers and then call this function.
;; Try with the Fibonacci numbers: 1, 1, 2, 3, 5, 8, 13, 21, ...

(defun calculator-sum-row (start end)
  "Adds numbers in rectangle."
  (interactive "r")
  (save-excursion                  ;function doesn't affect the cursor
    (kill-rectangle start end)
    (exchange-point-and-mark)
    (yank-rectangle)
    (set-buffer (get-buffer-create "*calc-sum*"))
    (erase-buffer)
    (yank-rectangle)
    (exchange-point-and-mark-nomark)
    (let ((sum 0))
      (while (re-search-forward "[0-9]*\\.?[0-9]+" nil t)
        (setq sum (+ sum (string-to-number (match-string 0)))))
      (message "Sum: %f" sum))))

(defun calculator-product-row (start end)
  "Multiply numbers in rectangle."
  (interactive "r")
  (save-excursion                  ;function doesn't affect the cursor
    (kill-rectangle start end)
    (exchange-point-and-mark)
    (yank-rectangle)
    (set-buffer (get-buffer-create "*calc-prod*"))
    (erase-buffer)
    (yank-rectangle)
    (exchange-point-and-mark-nomark)
    (let ((prod 1))
      (while (re-search-forward "[0-9]*\\.?[0-9]+" nil t)
        (setq prod (* prod (string-to-number (match-string 0)))))
      (message "Product: %f" prod))))

(provide 'calc-util)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; calc-util.el ends here
