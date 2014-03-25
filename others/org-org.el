;;; org-org.el --- Org links to Org entries

;; Copyright 2007 2008 Bastien Guerry
;;
;; Author: bzg@altern.org
;; Version: 0.1
;; Keywords: org link
;; URL: http://www.cognition.ens.fr/~guerry/u/org-org.el
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
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
;;
;;; Commentary:
;; 
;; Yes, this might sound crazy at first, but you might want to have
;; specific link facilities when remembering an Org entry with Org.
;; Hence org-org.el, which allows you to link to the entry at point 
;; and reuse some of this entry properties in the template.
;;
;; Put this file into your load-path and the following into your
;;   ~/.emacs: (require 'org-org)

;;; Code:

(require 'org)
(defvar description nil) ; dynamically scoped in org.el

(org-add-link-type "org" 'org-org-open)
(add-hook 'org-store-link-functions 'org-org-store-link)

(defun org-org-open (path)
  "Visit the Org entry on PATH."
  (let* ((search (when (string-match "::\\(.+\\)\\'" path)
		   (match-string 1 path)))
	 (path (substring path 0 (match-beginning 0))))
    (org-open-file path t nil search)))

;; FIXME give an example of a useful remember template?
(defun org-org-store-link ()
  "Store a link to an Org entry."
  (when (eq major-mode 'org-mode)
    (let* ((search (run-hook-with-args-until-success
		    'org-create-file-search-functions))
	   (link (concat "file:" 
			 ;; FIXME bad links like ~/org/bzg.org::
			 (abbreviate-file-name buffer-file-name)
			 "::" search))
	   (item (save-excursion
		   (org-back-to-heading)
		   (re-search-forward org-complex-heading-regexp nil t)
		   (match-string 4)))
	   (todo (match-string 2))
	   (priority (match-string 3))
	   (tags (match-string 5)))
      (org-store-link-props
       :type "org"
       :link link
       :todo todo
       :tags tags
       :item item
       :priority priority
       :alltags (org-entry-get (point) "ALLTAGS")
       :archive (org-entry-get (point) "ARCHIVE")
       :category (org-entry-get (point) "CATEGORY")
       :scheduled (org-entry-get (point) "SCHEDULED")
       :deadline (org-entry-get (point) "DEADLINE")
       :summary (org-entry-get (point) "SUMMARY")
       :location (org-entry-get (point) "LOCATION")
       :description (or description
			(org-entry-get (point) "DESCRIPTION"))))))

(provide 'org-org)


;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################

;;; org-org.el ends here
