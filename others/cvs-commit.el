;;; cvs-commit.el --- smart cvs-commit interface for emacs.

;; $Id: cvs-commit.el,v 1.136 2004/06/25 05:10:37 burton Exp $

;; Copyright (C) 1997-2000 Free Software Foundation, Inc.

;; Author: Kevin A. Burton (burton@openprivacy.org)
;; Maintainer: Kevin A. Burton (burton@openprivacy.org)
;; Location: http://relativity.yi.org/emacs
;; Keywords: cvs commit
;; Version: 1.4.0

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

;;; Commentary:

;; cvs-commit.el is a Emacs modification for smarter cvs-commit management.  It
;; contains the following features:
;;
;; - emulates console "cvs commit" by providing standard cvs comments which most
;;   CVS users would expect.
;;
;; - after commits, show cvs output
;; 
;; - when you run cvs-commit, vc-diff is also ran so that while you are
;;   providing your CVS log you can look at what you have actually done so that
;;   you don't forget to correctly document something
;;
;; - when editing your cvs log, you can use C-return to scroll the diff output.
;;
;; - rebinds C-xC-q so that cvs-commit is the default commit mechanism.  
;;
;; - manage window geometry so that all this information is shown to the user in
;;   an obvious manner.
;;
;; I don't think this should conflict with current vc operation.  It is possible
;; that it is not hooked in perfectly as I have not used in all situations.  

;;; Install:

