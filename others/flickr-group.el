;;; flickr-group.el --- Get more data about flickr groups
;;
;; Copyright 2008 Bastien Guerry
;;
;; Emacs Lisp Archive Entry
;; Filename: flickr-group.el
;; Version: 0.1a
;; Author: Bastien Guerry <bzg AT altern DOT org>
;; Maintainer: Bastien Guerry <bzg AT altern DOT org>
;; Keywords: org, wp, toc
;; Description: Shows a browsable table of contents for Org buffer
;; URL: http://www.cognition.ens.fr/~guerry/u/flickr-groups.el
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
;;  This package provides some tools to retrieve data about flickr
;;  groups through the flickr.el API client.  It stores the data in
;;  files and lets you export them in various formats, including org
;;  and csv.
;;
;;  FIXME: This uses w3m but should use the internal URL library with ssl
;;  gateway instead
;;
;;; Usage:
;;
;; I use this by first creating a flickr-track.el file containing the
;; necessary variables and then running this from a script.
;;
;; ,----[ flickr-track.el ]
;; | (require 'flickr-group)
;; |
;; | (setq flickr-group-data-directory "~/flickr/flickr_data/")
;; | (setq flickr-group-org-directory "~/flickr/flickr_org/")
;; |
;; | (setq flickr-group-track-groups
;; |       '(("20312110@N00" ;; Emacs screenshots
;; | 	 :write (:overview (with-discussions with-about)
;; | 		 :admins (t with-contacts)
;; | 		 :members (t with-contacts)
;; | 		 :moderators (t with-contacts)
;; | 		 :posters (t with-photos)
;; | 		 :photos (t with-commentators))
;; | 	 :export (:icon :group-url :num-members :num-photos
;; | 		  :privacy :discussions))))
;; `----

;; ,----[ flickr-group.sh ]
;; | #!/bin/bash
;; | /usr/local/bin/emacs-23.0.0 --batch --eval \
;; |     "(progn (load-file \"~/.emacs-flickr.el\") \
;; |             (load-file \"~/elisp/flickr-group.el\") \
;; |             (load-file \"~/elisp/flickr-track.el\") \
;; |             (flickr-group-track t) \
;; |             (flickr-group-export '(\"org\" \"csv\") t))"
;; `----
;;
;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'flickr-group)
;;
;;; Code:

(eval-when-compile
  (require 'cl))

(require 'org)
(require 'flickr)

;; FIXME: Well, DON'T use w3m!
(require 'w3m)

;; FIXME: Make sure we load a decent version of xml.el
(load "/usr/local/share/emacs/23.0.0/lisp/xml.el.gz")

(defvar flickr-group-flickr-page "http://www.flickr.com/groups/"
  "The flickr page for groups.")

(defvar flickr-group-track-groups nil
  "The list of tracked groups.  Each cell must contain the NISD
of the group and two parameters: the :write contains the list of
parameters to write, and :export contains the list of parameters
to export to in Org files.")

(defvar flickr-group-export-default-params
  '(:name :num-members :num-photos :iconfarm :iconserver
    :privacy :blast :moderated :throttle :discussions)
  "The list of the default parameters when exporting a group data.")

(defvar flickr-group-current-moderation-list nil
  "The list of moderation bits.  This list must be a list of 15
elements corresponding to the 15 possible moderation bits.")

(defvar flickr-group-current-formats nil
  "Current formats for export.")

(defvar flickr-group-current-data nil
  "The current data, as written by `flickr-group-export-data'.")

(defgroup flickr-group nil
  "A library for retrieving data about Flickr groups."
  :tag "Flickr"
  :group 'flickr)

(defcustom flickr-group-timestamp "%Y-%m-%d"
  "The default timestamp for files and content."
  :group 'flickr-group
  :type 'string)

(defcustom flickr-group-data-directory "~/flickr/flickr_data/"
  "Directory where to write the data."
  :type 'file
  :group 'flickr)

(defcustom flickr-group-org-directory "~/flickr/flickr_org/"
  "Directory where to write the Org pages."
  :type 'file
  :group 'flickr)

(defcustom flickr-group-export-default-from-date "2008-01-20"
  "The default date for the beginning of the Org report."
  :type 'string
  :group 'flickr)

(defcustom flickr-group-export-default-to-date "2008-03-30"
  "The default date for the end the of the Org report."
  :type 'string
  :group 'flickr)

(defcustom flickr-group-export-default-step 1
  "The default number of days between two rows in the Org
report."
  :type 'number
  :group 'flickr)

(defcustom flickr-group-export-org-header
  "#+OPTIONS:     H:1 num:nil toc:nil \\n:nil @:t ::t |:t ^:nil -:t f:t *:t TeX:t LaTeX:t skip:nil d:(HIDE) tags:not-in-toc
#+STARTUP:     align nofold nodlcheck hidestars oddeven lognotestate
#+TITLE:       Stats for the flickr group: %s
#+LaTeX_CLASS: flickr
#+AUTHOR:      Bastien
#+EMAIL:       bzg AT altern DOT org
#+LANGUAGE:    en

 [[file:index.org][{Back to the index page}]]

* Overview from %s to %s\n\n"
  "The default header formmatting string."
  :type 'string
  :group 'flickr)

(defcustom flickr-group-export-org-index-header
  "#+OPTIONS:     H:1 num:nil toc:nil \\n:nil @:t ::t |:t ^:nil -:t f:t *:t TeX:t LaTeX:t skip:nil d:(HIDE) tags:not-in-toc
#+STARTUP:     align nofold nodlcheck hidestars oddeven lognotestate
#+TITLE:       Index of flickr trackr
#+LaTeX_CLASS: flickr
#+AUTHOR:      Bastien
#+EMAIL:       bzg AT altern DOT org
#+LANGUAGE:    en

* Last update: %s at %s\n\n"
  "The default header formmatting string."
  :type 'string
  :group 'flickr)

(defcustom flickr-group-export-additional-params
  '(:icon ; the URL of the icon for the group
    (lambda(data)
      (let ((gid (plist-get data :gid))
	    (iconserver (plist-get data :iconserver))
	    (iconfarm (plist-get data :iconfarm)))
	(format "http://farm%s.static.flickr.com/%s/buddyicons/%s.jpg"
		iconfarm iconserver gid)))
    :num-admins
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(number-to-string (length (plist-get data :admins)))))
    :num-moderators
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(length (plist-get data :moderators))))
    :group-url
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(format "http://www.flickr.com/groups/%s/" gid)))
    :top-member ; the member with the more contacts
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(car (plist-get data :members))))
    :top-poster ; the poster with the more photos
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(car (plist-get data :posters))))
    :top-photo  ; the photo with the more comments
    (lambda(data)
      (let ((gid (plist-get data :gid)))
	(car (plist-get data :photos)))))
  "A property list of additional possible parameters. The value
of each parameter is a function taking the data of the group as
a single argument."
  :type '(plist :value-type function)
  :group 'flickr)

;;; Get the general information for a group:

(defun flickr-group-get-overview
  (gid &optional with-discussions with-about with-rules auth)
  "Get the general information for GID.
If WITH-DISCUSSIONS, include the number of discussion in this
group.  The WITH-ABOUT argument means check for the \"About\"
section.  The WITH-RULES argument means check for the rules of
this group.  If AUTH is non-nil, call method as an authenticated
user."
  (let* ((infos (car (flickr-groups-getInfo gid)))
	 (group (car (xml-get-children infos 'group)))
	 (name (caddar (xml-get-children group 'name)))
	 (members (caddar (xml-get-children group 'members)))
	 (iconfarm (cdr (assoc 'iconfarm (cadr group))))
	 (iconserver (cdr (assoc 'iconserver (cadr group))))
	 (moderated (cdr (assoc 'ispoolmoderated (cadr group))))
	 (blast (caddar (xml-get-children group 'blast)))
	 (privacy (caddar (xml-get-children group 'privacy)))
	 (throttle (cadar (xml-get-children group 'throttle)))
	 (discussions
	  (if with-discussions
	      (flickr-group-scrap-discussions gid) "N/A"))
	 (about (if with-about
		    (flickr-group-scrap-about gid) "N/A"))
	 (rules (if with-rules
		    (flickr-group-scrap-rules gid) "N/A"))
	 (photos
	  (cdr (assoc 'total
		      (cdadr (car (xml-get-children
				   (car (flickr-groups-pools-getPhotos
					 gid 1 1 auth))
				   'photos)))))))
    (list :name name
	  :num-members members
	  :num-photos photos
	  :moderated moderated
	  :privacy privacy
	  :blast blast
	  :iconserver iconserver
	  :iconfarm iconfarm
	  :throttle throttle
	  :discussions discussions
	  :about about
	  :rules rules)))

;;; Scraping core functions:

(defun flickr-group-scrap-users
  (gid status page &optional onlymaxpage)
  "Scrap the list of members from GID and PAGE.
If ONLYMAXPAGE is non-nil, then only return the maximum of
required pages for scrapping the list of members."
  (save-window-excursion
    (let ((w3m-async-exec nil) users maxpages)
      (with-temp-buffer
	(w3m-goto-url
	 (concat "about://source/"
		 (format "http://flickr.com/groups_members_detail.gne?id=%s&tab=%s&page=%d"
			 gid status page)))
	(search-forward "<div class=\"Paginator\">" nil t)
	(search-forward "</div>")
	(if onlymaxpage
	    (setq maxpages (if (re-search-backward "&page=\\([0-9]+\\)\">" nil t)
			       (match-string-no-properties 1) "1"))
	  (progn
	    (goto-char (point-min))
	    (while (search-forward "<div class=\"MembersList\">" nil t)
	      (re-search-forward "<img src=\".*/\\([^/]+\\)\\.jpg" nil t)
	      (add-to-list 'users (match-string-no-properties 1) t))))
	(or maxpages users)))))

(defun flickr-group-scrap-discussions (gid)
  "Scrap the number of discussions for GID."
  (save-window-excursion
    (let ((w3m-async-exec nil))
      (with-temp-buffer
	(w3m-goto-url
	 (concat "about://source/"
		 (format "http://www.flickr.com/groups/%s" gid)))
	(goto-char (point-min))
	(cond ((re-search-forward "[0-9]+ of \\(.*\\) posts" nil t)
	       (replace-regexp-in-string "," "" (match-string-no-properties 1)))
	      ((search-forward "No topics have been posted yet." nil t) "0")
	      (t nil))))))

(defun flickr-group-scrap-about (gid)
  "Return the \"About\" section for this group."
  (save-window-excursion
    (let ((w3m-async-exec nil))
      (with-temp-buffer
	(w3m-goto-url
	 (concat "about://source/"
		 (format "http://www.flickr.com/groups/%s" gid)))
	(goto-char (point-min))
	(cond ((re-search-forward "<h3>About .*</h3>" nil t)
	       (let ((beg (goto-char (match-end 0))))
		 (re-search-forward "</td>" nil t)
		 (org-trim (buffer-substring-no-properties
			    beg (match-beginning 0)))))
	      (t nil))))))

(defun flickr-group-scrap-rules (gid)
  "Check whether there are rules for this group."
  (save-window-excursion
    (let ((w3m-async-exec nil))
      (with-temp-buffer
	(w3m-goto-url
	 (concat "about://source/"
		 (format "http://www.flickr.com/groups/%s/rules/" gid)))
	(goto-char (point-min))
	(cond ((search-forward "There are no rules" nil t) nil)
	      ((re-search-forward "<div class=\"InfoCase\" style=\"font-size:12px\">" nil t)
	       (let ((beg (goto-char (match-end 0))))
		 (re-search-forward "</div>" nil t)
		 (org-trim (buffer-substring-no-properties
			    beg (match-beginning 0)))))
	      (t nil))))))

(defun flickr-group-scrap-tags (gid n)
  "Get the N most used tags for the group GID."
  (save-window-excursion
    (let ((w3m-async-exec nil) tags-list)
      (with-temp-buffer
	(w3m-goto-url
	 (concat "about://source/"
		 (format "http://www.flickr.com/groups/%s/pool/tags/" gid)))
	(goto-char (point-min))
	(re-search-forward "<p id=\"TagCloud\">" nil t)
	(let ((end (save-excursion
		     (re-search-forward "</p>" nil t)
		     (match-beginning 0)))
	      (cnt 0))
	  (while (and (re-search-forward
		       "font-size: \\([0-9]+\\)px;\">\\([^&]+\\)</a>" end t)
		      (< cnt n))
	    (add-to-list 'tags-list
			 (cons (match-string 2)
			       (string-to-number
				(match-string-no-properties 1))))
	    (setq cnt (1+ cnt))))
	(setq tags-list
	      (sort tags-list (lambda (a b) (> (cdr a) (cdr b)))))))))

;;; Get the complete list of members/photos:

(defun flickr-group-get-users (gid status &optional limit)
  "Get a list of users in GID with STATUS.
This is done by downloading the HTML page of the group and
scrapping for the list of users.  If LIMIT, only return that
number of users."
  (interactive)
  (let ((lim (or limit 1000000)) ; some arbitrary long
	(cnt 0) users
	(pages (string-to-number
		(flickr-group-scrap-users gid status 1 t))))
    (while (and (< cnt pages) (< (length users) lim))
      (setq cnt (1+ cnt))
      (setq users (append users
		    (flickr-group-scrap-users
		     gid status cnt))))
    (bzg-sublist users 0 lim)))

(defun flickr-group-get-admins (gid &optional with-contacts limit)
  "Get the list of admins for GID.
If WITH-CONTACTS, return an alist which cells CDR are the
contacts for the user.  If LIMIT, only return that number of
users."
  (let ((admins (flickr-group-get-users gid "admin" limit)))
    (if with-contacts
	(sort (flickr-group-get-users-contacts admins)
      	      (lambda (a b) (> (length a) (length b))))
      admins)))

(defun flickr-group-get-moderators (gid &optional with-contacts limit)
  "Get the list of moderators for GID.
If WITH-CONTACTS, return an alist which cells CDR are the
contacts for the user.  If LIMIT, only return that number of
users."
  (let ((moderators (flickr-group-get-users gid "moderator" limit)))
    (if with-contacts
	(sort (flickr-group-get-users-contacts moderators)
	      (lambda (a b) (> (length a) (length b))))
      moderators)))

(defun flickr-group-get-members (gid &optional with-contacts limit)
  "Get the list of moderators for GID.
If WITH-CONTACTS, return an alist which cells CDR are the
contacts for the user.  If LIMIT, only return that number of
users."
  (let ((members (flickr-group-get-users gid "member" limit)))
    (if with-contacts
	(sort (flickr-group-get-users-contacts members)
	      (lambda (a b) (> (length a) (length b))))
      members)))

(defun flickr-group-get-posters (gid &optional with-photos limit auth)
  "Get the full list of posters for GID.
If WITH-PHOTOS is non-nil, add the list of the photos they posted
into this group.  If LIMIT, only return that number of users.  If
AUTH, call this method as an authenticated user."
  (let ((photos (flickr-group-get-photos-raw gid auth))
	posters photo)
    (while (setq photo (pop photos))
      (let ((owner (cdr (assoc 'owner (cadr photo))))
	    (pic (cdr (assoc 'id (cadr photo)))))
	(if (and with-photos (assoc owner posters))
	    (setcdr (assoc owner posters)
		    (push pic (cdr (assoc owner posters))))
	  (add-to-list
	   'posters (if with-photos (delete nil (list owner pic)) owner) t))))
    (if limit (bzg-sublist posters 0 limit)
      posters)))

(defun flickr-group-get-users-contacts (users)
  "For USERS, return an alist which cell are (user . (contacts))."
  (mapcar
   (lambda (user)
     (let* ((rpl0 (flickr-contacts-getPublicList user 'max 1))
	    (rpl1 (xml-get-children (car rpl0) 'contacts))
	    (rpl2 (xml-get-children (car rpl1) 'contact))
	    (rpl3 (mapcar (lambda(c) (cdr (assoc 'nsid (cadr c)))) rpl2)))
       (cons user rpl3)))
   users))

;;; Get photos:

(defun flickr-group-get-photos-raw (gid &optional limit auth)
  "Get the raw list of photos for GID.
If LIMIT is a number, don't get more photos than this number.  If
AUTH is non-nil, call this method as an authenticated user."
  (let ((cnt 0) all-photos
	(pages
	 (string-to-number
	  (cdr (assoc 'pages
		      (cdadr
		       (car
			(xml-get-children
			 (car (flickr-groups-pools-getPhotos
			       gid 'max 1 auth))
			 'photos))))))))
    (while (< cnt pages)
      (setq cnt (1+ cnt))
      (let* ((pht0 (flickr-groups-pools-getPhotos
		    gid 'max cnt auth))
	     (pht1 (xml-get-children (car pht0) 'photos))
	     (pht2 (xml-get-children (car pht1) 'photo)))
	(add-to-list 'all-photos pht2 t)))
    (if limit (bzg-sublist (car all-photos) 0 limit)
      (car all-photos))))

(defun flickr-group-get-photos
  (gid &optional with-commentators limit auth)
  "Get the list of photos for GID.
If WITH-COMMENTATORS, each cell also contains the list of
commentators for the photo.  If LIMIT is a number, don't get more
photos than this number."
  (let ((output (mapcar (lambda(p) (cdr (assoc 'id (cadr p))))
			(flickr-group-get-photos-raw gid auth))))
    (if with-commentators
	(flickr-group-get-photos-commentators output)
      (if limit (bzg-sublist output 0 limit)
	output))))

(defun flickr-group-get-photos-commentators (photos &optional limit)
  "Get all commentators for a list of PHOTOS.
Return an list where each cell is an alist of the form

 (photo-id ((commenter#1 . number_of_comments)
            (commenter#2 . number_of_comments)))

An optional argument LIMIT specifies the number of commentators."
  (let (photo output)
    (while (setq photo (pop photos))
      (let* ((cmt0 (flickr-photos-comments-getList photo))
	     (cmt1 (xml-get-children (car cmt0) 'comments))
	     (cmt2 (xml-get-children (car cmt1) 'comment))
	     comments cmt)
	(add-to-list
	 'output
	 (cons photo
	       (progn
		 (while (setq cmt (pop cmt2))
		   (let* ((author (cdr (assoc 'author (cadr cmt))))
			  (author-entry (assoc author comments)))
		     (if author-entry
			 (setcdr (assoc author comments)
				 (1+ (cdr author-entry)))
		       (add-to-list 'comments (cons author 1) t))))
		 comments)) t)))
    (if limit (bzg-sublist output 0 limit)
      output)))

;;; Write data to files:

;; FIXME: this function is UGLY.  Refactoring?
(defun flickr-group-write-data (gid skip-existing-files &rest props)
  "Write data for GID in `flickr-group-data-directory'.
PROPS is a plist specifying which data to collect.

Possible values for these properties are:

  :overview    : t or '([with-discussions] [with-about])
  :admins      : t or '([t|N] [with-contacts])
  :moderators  : t or '([t|N] [with-contacts])
  :members     : t or '([t|N] [with-contacts])
  :posters     : t or '([t|N] [with-photos])
  :photos      : t or '([t|N] [with-commentators])

The :overview property includes these properties:

  :name        : the name of the group
  :num-members : the number of members
  :num-photos  : the number of photos
  :iconserver  : the server for the group icon
  :iconfarm    : the farm for the group icon
  :privacy     : the privacy bit
  :blast       : the blast
  :throttle    : the throttle information
 [:discussions : the discussions]"
  (interactive)
  (let* ((overviewp (plist-get props :overview))
	 (adminsp (plist-get props :admins))
	 (membersp (plist-get props :members))
	 (moderatorsp (plist-get props :moderators))
	 (postersp (plist-get props :posters))
	 (photosp (plist-get props :photos))
	 (file (concat flickr-group-data-directory gid "_"
		       (format-time-string flickr-group-timestamp) ".el")))
    (unless (and skip-existing-files (file-exists-p file))
      (with-temp-buffer
	(find-file file)
	(erase-buffer)
	(insert
	 (with-output-to-string
	   (princ ";; -*- emacs-lisp -*-\n")
	   (princ (format "(setq %s\n'(\n:gid \"%s\"\n" gid gid))
	   ;; insert overview
	   (if overviewp
	       (let ((overview (flickr-group-get-overview
				gid
				(member 'with-discussions overviewp)
				(member 'with-about overviewp)
				(member 'with-rules overviewp)
				)))
		 (progn (mapc (lambda(p) (prin1 p) (princ " ")) overview)
			(princ "\n"))))
	   ;; insert admins
	   (if adminsp
	       (let ((admins
		      (flickr-group-get-admins
		       gid
		       (member 'with-contacts adminsp)
		       (if (and (listp adminsp)
				(not (eq (car adminsp) t)))
			   (car adminsp)))))
		 (progn (princ ":admins ")
			(prin1 admins)
			(princ "\n"))))
	   ;; insert moderators
	   (if moderatorsp
	       (let ((moderators
		      (flickr-group-get-moderators
		       gid
		       (member 'with-contacts moderatorsp)
		       (if (and (listp moderatorsp)
				(not (eq (car moderatorsp) t)))
			   (car moderatorsp)))))
		 (progn (princ ":moderators ")
			(prin1 moderators)
			(princ "\n"))))
	   ;; insert members
	   (if membersp
	       (let ((members
		      (flickr-group-get-members
		       gid
		       (member 'with-contacts membersp)
		       (if (and (listp membersp)
				(not (eq (car membersp) t)))
			   (car membersp)))))
		 (progn (princ ":members ")
			(prin1 members)
			(princ "\n"))))
	   ;; insert posters
	   (if postersp
	       (let ((posters
		      (flickr-group-get-posters
		       gid
		       (member 'with-photos postersp)
		       (if (and (listp postersp)
				(not (eq (car postersp) t)))
			   (car postersp)))))
		 (progn (princ ":posters ")
			(prin1 posters)
			(princ "\n"))))
	   ;; insert photos
	   (if photosp
	       (let ((photos
		      (flickr-group-get-photos
		       gid
		       (member 'with-commentators photosp)
		       (if (and (listp postersp)
				(not (eq (car postersp) t)))
			   (car postersp)))))
		 (progn (princ ":photos ")
			(prin1 photos)
			(princ "\n"))))
	   (princ "))\n")))
	(set-buffer-file-coding-system 'utf-8)
	(save-buffer)
	(kill-buffer (current-buffer))))))

;;; Get the top N for specific parameters:

(defun flickr-group-get-top (gid n date parameter)
  "Return the N members having the more contacts in GID at DATE."
  (let (output)
    (save-window-excursion
      (load (concat flickr-group-data-directory gid "_"
		    (format-time-string flickr-group-timestamp
					(org-read-date nil t date))
		    ".el"))
      (let* ((val (plist-get (eval (intern gid)) parameter))
	     (l-val (length val))
	     (cnt 0))
	(while (> n cnt)
	  (setq output (push (nth cnt val) output))
	  (setq cnt (1+ cnt)))))
    (reverse output)))

(defun flickr-group-get-top-members (gid n date)
  "Return N members with the more contacts in GID at DATE."
  (flickr-group-get-top gid n date :members))

(defun flickr-group-get-top-photos (gid n date)
  "Return N most commented photos in GID at DATE."
  (flickr-group-get-top gid n date :photos))

(defun flickr-group-get-top-posters (gid n date)
  "Return N posters with the more photos in GID at DATE."
  (flickr-group-get-top gid n date :posters))

;;; Export functions:

(defun flickr-group-export-data
  (gid from-date to-date step &rest parameters)
  "Export the data of GID.
FROM-DATE is the date of the first record.  TO-DATE is the date
of the last record.  STEP is the number of days between to steps.
PARAMETERS are the parameters to retrieve.

When called interactively, this function lets you pick up the
group, the time range and step.  The parameters will be the
default parameters, defined in the variable
`flickr-group-export-default-params'."
  (interactive
   (list (completing-read "Group: " flickr-group-track-groups nil t)
	 (org-read-date nil nil nil "From date: ")
	 (org-read-date nil nil nil "To date: ")
	 (string-to-number (read-from-minibuffer "Step (in days): "))))
  (let ((params (or parameters flickr-group-export-default-params))
	(cnt 0) file files data)
    (while ;; Find the files to look the data for
	(and (setq
	      file
	      (concat flickr-group-data-directory gid "_"
		      (format-time-string flickr-group-timestamp
					  (time-add
					   (org-read-date nil t from-date)
					   (days-to-time (* cnt step))))
		      ".el"))
	     (time-less-p
	      (time-add (org-read-date nil t from-date) (days-to-time (* cnt step)))
	      (org-read-date nil t to-date)))
      (setq cnt (1+ cnt))
      (if (file-exists-p file)
	  (add-to-list 'files file)))
    ;; Loop over the list of files and convert the data in the file into
    ;; one line of separator-separated fiels:
    (mapc
     (lambda(file)
       (load file)
       (add-to-list
	'data
	(append
	 (and (string-match "\\([0-9-]+\\)\\.el" file)
	      (list (match-string 1 file)))
	 (mapcar (lambda(p)
		   (let* ((file-v (eval (intern gid)))
			  (v (plist-get file-v p)))
		     (cond ((plist-get flickr-group-export-additional-params p)
			    ;; look for another function for exotic params
			    (funcall
			     (plist-get
			      flickr-group-export-additional-params p) file-v))
			   ;; output list cleanly
			   ((listp v) (with-output-to-string (prin1 v)))
			   ;; we don't have this parameter...
			   ((null v) "N/A")
			   (t v))))
		 params)) t)) files)
    ;; FIXME: what if no data?
    (add-to-list ;; Add the header row for this column
     'data (append '("Date")
		   (mapcar (lambda(s) (substring (symbol-name s) 1))
			   params)))
    ;; Return the data:
    (setq flickr-group-current-data data)))

(defun flickr-group-export (formats index &optional from-date to-date step)
  "Export the flickr group data to FORMATS.
If INDEX is non-nil, all export the index of exported files.
Pick up files between FROM-DATE to TO-DATE by STEP days."
  ;; Store the formats for later retrieval
  (setq flickr-group-current-formats formats)
  (save-window-excursion
    (mapc (lambda (g)
	    (let* ((g (car g))
		   (data
		    (apply 'flickr-group-export-data
			   g ;; <= this is the gid
			   flickr-group-export-default-from-date
			   flickr-group-export-default-to-date
			   flickr-group-export-default-step
			   (plist-get (cdr (assoc g flickr-group-track-groups))
				      :export))))
	      ;; this loops over formats and perform export for each
	      (mapc (lambda(fmt)
		      (funcall (intern (concat "flickr-group-export-" fmt))
			       g data))
		    formats)))
	  flickr-group-track-groups)
    (if index (flickr-group-export-org-index))))

(defun flickr-group-export-csv (gid data)
  "Export GID's DATA to a cvs formatted file."
  (with-temp-buffer
    (find-file (concat flickr-group-org-directory gid ".csv"))
    (erase-buffer)
    (insert
     (mapconcat (lambda(r) (mapconcat 'identity r ",")) data "\n"))
    (set-buffer-file-coding-system 'utf-8)
    (save-buffer)
    (kill-buffer (current-buffer))))

(defun flickr-group-export-latex (gid &optional data)
  "Export GID's DATA to an LaTeX file."
  (with-temp-buffer
    (find-file (concat flickr-group-org-directory gid ".org"))
    (org-export-as-latex 1)
    (kill-buffer (current-buffer))))

(defun flickr-group-export-org (gid data)
  "Export GID's DATA to an Org file."
  (with-temp-buffer
    (find-file (concat flickr-group-org-directory gid ".org"))
    (erase-buffer)
    (insert (format flickr-group-export-org-header gid
		    flickr-group-export-default-from-date
		    flickr-group-export-default-to-date))
    (org-table-export-alist data)
    (set-buffer-file-coding-system 'utf-8)
    (save-buffer)
    (kill-buffer (current-buffer))))

(defun flickr-group-export-org-index ()
  "Export the flickr data in an Org index."
  (with-temp-buffer
    (find-file (concat flickr-group-org-directory "index.org"))
    (erase-buffer)
    (insert (format flickr-group-export-org-index-header
		    (format-time-string flickr-group-timestamp)
		    (format-time-string "%H:%M")))
    (mapc (lambda (g)
	    (setq g (car g))
	    (insert (format
		     (concat "| [[" flickr-group-flickr-page
			     "%s/][%s]] | "
			     (if (member "org" flickr-group-current-formats)
				 (format "[[file:%s.org][HTML]] | " g))
			     (if (member "latex" flickr-group-current-formats)
				 (format "[[file:%s.pdf][PDF]] | " g))
			     (if (member "csv" flickr-group-current-formats)
				 (format "[[file:%s.csv][CSV]] | " g))
			     "\n") g g))
	    (org-table-align))
	  flickr-group-track-groups)
    (set-buffer-file-coding-system 'utf-8)
    (save-buffer)
    (kill-buffer (current-buffer))))

;;; Main function for tracking groups:

(defun flickr-group-track (skip-existing-files)
  "Track flickr groups data and write them to files.
If SKIP-EXISTING-FILES is non-nil, skip existing files."
  (interactive)
  (save-window-excursion
    (mapc (lambda(group)
	    (apply 'flickr-group-write-data
		   (car group)
		   skip-existing-files
		   (plist-get (cdr group) :write)))
	  flickr-group-track-groups)))

;;; Get the distribution of groups over moderation bits:

(defun flickr-group-make-moderation-list (directory)
  "From the data files in DIRECTORY, return a list of 33
elements.  The Nth element is the list of groups having N as
moderation bit."
  (let ((files (dired-files-attributes directory)) file group modbit
	mod0 mod1 mod2 mod3 mod4 mod5 mod6 mod7 mod8
	mod9 mod10 mod11 mod12 mod13 mod14 mod15 mod16
	mod17 mod18 mod19 mod20 mod21 mod22 mod23 mod24
	mod25 mod26 mod27 mod28 mod29 mod30 mod31 mod32)
    (while (setq file (pop files))
      (when (string-match "\\([^_]+\\)_.*\.el$" (cadr file))
	(setq group (file-name-nondirectory
		     (match-string 1 (cadr file))))
	(load (cadr file))
	(setq modbit
	      (number-to-string
	       (flickr-group-compute-moderation-bit
		(eval (intern group)))))
	(add-to-list
	 (intern (concat "mod" modbit)) group t)))
    (list mod0 mod1 mod2 mod3 mod4 mod5 mod6 mod7 mod8
	  mod9 mod10 mod11 mod12 mod13 mod14 mod15 mod16
	  mod17 mod18 mod19 mod20 mod21 mod22 mod23 mod24
	  mod25 mod26 mod27 mod28 mod29 mod30 mod31 mod32)))

(defun flickr-group-normalize-throttle (directory)
  "From each file in DIRECTORY, compute the normalized throttle.
Return an alist which elements are a cons of the group name and
its normalized throttle value."
  (interactive)
  (let ((files (dired-files-attributes directory))
	file group-name group output throttle n-throttle)
    (while (setq file (pop files))
      (when (string-match "\\([^_]+\\)_[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\.el$" (cadr file))
	(setq group-name (file-name-nondirectory
			  (match-string 1 (cadr file))))
	(load (cadr file))
	(setq group (eval (intern group-name)))
	(setq n-throttle
	      (when (setq throttle (plist-get group :throttle))
		(cond ((equal (cdr (assoc 'mode throttle)) "day")
		       (string-to-number (cdr (assoc 'count throttle))))
		      ((equal (cdr (assoc 'mode throttle)) "week")
		       (/ 7.000 (string-to-number
				 (cdr (assoc 'count throttle)))))
		      ;; what is the exact number of days per year?
		      ((equal (cdr (assoc 'mode throttle)) "month")
		       (/ (/ 365.242 12)
			  (string-to-number
			   (cdr (assoc 'count throttle)))))
		      ((equal (cdr (assoc 'mode throttle)) "none") nil)
		      ((equal (cdr (assoc 'mode throttle)) "user" t)))))
	(add-to-list 'output (cons group-name n-throttle) t)))
    output))

(defun flickr-group-compute-moderation-bit (data)
  "For DATA of a group, compute the moderation bit.
The rule when computing the moderation bit of a group:

  is moderated    add 1
  is throttled    add 2
  have discussion add 4
  have rules      add 8

Then a moderation bit of 7, for example, means that the group is
moderated (+1), throttled (+2), allows discussions (+4), don't
have expressed rules and is public."
  (+ (if (equal (plist-get data :moderated) "1") 1 0)
     (if (equal (cdr (assoc 'mode (plist-get data :throttle))) "none") 0 2)
     (if (and (plist-get data :discussions)
	      (not (equal (plist-get data :discussions) "N/A"))) 4 0)
     (if (plist-get data :rules) 8 0)
     (if (equal (plist-get data :privacy) "3") 0 16)))

(defun flickr-group-write-moderation-repartition (directory)
  "Write the moderation repartition data for groups in DIRECTORY."
  (with-temp-buffer
    (find-file (concat (file-name-as-directory directory)
		       "moderation-repartition-"
		       (format-time-string flickr-group-timestamp)
		       ".el"))
    (erase-buffer)
    (insert ";; -*- emacs-lisp -*-\n(setq flickr-group-current-moderation-list '")
    (insert (with-output-to-string
	      (prin1 (flickr-group-make-moderation-list directory))) ")")
    (set-buffer-file-coding-system 'utf-8)
    (save-buffer)
    (kill-buffer (current-buffer))))

(defun flickr-group-compute-percentage (alist)
  ;; Take ALIST and return a list represcontaining the percentage of
  ;; elements in each...
  (let ((total-length 0))
    (mapc (lambda(elt) (setq total-length (+ total-length (length elt)))) alist)
    (mapcar (lambda(elt) (* (/ (length elt) (float total-length)) 100)) alist)))

;;; Ad hoc personal functions:

(defun org-table-export-alist (data)
  "Export DATA into a table.
DATA is an alist.  Each cell will be converted into a row."
  (mapcar (lambda(f)
	    (progn (mapcar (lambda (g) (insert "| " g)) f)
		   (insert "\n")
		   (if (equal (car f) "Date") (insert "|-\n")))) data)
  (org-table-align))

;; FIXME not in Emacs?
(defun bzg-sublist (list from-element number)
  "Return a sublist FROM-ELEMENT with NUMBER elements."
  (let* ((subl (reverse (member (elt list from-element) list))))
    (reverse (member (elt subl (- (length subl) number)) subl))))

(provide 'flickr-group)

;;; flickr-group.el ends here
