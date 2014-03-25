;;; outline-ext.el --- extensions to outline
;;
;; Filename: outline-ext.el
;; Description: Extensions to outline.el
;; Author: Per Nordlöw
;; Maintainer:
;; Created: tor jul  3 16:15:23 2008 (CEST)
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
;; Code copied from http://www.emacswiki.org/cgi-bin/wiki/OutlineMinorMode
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

(defun body-p ()
  (save-excursion
    (outline-back-to-heading)
    (outline-end-of-heading)
    (and (not (eobp))
         (progn (forward-char 1)
                (not (outline-on-heading-p))))))

(defun body-visible-p ()
  (save-excursion
    (outline-back-to-heading)
    (outline-end-of-heading)
    (not (outline-invisible-p))))

(defun subheadings-p ()
  (save-excursion
    (outline-back-to-heading)
    (let ((level (outline-level)))
      (outline-next-heading)
      (and (not (eobp))
           (< level (outline-level))))))

(defun subheadings-visible-p ()
  (interactive)
  (save-excursion
    (outline-next-heading)
    (not (outline-invisible-p))))

(defun outline-do-close ()
  (interactive)
  (if (outline-on-heading-p)
      (cond ((and (body-p) (body-visible-p))
             (hide-entry))
            ((and (subheadings-p)
                  (subheadings-visible-p))
             (hide-subtree))
            (t (outline-previous-visible-heading 1)))
    (outline-back-to-heading t)))

(defun outline-do-open ()
  (interactive)
  (if (outline-on-heading-p)
      (cond ((and (subheadings-p)
                  (not (subheadings-visible-p)))
             (show-children))
            ((and (body-p)
                  (not (body-visible-p)))
             (show-entry))
            (t (show-entry)))
    (outline-next-visible-heading 1)))

;;; Explorer like Key-Bindings
(when nil
  (define-key outline-mode-map '[left] 'outline-do-close)
  (define-key outline-mode-map '[right] 'outline-do-open)
  (define-key outline-minor-mode-map '[left] 'outline-do-close)
  (define-key outline-minor-mode-map '[right] 'outline-do-open)
  )

(when nil
;;; For years i wanted to modify outline-minor-mode, so that comments
;;; starting at the beginning of line were left visible. Now I add the
;;; condition that they dont get marked as headers. Heres the code:
  (defun outline-flag-region-make-overlay (from to) ;mmc
    (let ((o (make-overlay from to)))
      (overlay-put o 'invisible 'outline)
      (overlay-put o 'isearch-open-invisible
                   'outline-isearch-open-invisible)
      o))
  (defun outline-flag-region (from to flag) ;mmc
    "Hides or shows lines from FROM to TO, according to FLAG.
If FLAG is nil then text is shown, while if FLAG is t the text is hidden."
    (save-excursion
      (goto-char from)
      (end-of-line)
      ;; FIXME: outline-discard-overlays is not defined anymore.
      (outline-discard-overlays (point) to 'outline)
      (if flag
          ;;
          (let ((beginning (point))
                (regexp (concat "^" (regexp-quote comment-start)))
                )
            (while (re-search-forward regexp to 't)
              (goto-char (match-beginning 0))
              (if (> (- (point) beginning) 2)
                  (outline-flag-region-make-overlay beginning (point)))
                                        ;(goto-char
              (end-of-line)
              (setq beginning (point)))
            (outline-flag-region-make-overlay beginning to)))
      (run-hooks 'outline-view-change-hook)))
  )

(provide 'outline-ext)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; outline-ext.el ends here
