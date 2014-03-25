;;; saveframes.el --- Save and restore frames

;; Copyright (c) 2002 Pekka Marjola

;; Author: Pekka Marjola <pema@iki.fi>
;; Keywords: file, frame
;; Version: 0.1

;; This file is not part of XEmacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;;
;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to pema@iki.fi) or from the
;; Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139,
;; USA.
;;
;; Send bug reports to pema@iki.fi

;; Created: 22.4.2002 $Modified: Mon Apr 22 12:55:34 2002 by pema $

;;; Commentary:

;; Functions to save the state of frames showing files, and to
;; restoring those frames. See also dektop.el for for more complete
;; state restoring, but note that it does not restore frames.
;;
;; Tested so far only in XEmacs-21.5. Requires custom. Most likely
;; does not work in GNU Emacs.

;;; Code:

(defgroup saveframes nil
  "Confirmation for finding non-existing files and creation of
  duplicate frames."
  :group 'frames
  :prefix "saveframes-")

(defconst saveframes-version "0.1"
  "Version of saveframes package.")

(defcustom saveframes-mode nil
  "*If non-nil, activates saveframes-mode."
  :type 'boolean
  :require 'saveframes
  :group 'saveframes)

;;;###autoload
(defcustom saveframes-mode-line-string ""
  "*Modeline indicator for saveframes."
  :group 'saveframes
  :type 'string)

(defcustom saveframes-mode-hook nil
  "*List of functions to call when entering saveframes minor mode." 
  :group 'saveframes :type 'hook)

(defcustom saveframes-load-hook nil
  "*List of functions to call after loading saveframes." :group
  'saveframes :type 'hook)

(defcustom saveframes-default-file ".emacs_frames"
  "*Filename to save frame info by default."
  :group 'saveframes
  :type 'string)

;; Isn't there function for this?
(defun saveframes-list-visited-files ()
  (let ((buffers (buffer-list t))
        buf buf-file files)
    (while (setq buf (pop buffers))
      (setq buf-file (buffer-file-name buf))
      (if buf-file
          (push buf-file files)))
    files))
      
(defun saveframes-list-file-frames ()
  (let ((files (saveframes-list-visited-files))
        file buf frame-files frameless-files)
    (while (setq file (pop files))
      (let ((buf (find-buffer-visiting file)))
        ;; Must use get-buffer-window-list or sothing that allows
        ;; specifying parameters for walk-windows to get all frames. 
        ;; frames-of-buffer does not work. Insane!
        (let* ((window (get-buffer-window-list buf nil 0))
	       (frm (and window
                         (window-frame (car window)))))
	  (if frm
              (push file frame-files)
            (push file frameless-files)))))
    (list frame-files frameless-files)))
	
;;;###autoload
(defun saveframes-save (&optional file)
  "Save a list of frames to a file."
  (interactive)
  (if (interactive-p)
      (setq file (read-file-name
                  (concat "Save frame data to file (default "
                          saveframes-default-file "): ")
                  default-directory saveframes-default-file)))
  (if (not file)
      (setq file saveframes-default-file))
  (let* ((file-list (saveframes-list-file-frames))
         (frame-files (car file-list))
         (frameless-files (car (cdr file-list))))
    (with-temp-file file
      (insert "(setq frame-files      '"
              (prin1-to-string frame-files)
              "\n"
              "      frameless-files  '"
              (prin1-to-string frameless-files)
              ")\n")))
  (message (concat "Wrote " (expand-file-name file))))

;;;###autoload
(defun saveframes-load (&optional file)
  "Open a frame list file."
  (interactive)
  (if (interactive-p)
      (setq file (read-file-name
                  (concat "Read frame data from file (default "
                          saveframes-default-file "): ")
                  default-directory saveframes-default-file)))
  (if (not file)
      (setq file (concat default-directory saveframes-default-file)))
  (let (frame-files frameless-files)
    (load file nil t t)
    (while (setq file (pop frameless-files))
      (if (file-readable-p file)
          (find-file file)))
    (while (setq file (pop frame-files))
      (if (file-readable-p file)
          (find-file-other-frame file)))))

;;;###autoload
(defun saveframes-maybe-save ()
  "Open a frame list file."
  (interactive)
  (if (and saveframes-mode
           (y-or-n-p "Save frame list to file? "))
      (call-interactively 'saveframes-save)))

;;;###autoload
(defun saveframes-mode (&optional arg)
  "Toggle saveframes minor mode.
With arg, turn saveframes mode on iff arg is positive. When
saveframes mode is enabled, the editor asks for a while to save current frame
confirmation before exiting.
You must still load the frame file manually, or add following code to
your init.el:
(saveframes-load)"
  (interactive "*P")
  (setq saveframes-mode
      (if (null arg)
          (not saveframes-mode)
        (> (prefix-numeric-value arg) 0)))
(when saveframes-mode
  (run-hooks 'saveframes-mode-hook)
  (add-hook 'kill-emacs-hook 'saveframes-maybe-save)))

;;;###autoload
(defun turn-on-saveframes ()
  "Unconditionally turn on saveframes mode."
  (interactive)
  (saveframes-mode 1))

;;;###autoload
(when (fboundp 'add-minor-mode)
  ;; XEmacs
  (add-minor-mode 'saveframes-mode
		    saveframes-mode-line-string))

;; Emacs -- don't autoload
(unless (assq 'saveframes-mode minor-mode-alist)
  (setq minor-mode-alist
	(cons '(saveframes-mode saveframes-mode-line-string)
	      minor-mode-alist)))

(run-hooks 'saveframes-load-hook)

(provide 'saveframes)

