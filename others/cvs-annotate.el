;;; cvs-annotate.el --- cvs annotate interface for emacs.

;; Copyright (C) 1997-2000 Free Software Foundation, Inc.

;; Author: Kevin A. Burton (burton@openprivacy.org)
;; Maintainer: Kevin A. Burton (burton@openprivacy.org)
;; Location: http://relativity.yi.org
;; Keywords: cvs annotate
;; Version: 1.0.1

;; This file is [not yet] part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2 of the License, or any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; if not, write to the Free Software Foundation, Inc., 59 Temple
;; Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Introduction:

;; When working with CVS, it is nice to know who is responsible for sections of
;; writing code.  cvs-annotate.el is an interface to Emacs that allows
;; developers to view this information in a convenient manner.

;; cvs-annotate provides the following features:

;; remove redundant 'cvs annotate' lines.

;; [return] on an annotated line will show you the log that was checked into CVS
;; for that specific revision number.

;; [C-return] highlight the revision on the current line.

;; [C-down] goto the next CVS revision

;; [C-up] goto the previous CVS revision

;;; Commentary:

;; For starters... YES I KNOW THERE ALREADY IS `vc-annotate'..  I didn't like
;; it (not that the author didn't do an amazing job it just wasn't my cup of
;; tea.)  I wanted a cvs-annotate that was similar to webcvs.  It
;; might be a good idea to merge these in the future.  vc-annotate colors the
;; whole buffer and leaves all the annotation information.  cvs-annotate tries
;; to remove redundant annotation lines and only marks the current revision.
;; You can highlight multiple revisions if you want.  cvs-annotate has
;; additional features as well.  It allows you to view the log entry for a
;; specific revision and the diff that was applied.
;;
;; I would really love to see these modifications make it into the standard
;; emacs vc.el package.  Until that point it will be known as cvs-annotate.
;;
;; Should this become part of pcl-cvs???
;;
;;; Requirements:
;;
;; Emacs with ELib: http://theoryx5.uwinnipeg.ca/gnu/elib/elib.html
;;
;; ;; In order to use this.  You need to be open a file that is managed by CVS.
;; You can then run 'cvs-annotate' and another buffer will pop up with the cvs
;; annotation.

;;; TODO:

;; - Is there any way to get this to work with the major mode still on??? And
;;   not in another buffer?
;;
;; - provide some overview information at the top.  Date created, and then a
;;   breakdown of the users that have edited the document.
;;
;; - add support to diff to the previous version.
;;
;; - If CVS returns an error... make sure that we catch it... this happens
;;   when Ethernet is down.
;;
;; - go over everything and remove HACKs and make sure we aren't calling
;;   set-buffer too many times.
;;
;; - don't use kill-line.  This will insert things into the kill-ring.  Instead
;;   use something like:
;;     (delete-region (point) (progn (forward-line 3) (point)))
;;
;; - rethink the way I manage buffers.  I am using incorrect buffer functions
;;   internally and am naming buffers incorrectly.  Have all my global values use
;;   buffer objects and not filename strings.  Also try to get rid of duplicate
;;   calls to set-buffer
;;
;; use call-process

;;; History:
;;
;; Thu Nov 30 20:53:46 2000 (burton): removed cvs-annotate-mode-off... since it
;; was a major-mode this was not necessary.

(require 'easymenu)
(require 'vc)
(require 'vc-hooks)

;;provided by elib
(require 'stack-f)

;;; Code:
(defvar cvs-annotate-version "1.0.0")

(defvar cvs-annotate-log-buffer "*CVS Annotate Log*" "Buffer storing cvs log info.")

(defvar cvs-annotate-file-annotation-buffer "*CVS Annotate Temp Log*" "Buffer storing temp cvs log info.")

(defvar cvs-annotate-current-buffer nil "The buffer to annotate.")

(defvar cvs-annotate-log-entries-alist nil "Associated list for holding revision -> logentry map.")

(defvar cvs-annotate-highlights nil "List of the currently highlighted revision(s)  (overlay(s)).")

(defvar cvs-annotate-clean-revision-regexp "^.................................: "
  "Regexp for matching annotation lines")

(defvar cvs-annotate-clean-revision-replacement "-                                : "
  "Replacement for a redundant annotation line")

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BEGIN MODE SPECIFIC CODE
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cvs-annotate-mode-string "CVS-Annotate" "Major mode string.")

(defvar cvs-annotate-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-d" 'cvs-annotate-show-previous-revision-diff)
    (define-key map [(control return)] 'cvs-annotate-highlight-current-line)
    (define-key map [(return)] 'cvs-annotate-show-loginfo)
    (define-key map [(control down)] 'cvs-annotate-next-revision)
    (define-key map [(control up)] 'cvs-annotate-previous-revision)
    map)
  "Mode specific keymap for `cvs-annotate-mode'")

