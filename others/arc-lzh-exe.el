;;; arc-lzh-exe.el --- archive-mode support for LHa self-extracting .exe

;; Copyright 2006, 2007, 2008 Kevin Ryde
;;
;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 3
;; Keywords: data
;; URL: http://www.geocities.com/user42_kevin/arc-lzh-exe/index.html
;;
;; arc-lzh-exe.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; arc-lzh-exe.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses>.
 

;;; Commentary:

;; This is a spot of code for viewing the contents of LHa (ie. LZH)
;; self-extracting executables from `archive-mode'.  The executable part,
;; which is meant for DOS, is not executed.
;;
;; There's no support for modifying such files; it looks like the unix
;; version of the lha program doesn't have support for writing them (only
;; reading).
;;
;; A random .exe file is of course might not be an LHa file, so
;; `archive-exe-p' and `archive-lzh-exe-mode-maybe' below check the contents
;; before going to archive-mode.
;;

;;; Install:

;; Put arc-lzh-exe.el somewhere in your `load-path', and in your .emacs put
;;
;;     (autoload 'archive-lzh-exe-mode-maybe "arc-lzh-exe")
;;     (autoload 'archive-exe-p              "arc-lzh-exe")
;;
;;     (if (boundp 'magic-mode-alist)
;;         ;; emacs 22
;;         (add-to-list 'magic-mode-alist '(archive-exe-p . archive-mode))
;;       ;; emacs 21
;;       (modify-coding-system-alist 'file "\\.\\(exe\\|EXE\\)\\'"
;;                                   'raw-text-unix)
;;       (add-to-list 'auto-mode-alist
;;                    '("\\.\\(exe\\|EXE\\)\\'" . archive-lzh-exe-mode-maybe)))
;;
;; There's autoload cookies below for all this, if you know how to use
;; `update-file-autoloads' and friends.


;;; Emacsen:

;; Designed for Emacs 21 or 22, works in XEmacs 21 too.
;;
;; In Emacs 21 and XEmacs21 archive-lzh-summarize has trouble on some .lzh
;; files and that affects the .exe files setup here.  The symptom is either
;; garbage filenames or a "File mode specification error" and a buffer full
;; of raw bytes (a modified buffer -- don't save it).  You can copy some
;; code from Emacs 22 to improve that, if you're really keen.

;;; History:

;; Version 1 - the first version
;; Version 2 - notice partial support builtin in emacs 22
;; Version 3 - add some autoloads, avoid 'cl


;;; Code:

;; the following for emacs 21, it's already in emacs 22
(eval-after-load "arc-mode"
  '(unless (fboundp 'archive-lzh-exe-summarize)

     (defadvice archive-find-type (around archive-lzh-exe activate)
       "Recognise lzh .exe files, as `lzh-exe' type."
       (if (let ((case-fold-search nil))
             (save-restriction
               (widen)
               (save-excursion
                 (goto-char (point-min))
                 ;; have seen identifier "LHA's" in files
                 ;; the `file' command has "LHa's" too
                 (looking-at "MZ\\(.\\|\n\\)\\{34\\}LH[aA]'s SFX "))))
           (setq ad-return-value 'lzh-exe)
         ad-do-it))

     (defun archive-lzh-exe-summarize ()
       "Summarize contents of an LHa self-extracting exe for `archive-mode'."
       ;;
       ;; This code presses `archive-lzh-summarize' into service by
       ;; temporarily removing the executable stuff before the archive
       ;; proper.  It doesn't work to narrow to the desired region,
       ;; because archive-lzh-summarize in emacs 21.4 and 22.1 has "1"
       ;; hard coded as a buffer position (instead of using point-min).
       ;;
       (search-forward "-lh5-")
       (backward-char 7)
       (let ((str (buffer-substring (point-min) (point))))
         (delete-region (point-min) (point))
         (unwind-protect
             (archive-lzh-summarize)
           (save-excursion
             (insert str)))))

     ;; `archive-lzh-extract' runs "lha pq", and that works for .exe as
     ;; well as .lzh files
     (defalias 'archive-lzh-exe-extract 'archive-lzh-extract)))

;; this is an autoload instead of (require 'arc-mode) because such a require
;; fails in xemacs 21.4 (the file provides 'archive-mode instead of
;; 'arc-mode)
;;
(autoload 'archive-find-type "arc-mode")

;;;###autoload
(defun archive-lzh-exe-mode-maybe ()
  "Use `archive-mode' if the buffer is an LZH self-extracting exe.
This function is designed for use from `auto-mode-alist'.  If the
buffer isn't a recognisable lzh exe then any other entries for
.exe in `auto-mode-alist'.' are tried.

Note that for Emacs 22 a setup using `archive-exe-p' in
`magic-mode-alist' is recommended instead."

  ;; archive-find-type throws an error on unrecognised contents
  (if (condition-case nil (archive-find-type) (error nil))
      (archive-mode)

    ;; the file isn't an lzh exe, remove ourselves from auto-mode-alist and
    ;; see what, if anything, other entries can make of the contents
    ;;
    ;; this doesn't use `remove*' from cl.el because when running non byte
    ;; compiled it can result in a message "loading cl-macs ..."  at a bad
    ;; time; in particular `save-selected-window' uses dolist and can
    ;; provoke that load and message
    ;;
    (let ((auto-mode-alist
           (delq t (mapcar (lambda (elem)
                             (or (eq 'archive-lzh-exe-mode-maybe (cdr elem))
                                 elem))
                           auto-mode-alist))))
      (set-auto-mode))))

;;;###autoload
(defun archive-exe-p ()
  "Return true if the current buffer is a self-extracting .exe archive.
This is designed for use as a test in `magic-mode-alist', to
select `archive-mode'.

`magic-mode-alist' is new in Emacs 22, see
`archive-lzh-exe-mode-maybe' for a mode selection for prior
versions."

  (let (case-fold-search)
    (and (buffer-file-name) ;; oughtn't be nil normally, but watch out for that
         (string-match "\\.\\(exe\\|EXE\\)\\'" (buffer-file-name))
         (save-excursion
           (goto-char (point-min))
           ;; same regexp as in archive-find-type for `lzh-exe'
           (looking-at "MZ\\(.\\|\n\\)\\{34\\}LH[aA]'s SFX ")))))

;;;###autoload (if (boundp 'magic-mode-alist)
;;;###autoload     ;; emacs 22
;;;###autoload     (add-to-list 'magic-mode-alist '(archive-exe-p . archive-mode))
;;;###autoload   ;; emacs 21
;;;###autoload   (modify-coding-system-alist 'file "\\.\\(exe\\|EXE\\)\\'"
;;;###autoload                               'raw-text-unix)
;;;###autoload   (add-to-list 'auto-mode-alist
;;;###autoload                '("\\.\\(exe\\|EXE\\)\\'" . archive-lzh-exe-mode-maybe)))

(provide 'arc-lzh-exe)

;;; arc-lzh-exe.el ends here
