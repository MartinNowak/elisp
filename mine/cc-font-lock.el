;;; cc-font-lock.el --- extra type font locking in CC Mode

;; Copyright (C) 2007 Per Nordlöw

;; Author: Per Nordlöw <per.nordlow@gmail.com>
;; Keywords: unix files

;; This file is NOT part of GNU Emacs.

;; Extra font locking in C / C++.

;; Note: This logic is not needed in `cc-mode-5.30' or later since it
;; handles type-related language parsings much better.

;; Extra font locking in C

(eval-when-compile (require 'cl))

;; Boxed comments for C mode.
(defvar pnw/use-extra-types-font-locking nil
  "Set to non-nil to enable extra font locking C and C++.")

;; lazy font locking.
(if (GNUEmacs-21-p) (progn
                      (setq font-lock-support-mode 'lazy-lock-mode
                            ;; if fontification is too slow to keep up with scrolling.
                            lazy-lock-defer-on-scrolling t
                            ;; if fontification is too slow to keep up with your typing.
                            lazy-lock-defer-on-the-fly t
                            ;; if any buffer has any deferred fontification way this number of
                            ;; given number of seconds before continuing in the background.
                            lazy-lock-stealth-time 1)
                      ))

(defvar pnw/c-font-lock-extra-types
  `("[us]char"
    "[us]short"
    "[us]int"
    "[us]long"
    "[us]?onglong"
    "[us]?llong"
    "l[l]?double"

    "_Complex"			; ISO C99 Extension for complex types.

    ,(concat W+ "_struct")
    "fd_set"

    "PixT"

    "\\(vec\\|box\\|line\\|cir\\)[23]4[fds]"

    ;; X11 and Motif
    "Status" "Arg" "Dimension" "Position"
    "Display" "Window" "Drawable"
    "Widget" "Visual" "Colormap" "Screen" "Pixmap"
    "XImage" "GC" "Font"
    "XPoint" "XRectangle" "XArc" "XEvent" "XColor"
    "XWindowAttributes" "XSetWindowAttributes"
    "XFontStruct" "XWMHints" "XSizeHints"
    "KeySym"
    "XtAppContext" "XtIntervalId"
    "XmText" "XmTextPosition"

    ;; X11 Double Buffer Extension (DBE)
    "XdbeBackBuffer" "XdbeSwapInfo" "XdbeSwapAction"

    ;;"[[:upper:]]\\sw*[[:lower:]]\\sw*"
    )
  "Extra types to be font-locked in C.")

(defun c-extra-font-locking-hook ()
  (setq c-font-lock-extra-types
        (union c-font-lock-extra-types
                pnw/c-font-lock-extra-types))
  (delete-duplicates c-font-lock-extra-types))

(when pnw/use-extra-types-font-locking
  (add-hook 'c-mode-hook 'c-extra-font-locking-hook)
  (add-hook 'c++-mode-hook 'c-extra-font-locking-hook)
  )

;; Extra font locking in C++

;; Java Mode's: "[A-ZĂĆĂ˘âÂŹ-ĂĆĂ˘âŹâĂĆĂĹ-ĂĆĂÂ¸]\\sw*[[:lower:]]\\sw*"
;; Mine A: "[[:upper:]]+[[:lower:]]+[_[:alnum:]]*"
;; Mine B: "[[:upper:]]\\sw*[[:lower:]]\\sw*"

(defvar pnw/c++-font-lock-extra-types
  (append
   ;;pnw/c-font-lock-extra-types
   '("matrix" "\\sw+_matrix"
     "[io]stringstream"
     "bin_[io][sf]s"

     "array"
     "emerger"

     "\\(vec\\|dir\\|box\\|bbox\\|bbtree\\|line\\|hplane\\|cir\\|mat\\|rot\\|rot2tab\\|aff\\|rgbcolor\\|image\\)[234]" ;direction
     "T"				;STL type argument
     "value_type" "size_type"		;STL types

     ;;"[[:upper:]]\\sw*[[:lower:]]\\sw*"
     ))
  "Extra types to be font-locked in C++.")

(defun c++-extra-font-locking-hook ()
  (setq c++-font-lock-extra-types
	(union c++-font-lock-extra-types
                pnw/c++-font-lock-extra-types))
  (delete-duplicates c++-font-lock-extra-types))

(when pnw/use-extra-types-font-locking
    (add-hook 'c++-mode-hook 'c++-extra-font-locking-hook))

(provide 'cc-font-lock)