(defvar cvs-annotate-mode nil  "Non-nil means cvs-annotate local minor mode is enabled.")

(defvar cvs-annotate-mode-menu nil "Menu for cvs-annotate mode")
(easy-menu-define
 cvs-annotate-mode-menu
 cvs-annotate-mode-map
     "Cvs Annotate menu"
     (list
      "CVS Annotate"
      ["Highlight revision" cvs-annotate-highlight-current-line t]
      ["Show CVS log" cvs-annotate-show-loginfo t]
      ["Show 'cvs diff' for current annotation" cvs-annotate-show-previous-revision-diff t]
      "----"
      ["Goto next revision" cvs-annotate-next-revision t]
      ["Goto previous revision" cvs-annotate-previous-revision t]))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; END MODE SPECIFIC CODE
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; (defface cvs-annotate-default-side-face '((t (:background "gray80")))
;;   "Face used to highlight the annotation lines to the left of the annotate buffer.")

;; (defface cvs-annotate-highlight-revision-face '((t (:foreground "BlueViolet" :bold t)))
;;   "Face used to highlight the annotation lines to the left of the annotate buffer.")

(defface cvs-annotate-default-side-face '((t (:background "gray20")))
  "Face used to highlight the annotation lines to the left of the annotate buffer.")
  
(defface cvs-annotate-highlight-revision-face '((t (:foreground "GoldenRod" :bold t)))
  "Face used to highlight a specific revision.")

