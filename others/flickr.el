;;; flickr.el --- An flickr API client for Emacs
;;
;; Copyright 2008 Bastien Guerry
;;
;; Emacs Lisp Archive Entry
;; Filename: flickr.el
;; Version: 0.1a
;; Author: Bastien Guerry <bzg AT altern DOT org>
;; Maintainer: Bastien Guerry <bzg AT altern DOT org>
;; Keywords: org, wp, toc
;; Description: Shows a browsable table of contents for Org buffer
;; URL: http://www.cognition.ens.fr/~guerry/u/flickr.el
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
;; This is a rewriting of Mathias Dahl emacs-flickr.el :
;; FIXME: URL in the Emacs wiki ?
;;
;; Put this file into your `load-path' and add this into your ~/.emacs:
;;   (require 'flickr)
;; 
;;; Usage:
;;
;; You first need to get an API key from flickr:
;; http://www.flickr.com/services/api/keys/apply/
;; 
;; Once you've got your key, set these variables: 
;; 
;; `flickr-username' : your username (e.g. "baztien")
;; `flickr-api-key'  : the key (32 bits)
;; `flickr-secret'   : the shared secret (16 bits)
;;
;; The names of the client functions follow the names of the API
;; methods, just replacing the dots by a dash:
;; 
;; flickr.el function   : flickr-contacts-getPublicList
;; Corresponding method : flickr.contacts.getPublicList
;; 
;; The number of mandatory arguments for flickr.el functions maps over
;; the number of mandatory arguments for the flickr API methods. FIXME
;; (what about optional ones?)
;; 
;; The arguments user-id, group-id and photo-id are the identification
;; strings for users, groups and photos.
;;
;; Most methods from the flickr API are public.  If you need to
;; authenticate yourself, first do it with M-x flickr-authenticate 
;;
;;; Code:

(eval-when-compile
  (require 'cl))

(defgroup flickr nil
  "Emacs flickr API."
  :tag "Flickr"
  :group 'convenience)

(defcustom flickr-api-key "" 
  "Your API key."
  :type 'string
  :group 'flickr)

(defcustom flickr-secret "" 
  "Your shared secret."
  :type 'string
  :group 'flickr)

(defcustom flickr-username ""
  "The default username when using flickr."
  :type 'string
  :group 'flickr)

(defvar flickr-frob "" "The frob for the session.")
(defvar flickr-token "" "The token for the session.") 
(defvar flickr-login-url "" "The URL used for authentication.")
(defvar flickr-response-xml nil "The XML response.")
(defvar flickr-rest-base-url "http://www.flickr.com/services/rest/?"
  "Base URL for accessing Flickr services using REST.")
(defvar flickr-auth-base-url "http://flickr.com/services/auth/?" 
  "Base URL for authentication.")

;; (defvar flickr-current-user nil "The current user.")

;;; Set general values:

(defun flickr-api-key ()
  "Return the API key set by `flickr-api-key'. 
If no API key is set, return an error."
  (or (and (not (equal flickr-api-key "")) flickr-api-key)
      (error "Please set your flickr API key")))

(defun flickr-secret ()
  "Return the shared secret set by `flickr-secret'.
If no shared secret is set, return an error."
  (or (and (not (equal flickr-secret "")) flickr-secret)
      (error "Please set your shared secret")))

;;; Frob and token -- authentication

(defun flickr-frob ()
  "Return the frob or an error if it is null."
  (or (and (not (equal flickr-frob "")) flickr-frob)
      (error "Please set the frob for this session")))

(defun flickr-token ()
  "Return the token or an error if it is null."
  (or (and (not (equal flickr-token "")) flickr-token)
      (error "Please set the token for this session")))

(defun flickr-get-frob ()
  "Set the frob for the current session."
  (flickr-get-rest-response
   (list (cons "method"  "flickr.auth.getFrob")
         (cons "api_key" (flickr-api-key))))
  (setq flickr-frob
	(car (xml-node-children
	      (car (xml-get-children 
		    (car flickr-response-xml) 'frob))))))

(defun flickr-get-token ()
  "Set the token value for the current session."
  (flickr-get-rest-response
   (list (cons "method" "flickr.auth.getToken")
         (cons "api_key" (flickr-api-key))
         (cons "frob" (flickr-frob))))
  (setq flickr-token
	(car (xml-node-children
	      (car (xml-get-children
		    (car (xml-get-children
			  (car flickr-response-xml)
			  'auth))
		    'token))))))

(defun flickr-auth-checkToken ()
  (flickr-get-rest-response
   (list (cons "method" "flickr.auth.checkToken")
         (cons "api_key" (flickr-api-key))
         (cons "auth_token" (flickr-token)))))

(defun flickr-authenticate (permissions)
  "Get an authentication token for the session with PERMISSIONS."
  (let* ((frob (flickr-get-frob))
	 (key (flickr-api-key))
	 (url (concat 
	       flickr-auth-base-url
	       "api_key=" key "&perms=" permissions "&frob=" frob
	       "&api_sig=" (flickr-get-api-sig
			    (list (cons "api_key"  key)
				  (cons "frob"  frob)
				  (cons "perms" permissions))))))
    (browse-url url)
    (if (yes-or-no-p "Was authentication successful? ")
	(flickr-get-token)
      (message "Cancelled"))))

;;; Set the API sig and get the REST response:

(defun flickr-get-api-sig (args)
  "Create a signature according to the shared secret and ARGS."
  (let ((sorted-args 
	 (sort args (lambda (a b) (string< (car a) (car b))))))
    ;; concat shared secret and other arguments
    (md5 (concat (flickr-secret)
		 (mapconcat (lambda(x) (concat (car x) (cdr x)))
			    sorted-args "")))))

(defun flickr-get-rest-response (query)
  "Get the REST response from QUERY."
  (with-temp-buffer
    (url-insert-file-contents
     (concat flickr-rest-base-url
	     (mapconcat 
	      (lambda (x) (concat (car x) "=" (cdr x) "&"))
	      query "")
	     "api_sig="
	     (flickr-get-api-sig query)))
    ;; Stupid fix handling truncated XML responses
    (goto-char (point-max))
    (if (not (looking-back "</rsp>\n*"))
	(progn (re-search-backward "</" nil t)
	       (delete-region (match-beginning 0) (point-max))
	       (insert "</rsp>\n")))
    (setq flickr-response-xml
          (condition-case nil
	      (xml-parse-region (point-min) (point-max))
	    (error nil)))))

;;; Flickr API functions:

(defun flickr-contacts-getPublicList (user-id &optional per-page page)
  "Get the list of public contacts for user USER-ID.
PER-PAGE is either 'max or the number of photos per page.
PAGE is the page to fetch."
  (flickr-get-rest-response
   (list (cons "method" "flickr.contacts.getPublicList")
         (cons "api_key" (flickr-api-key))
         (cons "user_id" user-id)
	 (cons "page" (or (and page (number-to-string page)) 1))
	 (cons "per_page" (cond ((eq per-page 'max) "1000")
				((stringp per-page) per-page) (t "1000"))))))

(defun flickr-contacts-getList (user-id)
  "Get the list of public groups for user USER-ID."
  (flickr-get-rest-response
   (list (cons "method" "flickr.contacts.getList")
         (cons "api_key" (flickr-api-key))
         (cons "auth_token" (flickr-token)))))

(defun flickr-people-getPublicPhotos (user-id &optional per-page page)
  "Get the list of public photo for user USER-ID.
PER-PAGE is either 'max or the number of photos per page.
PAGE is the page to fetch."
  (flickr-get-rest-response
   (list (cons "method" "flickr.people.getPublicPhotos")
         (cons "api_key" (flickr-api-key))
         (cons "user_id" user-id)
	 (cons "page" (or (and page (number-to-string page)) 1))
	 (cons "per_page" (cond ((eq per-page 'max) "500")
				((stringp per-page) per-page) (t "100"))))))

(defun flickr-people-getPublicGroups (user-id)
  "Get the list of public groups for user USER-ID."
  (flickr-get-rest-response
   (list (cons "method" "flickr.people.getPublicGroups")
         (cons "api_key" (flickr-api-key))
         (cons "user_id" user-id))))

(defun flickr-groups-pools-getPhotos 
  (group-id &optional per-page page auth)
  "Get the list of public photos for GROUP-ID.
PER-PAGE is either 'max or the number of photos per page.  PAGE
is the page to fetch.  AUTH means that your calling this method
while being authenticated."
  (flickr-get-rest-response
   (list (cons "method" "flickr.groups.pools.getPhotos")
         (cons "api_key" (flickr-api-key))
         (cons "group_id" group-id)
	 (cons "page" (or (and page (number-to-string page)) 1))
	 (cons "per_page" (cond ((eq per-page 'max) "500")
				((stringp per-page) per-page) (t "100")))
	 (if auth (cons "auth_token" (flickr-token))))))

(defun flickr-groups-getInfo (group-id)
  "Get info for group USER-ID."
  (flickr-get-rest-response
   (list (cons "method" "flickr.groups.getInfo")
         (cons "api_key" (flickr-api-key))
         (cons "group_id" group-id))))

(defun flickr-photos-getInfo (photo-id &optional secret)
  "Get general information for PHOTO-ID.
Optional SECRET argument lets you skip the permissions checking."
  (flickr-get-rest-response
   (list (cons "method" "flickr.photos.getInfo")
         (cons "api_key" (flickr-api-key))
         (cons "photo_id" photo-id)
         (if secret (cons "secret" secret)))))

(defun flickr-photos-getExif (photo-id)
  "Get the exif info from PHOTO-ID."
  (flickr-get-rest-response
   (list (cons "method" "flickr.photos.getExif")
         (cons "api_key" (flickr-api-key))
         (cons "photo_id" photo-id))))

(defun flickr-photos-comments-getList (photo-id)
  "Get the list of comments for PHOTO-ID."
  (flickr-get-rest-response
   (list (cons "method" "flickr.photos.comments.getList")
         (cons "api_key" (flickr-api-key))
         (cons "photo_id" photo-id))))

(defun flickr-urls-lookup-groups (url)
  "Lookup for the group is and name from URL."
  (flickr-get-rest-response
   (list (cons "method" "flickr.urls.lookupGroup")
         (cons "api_key" (flickr-api-key))
         (cons "url" url))))

(defun flickr-get-group-id-from-url (url)
  "Get the group id from URL."
  (flickr-urls-lookup-groups url)
  (cdaadr (car (xml-get-children 
		(car flickr-response-xml) 'group))))

(defun flickr-get-groupname-from-url (url)
  "Get the group name from URL."
  (flickr-urls-lookup-groups url)
  (caddar (xml-get-children
	   (car (xml-get-children 
		 (car flickr-response-xml) 'group))
	   'groupname)))

(defun flickr-tags-getListPhoto (photo-id)
  "Get the list of tags for PHOTO-ID. 
Return this list as a emacs-lisp list."
  (flickr-get-rest-response
   (list (cons "method" "flickr.tags.getListPhoto")
         (cons "photo_id" photo-id)
         (cons "api_key" (flickr-api-key))))
  (mapcar
   (lambda (x)
     (car (cddr x)))
   ;; FIXME: what if no tags?
   (xml-get-children
    (car (xml-get-children
          (car (xml-get-children
                (car flickr-response-xml) 'photo)) 'tags)) 'tag)))
 

;;; Code for interacting with your flickr accound

;; - authentication
;; - upload
;; - change tags
;; - etc

;; (defun flickr-check-token

(provide 'flickr)

;;;  User Options, Variables



;;; flickr.el ends here
