;;; w3m-config.el --- 

;; Copyright 2004 Bastien Guerry
;;
;; Author: Bastien.Guerry@ens.fr
;; Version: $Id: w3m-config.el,v 0.0 2004/01/13 15:40:04 guerry Exp $
;; Keywords: w3m config
;; Time-stamp: <2008-01-24 05:00:49 guerry>
;; X-URL: not distributed yet

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; 

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'w3m-config)

;;; Code:

(require 'url)
;; FIXME (require 'w3m-ems)
;; (load "~/install/cvs/emacs-w3m/w3m.el")
(load "~/install/cvs/emacs-w3m/w3m-ems.el")
;;(load "~/install/cvs/emacs-w3m/w3m-search.el")

(require 'w3m)
(require 'w3m-ems)
(require 'w3m-load)
(require 'w3m-search)
(require 'w3m-cookie)
(require 'org nil t)
(require 'mm-url)
(require 'webjump)

(load "~/install/cvs/emacs-w3m/w3m.el")

(define-key w3m-mode-map "\C-ct" 'bzg-insert-url-as-current-todo)
(define-key w3m-mode-map "P" 'bzg-w3m-delicious-post-url)
(define-key w3m-mode-map "K" 'bzg-get-tinyurl)
(define-key w3m-mode-map "%" 'bzg-w3m-local-bmk-url)

(defvar w3m-delicious-login "bzg" "Login for del.icio.us")
(defvar webjump-sites-file "~/.emacs.webjump" "Webjump file")

(defvar bzg-w3m-bookmarks
  '(("~/.emacs.webjump" webjump-sites)
    ("~/.w3m/wikiprof" wikiprof-sites)
    ("~/.w3m/compas" compas-sites)))

(defvar bzg-w3m-bmk-files (mapcar 'car bzg-w3m-bookmarks))

;; (global-set-key "\C-cj" 'webjump)

(mapc 'load-file (mapcar 'car bzg-w3m-bookmarks))
(load-file webjump-sites-file)

(setq w3m-accept-languages '("fr;" "q=1.0" "en;")
      w3m-command "/usr/bin/w3m"
      w3m-command-arguments-alist nil
      w3m-default-save-directory "~/"
      w3m-home-page "http://www.cognition.ens.fr/~guerry/"
      w3m-use-ange-ftp t
      w3m-bookmark-file "~/.w3m/bookmark.html")

(autoload 'w3m "w3m" "Interface for w3m on Emacs." t)
(autoload 'w3m-find-file "w3m" "Find a local file using emacs-w3m." t)
(autoload 'w3m-search "w3m-search" "Search words using emacs-w3m." t)
(autoload 'w3m-antenna "w3m-antenna" "Report changes of web sites." t)
(autoload 'w3m-browse-url "w3m" "Ask emacs-w3m to show a URL." t)
(autoload 'w3m-rss "w3m-rss" "" t)
;; (autoload 'w3m-namazu "w3m-namazu" "Search files with Namazu." t)
;; (autoload 'w3m-weather "w3m-weather" "Display a weather report." t)

(setq w3m-icon-directory "/usr/local/share/emacs/21.4/site-lisp/w3m/icons/")

(defun bzg-w3m-delicious-post-url ()
  "Post current url to del.icio.us using your `w3m-delicious-login'."
  (interactive)
  (let ((url (concat "http://del.icio.us/"
		      w3m-delicious-login
		      "?url=" w3m-current-url
		      ";title=" w3m-current-title)))
    (w3m-goto-url url)))

(defun bzg-w3m-local-bmk-url (&optional to-webjump)
  "Add the current url to a w3m bookmark page."
  (interactive "P")
  (bzg-w3m-bmk-url to-webjump t))

(defun bzg-w3m-bmk-url (&optional to-webjump local)
  "Add the current url to a w3m bookmark page.
When not prefixed, add the URL directly to `webjump-sites-file'.
Otherwise ask for a file in `w3m-bmk-files'."
  (interactive "P")
  (let ((bmk (cons (or w3m-current-title w3m-current-url) w3m-current-url))
	(bmk-file (if to-webjump webjump-sites-file
		    (completing-read "Bookmark file: " bzg-w3m-bmk-files nil t))))
    (bzg-add-bmk bmk bmk-file)
    (message (concat "\"" (or w3m-current-title w3m-current-url) 
		     (if local (concat "\" stored in " bmk-file ", thanks!")
		       "\" stored in my database, thanks!")))))

(defun bzg-add-bmk (bmk &optional file)
  "Add BMK to FILE or `webjump-sites-file'."
  (with-temp-buffer
    (find-file (or file (completing-read "Bookmark file: " bzg-w3m-bmk-files nil t)))
    (goto-char (point-min))
    (re-search-forward "^\\( +\\))" nil t)
    (beginning-of-line)
    (insert (concat (match-string 1)
		    "(\"" (car bmk) "\" . \"" 
		    (cdr bmk) "\")\n"))
    (write-file buffer-file-name)
    (eval-buffer)
    (kill-buffer (buffer-name))))

(defun bzg-get-tinyurl ()
  "Grabs the url at point and echos the equivalent tinyurl in the
minibuffer to ease cutting and pasting."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "Location: " nil t)
    (let* ((long-url (thing-at-point 'url))
	   (tinyurl
	    (save-excursion
	      (with-temp-buffer
		(mm-url-insert
		 (concat "http://tinyurl.com/api-create.php?url=" long-url))
		(kill-ring-save (point-min) (1- (point-max)))
		(buffer-string)))))
      (message tinyurl))))

(defun bzg-replace-url-at-point-by-tinyurl (beg end)
  "Replace the URL at point by its tinyurl."
  (interactive "r")
  (let ((url (buffer-substring beg end)))
    (delete-region beg end)
    (mm-url-insert
     (concat "http://tinyurl.com/api-create.php?url=" url))
    (delete-backward-char 1)))

(defun bzg-match-bookmark (string file)
  "Store bookmarks matching STRING in RESULTS"
  (let ((results ""))
    (dolist (bmk (eval (cadr (assoc file bzg-w3m-bookmarks))))
      (when (string-match string (car bmk))
	(setq results 
	      (concat results (car bmk) " - "
		      (cdr bmk) "\n"))))
    (if (equal "" results)
	(concat "No relevant bookmark for \"" string "\", sorry!")
      (replace-regexp-in-string "\n$" "" results))))

(defun bzg-store-or-find-bmk (args file from)
  "Store or find bookmarks depending on the first string in ARGS"
  (if (equal args "") "Please set a bookmark"
    (if (string-match org-plain-link-re (car (split-string args)))
	(bzg-add-url-desc
	 (car (split-string args))
	 (concat (mapconcat 'identity (cdr (split-string args)) " ") " (" from ")")
	 file)
      (bzg-match-bookmark args file))))

(defun bzg-store-or-find-bmk-webjump (args from)
   (bzg-store-or-find-bmk args "~/.emacs.webjump" from))
(defun bzg-store-or-find-bmk-wikiprof (args from)
   (bzg-store-or-find-bmk args "~/.w3m/wikiprof" from))
(defun bzg-store-or-find-bmk-compas (args from)
   (bzg-store-or-find-bmk args "~/.w3m/compas" from))

(defun bzg-add-url-desc (url desc file)
  "Add URL to a bookmark file."
  (let ((bmk (cons desc url))
	(bmk-file (or file (completing-read "Bookmark file: " bzg-w3m-bmk-files nil t))))
    (bzg-add-bmk bmk bmk-file)
    (message "%s stored in my database, thanks!" desc)))


(defvar google-search-maxlen 50
  "Maximum string length of search term.  This prevents you from accidentally 
sending a five megabyte query string to Netscape.")


(defun google-it (search-string)
  "Search for SEARCH-STRING on google."
  (interactive "sSearch for: ")
  (browse-url (concat "http://www.google.com/search?client=emacs&q="
		      (url-hexify-string
		       (encode-coding-string search-string 'utf-8)))))

;; (defun google-search-selection ()
;;   "Create a Google search URL and send it to your web browser."
;;   (interactive)
;;   (let (start end term url)
;;     (if (or (not (fboundp 'region-exists-p)) (region-exists-p))
;;         (progn
;;           (setq start (region-beginning)
;;                 end   (region-end))
;;           (if (> (- start end) google-search-maxlen)
;;               (setq term (buffer-substring start (+ start google-search-maxlen)))
;;             (setq term (buffer-substring start end)))
;;           (google-it term))
;;       (beep)
;;       (message "Region not active"))))


(provide 'w3m-config)


;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################





;;; w3m-config.el ends here