;; Put this file in your lisp load path, then do a (require 'cvs-commit) in your
;; .emacs file.  You can either invoke this with C-x C-q or directly via
;; M-x cvs-commit

;; You might also want to install diff-mode (used to be part of PCL-CVS) to
;; better use `cvs diff' output. Can be found at
;; ftp://rum.cs.yale.edu/pub/monnier/misc 

;;; History:
;;
;; - Fri Nov 29 2002 08:04 PM (burton@openprivacy.org): fully updated for Emacs
;; 21 and ECB.

;; - Fri Jun 01 2001 11:58 PM (burton@relativity.yi.org): Need to support
;; directories so that we can commit whole directories instead of just files.
;;
;; Fri Jun 01 2001 11:57 PM (burton@relativity.yi.org): Need to add a 'CVS
;; Commit' menu to the "Tools" menu.
;;
;; Mon Apr 2 19:59:43 2001 (burton@relativity.yi.org): ported to XEmacs by Brad
;; Giaccio <bgiaccio@psrw.com>
;;
;; Wed Dec  6 02:37:30 2000 (burton): init

;;; TODO:
;;
;; the point int eh current buffer is moved to the top... what is wrong with
;; this?
;;
;; What do I need to change to enable support for directories?
;;
;;  - abstract away we interact with CVS:
;;
;;    - vc-diff should be handled by cvs-diff
;;
;;    - vc-next-action should be cvs-commit-next-action
;;
;;    - cvs-commit-current-buffer should become cvs-commit-current-path

;;; Code:

(require 'easymenu)
(require 'vc)
(require 'vc-hooks)
(require 'font-lock)
(require 'log-edit)

(require 'cvs-diff)

(defvar cvs-commit-vc-log-buffer-name "*VC-log*" "The buffer for cvs commits.")

(defvar cvs-commit-vc-diff-buffer-name "*vc-diff*" "The buffer used for cvs diffs.")

(defvar cvs-commit-vc-diff-window nil "The window that CVS diff is in.")

(defvar cvs-commit-vc-log-window nil "The window that will hold log input.")

(defvar cvs-commit-edit-window nil
  "The window that holds the buffer we are about to commit.")

(defvar cvs-commit-vc-output-buffer "*vc*" "Buffer which contains the output from cvs.")

(defvar cvs-commit-current-path nil "The buffer being commited.")

(defcustom cvs-commit-log-buffer-size 10 "Specify the size of the log entry buffer."
  :type 'integer
  :group 'cvs-commit)

(defvar cvs-commit-message "Enter a change comment.  Type C-c C-c when complete, C-c C-b to quit.")

(defvar cvs-commit-stolen-comments-message
  "-- THE FOLLOWING ANNOTATION WAS DETERMINED FROM COMMENTS WITHIN THIS PATCH. -- "
  "Message to add when we are quoting from the diff buffer.")
  
(defun cvs-commit(path)
  "Commit this document to CVS provide magic to show the current buffer 'cvs
diff' and the commit buffer."
  (interactive
   (list
    (current-buffer)))

  (save-some-buffers)

  ;;init all necessary variables
  (setq cvs-commit-current-path path)

  ;;TODO: need a better way to determine if this file is covered by CVS.  Some
  ;;users might not automatically be using vc-mode.  
  (message "Checking CVS status...")
  (let((status (vc-state (buffer-file-name cvs-commit-current-path))))

    (message "Checking CVS status... %s" (pp status))

    (if (and vc-mode status)
        (progn

          (if (or (equal status 'edited)
                  (equal status 'locally-modified)
                  (equal status 'locally-added)
                  (equal status 'unresolved-conflict)) ;;unresolved conflict
                                                       ;;would result from an
                                                       ;;update which had a
                                                       ;;conflct with the
                                                       ;;server.  CVS itself
                                                       ;;won't let a commit
                                                       ;;happen until this is
                                                       ;;resolved so we
                                                       ;;shouldn't worry about
                                                       ;;this. 
              (progn

                ;;NOTE: ecb-portablity is difficult here because
                ;;'compilation-buffer-p returns true here and I think that this
                ;;is async code so there is no way to disable advice while this
                ;;is working.up w
                
                ;; perform a diff

                (condition-case()
                    (progn 
                      (message "Fetching diff...")

                      ;;(vc-diff nil)
                      (cvs-diff cvs-commit-current-path)
                      (message "Fetching diff...done"))
                  (error
                   (progn

                      ;;erase the current diff buffer just to be on the safe
                      ;;side.  This is necessary because if we didn't we would
                      ;;have a stale vc buffer.
                      (save-excursion
                        (let((inhibit-read-only t))
                          (when (get-buffer cvs-commit-vc-diff-buffer-name)
                            (set-buffer cvs-commit-vc-diff-buffer-name)
                            (erase-buffer))))

                     (message "No revisions of file exist"))))

                ;; NOTE: this isn't working if PCL-CVS is loaded.  There is a
                ;; problem with some of their advice
                
                ;;now setup the commit
                (vc-next-action nil)

                (cvs-commit-decorate-log-buffer)
                
                ;; setup the window configuration correctly.
                (cvs-commit--setup-window-configuration)
                
                ;;of course... tell the user what to do...
                (message cvs-commit-message))

            (if (equal status 'needs-merge)
                (error "File needs merge")
              (error "File has not been locally modified.  %s" (symbol-name status)))))
      (error "Document not covered by CVS"))))

(defun cvs-commit-directory(directory)
  "This runs 'cvs commit' on the given directory.  It does not use 'vc' like
`cvs-commit' does.  The only problem with this scenario is that we need to have
the 'cvs' executable in your path."
  (interactive

   ;;when interactive read the directory to use...
   (let(default)

     ;; use the home dir if invoked from a special buffer
     (if (null (buffer-file-name))
         (setq default (expand-file-name "~"))
       (setq default (file-name-directory (buffer-file-name))))
     
     (list
      (read-file-name "Commit in directory: " nil default t))))

  ;;expand the directory so that we always use the full dir...
  (setq directory (expand-file-name directory))
  
  (if (not (file-directory-p directory))
      (error "%s is not a directory" directory))

  ;;create the *vc-diff* buffer...
  (set-buffer (get-buffer-create cvs-commit-vc-diff-buffer-name))

  (toggle-read-only -1)

  (erase-buffer)

  (message "Running cvs diff...")

  ;;run "cvs diff"
  (let((default-directory directory))

    (call-process "cvs" nil cvs-commit-vc-diff-buffer-name t "diff"))

  (message "Running cvs diff... done")
  
  (set-buffer cvs-commit-vc-diff-buffer-name)
  ;;now... if we have diff-mode... activate it.
  (if (functionp 'diff-mode)
      (diff-mode))

  (goto-char (point-min))

  ;;create the log buffer...
  (set-buffer (get-buffer-create cvs-commit-vc-log-buffer-name))

  (cvs-commit-decorate-log-buffer directory)

  (log-edit-mode)

  (cvs-commit--setup-window-configuration)
  
  (message cvs-commit-message))

(defun cvs-commit--setup-window-configuration(&optional buffer)
  "Setup window configuration with the current buffer in the top portion of the
buffer, the diff in the bottom portion and the remainder has
`cvs-commit-log-buffer-size' lines in length.  Note that in order for this to
work we need to have a log buffer and a diff buffer.

This function needs to work in the following 4 configurations (but needs to be
flexible and easy to adopt to other situations).

- Without ECB
    - with a newly added file (no diff)
    - with an older buffer (diff available)
- Within ECB
    - with a newly added file (no diff)
    - with an older buffer (diff available)"
  (interactive)
  
  ;;FIXME: rewrite this to CORRECTLY use windowing functionality within Emacs.
  ;;When I first wrote it I didn't understand everything about windows.

  ;;defensive programming

  (let((ecb-layout-switch-to-compilation-window nil))
  
    (when (null cvs-commit-current-path)
      (setq cvs-commit-current-path (current-buffer)))
    
    ;;create all the necessary windows.  Under ECB this should not get rid of
    ;;the side windows.
    (delete-other-windows)

    ;;setup the window variables we should be using

    ;;the edit window is easy.
    (setq cvs-commit-edit-window (selected-window))
      
    ;;when we have a diff buffer we need to create and then use a diff window.
    (when (cvs-commit-diff-available-p)
      ;;this should create the diff window
      (split-window-vertically (/ (window-height) 2))
        
      ;;(find-file (buffer-file-name cvs-commit-current-path))
      (other-window 1)
      (setq cvs-commit-vc-diff-window (selected-window)))

    ;;now find out which log window we should use
    (if (and (featurep 'ecb)
             (equal (selected-frame) ecb-frame))
        ;;we need to use the ecb-compile-window
        (setq cvs-commit-vc-log-window ecb-compile-window)
      ;;else split and then use that one.

      (split-window-vertically (- (window-height) cvs-commit-log-buffer-size))

      (other-window 1)
      (setq cvs-commit-vc-log-window (selected-window)))

    ;;set the edit window buffer
    (set-window-buffer cvs-commit-edit-window cvs-commit-current-path)

    ;;set the diff window buffer
    (when (cvs-commit-diff-available-p)
      (set-window-buffer cvs-commit-vc-diff-window cvs-commit-vc-diff-buffer-name)
      (shrink-window-if-larger-than-buffer cvs-commit-vc-diff-window))

    ;;set the log window buffer
    (set-window-buffer cvs-commit-vc-log-window cvs-commit-vc-log-buffer-name)
    (select-window (get-buffer-window cvs-commit-vc-log-buffer-name))
    ;;make sure we have the right window height for the log buffer
    (when (< (window-height) cvs-commit-log-buffer-size)
      (enlarge-window (- cvs-commit-log-buffer-size (window-height))))
    
    ;;tbis should leave us in the log-buffer
    (save-excursion
      (set-buffer cvs-commit-vc-log-buffer-name)

      (toggle-read-only -1))

    ;;this always needs to be done if we are in a
    (when (and (featurep 'ecb)
               (equal (selected-frame) ecb-frame))
      (ecb-toggle-enlarged-compilation-window -1))))

(defun cvs-commit-diff-available-p()
  "Return non-nil if we have an available diff window."
  (and (get-buffer cvs-commit-vc-diff-buffer-name)
       (> (buffer-size (get-buffer cvs-commit-vc-diff-buffer-name)) 0)))
  
(defun cvs-commit-decorate-log-buffer(&optional file)
  "Decorate the *VC-log* buffer."
  (interactive)

  (font-lock-mode -1)
  
  ;; CVS: ----------------------------------------------------------------------
  ;; CVS: Enter Log.  Lines beginning with `CVS:' are removed automatically
  ;; CVS:
  ;; CVS: Committing in .
  ;; CVS:

  (if (null file)
      (setq file (buffer-file-name cvs-commit-current-path)))
  
  (set-buffer (get-buffer-create cvs-commit-vc-log-buffer-name))

  (let((inhibit-read-only t))
    (set-text-properties (point-min) (point-max) nil))

  (erase-buffer)

  (let((start (point))
       (end nil))

    (insert "CVS: ----------------------------------------------------------------------\n")
    (insert "CVS: Enter Log.  Lines beginning with `CVS:' are removed automatically  \n")
    (insert "CVS: \n")
    (insert (format "CVS: Commiting %s \n" file))
    (insert "CVS: \n")

    ;;substract one form the end for \n
    (setq end (1- (point)))

    ;;add text properties to make it read-only..
    (add-text-properties start end
                         '(comment t intangible t read-only t fontified t face font-lock-comment-face))))

(defun cvs-commit-undecorate-log-buffer()
  "Remove decorations from the CVS commit buffer."
  (interactive)

  (set-buffer (get-buffer-create cvs-commit-vc-log-buffer-name))

  (let((inhibit-read-only t))
    (set-text-properties (point-min) (point-max) nil))
    
  (goto-char (point-min))
    
  (while (re-search-forward "^CVS:.*$" nil t)

    ;;remove the match
    (delete-region (match-beginning 0) (match-end 0))
    (kill-line 1)))

(defun cvs-commit-finish-logentry()
  "Remove decorations and then run function `vc-finish-logentry'"
  (interactive)

  ;;we need to delete other windows so that we don't have UI problems...

  (let((vc-delete-logbuf-window nil)
       (current-point (save-excursion
                        (set-buffer cvs-commit-current-path)
                        (point))))

    (when (not cvs-commit-current-path)
      (error "Unknown commit buffer"))

    (cvs-commit-undecorate-log-buffer)

    ;;Figure out what to do for directories.  If we are going to commit an actual
    ;;file then use vc, else use "cvs commit" for directories.
    (if (file-directory-p (buffer-file-name cvs-commit-current-path))
        (cvs-commit-directory-finish-logentry)
    
      ;;else use vc...
      (vc-finish-logentry))

    ;;now setup the commited file and show cvs output.
    (kill-buffer cvs-commit-vc-diff-buffer-name)

    ;;add a newline to the output buffer...
    (set-buffer cvs-commit-vc-output-buffer)
    (goto-char (point-max))
    (cvs-commit-output-mode)

    ;;FIXME: we aren't viewing the output buffer

    ;;we have to do this because for some reason vc deletes buffers!
    (find-file (buffer-file-name cvs-commit-current-path))
    ;;restore the point
    (set-window-point (get-buffer-window (current-buffer)) current-point)
    (goto-char current-point)

    (delete-other-windows)

    ;;show the cvs output buffer
    (if (and (featurep 'ecb)
             (equal (selected-frame) ecb-frame))
        (progn
          ;;things we need to do when under the ECB
          (display-buffer cvs-commit-vc-output-buffer)
          
          (ecb-toggle-enlarged-compilation-window -1))
      ;;not under the ECB
      (split-window)
      ;;(display-buffer cvs-commit-vc-output-buffer)
      
      (shrink-window-if-larger-than-buffer (display-buffer cvs-commit-vc-output-buffer)))
  
    (message "CVS file commited")))

(defun cvs-commit-directory-finish-logentry()
  "Run 'cvs commit' in the directory the user wants to commit."

  (let(directory working-message message-file)

    (setq directory (buffer-file-name cvs-commit-current-path))

    (message "Commiting directory %s..." directory)

    (setq message-file (cvs-commit-prepare-message-file))
    
    ;;obtain the commit message to use and stick it in a temp file...
    
    ;;run "cvs commit" in the correct dir...  we need to use vc buffer...
    (let(default-directory)

      ;;clean up the vc-output-buffer
      (set-buffer (get-buffer-create cvs-commit-vc-output-buffer))
      (erase-buffer)

      (setq default-directory directory)
      
      (insert "cvs commit: commiting in " directory "\n")
      
      ;;NOTE:  The cvs commit man page is wrong.  If you want to specify a file
      ;;for a cvs commit message you must use the -F option.
      (call-process "cvs" nil cvs-commit-vc-output-buffer t "commit" "-F" message-file))

    (message "Commiting directory %s...done" directory)))

(defun cvs-commit-prepare-message-file()
  "Grab the commit message and save it to a temp file.  Should return the temp
file when complete..."

  (save-excursion
    (let(message temp-file temp-buffer)
      
      (set-buffer cvs-commit-vc-log-buffer-name)

      (setq message (buffer-substring-no-properties (point-min) (point-max)))
    
      (setq temp-file (make-temp-name (concat (getenv "TEMP") "/cvs-commit-directory-")))

      (setq temp-buffer (find-file-noselect temp-file))
      
      (set-buffer temp-buffer)

      (insert message)

      (save-buffer)

      (kill-buffer temp-buffer)
      
      ;;return the buffer name we are using...
      (buffer-file-name temp-buffer))))

(defun cvs-commit-scroll-diff-buffer()
  "Goto the diff buffer and scroll up"
  (interactive)

  (let*((current-window (selected-window))
        (diff-buffer (get-buffer cvs-commit-vc-diff-buffer-name))
        (diff-window (when diff-buffer
                       (get-buffer-window diff-buffer))))

    (when diff-window
    
      ;;goto the diff window
      (select-window diff-window)
      (scroll-up 2)

      ;;restore the window
      (select-window current-window))))

(defun cvs-commit-steal-diff-comments()
  "Look at the diff buffer.  If there are some lines that have comments via
comment-start...  try to pull them into the CVS log."
  (interactive)

  ;;FIXME: ... need to work with both comment-start and comment-end.  Some java
  ;;style comments have bodies like:
  ;;
  ;; /**
  ;; WE NEED TO STEAL THIS...
  ;; */
  
  ;;determine what comment character to search for.
  (let(cvs-commit-comment-start
       cvs-commit-comment-end
       match
       (comments '()))
    (set-buffer cvs-commit-current-path)
    (setq cvs-commit-comment-start comment-start)
    (setq cvs-commit-comment-end comment-end)

    ;;go through the diff buffer, find comments, then insert them "cleaned" into
    ;;the log buffer.
    (set-buffer cvs-commit-vc-diff-buffer-name)
    
    (save-excursion

      (goto-char (point-min))
      ;;search for additional lines within this patch that are comments.
      (while (re-search-forward (concat "^\\+[ ]+" cvs-commit-comment-start ".*$") nil t)
        (progn
          (setq match (match-string 0))

          ;;clean up these comments and add them to end of the log buffer.
          (save-excursion
            (set-buffer cvs-commit-vc-log-buffer-name)
            (goto-char (point-max))

            ;;strip the comment chars if necessary.
            
            (insert (format "%s\n" match))))))

    ;;now clean up the buffer.
    (cvs-commit-steal-diff-comments-clean-log-buffer cvs-commit-comment-start cvs-commit-comment-end)))

(defun cvs-commit-steal-diff-comments-clean-log-buffer(comment-start comment-end)
  "Go through the log buffer and clean up all inserted comment strings."

  (save-excursion
    (set-buffer cvs-commit-vc-log-buffer-name)
    (goto-char (point-min))

    (while (re-search-forward (concat "^\\+[ ]*" comment-start "[^" comment-start "]*") nil t)
      (delete-region (match-beginning 0) (match-end 0)))))

(defun cvs-commit-break()
  "Break out of a CVS commit."
  (interactive)

  ;;get rid of the other windows
  (delete-other-windows)

  ;;kill the necsary buffers
  (cvs-commit-kill-live-buffer cvs-commit-vc-diff-buffer-name)

  (cvs-commit-kill-live-buffer cvs-commit-vc-log-buffer-name)

  ;;go back to the original file
  (find-file (buffer-file-name cvs-commit-current-path)))

(defun cvs-commit-kill-live-buffer(buffer)
  "If the given buffer is live, go ahead and kill it."
  
  (if (buffer-live-p buffer)
      (kill-buffer buffer)))

(define-derived-mode cvs-commit-output-mode fundamental-mode "CVS Output"
  "Move for cvs output."

  (font-lock-mode 1))

;;when a cvs commit starts... decorate the vc log buffer.
;;(add-hook 'vc-before-checkin-hook 'cvs-commit-decorate-log-buffer)

;;don't use the standard `vc-finish-logentry' instead use my own but it
;;internally calls this function anyway but I provide some extra stuff.
(define-key log-edit-mode-map "\C-c\C-c" 'cvs-commit-finish-logentry)
(define-key log-edit-mode-map "\C-c\C-b" 'cvs-commit-break)

(define-key log-edit-mode-map [(control return)] 'cvs-commit-scroll-diff-buffer)

;;add key binding to steal comments.
(define-key log-edit-mode-map [?\C-\"] 'cvs-commit-steal-diff-comments)

;;provide key binding replacement to vc-toggle-read-only
(global-set-key "\C-x\C-q" 'cvs-commit)

;;(font-lock-add-keywords 'log-edit-mode '(("\\(^CVS:.*\\)" 1 'font-lock-comment-face t)))(font-lock-add-keywords 'cvs-commit-output-mode '(("\\(^cvs commit.*$\\)" 1 'font-lock-comment-face t)))
(font-lock-add-keywords 'cvs-commit-output-mode '(("\\(^\\?.*$\\)" 1 'font-lock-warning-face t)))

;;add this to the tools menu.
(easy-menu-add-item 'menu-bar-tools-menu nil '("CVS Commit"
                                               ["Commit Current Buffer" cvs-commit t]
                                               ["Commit Directory" cvs-commit-directory t]))

;;support for ecb-profile
(when (featurep 'ecb-profile)

  (add-to-list 'ecb-profile-buffer-name-alist '("*VC-log*" . ((window . ecb-compile-window))))
  (add-to-list 'ecb-profile-buffer-name-alist '("*vc*" . ((window . ecb-compile-window))))
  (add-to-list 'ecb-profile-buffer-name-alist '("*vc-diff*" . ((window . ecb-edit-window-2)))))

(when (featurep 'ecb-compilation)
  (add-to-list 'ecb-compilation-buffer-names (cons "*vc*" nil))
  (add-to-list 'ecb-compilation-buffer-names (cons "*VC-log*" nil)))

(provide 'cvs-commit)

;;; cvs-commit.el ends




