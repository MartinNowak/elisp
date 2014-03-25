;; Copyright (C) 1997-2000 Free Software Foundation, Inc.

;; Author: Kevin A. Burton (burton@openprivacy.org)
;; Maintainer: Kevin A. Burton (burton@openprivacy.org)
;; Location: http://relativity.yi.org
;; Keywords: wget
;; Version: 1.1.0

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

;;; History:
;;
;; - Thu Sep 25 2003 07:01 PM (burton@peerfear.org): We also now save to a
;; tmpfile so that emacs doesn't have to insert the contents in real time and
;; burn CPU.  
;;
;; - Thu Sep 25 2003 06:42 PM (burton@peerfear.org): Migrated BACK to using
;; standard wget.  While this requires the use of an external command this is
;; still faster than wget.  Emacs sync IO sucks.
;; 
;; - Fri Nov 02 2001 01:43 AM (burton@openprivacy.org): it now uses 100%
;; elisp.. IE no external wget binary needed.
;;
;; - Tue Oct 30 2001 08:22 PM (burton@openprivacy.org): enable html-mode if we
;; are viewing an html file.
;;
;; - Mon Oct 29 2001 07:04 PM (burton@openprivacy.org): modernized for Emacs 21.

;; Version 1.0.1:
;;
;; - Correctly paying attention to stderr.  Invalid URLs will not be detected
;;   and the user notified.
;;
;; - Create a new *wget* buffer for each new URL and dont' reuse the same
;;   buffer.
;;
;; - supports --save-headers from wget
;;
;; - http:// is now specified as the init for input
;;
;; - have wget-mode that highlights the firsts
;;   lines of  the buffer until the regexp ^$

;; Version 1.0:
;; init.

;;; Commentary:

;; This is an interface for wget.  Basically it allows you to pull down URLs and
;; then view the output in a buffer.  This is a too to help develop/debug web
;; applications.

;;; TODO:

;; - This is NOT synchronous AKA if we have a server that is remove and times
;; out Emacs will allow the user to type things and the metaphor becomes VERY
;; confusing!  This needs to be fixed!
;; 

;; - FIXME: why are we getting ^M chars in the output?
;;
;;    - I think I need to set my character conversion

;; - include a mechanism to support posting content to a webserver.  This would
;; prompt for the URL, method (get|post), and any specific HTTP headers to send.
;; It should save this URL and all its params in memory for future use. The the
;; user can repeat this again.

(defface wget-headers-face '((t (:foreground "GoldenRod" :bold t)))
  "Face used to highlight the HTTP headers in the buffer.")

(defvar wget-current-url nil "");
(defvar wget-current-file nil "");