(defun cvs-annotate()
  "Run 'cvs annotate' on the current buffer."
  (interactive)

  ;; if vc-mode is not null then it must be in CVS
  (if vc-mode
      (progn

        ;; init all buffer information
        (cvs-annotate-buffer-init)

        ;;insert version information
        (set-buffer (cvs-annotate-get-temp-buffer))
        (insert "===============================================================================\n")

        (insert (concat "Annotation for local version: "
                        (vc-workfile-version cvs-annotate-current-buffer)
                        "\n"))

                                        ;(let (status)
                                        ;  (setq status (vc-cvs-status cvs-annotate-current-buffer))

        (insert "===============================================================================\n")

        ;; run cvs annotate
        (let (buffer)

          (message "Fetching annotation...")

          (setq buffer (cvs-annotate-get-temp-buffer))
          (set-buffer buffer)

          ;; make this buffer use the correct
          (setq default-directory (file-name-directory cvs-annotate-current-buffer))

          ;; FIXME: use call-process here.
          (insert (shell-command-to-string (concat "cvs annotate " (file-name-nondirectory cvs-annotate-current-buffer))))

          (message "Fetching annotation... DONE"))

        ;; kill the first two lines of 'cvs annotate' output
        (cvs-annotate-delete-header)

        (set-buffer (cvs-annotate-get-temp-buffer))

        (cvs-annotate-clean-duplicate-revision-lines (cvs-annotate-get-temp-buffer))

        (goto-char (point-min))

        ;;highlight the current revision
        (cvs-annotate-highlight-revision)

        ;;Make sure this buffer isn't read-only

        (view-buffer (cvs-annotate-get-temp-buffer))
        (toggle-read-only 1))
    (error "Current buffer is not covered under CVS")))

(defun cvs-annotate-delete-header()
  "Delete useless info from the 'cvs annotate' headers."
  (save-excursion
    (goto-char (point-min))
    (forward-line 3)
    (kill-line 4)))

(defun cvs-annotate-buffer-init()
  "Clear the temp buffer if there is data in it"

  (setq cvs-annotate-current-buffer (buffer-file-name))

  (if (null cvs-annotate-current-buffer)
      (error "UNKNOWN CURRENT BUFFER"))

  ;;switch to the correct buffer
  (set-buffer (get-buffer-create (cvs-annotate-get-temp-buffer)))

  ;; turn on cvs-annotate-mode for this buffer
  (cvs-annotate-mode)

  ;;erase it just in case the user runs cvs-annotate twice.
  (erase-buffer))

(defun cvs-annotate-clean-duplicate-revision-lines(&optional temp-buffer-name)
   "After cvs-annotate is run, go over the buffer and remove lines that have
   dupicate revisions/authors. `temp-buffer-name' is the buffer target which you
   need cleaning.

  This function looks at the output of `cvs-annotate' or 'cvs annotate' and
  removes duplicate annotation lines.
  
  EXAMPLE BEFORE:
  
  
  1.49         (burton   22-Oct-00): ;;*******************************************************************************
  1.82         (burton   22-Nov-00): ;;Last-Modified: $Date: 2003/01/10 05:57:59 $
  1.82         (burton   22-Nov-00): ;;Version: $Id: cvs-annotate.el,v 1.20 2003/01/10 05:57:59 burton Exp $
  1.49         (burton   22-Oct-00): ;;Author:  Kevin A. Burton ( burton@openprivacy.org )
  1.49         (burton   22-Oct-00): ;;*******************************************************************************
  1.49         (burton   22-Oct-00):


  EXAMPLE AFTER:


  1.49         (burton   22-Oct-00): ;;*******************************************************************************
  1.82         (burton   22-Nov-00): ;;Last-Modified: $Date: 2003/01/10 05:57:59 $
                                   : ;;Version: $Id: cvs-annotate.el,v 1.20 2003/01/10 05:57:59 burton Exp $
  1.49         (burton   22-Oct-00): ;;Author:  Kevin A. Burton ( burton@openprivacy.org )
                                   : ;;*******************************************************************************
                                   :"
  (save-excursion
    ;; use the correct buffer
    (set-buffer temp-buffer-name)

    (let (line-count i last-match current-match)
      (setq line-count (count-lines (point-min) (point-max)))

      (goto-char (point-min))

      ;; goto the first line of beginning of annotations
      (forward-line 3)
      (setq i 4)

      ;; use a default last-match
      (setq last-match "")

      (while (<= i line-count)

        (search-forward-regexp cvs-annotate-clean-revision-regexp nil t)
        (setq current-match (match-string 0))

        (if (string= current-match last-match)
            (replace-match cvs-annotate-clean-revision-replacement))

        (cvs-annotate-set-overlay-match)

        (setq last-match current-match)

        (setq i (1+ i))
        (forward-line 1)))))

(defun cvs-annotate-set-overlay-match()
  "Set the overlay for the current match"

  (let (current-overlay)

    (setq current-overlay (make-extent (match-beginning 0) (match-end 0)))

    (set-extent-property current-overlay 'face 'cvs-annotate-default-side-face)

    (set-extent-property current-overlay 'window (selected-window))))

(defun cvs-annotate-get-temp-buffer()
  "Get the temp buffer to use for cvs annotations."
  (concat "*CVS Annotate " cvs-annotate-current-buffer "*"))

(defun cvs-annotate-mode()
  "Turn on `cvs-annotate-mode'."
  (interactive)

  (kill-all-local-variables)
  (use-local-map cvs-annotate-mode-map)

  (setq major-mode 'cvs-annotate-mode)
  (setq mode-name cvs-annotate-mode-string)

  ;; set cvs-annotate-mode to t which should mean on.
  (make-local-variable 'cvs-annotate-mode)
  (make-local-variable 'cvs-annotate-current-buffer)
  (make-local-variable 'cvs-annotate-log-entries-alist)

  (setq cvs-annotate-mode t)

  (make-local-variable 'cvs-annotate-highlights)
  (setq cvs-annotate-highlights (stack-create))

  ;;should still be nil so that the log entries are made when the user first
  ;;requests them
  (make-local-variable 'cvs-annotate-log-entries-alist)

  ;;setup stack buffer to manage highlights.
  ;(make-variable-buffer-local 'cvs-annotate-highlights)
  ;(setq cvs-annotate-highlights (stack-create))

  (run-hooks 'cvs-annotate-mode-hook)

  (easy-menu-add cvs-annotate-mode-menu))

(defun cvs-annotate-get-revision-current-line()
  "Get the revision of the current line or nil"

  ;;determine what revision
  (save-excursion
    (goto-char (point-at-eol))

    ;; search backward for a revision number or error...
    (if (search-backward-regexp "^[0-9]+\.[0-9]+" nil t)
        (match-string-no-properties 0)
      nil)))

(defun cvs-annotate-show-loginfo(revision)
  "Given a revision... get the log for it and pop it to the user."
  (interactive
   (list 
    (cvs-annotate-get-revision-current-line)))
    
  (if revision

      ;; CVS command should be...
      ;;  'cvs log -r1.1 .emacs'

      (progn

        (message "Showing log for revision: %s" revision)

        ;; run cvs annotate if the hash of entries has not been setup
        (if (null cvs-annotate-log-entries-alist)

            (let(command hash)

              ;; create a hash with an init of 20 entries..
              ;; (20 seems to be a decent average start)
              (setq cvs-annotate-log-entries-alist '())

              (setq command (concat "cvs log "
                                    (file-name-nondirectory cvs-annotate-current-buffer)))

              (set-buffer (get-buffer-create cvs-annotate-file-annotation-buffer))
              (erase-buffer)

              ;;change to the correct directory.
              (setq default-directory (file-name-directory cvs-annotate-current-buffer))

              (insert (shell-command-to-string command))

              ;; now parse out the buffer into the associated list

              ;; File format should be the following...

              ;;----------------------------
              ;;revision 1.25
              ;;date: 2000/11/29 11:01:03;  author: burton;  state: Exp;  lines: +35 -8
              ;;added support for showing diffs based on previous revision

              (goto-char (point-min))

              (cvs-annotate-clean-log-buffer)

              (save-excursion
                (while (search-forward "revision " nil t)
                  (let (revision)
                    (search-forward-regexp "[0-9\\.]+$" nil t)
                    (setq revision (match-string 0))
                    (let (begin end log-entry log-end)

                      (forward-line 1)

                      (setq begin (point))
                      (setq log-end-regexp "^----------------------------$")

                      (search-forward-regexp log-end-regexp nil t)

                      ;; end is the point - the length of the regexp - 2...

                      (setq end (- (point) (- (length log-end-regexp) 2)))
                      (setq log-entry (buffer-substring begin end))

                      ;; now that we have the revision number and log-entry add them to the hash

                      ;;FIXME: need to modify this value in the CVS annotate
                      ;;buffer.
                      (save-excursion
                        (set-buffer cvs-annotate-current-buffer)
                        (add-to-list 'cvs-annotate-log-entries-alist (cons revision log-entry)))))))))

        (redraw-display)

        (message "Showing log for revision: %s%s" revision " DONE")

        ;; now pull the information from the hashtable and place this into the log-buffer

        (let (log-entry)

          (set-buffer (cvs-annotate-get-temp-buffer))

          ;; pull out the correct log-entry before changing buffers
          (setq log-entry (cdr (assoc revision cvs-annotate-log-entries-alist)))

          (unless log-entry
            (error "Unable to find revision for %s" revision))
          
          (set-buffer (get-buffer-create cvs-annotate-log-buffer))
          (erase-buffer) ;; just in case..

          ;;mimic the cvs log format... format should be:
          ;;----------------------------
          ;;revision 1.25
          ;;date: 2000/11/29 11:01:03;  author: burton;  state: Exp;  lines: +35 -8
          ;;added support for showing diffs based on previous revision

          (insert "---------------------------\n")
          (insert (concat "revision " revision "\n"))
          (insert log-entry)

        ;; need to redraw the frame here.. at the very minimum this alerts the
        ;; user that something has happened

        ;; now highlight the actual log entry...
          (cvs-annotate-create-log-buffer-overlay (display-buffer cvs-annotate-log-buffer))))
    (error "Unknown revision")))

(defun cvs-annotate-clean-log-buffer()
   "Go through the log buffer and clean it up so that the user only sees a log
   and not extra info."

  (save-excursion

    (set-buffer (get-buffer-create cvs-annotate-file-annotation-buffer))

    (goto-char (point-min))
    (kill-line 11)

    ;; remove the last line ... which should be: ==============
    (if (search-forward "=============================================================================" nil t)
        (progn
          (goto-char (point-at-bol))
          (kill-line)
          (insert "----------------------------\n")))))

(defun cvs-annotate-show-previous-revision-diff()
  "Show the diff necessary to apply the current annotation line"
  (interactive)
  (let (current-revision)

    (setq current-revision (cvs-annotate-get-revision-current-line))

    (if (not (null current-revision))
        (let (previous-revision)

          (if (string= current-revision "1.1")
              (error "No diff information available for initial revision number: 1.1")

            (setq previous-revision (vc-previous-version current-revision))
            (message "Showing diff between revisions %s%s%s" current-revision " and " previous-revision)
            (vc-version-diff cvs-annotate-current-buffer current-revision previous-revision)))
      (message "No revision info for current line"))))

(defun cvs-annotate-highlight-clear-all-overlays()
  "Remove all current highlights..."

  (set-buffer (cvs-annotate-get-temp-buffer))

  (while (not (= (stack-length cvs-annotate-highlights) 0))
    (let (current-highlight)
      (setq current-highlight (stack-pop cvs-annotate-highlights))
      (delete-extent current-highlight))))

(defun cvs-annotate-highlight-add-overlay( overlay )
  "Add the given highlight to the list of overlays."

  (set-buffer (cvs-annotate-get-temp-buffer))

  (stack-push cvs-annotate-highlights overlay))

(defun cvs-annotate-highlight-revision( &optional revision-number )
  "Highlight the given revision number."

  ;; if the revision-number is not specified... use the local revision.

  ;; get rid of all current highlights
  (cvs-annotate-highlight-clear-all-overlays)

  (if (null revision-number)
      (setq revision-number (vc-workfile-version cvs-annotate-current-buffer)))

  (message "Highlighting revision number: %s" revision-number)

  ;; now go through and highlight the specified revision...

  (goto-char (point-min))

  ;; search for lines that begin with this revision number...

  (save-excursion
    (while (search-forward-regexp (concat "^" revision-number ".+$") nil t)
        (progn

          (cvs-annotate-highlight-add-overlay (cvs-annotate-overlay-match 'cvs-annotate-highlight-revision-face))
          ;; now highlight all of the same region..
          (forward-line 1)
          (while (cvs-annotate-highlight-next-same-revision))))))

(defun cvs-annotate-highlight-current-line()
  "Highlight the revision shown on the current line"
  (interactive)

  ;; get rid of all current highlights
  (cvs-annotate-highlight-clear-all-overlays)

   (save-excursion
     (let (current-revision)
       (setq current-revision (cvs-annotate-get-revision-current-line))

       ;(message current-revision)

       (if (not (null current-revision))
           (cvs-annotate-highlight-revision current-revision)
         (error "Unknown revision")))))

(defun cvs-annotate-highlight-next-same-revision()
  "highlight the same next revision... or nil if there isn't one"

  (let (line-end-point result)

     (goto-char (point-at-eol))
     (setq line-end-point (point))
     (goto-char (point-at-bol))

     (setq result (search-forward-regexp (concat "^-.+$") line-end-point t))

     (if (not (null result))
         (cvs-annotate-highlight-add-overlay (cvs-annotate-overlay-match 'cvs-annotate-highlight-revision-face)))

  (forward-line 1)

  (not (null result))))

(defun cvs-annotate-overlay-match(face)
  "Given a face... overlay the current match... return the overlay that was created."

    (let (current-overlay)
      (setq current-overlay (make-extent (match-beginning 0) (match-end 0)))

      (set-extent-property current-overlay 'face face)

      (set-extent-property current-overlay 'window (selected-window))
      current-overlay))

(defun cvs-annotate-create-log-buffer-overlay(window)
  "Create the correct overlay for the log buffer."

    (let (current-overlay)

      (set-buffer cvs-annotate-log-buffer)

      (save-excursion
        (goto-char (point-min))
        (forward-line 3)
        (setq current-overlay (make-extent (point) (point-max)))

        (set-extent-property current-overlay 'face 'cvs-annotate-highlight-revision-face)

        (set-extent-property current-overlay 'window window))))

(defun cvs-annotate-version()
  "Display the installed version of cvs-annotate"
  (interactive)
  (message cvs-annotate-version))

(defun cvs-annotate-next-revision()
  "Go to the next reversion"
  (interactive)

  (forward-line 1)
  (if (re-search-forward "^[0-9]" nil t)
      (goto-char (point-at-bol))
    (progn
      (forward-line -1)
      (error "No more revisions"))))

(defun cvs-annotate-previous-revision()
  "Go to the previous reversion"
  (interactive)

  (forward-line -1)
  (if (re-search-backward "^[0-9]" nil t)
      (goto-char (point-at-bol))
    (progn
      (forward-line 1)
      (error "No more revisions"))))

;; install as a minor-mode
(add-to-list 'minor-mode-alist
             '(cvs-annotation-mode cvs-annotation-mode-string))

(provide 'cvs-annotate)

;;; cvs-annotate.el ends here
