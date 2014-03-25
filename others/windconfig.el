;;; windconfig.el --- resize windows interactively
;;
;; Copyright 2007 Bastien Guerry
;;
;; Author: Bastien <bzg AT altern DOT org>
;; Version: 0.6
;; Keywords: window
;; URL: http://www.cognition.ens.fr/~guerry/u/windconfig.el
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;; This is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; See `windconfig' docstring.
;;
;;; History:
;;
;; This was largely inspired by Hirose Yuuji and Bob Wiener original
;; `resize-window' as posted on the emacs-devel mailing list by Juanma.
;; This was also inspired by Lennart Borgman's bw-interactive.el. See
;; related discussions on the emacs-devel mailing list. Special thanks
;; to Drew Adams for detailed feedback.
;;
;; Also check http://www.emacswiki.org/cgi-bin/wiki/WindowResize for
;; general hints on window resizing.
;;
;; My main goal was to deal with window resizing in one single defun.
;;
;; Put this file into your load-path and the following into your
;;   ~/.emacs: (require 'windconfig)
;;
;;; Todo:
;;
;; - add numbers to window configurations in the ring
;; - let register key sequence as macros
;; - better help window?
;;
;;; Code:

(eval-when-compile
  (require 'cl)
  (require 'windmove)
  (require 'ring))

;;; User variables:

(defconst windconfig-version "0.6"
  "The version number of the file windconfig.el.")

(defcustom windconfig-move-borders t
  "Default method for resizing windows.
\\<windconfig-mode-map>Non-nil means that windconfig will move borders.
For example, \\[windconfig-left] will move the first movable border to the
left, first trying to move the right border.  \\[windconfig-up] will move
the first movable border up, first trying to move the bottom border.

Nil means that it will shrink or enlarge the window instead.
\\[windconfig-down] and  \\[windconfig-up] will shrink and enlarge the window
vertically.  \\[windconfig-left] and \\[windconfig-right] will shrink and
enlarge the window horizontally."
  :type 'boolean
  :group 'convenience)

(defcustom windconfig-default-increment 1
  "The default number of lines for resizing windows."
  :type 'integer
  :group 'convenience)

(defcustom windconfig-verbose 2
  "Integer that say how verbose Windconfig should be.
The higher the number, the more feedback Windconfig will give.
A value of 0 will prevent any message to be displayed.
A value of 1 will display errors only.
A value of 2 will display errors and messages."
  :type 'integer
  :group 'convenience)

(defcustom windconfig-ring-size 10
  "The size of the ring for storing window configurations."
  :type 'integer
  :group 'convenience)

(defcustom windconfig-windmove-relative-to-point 0
  "Nil means select adjacent window relatively to the point position.
Non-nil means select adjacent window relatively to the window
edges.  See the docstring of `windmove-up' for details."
  :group 'convenience
  :type 'integer)

(defcustom windconfig-modifiers '((meta shift) meta
				  (control meta) control)
  "A list of modifiers for arrow keys commands.
Each element can be a modifier or a list of modifiers.

The first modifier is for selecting windows with `windmove'.
The second modifier is for moving the up/left border instead of
the bottom/right border when there are two movable borders.
The third modifier is to move borders and keep the width/height
size fixed.
The fourth modifier is to move boder or resize window while
temporarily negating the increment value.

Make sure the four elements of this list are distinct to avoid
conflicts between keybindings."
  :group 'convenience
  :type '(list
	  (choice :tag "Modifier for selecting the adjacent windows"
		  (symbol :tag "Single modifier")
		  (repeat :tag "Multiple modifiers"
			  (symbol :tag "Modifier")))
	  (choice :tag "Modifier for moving the left/up border instead of the right/bottom border"
		  (symbol :tag "Single modifier")
		  (repeat :tag "Multiple modifiers"
			  (symbol :tag "Modifier")))
	  (choice :tag "Modifier for moving borders with fixed width/height"
		  (symbol :tag "Single modifier")
		  (repeat :tag "Multiple modifiers"
			  (symbol :tag "Modifier")))
	  (choice :tag "Modifier for negating increment temporarily"
		  (symbol :tag "Single modifier")
		  (repeat :tag "Multiple modifiers"
			  (symbol :tag "Modifier")))))

;;; Variables and keymap:

(defvar windconfig-msg '("" . 0))
(defvar windconfig-buffer nil)
(defvar windconfig-increment nil)
(defvar windconfig-configuration-ring nil)
(defvar windconfig-window-configuration-0 nil)
(defvar windconfig-previous-mode nil)
(defvar windconfig-overriding-terminal-local-map-0 nil)
(defvar windconfig-overriding-menu-flag-0 nil)

(defvar windconfig-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap self-insert-command] 'windconfig-other-char)
    ;; move borders outwards or shrink/enlarge
    (define-key map [left] 'windconfig-left)
    (define-key map [right] 'windconfig-right)
    (define-key map [up] 'windconfig-up)
    (define-key map [down] 'windconfig-down)
    ;; Use windmove to select adjacent window. The default keybindings
    ;; in `windconfig-modifiers' should match those of windmove
    (let ((mod (nth 0 windconfig-modifiers)))
      (if (symbolp mod) (setq mod (list mod)))
      (define-key map (vector (append mod '(left))) 'windconfig-select-left)
      (define-key map (vector (append mod '(right))) 'windconfig-select-right)
      (define-key map (vector (append mod '(up))) 'windconfig-select-up)
      (define-key map (vector (append mod '(down))) 'windconfig-select-down))
    ;; Move the up/left border instead of bottom/right when there are
    ;; two movable borders
    (let ((mod (nth 1 windconfig-modifiers)))
      (if (symbolp mod) (setq mod (list mod)))
      (define-key map (vector (append mod '(left))) 'windconfig-left-force-left)
      (define-key map (vector (append mod '(right))) 'windconfig-right-force-left)
      (define-key map (vector (append mod '(up))) 'windconfig-up-force-up)
      (define-key map (vector (append mod '(down))) 'windconfig-down-force-up))
    ;; Move borders with fixed width/height
    (let ((mod (nth 2 windconfig-modifiers)))
      (if (symbolp mod) (setq mod (list mod)))
      (define-key map (vector (append mod '(left))) 'windconfig-left-fixed)
      (define-key map (vector (append mod '(right))) 'windconfig-right-fixed)
      (define-key map (vector (append mod '(up))) 'windconfig-up-fixed)
      (define-key map (vector (append mod '(down))) 'windconfig-down-fixed))
    ;; Negate increment temporarily
    (let ((mod (nth 3 windconfig-modifiers)))
      (if (symbolp mod) (setq mod (list mod)))
      (define-key map (vector (append mod '(left))) 'windconfig-left-minus)
      (define-key map (vector (append mod '(right))) 'windconfig-right-minus)
      (define-key map (vector (append mod '(up))) 'windconfig-up-minus)
      (define-key map (vector (append mod '(down))) 'windconfig-down-minus))
    ;; Set the increment
    (define-key map "~" 'windconfig-negate-increment)
    (define-key map "+" 'windconfig-increase-increment)
    (define-key map "-" 'windconfig-decrease-increment)
    ;; FIXME
    (define-key map "i" 'windconfig-set-increment)
    ;; other keys
    (define-key map " " 'windconfig-toggle-method)
    (define-key map "s" 'windconfig-save-window-configuration)
    (define-key map "r" 'windconfig-restore-window-configuration)
    ;; shorcut keys for manipulating windows
    (define-key map "0" 'delete-window)
    (define-key map "o" 'windconfig-other-window)
    (define-key map "/" 'windconfig-bottom-right)
    (define-key map "\M-/" 'windconfig-up-left)
    (define-key map (kbd "\\") 'windconfig-up-right)
    (define-key map (kbd "M-\\") 'windconfig-bottom-left)
    (define-key map "1" 'windconfig-delete-other-windows)
    (define-key map "2" 'windconfig-split-window-vertically)
    (define-key map "3" 'windconfig-split-window-horizontally)
    (define-key map "=" 'windconfig-balance-windows)
    (define-key map "\C-xo" 'windconfig-other-window)
    (define-key map "\C-x0" 'windconfig-delete-window)
    (define-key map "\C-x1" 'windconfig-delete-other-windows)
    (define-key map "\C-x2" 'windconfig-split-window-vertically)
    (define-key map "\C-x3" 'windconfig-split-window-horizontally)
    (define-key map "\C-x+" 'windconfig-balance-windows)
    (define-key map (kbd "C-a")
      (lambda() (interactive) (move-beginning-of-line 1)))
    (define-key map (kbd "C-e")
      (lambda() (interactive) (move-end-of-line 1)))
    (define-key map "=" 'windconfig-balance-windows)
    (define-key map [down-mouse-1] 'mouse-set-point)
    ;; help, save and exit
    (define-key map (kbd "RET") 'windconfig-exit)
    (define-key map "x" 'windconfig-exit)
    (define-key map "\C-c\C-c" 'windconfig-exit)
    (define-key map "?" 'windconfig-help)
    (define-key map "q" 'windconfig-cancel-and-quit)
    (define-key map "c" 'windconfig-cancel-and-quit)
    (define-key map (kbd "C-g") 'windconfig-cancel-and-quit)
    map)
  "Keymap for `windconfig'.")

(defun windconfig-other-char ()
  "Undefine all keys.  Send a message for some."
  (interactive)
  (let* ((key (if current-prefix-arg
		  (substring (this-command-keys)
			     universal-argument-num-events)
		(this-command-keys))))
    (cond ((vectorp key) (ding))
	  ((stringp key)
	   ;; send warning for only no warning for complex keys and
	   ;; mouse events
	   (setq windconfig-msg
		 (cons (format "[`%s' not bound]" key) 1))))))

;;; Aliases:

(defun windconfig-other-window ()
  "Select other window."
  (interactive)
  (if (one-window-p)
      (setq windconfig-msg (cons "[No other window]" 1))
    (other-window 1)
    (setq windconfig-msg (cons (format "Now in %s" (buffer-name)) 2))))

(defun windconfig-delete-window ()
  "Delete window."
  (interactive)
  (if (one-window-p)
      (setq windconfig-msg (cons "[Can't delete sole window]" 1))
    (other-window 1)
    (setq windconfig-msg (cons "Window deleted" 2))))

(defun windconfig-delete-other-windows ()
  "Delete other windows."
  (interactive)
  (if (one-window-p)
      (setq windconfig-msg (cons "[No other window]" 1))
    (delete-other-windows)
    (setq windconfig-msg (cons "Windows deleted" 2))))

(defun windconfig-split-window-horizontally ()
  "Split window horizontally."
  (interactive)
  (split-window-horizontally)
  (setq windconfig-msg (cons "Window horizontally split" 2)))

(defun windconfig-split-window-vertically ()
  "Split window vertically."
  (interactive)
  (split-window-vertically)
  (setq windconfig-msg (cons "Window vertically split" 2)))

(defun windconfig-balance-windows ()
  "Balance windows."
  (interactive)
  (balance-windows)
  (setq windconfig-msg (cons "Windows balanced" 2)))

;;; Windconfig:

;;;###autoload
(defun windconfig-mode (&optional increment)
  "Resize windows interactively.
INCREMENT is the number of lines by which borders should move.

By default, the method for resizing is to move the borders.  The
left/right key will move the only movable vertical border to the
left/right and the up/down key will move the only horizontal
movable border up/down.  If there are two movable borders, move
the right or the bottom border.

Resizing can also be done by increasing/decreasing the window
width and height.  The up and down arrow keys will enlarge or
shrink the window vertically and the right and left arrow keys
will enlarge or shrink the window horizontally.

You can toggle between these two methods with \\[windconfig-toggle-method].

You can temporarily negate the number of lines by which the
windows are resized by using \\[windconfig-left-minus], \\[windconfig-right-minus], etc.
If you want to permanently negate this increment value,
use `\\[windconfig-negate-increment]' instead.

You can also save window configurations with `\\[windconfig-save-window-configuration]' in a ring,
and restore them with `\\[windconfig-restore-window-configuration]'.

Finally, you can either cancel the resizing with `\\[windconfig-cancel-and-quit]' or save it and
exit with `\\[windconfig-save-and-exit]'.

\\{windconfig-mode-map}"
  (interactive "P")
  ;; store previous major mode config
  (setq windconfig-previous-mode major-mode)
  (setq windconfig-overriding-terminal-local-map-0
	overriding-terminal-local-map)
  (setq windconfig-overriding-menu-flag-0
	overriding-local-map-menu-flag)
  (setq windconfig-window-configuration-0
	(current-window-configuration))
  ;; set increment, window configuration ring, initial buffer
  (setq windconfig-increment windconfig-default-increment)
  (setq windconfig-configuration-ring
	(make-ring windconfig-ring-size))
  (ring-insert windconfig-configuration-ring
	       (current-window-configuration))
  (setq windconfig-buffer (current-buffer))
  ;; set overriding map and pre/post-command hooks
  (setq overriding-terminal-local-map windconfig-mode-map)
  (setq overriding-local-map-menu-flag t)
  (windconfig-add-command-hooks)
  (setq mode-name "Windconfig")
  (force-mode-line-update)
  ;; set the initial message
  (setq windconfig-msg
	(if (one-window-p)
	    (setq windconfig-msg (cons "Split window with [23]" 2))
	  (setq windconfig-msg (cons "" 0))))
  (windconfig-message))

(defun windconfig-message (&optional message)
  "Display a message at the bottom of the screen.
If MESSAGE is nil, use `windconfig-msg' instead."
  (let* ((msg0 (or message windconfig-msg))
	 (msg-l (cdr msg0))
	 (msg (car msg0)))
    (cond ((< msg-l 2) ; information
	   (add-text-properties 0 (length msg) '(face bold) msg))
	  ((< msg-l 3) ; warnings
	   (add-text-properties 0 (length msg) '(face shadow) msg)))
    (message "Use arrow keys to %s  Increment:%-2d  RET:finish  ?:help  %s"
	     (if windconfig-move-borders "move borders " "resize window")
	     windconfig-increment
	     (if (< (cdr windconfig-msg) windconfig-verbose)
		 (car windconfig-msg) ""))))

(defun windconfig-add-command-hooks ()
  "Add hooks to commands when entering `windconfig-mode'."
  (add-hook 'pre-command-hook 'windconfig-pre-command)
  (add-hook 'post-command-hook 'windconfig-post-command))

(defun windconfig-remove-command-hooks ()
  "Remove hooks to commands when exiting `windconfig-mode'."
  (remove-hook 'pre-command-hook 'windconfig-pre-command)
  (remove-hook 'post-command-hook 'windconfig-post-command))

(defun windconfig-pre-command ()
  "Pre-command in `windconfig-mode'."
  (if (one-window-p)
      (setq windconfig-msg (cons "Command outside windconfig done" 2))
    (setq windconfig-msg (cons "" 0))))

(defun windconfig-post-command ()
  "Post-command in `windconfig-mode'."
  (windconfig-message))

(defun windconfig-toggle-method ()
  "Toggle resizing method."
  (interactive)
  (setq windconfig-move-borders
	(not windconfig-move-borders))
  (setq windconfig-msg
	(cons (format
	       "Method: %s"
	       (if (not windconfig-move-borders)
		   "resize window" "move borders")) 2)))

;;; Use windmove to select the adjacent window:

(defun windconfig-select-down (&optional arg)
  "Select the window below the current one.
If ARG is nil or zero, select the window relatively to the point
position.  If ARG is positive, select relatively to the left edge
and select relatively to the right edge otherwise."
  (interactive "P")
  (condition-case nil
      (windmove-down
       (or arg windconfig-windmove-relative-to-point))
    (error (setq windconfig-msg
		 (cons "[Can't select window below this one]" 1)))))

(defun windconfig-select-up (&optional arg)
  "Select the window above the current one.
If ARG is nil or zero, select the window relatively to the point
position.  If ARG is positive, select relatively to the left edge
and select relatively to the right edge otherwise."
  (interactive "P")
  (condition-case nil
      (windmove-up
       (or arg windconfig-windmove-relative-to-point))
    (error (setq windconfig-msg
		 (cons "[Can't select window above this one]" 1)))))

(defun windconfig-select-left (&optional arg)
  "Select the window to the left of the current one.
If ARG is nil or zero, select the window relatively to the point
position.  If ARG is positive, select relatively to the top edge
and select relatively to the bottom edge otherwise."
  (interactive "P")
  (condition-case nil
      (windmove-left
       (or arg windconfig-windmove-relative-to-point))
    (error (setq windconfig-msg
		 (cons "[Can't select window left this one]" 1)))))

(defun windconfig-select-right (&optional arg)
  "Select the window to the right of the current one.
If ARG is nil or zero, select the window relatively to the point
position.  If ARG is positive, select relatively to the top edge
and select relatively to the bottom edge otherwise."
  (interactive "P")
  (condition-case nil
      (windmove-right
       (or arg windconfig-windmove-relative-to-point))
    (error (setq windconfig-msg
		 (cons "[Can't select window right this one]" 1)))))

;;; Increase/decrease/set the increment value:

(defun windconfig-set-increment (&optional n)
  "Set the increment value to N."
  (interactive "p")
  (setq windconfig-increment n)
  (setq windconfig-msg (cons "Increment set" 2)))

(defun windconfig-negate-increment (&optional silent)
  "Negate the increment value.
If SILENT, dont output a message."
  (interactive)
  (setq windconfig-increment (- windconfig-increment))
  (unless silent (setq windconfig-msg (cons "Negated increment" 2))))

(defun windconfig-increase-increment (&optional silent)
  "Increase the increment.
If SILENT is non-nil, don't output a message."
  (interactive)
  (let ((i windconfig-increment))
    (if (eq i -1) (setq i (- i)) (setq i (1+ i)))
    (setq windconfig-increment i))
  (unless silent (setq windconfig-msg (cons "Increased increment" 2))))

(defun windconfig-decrease-increment (&optional silent)
  "Decrease the increment.
If SILENT is non-nil, don't output a message."
  (interactive "p")
  (let ((i windconfig-increment))
    (if (eq i 1) (setq i (- 1)) (setq i (1- i)))
    (setq windconfig-increment i))
  (unless silent (setq windconfig-msg (cons "Decreased increment" 2))))

;;; Window configuration ring:

(defun windconfig-save-window-configuration ()
  "Save the current window configuration in the ring."
  (interactive)
  (if (equal (ring-ref windconfig-configuration-ring 0)
	     (current-window-configuration))
      (setq windconfig-msg
	    (cons "[Same window configuration: not saved]" 1))
    (ring-insert windconfig-configuration-ring
		 (current-window-configuration))
    (setq windconfig-msg
	  (cons "Configuration saved -- use `r' to restore" 2))))

(defun windconfig-restore-window-configuration ()
  "Restore the previous window configuration in the ring."
  (interactive)
  (let ((wcf (ring-remove windconfig-configuration-ring 0)))
    (set-window-configuration wcf)
    (ring-insert-at-beginning windconfig-configuration-ring wcf))
  (setq windconfig-msg (cons "Previous configuration restored" 2)))

;;; Commands for arrow keys:

(defun windconfig-left (&optional n left-border fixed-width)
  "Main function for handling left commands.
N is the number of lines by which moving borders.
In the move-border method, move the right border to the left.
If LEFT-BORDER is non-nil, move the left border to the left.
In the resize-window method, shrink the window horizontally.

If FIXED-WIDTH is non-nil and both left and right borders are
movable, move the window to the left and preserve its width."
  (interactive "P")
  (let* ((left-w (windmove-find-other-window 'left))
	 (right-w (windmove-find-other-window 'right))
	 (i (if n (prefix-numeric-value n) windconfig-increment))
	 (shrink-ok (> (- (window-width) i) window-min-width))
	 (w (selected-window)))
    (if (not windconfig-move-borders)
	(if (not shrink-ok)
	    (setq windconfig-msg
		  (cons "[Can't shrink window horizontally]" 1))
	  (condition-case nil
	      (if shrink-ok (shrink-window-horizontally i)
		(error t))
	    (error (setq windconfig-msg
			 (cons "[Can't shrink window horizontally]" 1)))))
      (cond ((equal (frame-width) (window-width))
	     (setq windconfig-msg (cons "No vertical split" 2)))
	    ((and left-w right-w)
	     (if left-border
		 (progn (windmove-left windconfig-windmove-relative-to-point)
			(adjust-window-trailing-edge (selected-window) (- i) t)
			(select-window w)
			(if fixed-width (windconfig-left)))
	       (condition-case nil
		   (progn (adjust-window-trailing-edge w (- i) t)
			  (if fixed-width (windconfig-left nil t)))
		 (error (setq windconfig-msg
			      (cons "[Can't move right border left]" 1))))))
	    (left-w
	     (condition-case nil
		 (adjust-window-trailing-edge left-w (- i) t)
	       (error (setq windconfig-msg (cons "[Can't move left border left]" 1)))))
	    (right-w (windconfig-left-inwards))
	    (t (setq windconfig-msg (cons "[Can't move border]" 1)))))))

(defun windconfig-right (&optional n left-border fixed-width)
  "Main function for handling right commands.
N is the number of lines by which moving borders.
In the move-border method, move the right border to the right.
If LEFT-BORDER is non-nil, move the left border to the right.
In the resize-window method, enlarge the window horizontally.

If FIXED-WIDTH is non-nil and both left and right borders are
movable, move the window to the right and preserve its width."
  (interactive "P")
  (let ((right-w (windmove-find-other-window 'right))
	(left-w (windmove-find-other-window 'left))
	(i (if n (prefix-numeric-value n) windconfig-increment))
	(wcf (current-window-configuration))
	(w (selected-window)))
    (if (not windconfig-move-borders)
	(progn (ignore-errors (enlarge-window-horizontally i))
	       (if (equal wcf (current-window-configuration))
		   (setq windconfig-msg
			 (cons "[Can't enlarge window horizontally]" 1))))
      (cond ((equal (frame-width) (window-width))
	     (setq windconfig-msg (cons "No vertical split" 2)))
	    ((and right-w left-w left-border)
	     (progn (windmove-left windconfig-windmove-relative-to-point)
		    (adjust-window-trailing-edge left-w i t)
		    (select-window w)
		    (if fixed-width (windconfig-right))))
	    (right-w
	     (condition-case nil
		 (adjust-window-trailing-edge w i t)
	       (error (setq windconfig-msg
			    (cons "[Can't move right border right]" 1)))))
	    (left-w (windconfig-right-inwards))
	    (t (setq windconfig-msg (cons "[Can't move border]" 1)))))))

(defun windconfig-up (&optional n upper-border fixed-height)
  "Main function for handling up commands.
N is the number of lines by which moving borders.
In the move-border method, move the bottom border upwards.
If UPPER-BORDER is non-nil, move the upper border upwards.
In the resize-window method, enlarge the window vertically.

If FIXED-HEIGHT is non-nil and both the upper and lower borders
are movable, move the window up and preserve its height."
  (interactive "P")
  (let ((up-w (windmove-find-other-window 'up))
	(down-w (windmove-find-other-window 'down))
	(i (if n (prefix-numeric-value n) windconfig-increment))
	(wcf (current-window-configuration))
	(w (selected-window)))
    (if (not windconfig-move-borders)
	(progn (ignore-errors (enlarge-window i))
	       (if (equal wcf (current-window-configuration))
		   (setq windconfig-msg
			 (cons "[Can't enlarge window vertically]" 1))))
      (cond ((equal (frame-height) (1+ (window-height)))
	     (setq windconfig-msg (cons "No horizontal split" 2)))
	    ((and up-w down-w (not (window-minibuffer-p down-w)))
	     (if upper-border
		 (progn (windmove-up windconfig-windmove-relative-to-point)
			(adjust-window-trailing-edge (selected-window) (- i) nil)
			(select-window w)
			(if fixed-height (windconfig-up)))
	       (condition-case nil
		   (adjust-window-trailing-edge w (- i) nil)
		 (error
		  (setq windconfig-msg
			(cons "[Can't move bottom border up]" 1))))))
	    (up-w (condition-case nil
		      (adjust-window-trailing-edge up-w (- i) nil)
		    (error (setq windconfig-msg
				 (cons "[Can't move upper border up]" 1)))))
	    ((and down-w (not (window-minibuffer-p down-w)))
	     (windconfig-up-inwards))
	    (t (setq windconfig-msg (cons "[Can't move border]" 1)))))))

(defun windconfig-down (&optional n upper-border fixed-height)
  "Main function for handling down commands.
N is the number of lines by which moving borders.
In the move-border method, move the bottom border down.
If UPPER-BORDER is non-nil, move the upper border down.
In the resize-window method, shrink the window vertically.

If FIXED-HEIGHT is non-nil and both the upper and lower borders
are movable, move the window down and preserve its height."
  (interactive "P")
  (let* ((down-w (windmove-find-other-window 'down))
	 (up-w (windmove-find-other-window 'up))
	 (i (if n (prefix-numeric-value n) windconfig-increment))
	 (shrink-ok (> (- (window-width) i) window-min-width))
	 (wcf (current-window-configuration))
	 (w (selected-window)))
    (if (not windconfig-move-borders)
	(if (or (and (window-minibuffer-p down-w) (not up-w))
		(< (- (window-height) i) window-min-height))
	    (setq windconfig-msg (cons "[Can't shrink window vertically]" 1))
	  (if shrink-ok (shrink-window i)
	      (setq windconfig-msg (cons "[Can't shrink window vertically]" 1))))
      (cond ((equal (frame-height) (1+ (window-height)))
	     (setq windconfig-msg (cons "No horizontal split" 2)))
	    ((and up-w down-w (not (window-minibuffer-p down-w))
		  upper-border)
	     (progn (windmove-up windconfig-windmove-relative-to-point)
		    (adjust-window-trailing-edge (selected-window) i nil)
		    (select-window w)
		    (if fixed-height (windconfig-down))))
	    ((and down-w (not (window-minibuffer-p down-w)))
	     (condition-case nil
		 (adjust-window-trailing-edge w i nil)
	       (error (setq windconfig-msg (cons "[Can't move bottom border down]" 1)))))
	    (up-w (windconfig-down-inwards))
	    (t (setq windconfig-msg (cons "[Can't move border]" 1)))))))

;;; Moving the opposite border inwards:

(defun windconfig-left-inwards (&optional n)
  "Move the right border left by N lines."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n) windconfig-increment)))
    (condition-case nil
	(adjust-window-trailing-edge (selected-window) (- i) t)
      (error (setq windconfig-msg
		   (cons "[Can't move right border to the left]" 1))))))

(defun windconfig-right-inwards (&optional n)
  "Move the left border right by N lines."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n) windconfig-increment))
	(left-w (windmove-find-other-window 'left)))
    (condition-case nil
	(if left-w (adjust-window-trailing-edge left-w i t) (error t))
      (error (setq windconfig-msg
		   (cons "[Can't move left border right]" 1))))))

(defun windconfig-up-inwards (&optional n)
  "Move the bottom border up by N lines."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n) windconfig-increment))
	(down-w (windmove-find-other-window 'down)))
    (condition-case nil
	(progn (if (window-minibuffer-p down-w)
		   (setq windconfig-msg
			 (cons "[Can't move bottom border up]" 1)))
	       (adjust-window-trailing-edge
		(selected-window) (- i) nil))
      (error (setq windconfig-msg
		   (cons "[Can't move bottom border up]" 1))))))

(defun windconfig-down-inwards (&optional n)
  "Move the upper border down by N lines."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n) windconfig-increment))
	(wcf (current-window-configuration))
	(up-w (windmove-find-other-window 'up)))
    (condition-case nil
	(if up-w (adjust-window-trailing-edge up-w i nil)
	  (error t))
      (error (setq windconfig-msg
		   (cons "[Can't move upper border down]" 1))))))

;;; Arrow keys temoporarily negating the increment value:

(defun windconfig-down-minus ()
  "Same as `windconfig-left' but negate `windconfig-increment'."
  (interactive)
  (let ((i windconfig-increment))
    (windconfig-decrease-increment t)
    (windconfig-down)
    (windconfig-increase-increment t)))

(defun windconfig-right-minus ()
  "Same as `windconfig-left' but negate `windconfig-increment'."
  (interactive)
  (let ((i windconfig-increment))
    (windconfig-decrease-increment t)
    (windconfig-right)
    (windconfig-increase-increment t)))

(defun windconfig-up-minus ()
  "Same as `windconfig-left' but negate `windconfig-increment'."
  (interactive)
  (let ((i windconfig-increment))
    (windconfig-decrease-increment t)
    (windconfig-up)
    (windconfig-increase-increment t)))

(defun windconfig-left-minus ()
  "Same as `windconfig-left' but negate `windconfig-increment'."
  (interactive)
  (let ((i windconfig-increment))
    (windconfig-decrease-increment t)
    (windconfig-left)
    (windconfig-increase-increment t)))

;;; Let's left/up borders have priority over right/bottom borders:

(defun windconfig-left-force-left (&optional n)
  "If two movable borders, move the left border.
N is the number of lines by which moving borders."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n)
	     windconfig-increment)))
    (windconfig-left i t)))

(defun windconfig-right-force-left (&optional n)
  "If two movable borders, move the left border.
N is the number of lines by which moving borders."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n)
	     windconfig-increment)))
    (windconfig-right i t)))

(defun windconfig-up-force-up (n)
  "If two movable borders, move the upper border.
N is the number of lines by which moving borders."
  (interactive "P")
  (let ((i (if n (prefix-numeric-value n)
	     windconfig-increment)))
    (windconfig-up i t)))

(defun windconfig-down-force-up (n)
  "If two movable borders, move the upper border.
N is the number of lines by which moving borders."
  (interactive)
  (let ((i (if n (prefix-numeric-value n)
	     windconfig-increment)))
    (windconfig-down i t)))

;;; Move the whole window, with fixed width/height:

(defun windconfig-left-fixed ()
  "Move the window left, keeping its width constant."
  (interactive)
  (windconfig-left nil t t))

(defun windconfig-right-fixed ()
  "Move the window right, keeping its width constant."
  (interactive)
  (windconfig-right nil t t))

(defun windconfig-up-fixed ()
  "Move the window up, keeping its height constant."
  (interactive)
  (windconfig-up nil t t))

(defun windconfig-down-fixed ()
  "Move the window down, keeping its height constant."
  (interactive)
  (windconfig-down nil t t))

;;; Move edges:

(defun windconfig-bottom-right ()
  "Move the bottom-right edge of the window outwards."
  (interactive)
  (windconfig-right)
  (windconfig-down))

(defun windconfig-up-left ()
  "Move the upper-left edge of the window outwards."
  (interactive)
  (windconfig-left nil t)
  (windconfig-up nil t))

(defun windconfig-up-right ()
  "Move the upper-right edge of the window outwards."
  (interactive)
  (windconfig-right)
  (windconfig-up nil t))

(defun windconfig-bottom-left ()
  "Move the bottom-left edge of the window outwards."
  (interactive)
  (windconfig-left nil t)
  (windconfig-down))

;;; Cancel, exit and help:

(defun windconfig-cancel-and-quit ()
  "Cancel window resizing and quit `windconfig'."
  (interactive)
  (switch-to-buffer windconfig-buffer)
  (set-window-configuration windconfig-window-configuration-0)
  (setq overriding-local-map-menu-flag
	windconfig-overriding-terminal-local-map-0)
  (setq overriding-terminal-local-map
	windconfig-overriding-menu-flag-0)
  (funcall windconfig-previous-mode)
  (message "Window resizing quit (not saved)")
  (windconfig-remove-command-hooks))

(defun windconfig-exit ()
  "Keep this window configuration and exit `windconfig'."
  (interactive)
  (setq overriding-local-map-menu-flag
	windconfig-overriding-terminal-local-map-0)
  (setq overriding-terminal-local-map
	windconfig-overriding-menu-flag-0)
  (funcall windconfig-previous-mode)
  (message "Window configuration set")
  (windconfig-remove-command-hooks))

(defun windconfig-help ()
  "Show help for `windconfig'."
  (interactive)
  (let ((pop-up-frames nil) ; otherwise we exit the loop
	(temp-buffer-show-hook
	 '(lambda ()
	    (fit-window-to-buffer)
	    (shrink-window-if-larger-than-buffer)
	    (goto-char (point-min))
	    (save-excursion
	      (while (re-search-forward
		      "^[ M][^\n:]+:\\|[0123~=oq]:\\|RET:" nil t)
		(add-text-properties (match-beginning 0)
				     (match-end 0) '(face bold))))))
	(help
"Use the arrow keys to move a border into the arrow direction.
Right and bottom borders have priority over left and up borders.
Press SPC to toggle between moving borders and resizing windows,
where arrow keys mean shrink/enlarge.

Here is a list of default keybindings:

       SPC:  toggle method: move border, resize  RET:  set and exit
    arrows:  move border or resize windows         q:  cancel and quit
M-S-arrows:  select adjacent window                =:  balance windows
C-M-arrows:  move window with fixed width/height   o:  other-window
  C-arrows:  temporarilly negate INCREMENT         0:  delete current window
  M-arrows:  move with priority to left/up         ~:  negate INCREMENT
     C-`N':  set INCREMENT to N                    1:  delete other windows
       +/-:  increase/decrease INCREMENT           2:  split window vertically
         s:  save window configuration             3:  split window horizontally
         r:  restore window configuration          ?:  show this help window

See the docstring of `windconfig' for detailed description."))
    (with-output-to-temp-buffer "*Help*"
      (princ help))))

(provide 'windconfig)

;;; windconfig.el ends here
