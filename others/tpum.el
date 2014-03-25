;;; tpum.el --- Popup menus in text mode.

;; Copyright (C) 2003 by Free Software Foundation, Inc.

;; Author: Zajcev Evgeny <zevlg@yandex.ru>
;; Maintainer: none, if you want be a maintainer please e-mail me.
;; Created: 2003/10/21
;; Keywords: tools, menus
;; X-CVS: $Id: tpum.el,v 1.2 2003/10/21 21:05:54 lg Exp $

;; This file is NOT part of XEmacs.

;; tpum.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; tpum.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with XEmacs; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.

;;; Synched up with: Not in FSF

;;; Commentary:
;;
;; Save original `popup-menu':
;;
;;    (fset 'old-popup-menu (symbol-function 'popup-menu))
;;
;; Install new `popup-menu':
;;
;;    (fset 'popup-menu (symbol-function 'tpum-popup-menu))
;;  or
;;    (fset 'popup-menu (symbol-function 'tpum-frame-popup-menu))
;;
;; Using various menu styles:
;;  - For popups in separate frame:
;;
;;    (setq tpum-cstyle 'tpum-style-frame)   ; for tpum-frame-popup-menu
;;
;;  - For inplace popups:
;;
;;    (setq tpum-cstyle 'tpum-style-plain)
;;   or
;;    (setq tpum-cstyle 'tpum-style-pseudo)
;; 

;;; Code:
;;

(eval-when-compile
  (require 'cl))

(defgroup tpum nil
  "Popup menus in text mode."
  :prefix "tpum-"
  :group 'environment)

(defgroup tpum-faces nil
  "Faces used in tpum."
  :prefix "tpum-"
  :group 'tpum
  :group 'faces)

(defface tpum-active-face
  (` ((((class grayscale) (background light))
       (:background "Gray90"))
      (((class grayscale) (background dark))
       (:foreground "Gray80"))
      (((class color) (background light))
       (:foreground "black"))
      (((class color) (background dark))
       (:foreground "white"))
      (t (:bold t :underline t))))
  "*Face for displaying activated menu items."
  :group 'tpum-faces)

(defface tpum-deactive-face
  '((((class grayscale) (background dark))
       (:foreground "Gray"))
    (((class grayscale) (background light))
       (:background "Gray"))
    (((class color))
     (:foreground "Gray" :bold nil)))
  "*Face for displaying deactivated menu items."
  :group 'tpum-faces)

(defface tpum-title-face
  '((((class color))
     (:foreground "red4" :bold t)))
  "*Face to display title of menu."
  :group 'tpum-faces)

(defcustom tpum-auto-submenu-mode nil
  "*Non-nil mean auto opening submenus at point."
  :type 'boolean
  :group 'tpum)

(defcustom tpum-isearch-global-scope t
  "*Non-nil mean that isearch will be performed in any shown tpums."
  :type 'boolean
  :group 'tpum)

(defcustom tpum-truncate-lines nil
  "*Value of `truncate-lines' while in `tpum-mode'."
  :type 'boolean
  :group 'tpum)
;(make-variable-buffer-local 'tpum-truncate-lines)

(defcustom tpum-cstyle 'tpum-style-plain
  "*Style to be used."
  :type 'symbol
  :group 'tpum)
;(make-variable-buffer-local 'tpum-cstyle)

(unless (fboundp 'get-face)
  (defalias 'get-face 'identity))

(defface tpum-plain-face1
  `((((class color))
     (:foreground "blue" :bold t)))
  "Border face for plain style."
  :group 'tpum-faces)

(defvar tpum-plain-face (get-face 'tpum-plain-face1))

(defface tpum-pseudo-face1
  `((((class color))
     (:foreground "blue" :bold t))
    (t (:bold t)))
  "Border face for pseudo style."
  :group 'tpum-face)

(defvar tpum-pseudo-face (get-face 'tpum-pseudo-face1))

(defvar tpum-frame-face (get-face 'blue))

(defcustom tpum-max-height 80
  "*Maximum height of popup menu."
  :type 'number
  :group 'tpum)

(defcustom tpum-search-ahead-mode t
  "*Non-nil mean to use type ahead search mode."
  :type 'boolean
  :group 'tpum)

;; FSFmacs
(unless (fboundp 'set-keymap-default-binding)
  (defun set-keymap-default-binding (map cmd)
    (define-key map [t] cmd)))

(defvar tpum-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-default-binding map 'tpum-default-command)
    (define-key map (kbd "C-u") 'universal-argument)
    (define-key map (kbd "C-1") 'digit-argument)
    (define-key map (kbd "C-2") 'digit-argument)
    (define-key map (kbd "C-3") 'digit-argument)
    (define-key map (kbd "C-4") 'digit-argument)
    (define-key map (kbd "C-5") 'digit-argument)
    (define-key map (kbd "C-6") 'digit-argument)
    (define-key map (kbd "C-7") 'digit-argument)
    (define-key map (kbd "C-8") 'digit-argument)
    (define-key map (kbd "C-9") 'digit-argument)
    (define-key map (kbd "C-0") 'digit-argument)
    (define-key map (kbd "M-1") 'digit-argument)
    (define-key map (kbd "M-2") 'digit-argument)
    (define-key map (kbd "M-3") 'digit-argument)
    (define-key map (kbd "M-4") 'digit-argument)
    (define-key map (kbd "M-5") 'digit-argument)
    (define-key map (kbd "M-6") 'digit-argument)
    (define-key map (kbd "M-7") 'digit-argument)
    (define-key map (kbd "M-8") 'digit-argument)
    (define-key map (kbd "M-9") 'digit-argument)
    (define-key map (kbd "M-0") 'digit-argument)

    (define-key map (kbd "C-g") 'tpum-quit)
    (define-key map (kbd "C-G") 'tpum-global-quit)
    ;; Motion
    (define-key map (kbd "C-l") 'recenter)
    (define-key map (kbd "C-n") 'tpum-next)
    (define-key map (kbd "<up>") 'tpum-prev)
    (define-key map (kbd "C-p") 'tpum-prev)
    (define-key map (kbd "<down>") 'tpum-next)
    (define-key map (kbd "M->") 'tpum-goto-last)
    (define-key map (kbd "M-<") 'tpum-goto-first)

    (define-key map (kbd "M-RET") 'tpum-submenu-toggle)
    (define-key map (kbd "M-t") 'tpum-auto-submenu-toggle)
    (define-key map (kbd "RET") 'tpum-select)
;    (define-key map (kbd "M-s") 'tpum-submenu-show)
;    (define-key map (kbd "M-c") 'tpum-submenu-hide)

    ;; Searching
    (define-key map (kbd "C-t") 'tpum-isearch-global-toggle)
    (define-key map (kbd "C-s") 'isearch-forward)
    (define-key map (kbd "C-r") 'isearch-backward)

    ;; Misc
    (define-key map (kbd "<f1>") 'tpum-help)
    (define-key map (kbd "C-h") 'tpum-help)
    (define-key map (kbd "M-h") 'describe-bindings)
    (define-key map (kbd "M-x") 'execute-extended-command)
    (define-key map (kbd "M-:") 'eval-expression)
    (define-key map (kbd "C-x 1") 'delete-other-windows)
    map)
  "Keymap used while in tpum.")


(defun tpum-da-face (isactive)
  "Return face according to ISACTIVE."
  (if isactive 'tpum-active-face 'tpum-deactive-face))

(defstruct tpum-style
  border-face				; face used to draw borders
  toggle-dis toggle-act radio-dis radio-act submenu
  title-sep title-sl title-sr
  left right top bottom
  left-top left-bottom
  right-top right-bottom
  right-bot2 left-bot2 line-bot2 center-bot2 ;when menu is not fully displayed

  ;; delimiters
  single-line double-line
  single-dashed-line double-dashed-line
  no-line
  right-sl right-dl right-sdl right-ddl right-nl
  left-sl left-dl left-sdl left-ddl left-nl)

(defvar tpum-style-plain
  (make-tpum-style
   :border-face tpum-plain-face
   :toggle-dis "[ ] " :toggle-act "[x] " :radio-dis "( ) " :radio-act "(*) "
   :submenu " >>"
   :title-sep "=" :title-sl "|" :title-sr "|"
   :left "|" :right "|" :top "-" :bottom "-"
   :left-top "." :left-bottom "`" :right-top "." :right-bottom "'"
   :right-bot2 "|" :left-bot2 "|" :line-bot2 "." :center-bot2 "vvv"

   :single-line "-" :double-line "=" :single-dashed-line "- -"
   :double-dashed-line "= =" :no-line " "
   :right-sl "|" :right-dl "|" :right-sdl "|" :right-ddl "|" :right-nl "|"
   :left-sl "|" :left-dl "|" :left-sdl "|" :left-ddl "|" :left-nl "|")
  "Plain text style.")

(defvar tpum-style-pseudo
  (make-tpum-style
   :border-face  tpum-pseudo-face
   :toggle-dis "[ ] " :toggle-act "[x] " :radio-dis "( ) " :radio-act "(*) "
   :submenu " >>"
   :title-sep "=" :title-sl "\x15" :title-sr "\x16"
   :left "\x19" :right "\x19" :top "\x12" :bottom "\x12"
   :left-top "\x0d" :left-bottom "\x0e" :right-top "\x0c" :right-bottom "\x0b"
   :right-bot2 "|" :left-bot2 "|" :line-bot2 "." :center-bot2 "vvv"

   :single-line "\x12" :double-line "=" :single-dashed-line "- -"
   :double-dashed-line "= =" :no-line " "
   :right-sl "\x16" :right-dl "\x16" :right-sdl "|" :right-ddl "|" :right-nl "|"
   :left-sl "\x15" :left-dl "\x15" :left-sdl "|" :left-ddl "|" :left-nl "|")
  "Pseudo graphics style.")

(defvar tpum-style-frame
  (make-tpum-style
   :border-face tpum-frame-face
   :toggle-dis "[ ] " :toggle-act "[x] " :radio-dis "( ) " :radio-act "(*) "
   :submenu " >>"
   :title-sep "=" :title-sl "" :title-sr ""
   :left "" :right "" :top "-" :bottom "-"
   :left-top "" :left-bottom "" :right-top "" :right-bottom ""
   :right-bot2 "" :left-bot2 "" :line-bot2 "" :center-bot2 "vvv"

   :single-line "-" :double-line "=" :single-dashed-line "- -"
   :double-dashed-line "= =" :no-line " "
   :right-sl "" :right-dl "" :right-sdl "" :right-ddl "" :right-nl ""
   :left-sl "" :left-dl "" :left-sdl "" :left-ddl "" :left-nl "")
  "Separate frame style.")

(defun tpum-style-toggle (&optional act)
  "Return toggle button, if ACT non-nil toggle button is on."
  (if act
      (tpum-style-toggle-act (eval tpum-cstyle))
    (tpum-style-toggle-dis (eval tpum-cstyle))))

(defun tpum-style-radio (&optional act)
  "Return radio button, if ACT is non-nil - radio button is on."
  (if act
      (tpum-style-radio-act (eval tpum-cstyle))
    (tpum-style-radio-dis (eval tpum-cstyle))))

(defmacro tpum-defmacro (new old)
  "Define NEW accesor using OLD accessor."
  `(defun ,new ()
     (,old (eval tpum-cstyle))))

(tpum-defmacro tpum-st-bface tpum-style-border-face)
(tpum-defmacro tpum-st-td tpum-style-toggle-dis)
(tpum-defmacro tpum-st-ta tpum-style-toggle-act)
(tpum-defmacro tpum-st-rd tpum-style-radio-dis)
(tpum-defmacro tpum-st-ra tpum-style-radio-act)
(tpum-defmacro tpum-st-sub tpum-style-submenu)
(tpum-defmacro tpum-st-ts tpum-style-title-sep)
(tpum-defmacro tpum-st-tsl tpum-style-title-sl)
(tpum-defmacro tpum-st-tsr tpum-style-title-sr)
(tpum-defmacro tpum-st-l tpum-style-left)
(tpum-defmacro tpum-st-r tpum-style-right)
(tpum-defmacro tpum-st-t tpum-style-top)
(tpum-defmacro tpum-st-b tpum-style-bottom)
(tpum-defmacro tpum-st-lt tpum-style-left-top)
(tpum-defmacro tpum-st-lb tpum-style-left-bottom)
(tpum-defmacro tpum-st-lb2 tpum-style-left-bot2)
(tpum-defmacro tpum-st-rt tpum-style-right-top)
(tpum-defmacro tpum-st-rb tpum-style-right-bottom)
(tpum-defmacro tpum-st-rb2 tpum-style-right-bot2)
(tpum-defmacro tpum-st-lbot2 tpum-style-line-bot2)
(tpum-defmacro tpum-st-cbot2 tpum-style-center-bot2)
(tpum-defmacro tpum-st-sl tpum-style-single-line)
(tpum-defmacro tpum-st-dl tpum-style-double-line)
(tpum-defmacro tpum-st-sdl tpum-style-single-dashed-line)
(tpum-defmacro tpum-st-ddl tpum-style-double-dashed-line)
(tpum-defmacro tpum-st-noline tpum-style-no-line)
(tpum-defmacro tpum-st-rsl tpum-style-right-sl)
(tpum-defmacro tpum-st-rdl tpum-style-right-dl)
(tpum-defmacro tpum-st-rsdl tpum-style-right-sdl)
(tpum-defmacro tpum-st-rddl tpum-style-right-ddl)
(tpum-defmacro tpum-st-rnl tpum-style-right-nl)
(tpum-defmacro tpum-st-lsl tpum-style-left-sl)
(tpum-defmacro tpum-st-ldl tpum-style-left-dl)
(tpum-defmacro tpum-st-lsdl tpum-style-left-sdl)
(tpum-defmacro tpum-st-lddl tpum-style-left-ddl)
(tpum-defmacro tpum-st-lnl tpum-style-left-nl)

(defstruct tpum-ctx
  local-mode-map local-mode-name
  recursive-p post-command-hooks truncate-lines after-change-functions undo-list
  point tmpoint column width offset height atomics-list todel-list
  frame child-ctx parent-ctx

  plist)				; user defined plist

;;; Functions
(defun tpum-plist-put (ctx prop val)
  "In CTX put property PROP with value VAL."
  (setf (tpum-ctx-plist ctx) (plist-put (tpum-ctx-plist ctx) prop val)))

(defun tpum-plist-get (ctx prop)
  "In CTX get value of property PROP."
  (plist-get (tpum-ctx-plist ctx) prop))

(defun tpum-plist-rem (ctx prop)
  "In CTX remove property PROP."
  (setf (tpum-ctx-plist ctx) (plist-remprop (tpum-ctx-plist ctx) prop)))

(defun tpum-delete-region (tpum-ctx start end)
  "In TPUM-CTX delete region from START to END.
Check for overlaps inside todel-list in TPUM-CTX."
  (push (cons start end) (tpum-ctx-todel-list tpum-ctx)))

(defun tpum-get-context (&optional point)
  "Return tpum context at POINT."
  (get-text-property (or point (point)) 'tpum-ctx))

(defun tpum-line-num (&optional pnt)
  "Get number of line at PNT.
PNT default to `(point)'."
  (let ((p (or pnt (point))))
    (count-lines (point-min) p)))

(defun tpum-current-column ()
  "Return current column skiping invisible chars."
  (let ((spnt (point))
	(col 0))
    (save-excursion
      (beginning-of-line)
      (while (< (point) spnt)
	(unless (get-text-property (point) 'invisible)
	  (setq col (1+ col)))
	(forward-char 1)))
    col))

(defun tpum-forward-char (num)
  "Forward NUM chars skiping invisible chars."
  (let ((fcfun (if (>= num 0) 'forward-char 'backward-char)))
    (when (< num 0)
      (setq num (- num)))

    ;; First skip any invisible chars at point
    (while (get-text-property (point) 'invisible)
      (funcall fcfun 1))

    (while (> num 0)
      (funcall fcfun 1)
      (unless (get-text-property (point) 'invisible)
	(setq num (1- num)))
      )))

(defun tpum-next-line (num)
  "Move NUM next lines in tpum's CTX."
  (let ((ccol (tpum-current-column)))
    (next-line num)
    (beginning-of-line)
    (tpum-forward-char ccol)
    ))

(defun tpum-move-to-offset (&optional tpum-context)
  "In TPUM-CONTEXT move point to offset column."
  (let ((ctx (or tpum-context (tpum-get-context))))
    (when (tpum-ctx-p ctx)
      (tpum-forward-char (- (+ (tpum-ctx-column ctx)
                               (tpum-ctx-offset ctx))
                            (tpum-current-column))))))

(defun tpum-get-mi (&optional point)
  "Get menu item at POINT."
  (save-excursion
    (and point (goto-char point))
    (get-text-property (point) 'tpum-menu-item)))

(defun tpum-mi-help (mi)
  "Display menu item MI help string in minibuffer."
  (let ((help (tpum-get-keyword mi :help)))
    (when help
      (message help))))

(defun tpum-move-point (arg &optional ctx)
  "Move point ARG times down.
If CTX is ommited `tpum-get-context' will be used."
  (let ((tpum-ctx (or ctx (tpum-get-context)))
        (sarg arg)
        (lines-to-go 0)
        (not-break t))
    (save-excursion
      (catch 'lout
        (while not-break
          (condition-case nil
                (tpum-next-line (if (> sarg 0) 1 -1))
            (t (throw 'lout (setq lines-to-go 0))))

          (when (not (eq (tpum-get-context) tpum-ctx))
            (throw 'lout (setq lines-to-go 0)))

	  (let ((mi (tpum-get-mi)))
	    (when (and mi (tpum-mi-active-p mi))
	      (setq arg (if (> arg 0) (1- arg) (1+ arg)))
	      (when (= arg 0)
		(setq not-break nil))))
	  (setq lines-to-go (1+ lines-to-go)))
	))

    (if (= lines-to-go 0)
	(error "TPUM: can't move")
      (tpum-next-line (if (> sarg 0) lines-to-go (- lines-to-go))))
    ))

;;; Interactive commands
(defun tpum-help ()
  "Show tpum help in minibuffer."
  (interactive)
  (message
   (substitute-command-keys
    "`\\[tpum-help]':help `\\[tpum-next]':next `\\[tpum-prev]':prev `\\[tpum-quit]':quit")))

(defun tpum-next (arg)
  "Goto ARG next visible items."
  (interactive "p")

  (tpum-submenu-hide)
  (condition-case nil
      (tpum-move-point arg)
    (t (call-interactively 'tpum-goto-first)))
  (tpum-mi-help (tpum-get-mi))
  (when tpum-auto-submenu-mode
    (tpum-submenu-show)))

(defun tpum-prev (arg)
  "Goto ARG previous visible items."
  (interactive "p")

  (tpum-submenu-hide)
  (condition-case nil
	(tpum-move-point (- arg))
    (t (call-interactively 'tpum-goto-last)))
  (tpum-mi-help (tpum-get-mi))
  (when tpum-auto-submenu-mode
    (tpum-submenu-show)))

(defun tpum-goto-first ()
  "Go to the first menu item."
  (interactive)
  
  (tpum-submenu-hide)
  (while (condition-case nil
             (progn (tpum-move-point -1) t)
           (t nil)))
  (when tpum-auto-submenu-mode
    (tpum-submenu-show))
  (tpum-mi-help (tpum-get-mi)))

(defun tpum-goto-last ()
  "Go to the last menu item."
  (interactive)

  (tpum-submenu-hide)
  (while (condition-case nil
             (progn (tpum-move-point 1) t)
           (t nil)))

  (when tpum-auto-submenu-mode
    (tpum-submenu-show))
  (tpum-mi-help (tpum-get-mi)))

(defun tpum-auto-submenu-toggle ()
  "Toggle `tpum-auto-submenu-mode'."
  (interactive)
  (setq tpum-auto-submenu-mode (not tpum-auto-submenu-mode))

  (if tpum-auto-submenu-mode
      (message "tpum: Auto submenus mode on.")
    (message "tpum: Auto submenus mode off."))

  (when (interactive-p)
    (if tpum-auto-submenu-mode
	(tpum-submenu-show)
      (tpum-submenu-hide)))
  )

(defun tpum-isearch-global-toggle ()
  "Toggle `tpum-isearch-global-scope'."
  (interactive)
  (setq tpum-isearch-global-scope (not tpum-isearch-global-scope))
  (if tpum-isearch-global-scope
      (message "tpum: Global isearch mode on.")
    (message "tpum: Global isearch mode off.")))

(defvar tpum-isearch-mode nil
  "Non nil mean that isearch uses tpum's searcher.")

(defun tpum-search-data (searcher what &optional bound noerror count)
  "Use SEARCHER to search WHAT in tpum menu after or before point.
If SEARCHER contain 'backward' search performed before point.
BOUND, NOERROR and COUNT are described in `search-forward'."
  (let* ((cctx (tpum-get-context))
	 (origin (point))
	 (cnt (or count 1))
	 (step (cond ((= cnt 0) 0)
		     ((> cnt 0) 1)
		     (t (setq cnt (- cnt)) -1)))
	 found next sstart send mi)
    (or (= step 0)
	(while (and (not found)
		    (setq next (funcall searcher what bound t step)))
	  (setq sstart (match-beginning 0)
		send (match-end 0)
		mi (tpum-get-mi))
	  

	  (if (= sstart send)
	      (setq found t)
	    (goto-char next)
	    (when (and (if tpum-isearch-global-scope
			   t
			 (eq (tpum-get-context) cctx))
		       mi (tpum-mi-active-p mi))
	      (setq found t)))
	  ))

    (cond ((null found)
           (setq next origin
                 send origin))
          ((= step (if (string-match "backward" (symbol-name searcher)) 1 -1))
           (setq next send
                 send sstart))
          (t
           (setq next sstart)))
    (goto-char next)
    ;; Setup the returned value and the `match-data' or maybe fail!
    (funcall searcher what send noerror step)
    ))

(defun tpum-search-forward (what &optional bound noerror count)
  "Search tpum menu item forward from point for string WHAT.
For optional BOUND, NOERROR and COUNT see description for `search-forward'."
  (tpum-search-data #'search-forward what bound noerror count))

(defun tpum-search-backward (what &optional bound noerror count)
  "Search tpum menu item backward from point for string WHAT.
For optional BOUND, NOERROR and COUNT see description for `search-backward'."
  (tpum-search-data #'search-backward what bound noerror count))

(defmacro tpum-define-search-advice (searcher)
  "Advice the built-in SEARCHER function to do tpum search.
That is to call the tpum searcher when variables
`isearch-mode' and `tpum-isearch-mode' are non-nil."
  (let ((tpum-searcher (intern (format "tpum-%s" searcher))))
    `(defadvice ,searcher (around unused activate)
       (if (and tpum-isearch-mode
                ;; The following condition ensure to do a tpum
                ;; search on the `isearch-string' only!
                (string-equal (ad-get-arg 0) isearch-string))
	   (let ((old-isearch-mode tpum-isearch-mode))
	     (unwind-protect
		 (progn
		   ;; Temporarily set `tpum-isearch-mode' to
		   ;; nil to avoid an infinite recursive call of the
		   ;; tpum search function!
		   (setq tpum-isearch-mode nil)
		   (setq ad-return-value
			 (funcall ',tpum-searcher
				  (ad-get-arg 0) ; string
				  (ad-get-arg 1) ; bound
				  (ad-get-arg 2) ; no-error
				  (ad-get-arg 3) ; count
				  )))
	       (setq tpum-isearch-mode old-isearch-mode)))
	 ad-do-it))))

(tpum-define-search-advice search-forward)
(tpum-define-search-advice search-backward)

(defun tpum-isearch-end-hook ()
  "To be used in `isearch-mode-end-hook'."
  (when tpum-isearch-mode
    ;; Hide submenu if needed
    (when (eq (tpum-get-context)
              (save-excursion
                (goto-char isearch-opoint)
                (tpum-get-context)))
      (save-excursion
        (goto-char isearch-opoint)
        (tpum-submenu-hide)))

    (tpum-move-to-offset)
    (when tpum-auto-submenu-mode
      (tpum-submenu-show))
    (tpum-mi-help (tpum-get-mi))))

(defun tpum-search-symbol (chr)
  "Begin to search for CHR."
  (let ((executing-kbd-macro t))	; do not make isearch to be modal
    (isearch-mode t nil nil (not (interactive-p)))
    (isearch-process-search-string
     (char-to-string chr)
     (isearch-text-char-description chr))))

(defun tpum-default-command (keys)
  "Search ahead after KEYS presses."
  (interactive (list (this-command-keys)))
  (let* ((evk (and (= (length keys) 1)
		   (key-press-event-p (aref keys 0))
		   (null (event-modifiers (aref keys 0)))
		   (event-key (aref keys 0))))
	 (kchr evk))
    (if (and tpum-search-ahead-mode (characterp kchr))
	(tpum-search-symbol kchr)

      (if (eq (event-type (aref keys 0)) 'button-release)
	  ;; Button release event are ok
          nil

        (signal 'undefined-keystroke-sequence (list keys))))))

(defun tpum-quit (&optional ctx)
  "Exit tpum mode, using tpum CTX."
  (interactive)
  (let ((tpum-ctx (or ctx (tpum-get-context)))
         (buffer-read-only nil))
;       (after-change-functions nil))

    (unless (tpum-ctx-p ctx)
      (tpum-submenu-hide))
    (if (null tpum-ctx)
        (error "No tpum context at point")

      (if (tpum-ctx-frame tpum-ctx)
          (select-frame (tpum-ctx-frame tpum-ctx))

        ;; Restore things
        (tpum-restore-todel-atomics tpum-ctx))
        
      (setq tpum-isearch-mode (cdr tpum-isearch-mode))

      (setq post-command-hook (tpum-ctx-post-command-hooks tpum-ctx))
      (setq truncate-lines (tpum-ctx-truncate-lines tpum-ctx))
      (setq after-change-functions (tpum-ctx-after-change-functions tpum-ctx))
      (setq buffer-undo-list (tpum-ctx-undo-list tpum-ctx))

      (use-local-map (tpum-ctx-local-mode-map tpum-ctx))
      (setq mode-name (tpum-ctx-local-mode-name tpum-ctx))

      (goto-char (tpum-ctx-point tpum-ctx))
      (set-buffer-modified-p nil)

      ;; ctl-arrow used by pseudo style
      (when (tpum-plist-get tpum-ctx 'ctl-arrow)
	(setq ctl-arrow (tpum-plist-get tpum-ctx 'ctl-arrow)))

      (when (tpum-ctx-recursive-p tpum-ctx)
	(exit-recursive-edit))

      ;; Generate fake misc-user event
      (setq unread-command-event
	    (make-event 'misc-user '(x 0 y 0 button 1 function ignore)))

      (when (tpum-ctx-frame tpum-ctx)
	(delete-frame (tpum-ctx-frame tpum-ctx)))

      ;; Select parent frame if any
      (let ((pctx (tpum-ctx-parent-ctx tpum-ctx)))
	(when (tpum-ctx-p pctx)
	  ;; Unset child ctx and select parent's frame
	  (setf (tpum-ctx-child-ctx pctx) nil)
	  (when (tpum-ctx-frame pctx)
	    (focus-frame (tpum-ctx-frame pctx)))))

      (when (interactive-p)
	(message "TPUM exit."))
      )))

(defun tpum-global-quit ()
  "Quit from all TPUM menus."
  (interactive)
  (while (string= mode-name "TPUM")     ;XXX
    (tpum-quit)))

(defun tpum-submenu-show ()
  "Show submenu if any."
  (interactive)
  (let ((tmi (tpum-get-mi))
	(tpum-auto-submenu-mode nil)
	nctx pctx)

    (when (and tmi (consp tmi))
      (save-excursion
	(tpum-select)
	(setq nctx (tpum-get-context)))
      (setq pctx (tpum-ctx-parent-ctx nctx))
      (when (and (tpum-ctx-p pctx) (tpum-ctx-frame pctx))
	(focus-frame (tpum-ctx-frame pctx)))))
  )

(defun tpum-submenu-hide ()
  "Hide submenu if any."
  (interactive)
  (let* ((cctx (tpum-get-context))
	 (smctx (tpum-ctx-child-ctx cctx)))

    (when (tpum-ctx-p smctx)
      (save-excursion
	(tpum-quit smctx))
      )))

(defun tpum-submenu-toggle ()
  "Show or hide submenu."
  (interactive)
  (if (tpum-ctx-child-ctx (tpum-get-context))
      (tpum-submenu-hide)
    (tpum-submenu-show)))

(defun tpum-submenu-select ()
  "Select submenu."
  (interactive)
  (let ((smctx (tpum-ctx-child-ctx (tpum-get-context))))

    (when (tpum-ctx-p smctx)
      (if (tpum-ctx-frame smctx)
	  (focus-frame (tpum-ctx-frame smctx))

	(goto-char (tpum-ctx-tmpoint smctx))
	(tpum-move-point 1 smctx)
	(tpum-move-to-offset smctx))

      (when tpum-auto-submenu-mode
	(tpum-submenu-show))
      )))

(defun tpum-apply-callback (cbfun)
  "Apply menuitem's call back function CBFUN."
  (cond ((listp cbfun) (eval cbfun))
	((commandp cbfun) (call-interactively cbfun))
	((symbolp cbfun) (call-interactively cbfun))
	(t nil)))

(defun tpum-select ()
  "Select current menu item."
  (interactive)
  (let ((tpum-ctx (tpum-get-context))
	(mi (tpum-get-mi))
	nctx)
    (if (not mi)
	(progn
	  (beep)
	  (message "TPUM: No menu item under cursor."))

      (cond ((listp mi)			;submenu
	     (if (tpum-ctx-child-ctx tpum-ctx)
		 (call-interactively 'tpum-submenu-select)

	       (setq nctx
		     (if (tpum-ctx-frame tpum-ctx)
			 (let* ((tfr (tpum-ctx-frame tpum-ctx))
				(tpum-frame-y-offset 0) ; hack
				(tpum-frame-x-offset 2)) ; hack
			   (tpum-frame-do-menu
			    mi
			    (cons (+ (frame-property tfr 'left)
				     (frame-pixel-width tfr)
				     tpum-frame-x-offset)
				  (+ (frame-property tfr 'top)
				     (cdr (tpum-frame-get-coord))))))

		       (tpum-do-menu mi (save-excursion
					  (tpum-next-line -1)
					  (tpum-forward-char (- (tpum-ctx-width tpum-ctx)
								(tpum-ctx-offset tpum-ctx) -1))
					  (point)))))
	       (setf (tpum-ctx-child-ctx tpum-ctx) nctx)
	       (setf (tpum-ctx-parent-ctx nctx) tpum-ctx)))

	    ((vectorp mi)		; Normal menu-item
	     (tpum-global-quit)
	     (tpum-apply-callback (cadr (append mi nil))))

	    (t (message "Unknown menu item type."))))))

(defun tpum-mode (tpum-ctx)
  "Enter tpum mode, using TPUM-CTX."
  (setf (tpum-ctx-local-mode-map tpum-ctx) (current-local-map))
  (setf (tpum-ctx-local-mode-name tpum-ctx) mode-name)

  (use-local-map tpum-mode-map)
  (setq mode-name "TPUM")
  (setq tpum-isearch-mode (cons t tpum-isearch-mode))

  (set-buffer-modified-p nil)

  (add-hook 'isearch-mode-end-hook 'tpum-isearch-end-hook)
  )

(defun tpum-safe-delrec (tpum-ctx width height &optional startpoint)
  "In TPUM-CTX safe delete rectangle with sizes WIDTH HEIGHT.
Starting from STARTPOINT, if ommited `point' will be used."
  (let (ccol ep)
    (save-excursion
      (and startpoint (goto-char startpoint))
      (setq ccol (tpum-current-column))
      (while (> height 0)
        ;; XXX Untabify line
        (funcall (lambda (beg end)
                   (save-excursion
                     (narrow-to-region beg end)
                     (goto-char beg)
                     (while (re-search-forward "\t" nil t)
		       (let ((indent-tabs-mode nil))
                         (replace-match (make-string tab-width ?\x20))))
                     (widen)))
                 (progn (beginning-of-line) (point)) (progn (end-of-line) (point)))

        ;; Now we are at the end of line
        (setq ep (tpum-current-column))
        (when (< (- ep ccol) width)
          (end-of-line)
          (tpum-delete-region
           tpum-ctx
           (point-marker)
           (progn (insert (make-string (- width (- ep ccol)) ?\x20)) (point-marker))))

        (beginning-of-line)
        (tpum-forward-char ccol)
        (push (cons (point-marker)
                    (save-excursion
                      (forward-char width)
                      (point-marker)))
              (tpum-ctx-atomics-list tpum-ctx))

	(add-text-properties (point) (+ (point) width) '(invisible t))

	(end-of-line)
	(when (eobp)
	  (tpum-delete-region
	   tpum-ctx
	   (point-marker) (progn (insert "\n") (point-marker))))
	(forward-line)
	(setq height (1- height))))
    (goto-char (+ (point) width))
    ))

(defun tpum-restore-todel-atomics (ctx)
  "Restore some stuff of tpum CTX."
  (mapcar (lambda (el)
	    (delete-region (marker-position (car el)) (marker-position (cdr el))))
	  (tpum-ctx-todel-list ctx))
  (mapcar (lambda (el)
	    (add-text-properties (marker-position (car el)) (marker-position (cdr el))
				 '(invisible nil)))
	  (tpum-ctx-atomics-list ctx)))

(defun tpum-insert-string (tpum-ctx tpum-string)
  "Using TPUM-CTX insert TPUM-STRING.
TPUM-STRING is list of conses (str . face)."
  (mapcar (lambda (el)
	    (let ((str (if (consp el) (car el) el))
		  (face (if (consp el) (cdr el) 'default)))
              (tpum-delete-region
               tpum-ctx
               (point-marker) (progn (insert-face str face) (point-marker)))))
          tpum-string))

(defun tpum-insert-menu (tpum-menu tpum-ctx &optional startpoint)
  "Insert TPUM-MENU using TPUM-CTX at STARTPOINT.
TPUM-MENU is list of conses which car is menu-item and cdr is tpum string."
  (let ((lines tpum-menu))

    (when startpoint
      (goto-char startpoint))

    (while lines
      (save-excursion
	(add-text-properties (point)
			     (progn
			       (tpum-insert-string tpum-ctx (cdar lines))
			       (point))
			     (list 'tpum-ctx tpum-ctx
				   'tpum-menu-item (caar lines))))
      (setq lines (cdr lines))

      (when lines
	(tpum-next-line 1)))
    ))

(defun tpum-get-keyword (menu-item keyword &optional defret)
  "From MENU-ITEM get KEYWORD value.
If KEYWORD not found DEFRET returned."
  (let* ((mi-list (if (listp menu-item) menu-item (append menu-item nil)))
	 (ckword (car mi-list))
	 (kw-retval defret))
    (while mi-list
      (if (eq ckword keyword)
	  (progn
	    (setq kw-retval (cadr mi-list))
	    (setq mi-list nil)))	; break
      (setq mi-list (cdr mi-list))
      (setq ckword (car mi-list)))
    kw-retval))

;; FSFmacs
(unless (fboundp 'keywordp)
  (defun keywordp (sym)
    (eq (aref (symbol-name sym) 0) ?:)))

(defun tpum-get-suffix (menu-item)
  "Get suffix of MENU-ITEM."
  (if (vectorp menu-item)
      (let* ((mit (append menu-item nil))
	     (sf1 (and (> (length mit) 3)
		       (not (keywordp (nth 2 mit)))
		       (not (keywordp (nth 3 mit)))
		       (nth 3 mit)))
	     (sf2 (tpum-get-keyword menu-item :suffix)))
	(or sf2 sf1))
    nil))
	
(defun tpum-mi-active-p (menu-item)
  "Return non-nil if MENU-ITEM is active."
  (cond ((stringp menu-item) nil)	; title or separator
	((consp menu-item) t)		; submenu
	((vectorp menu-item)
	 (let ((mit (append menu-item nil))
	       (at2 (tpum-get-keyword menu-item :active t))) ; Get value of :active keyword

	   (cond ((and (> (length mit) 2) (not (keywordp (nth 2 mit))))
		  (nth 2 mit))
		 (at2 (eval at2))
		 (t t))))))

(defun tpum-setup-ctx (menuspec tpum-ctx)
  "According to MENUSPEC setup TPUM-CTX."
  (let ((fel (car menuspec))
        (ret-wid 0)
        (ret-hei 0)
        (ret-off 1))                        ; XXX see tpum-move-to-offset

    (while fel
      (let* ((mistyle (cond ((vectorp fel) (tpum-get-keyword fel :style))
                            ((consp fel) nil)
                            (t nil)))
             (offset (cond ((eq mistyle 'toggle)
                            (length (tpum-st-td)))
                           ((eq mistyle 'radio)
                            (length (tpum-st-rd)))
                           (t 0)))
             (width (length
                     (cond ((vectorp fel) (car (append fel nil)))
                           ((consp fel) (concat (car fel) (tpum-st-sub)))
                           ((stringp fel) fel)
			   (t ""))))
	     (suffix (tpum-get-suffix fel))
	     (suflen (if suffix (1+ (length (eval suffix))) 0)))

	(when (> (+ width suflen) ret-wid)
	  (setq ret-wid (+ width suflen)))
	(setq ret-hei (1+ ret-hei))
	(when (> offset ret-off)
	  (setq ret-off offset))

	(setq menuspec (cdr menuspec))
	(setq fel (car menuspec))))

    (setf (tpum-ctx-offset tpum-ctx) ret-off)
    (setf (tpum-ctx-width tpum-ctx) (+ ret-wid ret-off)) ; XXX
    (setf (tpum-ctx-height tpum-ctx) ret-hei)))

(defun tpum-make-delim (menu-item width)
  "Make delimiter string using MENU-ITEM.
Delimeter shold be WIDTH chars length."
  (let (lb rb lin)
    (cond ((string= menu-item "--:singleLine")
	   (setq lb (tpum-st-lsl))
	   (setq rb (tpum-st-rsl))
	   (setq lin (tpum-st-sl)))
	  ((string= menu-item "--:doubleLine")
	   (setq lb (tpum-st-ldl))
	   (setq rb (tpum-st-rdl))
	   (setq lin (tpum-st-dl)))
	  ((string= menu-item "--:singleDashedLine")
	   (setq lb (tpum-st-lsdl))
	   (setq rb (tpum-st-rsdl))
	   (setq lin (tpum-st-sdl)))
	  ((string= menu-item "--:doubleDashedLine")
	   (setq lb (tpum-st-lddl))
	   (setq rb (tpum-st-rddl))
	   (setq lin (tpum-st-ddl)))

	  ;; Default separator as is "--:singleLine"
	  (t
	   (setq lb (tpum-st-lsl))
	   (setq rb (tpum-st-rsl))
	   (setq lin (tpum-st-sl))))

    (list
     (cons lb (tpum-st-bface))
     (substring
      (mapconcat 'identity
		 (make-list width lin) "")
	   0 width)
     (cons rb (tpum-st-bface))))
  )

(defun tpum-mitotmi (menu-item tpum-ctx)
  "Convert MENU-ITEM to tpum menu item using TPUM-CTX."
  (let ((width (tpum-ctx-width tpum-ctx))
;	(height (tpum-ctx-height tpum-ctx))
	(offset (tpum-ctx-offset tpum-ctx)))

    (cond ((listp menu-item)		;submenu
	   (let ((iname (car menu-item)))

	     (list (cons (tpum-st-l) (tpum-st-bface))
		   (concat (make-string offset ?\ ) iname)
		   (concat (make-string
			    (- width (length iname) offset
			       (length (tpum-st-sub))) ?\ ))
		 (tpum-st-sub)
		 (cons (tpum-st-r) (tpum-st-bface)))))

	  ((vectorp menu-item)
	   (let* ((mi-list (append menu-item nil))
		  (iname (car mi-list))
		  (style (tpum-get-keyword menu-item :style))
		  (active (tpum-mi-active-p menu-item))
		  (selected (eval (tpum-get-keyword menu-item :selected)))
		  (suffix (eval (tpum-get-suffix menu-item))))

	     (when suffix
	       (setq iname (if (> (length iname) 0)
			       (concat iname " " suffix)
			     suffix)))
	     (cond ((eq style 'toggle)
		    (list
		     (cons (tpum-st-l) (tpum-st-bface))
		     (cons (tpum-style-toggle selected) (tpum-da-face active))
		     (cons iname (tpum-da-face active))
		     (make-string (- width (length iname) offset) ?\x20)
		     (cons (tpum-st-r) (tpum-st-bface))))

		   ((eq style 'radio)
		    (list
		     (cons (tpum-st-l) (tpum-st-bface))
		     (cons (tpum-style-radio selected) (tpum-da-face active))
		     (cons iname (tpum-da-face active))
		     (make-string (- width (length iname) offset) ?\ )
		     (cons (tpum-st-r) (tpum-st-bface))))
		   ;; TODO: radio, normal, etc
		   (t
		    (list
		     (cons (tpum-st-l) (tpum-st-bface))
		     (make-string offset ?\ )
		     (cons iname (tpum-da-face active))
		     (make-string (- width (length iname) offset) ?\ )
		     (cons (tpum-st-r) (tpum-st-bface)))))
	     ))

	  ((stringp menu-item)
	   (cond ((and (> (length menu-item) 1) (string= "--" (substring menu-item 0 2)))
		  (tpum-make-delim menu-item width))
		 (t
		  (list
		   (cons (tpum-st-l) (tpum-st-bface))
		   (make-string offset ?\ )
		   (cons menu-item 'tpum-deactive-face)
		   (make-string (- width (length menu-item) offset) ?\ )
		   (cons (tpum-st-r) (tpum-st-bface))))))

	  ((symbolp menu-item)
	   (cond ((eq menu-item 'menu-begin)
		  (list
		   (cons (tpum-st-lt) (tpum-st-bface))
		   (cons (substring
			  (mapconcat 'identity
				     (make-list width (tpum-st-t)) "")
			  0 width) (tpum-st-bface))
		   (cons (tpum-st-rt) (tpum-st-bface))))
		 ((eq menu-item 'menu-title)
		  (list
		   (cons (tpum-st-l) (tpum-st-bface))
		   (cons (eval menu-item) 'tpum-title-face)
		   (make-string (- width (length (eval menu-item))) ?\ )
		   (cons (tpum-st-r) (tpum-st-bface))))

		 ((eq menu-item 'menu-separator)
		  (list
		   (cons (tpum-st-tsl) (tpum-st-bface))
		   (cons (substring
			  (mapconcat 'identity
				     (make-list width (tpum-st-ts)) "")
			  0 width) (tpum-st-bface))
		   (cons (tpum-st-tsr) (tpum-st-bface))))

		 ((eq menu-item 'menu-end)
		  (list
		   (cons (tpum-st-lb) (tpum-st-bface))
		   (cons (substring
			  (mapconcat 'identity
				     (make-list width (tpum-st-b)) "")
			  0 width) (tpum-st-bface))
		   (cons (tpum-st-rb) (tpum-st-bface))))
		 (t nil)))

	  (t (list
	      (cons (tpum-st-l) (tpum-st-bface))
	      "defstring"
	      (cons (tpum-st-r) (tpum-st-bface)))))))

(defun tpum-menu-title (menuspec)
  "Return title of MENUSPEC or nil, if there no title."
  (let ((postit (car menuspec)))
  (if (and (not (keywordp postit))
	   (not (listp postit)))
      postit
    nil)))

(defun tpum-menu-process-keywords (menuspec)
  "Cut off all keywords in MENUSPEC."
  (while (keywordp (car menuspec))
    (setq menuspec (cddr menuspec)))
  menuspec)

(defun tpum-apply-filter (menuspec)
  "Apply filter function to MENUSPEC and return new MENU."
  (let* ((filter (tpum-get-keyword menuspec :filter))
	 (nm (if filter (funcall filter menuspec) menuspec)))
    nm))

(defun tpum-do-modal (ctx)
  "Do modal mode using CTX."

  (setf (tpum-ctx-recursive-p ctx) t)
  (recursive-edit))

(defun tpum-do-menu (menuspec &optional spoint frame-coords)
  "Insert menu specified by MENUSPEC at the SPOINT.
If FRAME-COORDS is given, then popup Emacs frame at FRAME-COORDS.
Return tpum context."
  ;; XXX
  (let* ((tpum-ctx (make-tpum-ctx :frame frame-coords)) ;tpum-ctx-frame will hold frame coords temporary
	 (filter (tpum-get-keyword menuspec :filter))
	 (menu-title (tpum-menu-title menuspec))
	 (desc (tpum-menu-process-keywords (if menu-title (cdr menuspec) menuspec)))
	 (inrec nil)
	 (buffer-read-only nil))

    ;; Remove any post command hooks
    (setf (tpum-ctx-post-command-hooks tpum-ctx) post-command-hook)
    (setq post-command-hook nil)
    (setf (tpum-ctx-truncate-lines tpum-ctx) truncate-lines)
    (setq truncate-lines tpum-truncate-lines)
    (setf (tpum-ctx-after-change-functions tpum-ctx) after-change-functions)
    (setq after-change-functions nil)
    (setf (tpum-ctx-undo-list tpum-ctx) buffer-undo-list)

    ;; pseudo stlye uses ctl-arrow
    (when (eq tpum-cstyle 'tpum-style-pseudo)
      (tpum-plist-put tpum-ctx 'ctl-arrow ctl-arrow)
      (setq ctl-arrow 11))

    ;; Apply filter function
    (when filter
      (setq desc (funcall filter desc)))

    (tpum-setup-ctx (cons menu-title desc) tpum-ctx)

    ;; Construct list of strings to insert
    (unless (tpum-ctx-frame tpum-ctx)
      (setq inrec (cons (cons nil (tpum-mitotmi 'menu-begin tpum-ctx)) inrec))
      (setf (tpum-ctx-height tpum-ctx) (+ 1 (tpum-ctx-height tpum-ctx))))

    (when popup-menu-titles
      (setq inrec (cons (cons nil (tpum-mitotmi 'menu-title tpum-ctx)) inrec))
      (setq inrec (cons (cons nil (tpum-mitotmi 'menu-separator tpum-ctx)) inrec))
      (setf (tpum-ctx-height tpum-ctx) (+ 2 (tpum-ctx-height tpum-ctx))))

    ;; Construct tpum-menu
    (while desc
      (let ((inc (tpum-get-keyword (car desc) :included))
	    (conf (tpum-get-keyword (car desc) :config)))
	(setq inc (if inc (eval inc) t))
	(setq inc (if conf (memq conf menubar-configuration) inc))

	(when inc
	  (setq inrec (cons (cons (car desc)
				  (tpum-mitotmi (car desc) tpum-ctx))
			    inrec))))
      (setq desc (cdr desc)))

    (unless (tpum-ctx-frame tpum-ctx)
      (setq inrec (cons (cons nil (tpum-mitotmi 'menu-end tpum-ctx)) inrec)))
    (setq inrec (nreverse inrec))

    ;; Configure frame if needed
    (when (tpum-ctx-frame tpum-ctx)
      (let ((coord (tpum-ctx-frame tpum-ctx))
	    (blv (buffer-local-variables))
	    buf tcf)
	(setf (tpum-ctx-frame tpum-ctx)
	      (tpum-frame-make (car coord) (cdr coord)
			       (+ 2 (tpum-ctx-width tpum-ctx)) (tpum-ctx-height tpum-ctx)))
	(setq tcf (tpum-ctx-frame tpum-ctx))
	(set-frame-size tcf (+ 2 (tpum-ctx-width tpum-ctx))
			(tpum-ctx-height tpum-ctx))
	(setq buf (generate-new-buffer (concat "*tpum*" (if menu-title menu-title "empty*"))))
	(set-window-buffer (frame-selected-window tcf) buf)
	(make-frame-visible tcf)
	(focus-frame tcf)
	(switch-to-buffer buf)
	;; Setup buffer local variables
	(mapcar (lambda (vv) (condition-case nil (set (car vv) (cdr vv)) (t nil))) blv)))

    (setf (tpum-ctx-point tpum-ctx) (point)) ; save position before moving point
    ;; Move point to start location
    (when spoint
      (goto-char spoint))

    ;; Delete rectangle
    (tpum-safe-delrec tpum-ctx (+ 2 (tpum-ctx-width tpum-ctx)) (length inrec))

    (save-excursion
      (tpum-insert-menu inrec tpum-ctx))

    ;; Save column and point
    (setf (tpum-ctx-tmpoint tpum-ctx) (point))
    (setf (tpum-ctx-column tpum-ctx) (tpum-current-column))

    (condition-case nil
	(progn
	  (tpum-move-point 1)
	  (tpum-move-to-offset tpum-ctx))
      (t nil))

    (tpum-mode tpum-ctx)

    (when tpum-auto-submenu-mode
      (tpum-submenu-show))

  tpum-ctx))

(defun tpum-popup-menu (menu &optional event)
  "Popup MENU in text mode.
EVENT is not used."
  (tpum-do-menu menu))

;;; Ballooning support
(defun tpum-frame-make (x y width height &optional buffer)
  "At X Y using WIDTH HEIGHT size make balloon frame to be used by tpum.
Optionally you may specify BUFFER to select in newly created frame.
Return Emacs frame."
  (let ((frame (make-frame `(
			     (top-toolbar-visible-p . nil)
			     (left-toolbar-visible-p . nil)
			     (right-toolbar-visible-p . nil)
			     (bottom-toolbar-visible-p . nil)
			     (has-modeline-p . nil)
			     (modeline-shadow-thickness . 0)
			     (vertical-scrollbar-visible-p . nil)
			     (horizontal-scrollbar-visible-p . nil)
			     (menubar-visible-p . nil)
			     (text-cursor-visible-p . t)
			     (left-margin-width . 1)
			     (initially-unmapped . t)
			     (internal-border-width . 1)
			     (name . "*tpum frame*")
			     (border-width . 2)
			     (border-color . ,(face-foreground-name (tpum-st-bface)))
			     (top . ,y)
			     (left . ,x)
			     (popup . ,(selected-frame))
			     (minibuffer . nil)
			     (width . ,width)
			     (height . ,height)))))
    (when buffer
      (set-window-buffer (frame-selected-window frame) buffer))

    frame))

(defvar tpum-frame-y-offset 42 "Hack")
(defvar tpum-frame-x-offset 6 "Hack")

(defun tpum-frame-get-coord ()
  "Get coordinates of point."
  (let ((edgs (window-pixel-edges))
        (lw (/ (window-text-area-pixel-width) (window-width)))
        (lh (/ (window-text-area-pixel-height) (window-height))))
    (cons (+ tpum-frame-x-offset (* lw (current-column)) (car edgs))
          (+ tpum-frame-y-offset (* lh (count-lines (window-start) (window-dot))) (cadr edgs)))))

(defun tpum-frame-do-menu (menu coor)
  "Popup MENU in separate frame at COOR.
COOR is cons cell in form (x . y)."
;  (let ((tfr (tpum-frame-make (car coor) (cdr coor) 3 1)))
;    (tpum-do-menu menu nil tfr)))
  (tpum-do-menu menu nil coor))

(defun tpum-frame-popup-menu (menu &optional event)
  "Popup MENU in separate frame.
EVENT is some mouse event."
  (tpum-frame-do-menu
   menu
   (if event
       (cons (event-x-pixel event) (event-y-pixel event))
     (tpum-frame-get-coord))))

(provide 'tpum)

;;; tpum.el ends here
