;; pnw-findr.el Breadth-first file-finding facility for (X)Emacs
;;  Dec 1, 2006

;; Copyright (C) 1999 Free Software Foundation, Inc.

;; Author: David Bakhash <cadet@bu.edu>
;; Maintainer: David Bakhash <cadet@bu.edu>
;; Version: 0.7
;; Created: Tue Jul 27 12:49:22 EST 1999
;; Keywords: files

;; This file is not part of emacs or XEmacs.

;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with XEmacs; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.


;;; Commentary:

;; This code contains a command, called `findr', which allows you to
;; search for a file breadth-first.  This works on UNIX, Windows, and
;; over the network, using efs and ange-ftp. It's pretty quick, and (at
;; times) is a better and easier alternative to other mechanisms of
;; finding nested files, when you've forgotten where they are.

;; You pass `findr' a regexp, which must match the file you're looking
;; for, and a directory, and then it just does its thing:

;; M-x findr <ENTER> ^my-lib.p[lm]$ <ENTER> c:/ <ENTER>

;; If called interactively, findr will prompt the user for opening the
;; found file(s).  Regardless, it will continue to search, until
;; either the search is complete or the user quits the search.
;; Regardless of the exit (natural or user-invoked), a findr will
;; return a list of found matches.

;; Two other entrypoints let you to act on regexps within the files:
;; `findr-search' to search
;; `findr-query-replace' to replace


;;; Installation:

