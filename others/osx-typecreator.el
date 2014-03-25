;;; osx-typecreator.el --- Set OSX type and creator
;;
;; ~harley/share/emacs/pkg/osx/osx-typecreator.el ---
;;
;; $Id: osx-typecreator.el,v 1.8 2003/03/18 19:56:37 harley Exp $
;;

;; Author:    Harley Gorrell <harley@mahalito.net>
;; URL:       http://www.mahalito.net/~harley/elisp/osx-typecreator.el
;; License:   GPL v2
;; Keywords:  osx, type, creator

;;; Commentary:
;; * Sets the type and creator on OSX systems based on major-mode or
;;   buffer-file-name.
;; * Yea, I know that T&C info is being phased out of OSX,
;;   but the process isn't complete yet.
;; * Kinda odd that OSX is stripping out resouce forks while Linux,
;;   BSD and NFSv4 are in the process of adding extended attributes
;;   to their filesystems.

;;; Installation:
;;  Put this file somewhere in your load path and add the following to '~/.emacs':
;;   (when (eq system-type 'darwin)
;;     ;; Optionally you may want this line
;;     ;; (add-hook 'after-save-hook 'osx-tc-save-buffer-tc)
;;     (require 'osx-typecreator))
;;   ;; To add your own T&C info add lines like:
;;   (add-to-list 'osx-tc-defaults-by-mode '(foo-mode    "FOOT" "FOOC"))
;;   (add-to-list 'osx-tc-defaults-by-name '("\\.foo\\'" "FOOT" "FOOC"))

;;; History:
;;  2003-03-15 : Given to friends.
;;  2003-03-16 : Updated URL and contact info.

;;; Code:

(defvar osx-tc-defaults-by-mode
  ;; mode                 type   creator
  '((lisp-mode           "TEXT" "CCL2") ;; Macintosh Common Lisp
    (emacs-lisp-mode     "TEXT" "CCL2")
    (html-mode           "TEXT" "MOZZ") ;; Mozilla
    (html-mode           "TEXT" "iCAB")
    (html-mode           "TEXT" "MSIE")
    ;; uncommenting fundamental-mode might be too liberal
    ;; (fundamental-mode    ""     ""    ) ;; don't set tc
    ;; (fundamental-mode    "TEXT" "ttxt") ;; simple text
    ;; (fundamental-mode    "TEXT" "R*ch") ;; bbedit
    ;; (fundamental-mode    "TEXT" "MPW ") ;; MPW
    )
  "A mapping of the current `major-mode' to an OSX type and creator.
Types or creators of 'nil' or '\"\"' are not set.
The first match is used.
The major mode is checked before the filename.")

(defvar osx-tc-defaults-by-name
  '(("\\.te?xt"          "TEXT" "R*ch") ;; or one of the above creators
    ("\\.gif\\'"         "GIFf" "GKON")
    ("\\.png\\'"         "PNGf" "GKON")
    ("\\.mp3\\'"         "MP3 " ""    )
    ("\\.pdf\\'"         "PDF " ""    )
    ("\\.sit\\'"         "SITD" "SITx")
    )
  "A mapping of the `buffer-file-name' to an OSX type and creator.
Sometimes you will be editing a binary file which doesn't really
have a mode.  Guess as to what the T&C should be from the name.
See osx-tc-defaults-by-mode.")

(defvar osx-setfile-program "SetFile"
  "The path to the SetFile program.
This is normally installed with the Developer Tools as /Developer/Tools/SetFile.")

(defvar osx-getfileinfo-program "GetFileInfo"
  "The path to the GetFileInfo program.
This is normally installed with the Developer Tools as /Developer/Tools/GetFileInfo.")

(defvar osx-tc-file-type nil
  "The osx file type for the current buffer.")
(make-variable-buffer-local 'osx-tc-file-type)

(defvar osx-tc-file-creator nil
  "The osx file creator for the current buffer.")
(make-variable-buffer-local 'osx-tc-file-creator)



;;;;;;;;;;

(defun osx-tc-get-tcinfo-by-name (filename)
  "Find the type and creator info by FILENAME."
  (let ((maplst osx-tc-defaults-by-name))
    (while (and maplst (not (string-match (caar maplst) filename)))
      (setq maplst (cdr maplst)) )
    (car maplst)))
;; (osx-tc-get-tcinfo-by-name "foo.gif")

(defun osx-tc-guess-file-type ()
  "Get the default type for this buffer."
  (cadr (or (assq major-mode osx-tc-defaults-by-mode)
            (osx-tc-get-tcinfo-by-name buffer-file-name) )))
;; (osx-tc-guess-file-type)

(defun osx-tc-guess-file-creator ()
  "Get the default type for this buffer."
  (caddr (or (assq major-mode osx-tc-defaults-by-mode)
             (osx-tc-get-tcinfo-by-name buffer-file-name))))
;; (osx-tc-guess-file-creator)

(defun osx-tc-buffer-type ()
  "Get or guess the the OSX file type of the buffer."
  (or osx-tc-file-type (osx-tc-guess-file-type)))

(defun osx-tc-buffer-creator ()
  "Get or guess the the OSX file creator of the buffer."
  (or osx-tc-file-creator (osx-tc-guess-file-creator)))

;;;;;;;;;;

(defun osx-tc-setfile (filename type creator)
  "For FILENAME set the TYPE and CREATOR ."
  (interactive "fFile: \nMType: \nMCreator: ")
  (let ((opt-c (if (and creator (not (string= creator "")))
                 (concat " -c '" creator "'") ))
        (opt-t (if (and type (not (string= type "")))
                 (concat " -t '" type "'") )))
    (if (and filename (or opt-c opt-t))
      (shell-command (concat osx-setfile-program opt-t opt-c " '" filename "'")) )))

(defun osx-tc-save-buffer-tc ()
  "Save the OSX type and creator for the file visited by this buffer."
  (interactive)
  (if buffer-file-name
    (osx-tc-setfile buffer-file-name (osx-tc-buffer-type) (osx-tc-buffer-creator))
    (error "No file for this buffer") ))

(defun osx-tc-setfile-buffer ()
  "Prompt for and save the OSX type and creator for this buffer."
  (interactive)
  (let ((new-t (read-string "OSX type: "    osx-tc-file-type))
        (new-c (read-string "OSX creator: " osx-tc-file-creator)) )
    (setq osx-tc-file-type    new-t
          osx-tc-file-creator new-c)
    (osx-tc-save-buffer-tc)))

;;;;;;;;;;

(defun osx-tc-getfileinfo (filename)
  "Display the output of GetFileInfo for FILENAME."
  (interactive "fGetFileInfo:")
  (let ((gfibuf (get-buffer-create " *GetFileInfo*"))
        (resize-mini-windows nil) )
    (save-excursion
      (switch-to-buffer-other-window gfibuf)
      (erase-buffer)
      (shell-command (concat osx-getfileinfo-program " '" filename "'") gfibuf) )))

(defun osx-tc-getfileinfo-buffer ()
  "Display the GetFileInfo output for this buffer."
  (interactive)
  (if buffer-file-name
    (osx-tc-getfileinfo buffer-file-name)
    (error "This buffer is not visiting a file")))

;;;;;;;;;;

;; Local Variables:
;; osx-tc-file-type:    "TEXT"
;; osx-tc-file-creator: "R*ch"
;; End:

(provide 'osx-typecreator)

;;; osx-typecreator.el ends here
