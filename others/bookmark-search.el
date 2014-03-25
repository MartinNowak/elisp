;;; bookmark-search.el --- Provide a search command for emacs bookmarks ala anything. 

;; Author: ThierryVolpiatto 
;; Maintainer: ThierryVolpiatto

;; Created: jeu. oct. 15 13:26:19 2009 (+0200)

;; X-URL: http://mercurial.intuxication.org/hg/bookmark-search
;; Keywords: bookmarks, search. 
;; Compatibility: Tested with emacs23.*

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Things Defined Here
;;  -------------------

;;  [UPDATE ALL EVAL] (traverse-auto-update-documentation)

;;; ;;  * Vanilla bookmark Functions redefined here
;; [EVAL] (traverse-auto-document-lisp-buffer :type 'function :prefix "^bookmark")
;; `bookmark-maybe-sort-alist'
;; `bookmark-bmenu-bookmark'

;;  * Commands defined here
;; [EVAL] (traverse-auto-document-lisp-buffer :type 'command :prefix "sbookmark")
;; `sbookmark-bmenu-search'

;;  * Functions defined here
;; [EVAL] (traverse-auto-document-lisp-buffer :type 'function :prefix "sbookmark")
;; `sbookmark-read-search-input'
;; `sbookmark-filtered-alist-by-regexp-only'
;; `sbookmark-bmenu-filter-alist-by-regexp'
;; `sbookmark-bmenu-search'
;; `sbookmark-bmenu-cancel-search'

;;  * Internals Variables defined here
;; [EVAL] (traverse-auto-document-lisp-buffer :type 'internal-variable :prefix "sbookmark")
;; `sbookmark-search-pattern'
;; `sbookmark-search-timer'
;; `sbookmark-latest-sorted-alist'

;;  *** END auto-documentation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Commentary:
;;  ----------

;; This file provide A search command `sbookmark-bmenu-search' (M-g) to Emacs bookmarks.
;; That allow narrowing the bookmark list depending on what you enter in prompt.
;; This command is incremental and work a little like ANYTHING.
;; You can use this library with VANILLA BOOKMARK.(bookmark.el)
;; No extra dependency is needed.

;;; Usage:
;;  -----

;; Add this file to your `load-path'.
;; (require 'bookmark-search)
;; After getting the bookmark list with C-x r l, use M-g and enter characters.
;; Use DEL to remove characters from prompt.
;; Quit searching with RET or ESC or C-g.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
;;; Code:
(require 'bookmark)
(eval-when-compile (require 'cl))

(defcustom sbookmark-search-delay 0.2
  "*Display when searching bookmarks is updated all `bookmarkp-search-delay' seconds."
  :group 'bookmark
  :type  'integer)

(defcustom sbookmark-search-prompt "Pattern: "
  "*Prompt used for `bookmarkp-bmenu-search'."
  :group 'bookmark
  :type  'string)

;;; Internal variables
(defvar sbookmark-search-pattern "")
(defvar sbookmark-search-timer nil)
(defvar sbookmark-latest-sorted-alist nil)

;;; Keymap
;;;###autoload
(define-key bookmark-bmenu-mode-map (kbd "M-g") 'sbookmark-bmenu-search)

;; REPLACES ORIGINAL in `bookmark.el'.
;;
;; Set `sbookmark-latest-sorted-alist' to a copy of `bookmark-alist' sorted.
;;
(defun bookmark-maybe-sort-alist ()
  "Return a sorted copy of `bookmark-alist'.
If `bookmark-sort-flag' is nil return `bookmark-alist'.
The sorted copy of `bookmark-alist' is set to `sbookmark-latest-sorted-alist'."
  (let ((bmk-alist (copy-alist bookmark-alist)))
    (if bookmark-sort-flag
        (setq sbookmark-latest-sorted-alist
              (sort bmk-alist #'(lambda (x y) (string-lessp (car x) (car y)))))
        (setq sbookmark-latest-sorted-alist bookmark-alist))))

;; REPLACES ORIGINAL in `bookmark.el'.
;;
;; Get bookmark name with position in the sorted `bookmark-alist'.
;; No need to toggle filenames when operating on bmenu-list.
;; Much faster than vanilla bookmark code.
;;
(defun bookmark-bmenu-bookmark ()
  "Return a string which is bookmark of this line."
  (let ((pos (- (line-number-at-pos) 3)))
    (car (nth pos sbookmark-latest-sorted-alist))))


(defun sbookmark-read-search-input ()
  "Read each keyboard input and add it to `sbookmark-search-pattern'."
  (setq sbookmark-search-pattern "")    ; Always reset pattern to empty string
  (let (char
        (tmp-list ()))
    (catch 'break
      (while 1
        (catch 'continue
          (condition-case nil
              (setq char (read-char         ; Read character from prompt
                          (concat (propertize sbookmark-search-prompt
                                              'face '((:foreground "cyan"))) sbookmark-search-pattern)))
            (error (throw 'break nil)))
          (case char
            ((or ?\e ?\r) (throw 'break nil))    ; RET or ESC break and exit code.
            (?\d (pop tmp-list)         ; Delete last char of `sbookmark-search-pattern' with DEL
                 (setq sbookmark-search-pattern (mapconcat 'identity (reverse tmp-list) ""))
                 (throw 'continue nil))
            (t
             (push (text-char-description char) tmp-list)
             (setq sbookmark-search-pattern (mapconcat 'identity (reverse tmp-list) ""))
             (throw 'continue nil))))))))


(defun sbookmark-filtered-alist-by-regexp-only (regexp)
  "Return a filtered `sbookmark-alist' with bookmarks matching REGEXP."
  (loop for i in bookmark-alist
     when (string-match regexp (car i)) collect i into new
     finally return new))

(defun sbookmark-bmenu-filter-alist-by-regexp (regexp)
  "Filter `sbookmark-alist' with bookmarks matching REGEXP and rebuild list."
  (let ((bookmark-alist (sbookmark-filtered-alist-by-regexp-only regexp)))
    (bookmark-bmenu-list)))

;;;###autoload
(defun sbookmark-bmenu-search ()
  "Incremental search of bookmarks matching `bookmarkp-search-pattern'."
  (interactive)
  (unwind-protect
       (progn
         (setq sbookmark-search-timer
               (run-with-idle-timer sbookmark-search-delay 'repeat
                                    #'(lambda ()
                                        (sbookmark-bmenu-filter-alist-by-regexp sbookmark-search-pattern))))
         (sbookmark-read-search-input))
    (sbookmark-bmenu-cancel-search)))

(defun sbookmark-bmenu-cancel-search ()
  "Cancel timer used for searching in bookmarks."
  (cancel-timer sbookmark-search-timer)
  (setq sbookmark-search-timer nil))

(provide 'bookmark-search)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; bookmark-search.el ends here
