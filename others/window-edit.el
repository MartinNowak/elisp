;;; window-edit.el --- edit windows interactively
;;
;; Copyright 2007 Bastien Guerry
;;
;; Author: Bastien Guerry <bzg AT altern DOT org>
;; Version: 0.9a
;; Keywords: window
;; URL: http://www.cognition.ens.fr/~guerry/u/window-edit.el
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
;; See `window-edit' docstring.
;;
;;; History:
;;
;; This was largely inspired by Hirose Yuuji and Bob Wiener original
;; `resize-window' as posted on the emacs-devel mailing list by Juanma.
;; This was also inspired by Lennart Borgman's bw-interactive.el. See
;; related discussions on the emacs-devel mailing list.  Special thanks
;; to Drew Adams for insightful and detailed comments.
;;
;; Also check http://www.emacswiki.org/cgi-bin/wiki/WindowResize for
;; general hints on window resizing.
;;
;; My main goal was to deal with window resizing in one single defun.
;;
;; Put this file into your load-path and the following into your
;;   ~/.emacs: (require 'window-edit)
;;
;;; Todo:
;; 
;; - use / to enlarge vertically and horizontally
;; - add numbers to the saved configurations
;;
;;; Code:

(eval-when-compile
  (require 'cl)
  (require 'windmove)
  (require 'ring))

(defun window-edit (&optional increment)
  "Edit windows interactively.
INCREMENT is the number of lines by which the window should be
resized.

By default, resizing is done by moving the window borders.  In
this mode, use the arrow keys to move the corresponding border in
the arrow direction -- e.g. the left arrow key will try to move
the left border to the left, thus enlarging the window.  If the
border cannot be moved into that direction, then `window-edit'
tries to move the opposite border to the same direction, hence
shrinking the window.

Resizing can also be done by increasing/decreasing window width
and height.  In this mode, use the up and down arrow keys to
enlarge or shrink the window and use the right and left arrow
keys to enlarge or shrink the window horizontally.

You can toggle between this two ways of editing windows with SPC.

The initial window configuration is saved in a ring.  You can
switch back to this configuration by pressing `r'.  You can add
more window configurations to this ring by pressing `s'.

  arrows:    resize window or move borders direction-wise
S-arrows:    same as above, with temporary negated INCREMENT
M-arrows:    next window in arrow direction
     SPC:    toggle resize-windows/move-borders mode
   C-`N':    set INCREMENT (`N' > 0)
     +/-:    increase/decrease INCREMENT
       ~:    negate INCREMENT
       s:    save window configuration
       r:    restore windows configuration
       0:    delete window
       1:    delete other windows
       2:    split window vertically
       3:    split window horizontally
       =:    balance windows
       o:    jump to other window
       ?:    show a help buffer
       q:    quit"
  (interactive "p")
  (unless increment (setq increment 1))
  (let* ((echo-keystrokes 0)
	 (window-configuration-ring (make-ring 10))
	 (window-edit-echo "")   ; `window-edit-echo' stores warnings and messages.
	 (timer (run-at-time     ; This timer resets the value of `window-edit-echo'.
		 nil 2           ; This timer gets canceled when window editing is done.
		 '(lambda () (setq window-edit-echo ""))))
	 (move-borders-p t) 
	 edit-mode echo)
    
    ;; Insert the initial window configuration in a ring.
    (ring-insert window-configuration-ring 
		 (current-window-configuration))
    ;; Start the main loop
    (catch 'done
      (while t
	;; set the name of the current mode
	(setq edit-mode (if move-borders-p " move borders" "resize window"))
	;; set and display the echo-area
	(add-text-properties 0 (length window-edit-echo)
			     '(face org-warning) window-edit-echo)
	(setq echo (format "(S-)Arrows: %s by %d lines  [? for help]  %s"
			   edit-mode increment window-edit-echo))
	(message echo)
	(ignore-errors
	  (let* ((wcf (current-window-configuration))
		 (w (selected-window))
		 window-size-fixed inc
		 (e (read-event)))
	    (case e
	      
	      ;; shrink window horizontally or move left border to the left
	      ((left S-left)
	       (let* ((inc (if (eq e 'S-left) (- increment) increment))
		      (left-w (windmove-find-other-window 'left))
		      (shrink-ok (> (- (window-width) inc) window-min-width)))
		 (if (and (not move-borders-p) shrink-ok)
		     (condition-case nil
			 (shrink-window-horizontally inc)
		       (error (setq window-edit-echo "[can't shrink horizontally]")))
		   (or (not (condition-case nil
				(adjust-window-trailing-edge left-w (- inc) t)
			      (error t)))
		       (not (condition-case nil
				(adjust-window-trailing-edge w (- inc) t)
			      (error t)))
		       (setq window-edit-echo "[can't move border left]")))))
	      
	      ;; Enlarge window horizontally or move right border to the right
	      ((right S-right)
	       (let ((inc (if (eq e 'S-right) (- increment) increment))
		     (right-w (windmove-find-other-window 'right))
		     (left-w (windmove-find-other-window 'left)))
		 (if (and (not move-borders-p)
			  (> (- (window-width right-w) inc) window-min-width))
		     (condition-case nil
			 (enlarge-window-horizontally inc)
		       (error (setq window-edit-echo "[can't enlarge horizontally]")))
		   (or (not (condition-case nil
				(adjust-window-trailing-edge w inc t)
			      (error t)))
		       (not (condition-case nil
				(adjust-window-trailing-edge right-w (- inc) t)
			      (error t)))
		       (not (condition-case nil
				(adjust-window-trailing-edge left-w inc t)
			      (error t)))
		       (setq window-edit-echo "[can't move border right]")))))

	      ;; enlarge window vertically or move upper border up
	      ((up S-up)
	       (let ((inc (if (eq e 'S-up) (- increment) increment))
		     (up-w (windmove-find-other-window 'up))
		     (down-w (windmove-find-other-window 'down)))
		 (if (and (not move-borders-p)
			  (> (- (window-height up-w) inc) window-min-height))
		     (progn (enlarge-window inc)
			    (when (equal wcf (current-window-configuration)) 
			      (setq window-edit-echo "[can't enlarge]")))
		   (or (and (one-window-p)
			    (setq window-edit-echo "[can't move border up]"))
		       (not (condition-case nil
				(adjust-window-trailing-edge up-w (- inc) nil)
			      (error t)))
		       (not (condition-case nil
				(progn (if (window-minibuffer-p down-w) (error t))
				       (adjust-window-trailing-edge w (- inc) nil))
			      (error t)))
		       (setq window-edit-echo "[can't move border up]")))))

	      ;; shrink window vertically or move bottom border down
	      ((down S-down)
	       (let ((inc (if (eq e 'S-down) (- increment) increment))
		     (down-w (windmove-find-other-window 'down))
		     (up-w (windmove-find-other-window 'up)))
		 (if (not move-borders-p)
		     (if (and (window-minibuffer-p down-w) (not up-w)
			      (> (- (window-height) inc) window-min-height))
			 (setq window-edit-echo "[can't shrink]")
		       (progn (shrink-window inc)
			      (when (equal wcf (current-window-configuration)) 
				(setq window-edit-echo "[can't shrink]"))))
		   (or (not (condition-case nil
				(adjust-window-trailing-edge w inc nil)
			      (error t)))
		       (not (condition-case nil
				(adjust-window-trailing-edge down-w (- inc) nil)
			      (error t)))
		       (not (condition-case nil
				(adjust-window-trailing-edge up-w inc nil)
			      (error t)))
		       (setq window-edit-echo "[can't move border down]")))))
	      
	      ;; toggle resize-window/move-borders and warn if only one window
	      (?  (if (one-window-p) (setq window-edit-echo "[Note: only one window]"))
		  (setq move-borders-p (null move-borders-p)))
	      
	      ;; Move the point
	      ((?\^a ?a) (move-beginning-of-line 1))
	      ((?\^e ?e) (move-end-of-line 1))
	      ((?\^f ?f) (forward-char))
	      ((?\^b ?b) (backward-char))
	      ((?\^n ?n) (next-line))
	      ((?\^p ?p) (previous-line))
	      
	      ;; Split/delete/move/balance windows
	      (?0 (condition-case nil 
		      (progn (delete-window)
			     (setq window-edit-echo "[window deleted]"))
		    (error (setq window-edit-echo "[Can't delete sole window]"))))
	      (?1 (delete-other-windows) 
		  (if (equal wcf (current-window-configuration))
		      (setq window-edit-echo "[No other window]")
		    (setq window-edit-echo "[Other windows deleted]")))
	      (?2 (split-window) (setq window-edit-echo "[window vertically split]"))
	      (?3 (split-window-horizontally)
		  (setq window-edit-echo "[window horizontally split]"))
	      (?o (other-window 1) (setq window-edit-echo 
					 (format "[Now in: %s]" 
						 (buffer-name (window-buffer)))))
	      (?= (balance-windows) (setq window-edit-echo "[windows balanced]"))
	      
	      ;; Store and restore window configuration
	      (?s (if (equal (ring-ref window-configuration-ring 0) wcf)
		      (setq window-edit-echo "[same window configuration: not saved]")
		    (ring-insert window-configuration-ring wcf)
		    (setq window-edit-echo "[configuration saved -- `r' to restore]")))
	      
	      (?r (let ((wcf0 (ring-remove window-configuration-ring 0)))
		    (set-window-configuration wcf0)
		    (ring-insert-at-beginning window-configuration-ring wcf0))
		  (setq window-edit-echo "[configuration restored]"))

	      ;; Move point to other windows
	      ((M-left M-right M-down M-up)
	       (let* ((direction (substring (symbol-name e) 2))
		      (dir-w (windmove-find-other-window (intern direction))))
		 (if (and dir-w (not (window-minibuffer-p dir-w)))
		     (progn (funcall (intern (concat "windmove-" direction)))
			    (setq window-edit-echo 
				  (format "[Now in: %s]" 
					  (buffer-name (window-buffer)))))
		   (setq window-edit-echo (format "[No window %s]" direction)))))
	      
	      ;; Negate/increase/decrease/set increment
	      (?~ (setq increment (- increment)))
	      (?+ (if (eq increment -1)
		      (setq increment (- increment))
		    (setq increment (1+ increment))))
	      (?- (if (eq increment 1)
		      (setq increment (- increment))
		    (setq increment (1- increment))))
	      
	      ;; Set INCREMENT with C-`N', `N' > 0
	      ((?\^1 ?\^2 ?\^3 ?\^4 ?\^5 ?\^6 ?\^7 ?\^8 ?\^9)
	       (setq inc (memq e '(?\^1 ?\^2 ?\^3 ?\^4 ?\^5 ?\^6 ?\^7 ?\^8 ?\^9)))
	       ;; `N' is computed from the position of the keystroke in
	       ;; the list of possible C-`N' keystrokes
	       (setq increment (- 10 (length inc))))

	      ;; quit
	      (?\^G (progn (cancel-timer timer) (keyboard-quit)))
	      (?q (progn (cancel-timer timer) (throw 'done t)))

	      ;; display a help window
	      ((?h ??)
	       (let ((temp-buffer-show-hook
		      '(lambda ()
			 (fit-window-to-buffer)
			 (shrink-window-if-larger-than-buffer)
			 (goto-char (point-min))
			 (save-excursion
			   (while (re-search-forward 
				   "^[^\n:]+:\\|[0123~=oq]:" nil t)
			     (add-text-properties (match-beginning 0)
						  (match-end 0) '(face bold))))))
		     (help "Use the arrow keys to resize the current window.

Press SPC to toggle between the resize-window mode (where the
arrow keys increase/decrease the height/width of the window) and
the move-borders mode (where arrow keys move their corresponding
borders in arrow's direction).

By default, resizing moves are done by 1 line.  You can change
set INCREMENT directly with C-`N' (`N' > 0) or by using +/-.

     SPC:  toggle mode: move border, resize        =:  balance windows
  arrows:  resize windows or move border           o:  other-window
S-arrows:  same as above with negative INCREMENT   ~:  negate INCREMENT
M-arrows:  select adjacent window                  0:  delete current window
   C-`N':  set INCREMENT to number `N'             1:  delete other windows
     +/-:  increase/decrease INCREMENT             2:  split window vertically
       s:  save window configuration               3:  split window horizontally
       r:  restore window configuration            q:  quit
       ?:  show this help buffer

C-a, C-e, C-f, C-b, C-n, C-p:  move cursor"))
		 (with-output-to-temp-buffer "*Help*"
		   (princ help))
		 (if pop-up-frames (throw 'done t))))
	      (t (when (and (listp e) (eq (car e) 'down-mouse-1))
		   (select-window (caadr e))))))))))
  (message "Window editing done"))

(provide 'window-edit)


;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################


;;; window-edit.el ends here