;; (autoload 'findr "findr" "Find file name." t)
;; (define-key global-map [(meta control S)] 'findr)

;; (autoload 'findr-search "findr" "Find text in files." t)
;; (define-key global-map [(meta control s)] 'findr-search)

;; (autoload 'findr-query-replace "findr" "Replace text in files." t)
;; (define-key global-map [(meta control r)] 'findr-query-replace)


;; Change Log:

;; 0.1: Added prompt to open file, if uses so chooses, following
;;      request and code example from Thomas Plass.
;; 0.2: Made `findr' not stop after the first match, based on the
;;      request by Thomas Plass.
;;      Also, fixed a minor bug where findr was finding additional
;;      files that were not correct matches, based on
;;      `file-relative-name' misuse (I had to add the 2nd arg to it).
;; 0.3: Added a `sit-for' for redisplay reasons.
;;      Modifications as suggested by RMS: e.g. docstring.
;; 0.4  Added `findr-query-replace', courtesy of Dan Nelsen.
;; 0.5  Fixed spelling and minor bug in `findr-query-replace' when
;;      non-byte-compiled.
;; 0.6  http://groups.google.com/groups?selm=cxjhfml4b2c.fsf_-_%40acs5.bu.edu :
;; From: David Bakhash (cadet@bu.edu)
;; Subject: Re: latest version of findr.el (5)
;; Date: 1999/07/31
;; Courtesy of Dan Nelsen, this version has search-and-replace capabilities.
;; it's still a bit experimental, so I wouldn't expect too much of it.  But it
;; hasn't been tested yet for friendly behavior.
;;
;; The function `findr-query-replace' wasn't working unless you byte-compile the
;; file.  But, since findr is really designed for speed, that's not a bad thing
;; (i.e. it forces you to byte-compile it).  It's as simple as:
;;
;; M-x byte-compile-file <ENTER> /path/to/findr.el <ENTER>
;;
;; anyhow, I think it should work now.
;;
;; dave
;;
;; 0.7: Added `findr-search', broke `findr' by Patrick Anderson
;; 0.8: fixed 0.7 breakage by Patrick Anderson
;; 0.9: Added customize variables, added file/directory filter regexp
;;      minibuffer history by attila.lendvai@gmail.com
;; 0.9.1: Updated date at the top of the file, added .svn filter
;; 0.9.2: Added support for skipping symlinks

(eval-when-compile
  (require 'cl))

(require 'filedb)

(provide 'pnw-findr)

(defgroup findr nil
  "findr configuration."
  :prefix "findr-"
  :group 'findr)

(defvar findr-search-regexp-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'findr-search-regexp-history t))

(defvar findr-search-replacement-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'findr-search-replacement-history t))

(defvar findr-file-name-regexp-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'findr-file-name-regexp-history t))

(defvar findr-directory-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'findr-directory-history t))

(defun findr-read-search-regexp (&optional prompt)
  (read-from-minibuffer
   (or prompt "Search through files for (regexp): ")
   nil nil nil 'findr-search-regexp-history))

(defun findr-read-file-regexp (&optional prompt)
  (read-from-minibuffer
   (or prompt "Look in these files (regexp): ")
   (first findr-file-name-regexp-history)
   nil nil 'findr-file-name-regexp-history))

(defun findr-read-starting-directory (&optional prompt)
  (apply 'read-directory-name
         (append
          (list (or prompt "Start in directory: ") default-directory
                default-directory t nil)
          (when (featurep 'xemacs)
            (list 'findr-directory-history)))))

(defun* findr-scan (fmatch dmatch dir &key (prompt-p (interactive-p)) (skip-symlinks t))
  "Scan directory DIR breadth-first for files matching regexp FPATT.
If PROMPT-P is non-nil, or if called interactively, Prompts for
visiting search result\(s\)."
  (let ((*dirs* (findr-make-queue))
        *files*)
    (cl-labels ((findr-1 (dir)
                      ;;(message "Searching %s ..." (faze dir 'dir))
                      (let ((subs (directory-files dir t (if (stringp fmatch) fmatch))))
                        ;;(message (concat "subs length: " (number-to-string (length subs))))
                        (loop
                         for sub in subs ;for sub-file in sub list
                         for fname = (file-relative-name sub dir) ;filter patterns operate on relative names
                         when (and ;;(progn (message "findr: Checking dir: %s " (faze sub 'dir)) t)
                               (file-directory-p sub) ;if sub is a directory
                               (string-match (or dmatch "") fname)
                               (and skip-symlinks (not (file-symlink-p sub))) ;skip symbolic links
                               )
                         do (progn
                              ;;(message "findr: Enqueueing directory %s" sub)
                              (findr-enqueue sub *dirs*)
                              )
                         when (and ;;(progn (message "findr: Checking file: %s " fname) t)
                               (string-match (or fmatch "") fname) ;if our pattern FMATCH matches sub file FNAME
                               (and skip-symlinks (not (file-symlink-p sub))) ;skip symbolic links
                               )
                         do
                         ;; Don't return directory names when
                         ;; building list for `tags-query-replace' or `tags-search'
                         ;;(when (and (file-regular-p sub)
                         ;;           (not prompt-p))
                         ;;  (push sub *files*))

                         ;; _never_ return directory names
                         (when (file-regular-p sub)
                           ;;(message "findr: Adding file %s" (faze sub 'file))
                           (push sub *files*)
                           )
                         (when (and prompt-p
                                    (y-or-n-p (format "Find file %s? " (faze sub 'file))))
                           (find-file sub)
                           (sit-for 0)	; redisplay hack
                           )))))
      (unwind-protect
          (progn
            (findr-enqueue dir *dirs*)
            (while (findr-queue-contents *dirs*)
              (findr-1 (findr-dequeue *dirs*)))
            (message "findr(): Searching %s traversed %d directories and gave %d hits"
                     (faze dir 'dir)
                     (faze (length *dirs*) 'num)
                     (faze (length *files*) 'num)))
        (return-from findr (nreverse *files*))))))

(defun findr-query-replace (from to fmatch dmatch dir)
  "Do `query-replace-regexp' of FROM with TO, on each file found by findr.
If you exit (\\[keyboard-quit] or ESC), you can resume the query replace
with the command \\[tags-loop-continue]."
  (interactive (let ((search-for (findr-read-search-regexp "Replace text (regexp): ")))
                 (list search-for
                       (read-from-minibuffer (format "Replace '%s' by: " (faze search-for 'regexp))
                                             nil nil nil 'findr-search-replacement-history)
                       (findr-read-file-regexp)
                       (findr-read-starting-directory))))
  (tags-query-replace from to nil '(findr-scan fmatch dmatch dir)))

(defun findr-search (regexp files dir)
  "Search through all files listed in tags table for match for REGEXP.
Stops when a match is found.
To continue searching for next match, use command \\[tags-loop-continue]."
  (interactive (list (findr-read-search-regexp)
                     (findr-read-file-regexp)
                     (findr-read-starting-directory)))
  (tags-search regexp '(findr-scan files dir)))


(defun findr-find-files (files dir)
  "Same as `findr' except file names are put in a compilation buffer."
  (interactive (list (findr-read-file-regexp)
                     (findr-read-starting-directory)))
  ;; ToDo: open a scratch buffer or store in the clipboard
  (mapcar 'message (findr-scan files dir)))

;;;; Queues

(defun findr-make-queue ()
  "Build a new queue, with no elements."
  (let ((q (cons nil nil)))
    (setf (car q) q)
    q))

(defun findr-enqueue (item q)
  "Insert item at the end of the queue."
  (setf (car q)
        (setf (rest (car q))
              (cons item nil)))
  q)

(defun findr-dequeue (q)
  "Remove an item from the front of the queue."
  (prog1 (pop (cdr q))
    (when (null (cdr q))
      (setf (car q) q))))

(defsubst findr-queue-contents (q)
  (cdr q))

;;; findr.el ends here