(defun with-async-reverted-process(program function directory &rest program-args)
  "When complete call `function' Return the tmp filename being used."

  ;;FIXME: make SURE we put up an error so that the user doesn't reset the
  ;;buffer.

  ;;FIXME: make 100% sure that we don't do anything in any other window or
  ;;frame.s
  
  (let*((process nil)
        (buffer nil)
        (tmp-buffer "*tmp*")
        (tmpfile (make-temp-file "tmp-")))

    ;;we have to write a few bytes here so that emacs can 
    (setq buffer (find-file-noselect tmpfile))
    (switch-to-buffer buffer)
    ;;need to have ONE char to allow save.
    (insert (format "Please wait... running %s\n" program))
    (save-buffer)
    ;;need to disable auto-revert... we're going to do it manually
    ;;(auto-revert-mode -1)
    (goto-char (point-min))

    ;;set the current directory
    (setq default-directory directory)
    
    (get-buffer-create tmp-buffer)

    (start-process "pwd" tmp-buffer "pwd")

    ;;FIXME: use an output stream here.
    (setq process (apply 'start-process program tmp-buffer program program-args))

    (setq with-async-reverted-process--function function)
    
    ;;auto-revert sentinel
    (set-process-sentinel process (lambda(process event)

                                    (when (string-match "exited abnormally with code.*" event)
                                      (message event)
                                      ;;FIXME: ONLY do this if we are still in the original buffer.
                                      (switch-to-buffer (process-buffer process)))
                                    
                                    (when (string-equal event "finished\n")
                                    
                                      ;;FIXME: bug bug bug... if we switch
                                      ;;buffers while this is running we will
                                      ;;have a BIG problem  
                                      
                                      ;;fetch the conten from disk
                                      (kill-buffer (process-buffer process))

                                      ;;(find-file (buffer-file-name (process-buffer process)))
                                      (find-file wget-current-file)
                                      ;;(revert-buffer t t t)
                                      ;;(goto-char (point-min))
                                      (beginning-of-buffer)
                                      ;;highlight all headers
                                      (save-buffer)

                                      (funcall function))))))
  
(defun wget(url)
  (interactive
   (list
    (read-string "URL: " "")))

;;   (shell-command (concat "wget --save-headers --output-document=/dev/stdout --non-verbose " 
;;                          url) 
;;                  (wget-get-buffer url) 
;;                  (wget-get-buffer url))

  (setq wget-current-url url)
  
  (let*((process nil)
        (buffer nil)
        (tmpfile (make-temp-file "wget-")))

    (setq wget-current-file tmpfile)

    ;;we have to write a few bytes here so that emacs can 
    (setq buffer (find-file-noselect tmpfile))
    (switch-to-buffer buffer)
    (insert "\n")
    (save-buffer)
    ;;need to disable auto-revert... we're going to do it manually
    ;;(auto-revert-mode -1)
    (goto-char (point-min))
    
    (setq process (start-process "wget"
                                 "*wget*"
                                 "wget"
                                 "--non-verbose"
                                 "--save-headers"
                                 (concat "--output-document=" tmpfile)
                                 url))

    ;;auto-revert sentinel
    (set-process-sentinel process (lambda(process event)

                                    (when (string-equal event "finished\n")
                                    
                                      ;;FIXME: bug bug bug... if we switch
                                      ;;buffers while this is running we will
                                      ;;have a BIG problem  
                                      
                                      ;;fetch the conten from disk
                                      (kill-buffer (process-buffer process))

                                      ;;(find-file (buffer-file-name (process-buffer process)))
                                      (find-file wget-current-file)
                                      ;;(revert-buffer t t t)
                                      ;;(goto-char (point-min))
                                      (beginning-of-buffer)
                                      ;;highlight all headers
                                      (wget-highlight-buffer)
                                      (save-buffer)

                                      ;;now determine diff mode
                                      (save-excursion
                                        (goto-char (point-min))
                                        (when (re-search-forward "^Content-Type: \\(.*\\)$" nil t)
                                          (let((content-type (match-string 1)))

                                            (when (string-match "^text/html" content-type)
                                              (html-mode))

                                            (when (string-match "^text/xml" content-type)
                                              (sgml-mode)))))
                                      (message (concat "Fetching " wget-current-url " ...done")))))

    (message (concat "Fetching " wget-current-url " ..."))))

(defun wget-init(url)
  "Clear the temp wget buffer if there is data in it"

  ;;switch to the correct buffer
  (view-buffer (wget-get-buffer url))

  ;;(mark-whole-buffer)

  ;;if the wget buffer is full reset it
  (if (> (buffer-size) 0)
      (delete-region (region-beginning) (region-end))))

(defun wget-get-buffer(url)
  ;;based on the url... get a correct temporary buffer.
  (concat "*wget " url "*"))

(defun wget-highlight-buffer()
  
  (save-excursion
    (insert "--------------------------------------------------------------------------------\n")
    (search-forward-regexp "^$" nil t)
    (insert "--------------------------------------------------------------------------------\n")
    (end-of-line)

    (setq current-overlay (make-overlay 1 (point)))
      
    (overlay-put current-overlay 'face 'wget-headers-face)
    
    (overlay-put current-overlay 'window (selected-window))))

(provide 'wget)

;;; wget.el ends here
