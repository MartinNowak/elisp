;;; rcirc-late-fix.el --- Replace s/wrong/right strings on rcirc buffers
;; Copyright 2007  Hugo Schmitt <hugows@gmail.com>
;; Copyright 2011  Elias Pipping <pipping@exherbo.org>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; The idea is to detect messages like 's/tset/test' and overwrite the
;; wrong word with the correction, on the original phrase, using
;; overlays.

;; Please mail me (hugows@gmail.com) about any improvements or bug
;; reports you have regarding this file.

;;; Changes (16/07/2011) by Elias Pipping
;; [x] Use rcirc-response-formats for building the name string
;; [x] Support s/word// and s/word//g for removing matching text
;; [x] s/a/b/g bug for input "aaaaaa" fixed
;;
;; plus some cleanup/improvements

;;; Changes (31/01/2011) Fix two warnings

;;; Changes (11/12/2007) (Tks tsdh for the suggestions)

;; [x] Exclude the nicknames from correction.
;; [x] Strip the / from the replacement text.
;; [x] With s/foo/bar the last occurence of foo is replaced with bar, not the first.
;; [x] Support s/foo/bar/g to replace all occurences of foo with bar.
;; [ ] Use rcirc-response-formats for building the name string
;; [ ] A variable could control whether only whole words are changed (then
;; just concat "<" word ">")
;; [ ] Support s/word// and s/word//g for removing matching text

;;; Code:

(eval-when-compile (require 'cl))

(require 'rcirc)

(add-hook 'rcirc-print-hooks 'rcirc-late-fix-hook)

(defface rcirc-late-fix-face '((t (:underline t :foreground "Blue")))
  "Face for showing fixed words on the channel buffer."
  :group 'rcirc-faces)

(defun rcirc-late-fix-hook (process sender response target text)
  (save-excursion
    (when (string-equal response "PRIVMSG")
      (when (string-match "^s/\\([^/]+\\)/\\([^/]*\\)/\\(g?\\)$" text)
	(let ((from (match-string 1 text))
	      (to (propertize
		   (if (string= "" (match-string 2 text)) "_" (match-string 2 text))
		   'face 'rcirc-late-fix-face))
	      (global (not (string= "" (match-string 3 text)))))
	  (set-buffer (rcirc-late-fix-matching-buffer target))
	  (goto-char (point-max))
	  (when (search-backward-regexp
		 (rcirc-format-response-string process sender "PRIVMSG" target "\\(.*\\)") nil t 2)
	    (if (not global)
		(if (search-forward from (save-excursion (search-forward "\n")) t)
		    (replace-match to))
	      (while (search-forward from (save-excursion (search-forward "\n")) t)
		(replace-match to)))))))))

(defun rcirc-late-fix-matching-buffer (name)
  "Find buffer (channel) that starts with NAME."
  (find-if '(lambda (x) (string-match (concat "^" name) x))
           (mapcar 'buffer-name (buffer-list))))



;;; rcirc-late-fix.el ends here
(provide 'rcirc-late-fix)
