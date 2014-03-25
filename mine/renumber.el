;;; renumber.el --- Renumbering Utilies.
;;
;; Filename: renumber.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: ons maj 28 09:42:46 2008 (CEST)
;; Version:
;; Last-Updated:
;;           By:
;;     Update #: 2
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

;; Renumber paragraph. Use prefixing along with this function.
(defun renumber-paragraph (&optional num)
  "Renumber the list items in the current paragraph,
    starting at point."
  (interactive "p")
  (setq num (or num 1))
  (let ((end
         (save-excursion           ;function doesn't affect the cursor
           (forward-paragraph)
           (point))))
    (while (re-search-forward "^[0-9]+" end t)
      (replace-match (number-to-string num))
      (setq num (1+ num)))))

;; Here is an alternative version that does the same thing but for the
;; current region instead of paragraph. It's good if you, like me,
;; have set paragraph-start and paragraph-separate to treat each list
;; item as a separate paragraph.
(defun renumber-list (start end &optional num)
  "Renumber the list items in the current START..END region.
  If optional prefix arg NUM is given, start numbering from that number
  instead of 1."
  (interactive "*r\np")
  (save-excursion                  ;function doesn't affect the cursor
    (goto-char start)
    (setq num (or num 1))
    (save-match-data
      (while (re-search-forward "^[0-9]+" end t) ;number at beginning of line
        (replace-match (number-to-string num))
        (setq num (1+ num))))))

(provide 'renumber)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; renumber.el ends here
