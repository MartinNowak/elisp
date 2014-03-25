;;; search-utils.el --- Search Utilities
;;
;; Filename: search-utils.el
;; Description:
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jun 25 16:43:47 2009 (+0200)
;; Version:
;; Last-Updated: fre dec 18 21:16:34 2009 (+0100)
;;     Update #: 6
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

(defun re-search-forward-case-sensitive (regexp &optional bound noerror count)
  "Wrapper for re-search-forward that locally binds case-fold-search to
nil to force a case-sensitive search."
  (let ((case-fold-search nil))
    (re-search-forward regexp bound noerror count)))

;; ToDo: Change prompt to "I-search (case-sensitive): "
(defun isearch-forward-case-sensitive (&optional regexp-p no-recursive-edit)
  "Wrapper for isearch-forward that locally binds case-fold-search to
nil to force a case-sensitive search."
  (interactive "P\np")
  (let ((case-fold-search nil))
    (isearch-forward regexp-p no-recursive-edit)))

;;(global-set-key [(control shift s)] 'isearch-forward-case-sensitive)

(defun re-search-backward-case-sensitive (regexp &optional bound noerror count)
  "Wrapper for re-search-backward that locally binds case-fold-search to
nil to force a case-sensitive search."
  (let ((case-fold-search nil))
    (re-search-backward regexp bound noerror count)))

;; ToDo: Change prompt to "I-search (case-sensitive): "
(defun isearch-backward-case-sensitive (&optional regexp-p no-recursive-edit)
  "Wrapper for isearch-backward that locally binds case-fold-search to
nil to force a case-sensitive search."
  (interactive "P\np")
  (let ((case-fold-search nil))
    (isearch-backward regexp-p no-recursive-edit)))

;;(global-set-key [(control shift r)] 'isearch-backward-case-sensitive)

(provide 'search-utils)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; search-utils.el ends here
