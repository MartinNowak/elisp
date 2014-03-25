;;; ldif-ns.el --- convert name service records to LDIF records

;; Copyright (C) 2004, 2005  Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: data
;; $Revision: 1.3 $

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This package converts some types of name service records to LDIF
;; format for loading into an LDAP server with the appropriate schema.

;; Replaces the processing of /etc/passwd from the PADL migrationtools
;; scripts, for instance.  PADL generates a single record for each
;; entry.  This version assumes that account and person entries are
;; separate, and makes ldif records as follows.  From:

;; fb:*:11440:12229:F.Bloggs:/home/fb:/bin/csh

;; `ldif-ns-passwd' generates:

;; dn: uid=fb,ou=People,dc=dl,dc=ac,dc=uk
;; objectClass: posixAccount
;; objectClass: top
;; objectClass: shadowAccount
;; objectClass: account
;; uid: fb
;; cn: fb
;; uidNumber: 11440
;; gidNumber: 12229
;; gecos: Fred Bloggs
;; homeDirectory: /home/fb
;; loginShell: /bin/csh
;; cn: Fred Bloggs
;; 
;; dn: cn=Fred Bloggs,ou=People,dc=dl,dc=ac,dc=uk
;; objectClass: top
;; objectClass: person
;; objectClass: organizationalPerson
;; objectClass: inetOrgPerson
;; objectClass: eduPerson
;; cn: Fred Bloggs
;; displayName: Fred Bloggs
;; uid: fb
;; sn: Bloggs
;; initials: F
;; givenName:Fred
;; cn: F Bloggs
;; 

;; Possibly the gecos field should be dissected for comma-separated
;; fields.  Depending on the schema you use, you may need to adjust
;; the way things are inserted into the buffer below in an obvious
;; way.  My account records are under `People' for historical reasons
;; -- I think as a result of migrationtools putting the combined
;; account/person record there originally -- but they'd probably be
;; better elsewhere; I think libnss_pam will still cope.

;; There are also commands to process services and group databases,
;; `ldif-ns-services' and `ldif-ns-group'.

;; The commands create a buffer of the results, in LDIF mode, so you
;; need the library ldap-mode.el.  Unless you're at Daresbury, you'll
;; need at least to change `ldif-ns-root-dn', the root DN assumed to
;; contain RDNs `Group' and `Services' and those for people and
;; accounts, parameterized by `ldif-ns-person-rdn' and
;; `ldif-ns-account-rdn' respectively.

;; Here's an example of using it for a shell command, assuming this
;; library and ldap-mode are found on load-path, probably via
;; site-start.el.

;; #!/bin/sh
;; if [ $# -ne 2 -o "x$1" = x--help ]; then
;;     echo "Usage: `basename $0` <group input> <LDIF output>" 2>&1
;;     [ "x$1" = x--help ]; exit
;; fi
;; case $2 in
;;     -) out=`mktemp`
;;        trap "rm -f \"$out\"" EXIT ;;
;;     *) out=$2 ;;
;; esac
;; emacs --batch --eval "(progn (require 'ldif-ns) (ldif-ns-group-to-file \"$1\" \"$out\"))"
;; [ "x$2" = x- ] && cat "$out"

;;; Code:

(autoload 'ldif-mode "ldap-mode")

(defvar ldif-ns-result-buffer "*LDIF*")

(defvar ldif-ns-account-rdn "People"
  "LDAP RDN under which account records live.")

(defvar ldif-ns-person-rdn "People"
  "LDAP RDN under which records for people live.")

(defvar ldif-ns-root-dn "dc=dl,dc=ac,dc=uk"
  "*Distinguished name of the root of the directory tree.
This contains the `ldif-ns-person-rdn', `ldif-ns-account-rdn', Group
and Services RDNs.")

;;;; passwd

(defvar ldif-ns-min-uid 1001
  "*Minimum uid to consider.
Lower numbers are assumed to be system-dependent ones, which should
stay local.")

(defvar ldif-ns-max-uid 60000
  "*Maximum uid to consider.
Higher numbers are assumed to be potentially system-dependent ones which
should stay local, e.g. `nobody'.")

(defvar ldif-ns-min-gid ldif-ns-min-uid
  "*Minimum gid to consider.
Lower numbers are assumed to be system-dependent ones, which should
stay local.")

(defvar ldif-ns-max-gid ldif-ns-max-uid
  "*Maximum gid to consider.
Higher numbers are assumed to be potentially system-dependent ones which
should stay local, e.g. `nobody'.")

(defvar ldif-ns-getent-check nil
  "*Non-nil means check record with `getent(1)'.
Then don't output an LDIF record if getent finds one.")

(defun ldif-ns-passwd (file)
  "Process FILE to produce LDAP input.
FILE is in the format of /etc/passwd.  The output buffer contains the
corresponding LDIF data with DNs by uname and cn."
  (interactive "fPasswd file to convert? ")
  (with-temp-buffer
    (insert-file-contents file)
    (if (get-buffer ldif-ns-result-buffer)
	(kill-buffer ldif-ns-result-buffer))
    (while (not (eobp))
      (unless (looking-at "^[ \t]#")
	(if (looking-at "\\([^:\n]*\\):\\([^:\n]*\\):\\([^:\n]*\\):\
\\([^:\n]*\\):\\([^:\n]*\\):\\([^:\n]*\\):\\([^:\n]*\\)")
	    (when (if ldif-ns-getent-check
		      (not (and (equal 0 ; check uname
				       (call-process "getent" nil nil nil
						     "passwd"
						     (match-string 1)))
				(equal 0 ; check uid
				       (call-process "getent" nil nil nil
						     "passwd"
						     (match-string 3)))))
		    t)
	      (ldif-ns-passwd-record (match-string 1) (match-string 2)
				   (match-string 3) (match-string 4)
				   (match-string 5) (match-string 6)
				   (match-string 7)))))
      (forward-line))
    (pop-to-buffer ldif-ns-result-buffer)
    (ldif-mode)))
(defun ldif-ns-passwd-record (account password uid gid gecos directory shell)
  "Write an LDIF account record for the given passwd components."
  (when (and (>= (string-to-number uid) ldif-ns-min-uid)
	     (<= (string-to-number uid) ldif-ns-max-uid))
    (with-current-buffer (get-buffer-create ldif-ns-result-buffer)
      (buffer-disable-undo)
      (let* ((name (ldif-ns-name (replace-regexp-in-string "&" account
							   gecos)))
	     (surname (if name (ldif-ns-surname name)))
	     (initials (if name (ldif-ns-initials name)))
	     (givenname (if name (ldif-ns-given name))))
	(insert "\
dn: uid=" account ",ou=" ldif-ns-account-rdn "," ldif-ns-root-dn "
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
objectClass: account
uid: " account "
cn: " account "
uidNumber: " uid "
gidNumber: " gid "
")
	(if (/= 0 (length gecos))
	    (insert "gecos: " gecos ?\n))
	(if (/= 0 (length directory))
	    (insert "homeDirectory: " directory ?\n))
	(if (/= 0 (length gecos))
	    (insert "loginShell: " shell ?\n))
	(if name (insert "cn: " name ?\n))
	(newline)
	(when name
	  (insert "\
dn: cn=" name ",ou=" ldif-ns-person-rdn "," ldif-ns-root-dn "
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: eduPerson
cn: " name "
displayName: " name "
uid: " account "
")
	  (if surname (insert "sn: " surname ?\n))
	  (if initials (insert "initials: " initials ?\n))
	  (when givenname
	    (insert "givenName: " givenname ?\n
		    "cn: " initials " " surname ?\n))
	  (newline))))))

(defun ldif-ns-passwd-to-file (infile outfile)
  "Like `ldif-ns-passwd', but write the result from file INFILE to file OUTFILE."
  (interactive "fInput passwd file? \nFOutput LDIF file? ")
  (ldif-ns-passwd infile)
  (with-current-buffer ldif-ns-result-buffer
    (write-file outfile (interactive-p)))
  (kill-buffer ldif-ns-result-buffer))

(defun ldif-ns-name (gecos)
  "Return canonicalized personal name from the supplied GECOS field (or nil).
A personal name has a word at the end (surname) and at least one leading
name or initial.  Initials may be either an uppercase block or uppercase
letters separated by full stops.  The stops are stripped from the
canonicalized version, so that, say, `D.J.G.Love' becomes `DJG Love'."
  (setq gecos (or (car (split-string gecos ",")) ""))
  (let ((fields (delete "" (split-string gecos "[ .]"))))
    (if (> (length fields) 1)
	(replace-regexp-in-string "\\(\\<[[:alpha:]][ .]+\\)+"
				  (lambda (m)
				    (save-match-data
				      (concat (replace-regexp-in-string
					       "[ .]+" "" m)
					      " ")))
				  gecos))))

(defun ldif-ns-surname (name)
  "Return the surname part of NAME.
NAME is assumed to be the result of `ldif-ns-name'."
  (car (last (split-string name))))

(defun ldif-ns-given (name)
  "Return the given part of NAME, or nil.
NAME is assumed to be the result of `ldif-ns-name'."
  (let ((words (split-string name))
	case-fold-search)
    (if (string-match "^[[:upper:]][][:lower:]]" (car words))
	(car words))))

(defun ldif-ns-initials (name)
  "Return the initials from NAME.
NAME is assumed to be the result of `ldif-ns-name'."
  (let ((words (butlast (split-string name)))
	case-fold-search)
    (mapconcat (lambda (word)
		 (if (string-match "\\`[[:upper:]]+\\'" word)
		     word
		   (substring word 0 1)))
	       words "")))


;;;; services

(defvar ldif-ns-services-list nil
  "List of services read.
List of the form (PORT SERVICE-NAME PROTOCOLS ALIASES DESCRIPTION).")

(defun ldif-ns-services (file)
  "Process FILE to produce LDAP input.
FILE is in the format of /etc/services.  The output buffer contains the
corresponding LDIF data with DNs by uname and cn."
  (interactive "fServices file to convert? ")
  (setq ldif-ns-services-list nil)
  (with-temp-buffer
    (insert-file-contents file)
    (if (get-buffer ldif-ns-result-buffer)
	(kill-buffer ldif-ns-result-buffer))
    (with-syntax-table (copy-syntax-table)
      (aset (syntax-table) ?- '(2))
      (while (not (eobp))
	(unless (looking-at "^[ \t]#")
	  (if (looking-at "\\(\\sw+\\)\\s-+\\([[:alnum:]/]+\\)\\(\\(?:\\s-+\\sw+\\)+\\)?\\(?:\\s-*#\\(.*\\)\\)?")
	      (when (if ldif-ns-getent-check
			(not (equal 0
				    (call-process "getent" nil nil nil
						  "services"
						  (match-string 1))))
		      t)
	      (ldif-ns-services-record (match-string 1) (match-string 2)
				       (match-string 3) (match-string 4)))))
	(forward-line)))
    (pop-to-buffer (get-buffer-create ldif-ns-result-buffer))
    (buffer-disable-undo)
    (dolist (service (nreverse ldif-ns-services-list))
      (let ((aliases (nth 3 service)))
	(insert "\
dn: cn=" (nth 1 service) ",ou=Services," ldif-ns-root-dn "
objectClass: ipService
objectClass: top
cn: " (nth 1 service) ?\n)
	(dolist (alias aliases)
	  ;; Assume case isn't significant.
	  (unless (compare-strings alias nil nil (car service) nil nil t)
	    (insert "cn: " alias ?\n)))
	(insert "ipServicePort: " (nth 0 service) ?\n)
	(dolist (proto (nth 2 service))
	  (insert "ipServiceProtocol: " proto ?\n))
	(if (nth 4 service) (insert "description: " (nth 4 service) ?\n))
	(insert ?\n)))
    (ldif-mode)))

(defun ldif-ns-services-record (service port/proto aliases comment)
  (let* ((aliases (if aliases (split-string aliases)))
	 (_ (string-match "\\([^/]+\\)/\\(.*\\)" port/proto))
	 (port (match-string 1 port/proto))
	 (proto (match-string 2 port/proto))
	 (existing (assoc port ldif-ns-services-list))
	 (description (or (nth 4 existing)
			  comment))
	 (protos (cons proto (nth 2 existing)))
	 (aliases1 (cons service aliases)))
    (if (not existing)
	(push (list port service protos aliases description)
	      ldif-ns-services-list)
      (dolist (alias aliases1)
	(add-to-list 'aliases alias))
      (setcdr (cdr existing) (list protos aliases description)))))

(defun ldif-ns-services-to-file (infile outfile)
  "Like `ldif-ns-services', but write the result from file INFILE to file OUTFILE."
  (interactive "fInput services file? \nFOutput LDIF file? ")
  (ldif-ns-services infile)
  (with-current-buffer ldif-ns-result-buffer
    (write-file outfile (interactive-p))
    (kill-buffer (current-buffer))))


;;;; group

(defun ldif-ns-group (file)
  "Process FILE to produce LDAP input.
FILE is in the format of /etc/group.  The output buffer contains the
corresponding LDIF data with DN by gname."
  (interactive "fGroup file to convert? ")
  (with-temp-buffer
    (insert-file-contents file)
    (if (get-buffer ldif-ns-result-buffer)
	(kill-buffer ldif-ns-result-buffer))
    (aset (syntax-table) ?- '(2))
    (while (not (eobp))
      (unless (looking-at "^[ \t]#")
	(if (looking-at "\\([^:\n]*\\):\\([^:\n]*\\):\\([^:\n]*\\):\
\\([^:\n]*\\)")
	    (when (if ldif-ns-getent-check
		      (not (and (equal 0 ; check gname
				       (call-process "getent" nil nil nil
						     "group" (match-string 1)))
				(equal 0 ; check gid
				       (call-process "getent" nil nil nil
						     "group" (match-string 3)))))
		    t)
	    (ldif-ns-group-record (match-string 1) (match-string 2)
				  (match-string 3) (match-string 4)))))
      (forward-line))
    (pop-to-buffer ldif-ns-result-buffer)
    (ldif-mode)))

(defun ldif-ns-group-record (gname password gid members)
  "Write an LDIF group record from the supplied group fields."
  (when (and (>= (string-to-number gid) ldif-ns-min-gid)
	     (<= (string-to-number gid) ldif-ns-max-gid))
    (with-current-buffer (get-buffer-create ldif-ns-result-buffer)
      (buffer-disable-undo)
      (let ((members (split-string members "[, \t]+")))
	(insert "\
dn: cn=" gname ",ou=Group," ldif-ns-root-dn "
objectClass: posixGroup
objectClass: top
cn: " gname "
gidNumber: " gid ?\n)
	(dolist (member members)
	  (insert "memberUid: " member ?\n))
	(newline)))))

(defun ldif-ns-group-to-file (infile outfile)
  "Like `ldif-ns-group', but write the result from file INFILE to file OUTFILE."
  (interactive "fInput group file? \nFOutput LDIF file? ")
  (ldif-ns-group infile)
  (with-current-buffer ldif-ns-result-buffer
    (write-file outfile (interactive-p))
    (kill-buffer (current-buffer))))

(provide 'ldif-ns)
;;; ldif-ns.el ends here
