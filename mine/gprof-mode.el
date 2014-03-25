;;; gprof-mode.el --- GNU Emacs major mode (only font-locking) for gprof output

;; Copyright (C) 2007 by Per Nordlöw

;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Version 0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;;; Code:

(defgroup gprof-mode nil
  "GProf mode."
  :group 'wp
  :prefix "gprof-")

(defvar gprof-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\es" 'center-line)
    map)
  "Major mode keymap for `gprof-mode'.")

(defconst gprof-mode-font-lock-keywords
  (progn
    (require 'font-lock)
    (list
     ;; Function Names
     (list (concat
	    "\\[" "\\(" "[[:digit:]]+" "\\)" "\\]")
	   1 'font-lock-constant-face)
     (list (concat
	    "\\(" "[[:alnum:]_]+" "\\)" " " "\\[" "[[:digit:]]+" "\\]" "$")
	   1 'font-lock-function-name-face)
     (list (concat
	    "\\[" "[[:digit:]]+" "\\]" " " "\\(" "[[:alnum:]_]+" "\\)")
	   1 'font-lock-function-name-face)
     ))
  "Expressions to font-lock in Operators mode.")

(defcustom gprof-mode-hook nil
  "Hook run by function `gprof-mode'."
  :type 'hook
  :group 'gprof-mode)

;;;###autoload
(define-derived-mode gprof-mode text-mode "Profile (gprof)"
  "Major mode for font locking of gprof output.
\\{gprof-mode-map}
Turning on Operators mode runs `text-mode-hook', then `gprof-mode-hook'."
  (use-local-map gprof-mode-map)
  (set
   (make-local-variable 'font-lock-defaults)
   '((gprof-mode-font-lock-keywords)))
  )

(provide 'gprof-mode)

;;; gprof-mode.el ends here
