;;; mouse-focus.el --- Focus follows mouse in Emacs windows
;; $Id: $
;; Copyright (C) 2003 by Stefan Kamphausen
;; Author: Stefan Kamphausen <mail@skamphausen.de>
;; Keywords: mouse, gui
;; This file is not part of XEmacs.

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING. If not, write to the Free
;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;; 02111-1307, USA.


;;; Commentary:
;; Common window managers in Un*x usually implement several focus
;; policies. Besides the common but awfull (IMHO) click-to-focus there
;; is also a focus follows mouse mode which means that the window
;; under the mouse pointer receives the keyboard presses.
;;
;; A friend of mine wanted this for (X)Emacs, too and so here it is. I
;; don't use it, though, because I stick with the keys when inside
;; XEmacs. 
;;
;; Installation
;; Put into your init file (~/.emacs or ~/.xemacs/init.el):
;; (require 'mouse-focus)
;; (turn-on-mouse-focus)
;;
;; Bugs:
;; Doesn't work in GNU Emacs and since I have no knowledge about it's
;; mouse handling system I probably won't adress this problem (even
;; more since I don't use this package myself)

;;; Code:

(defvar mouse-focus-activep nil
  "Used internally to store that status of mouse focus mode.")

(defvar mouse-focus-original-mouse-motion-handler
  "Used internally to store the original mouse motion handler.
This is called after the mouse focus functions.")

(defun mouse-focus (event)
  "Implement a focus follows mouse behaviour.
This is common to window managers but hasn't been available in Emacs
before as far as I know."
  (and (event-window event)
  (select-window (event-window event))))

(defun mouse-focus-mouse-motion-handler (event)
  "Call `mouse-focus' before calling the original motion handler." 
  (mouse-focus event)
  (funcall mouse-focus-original-mouse-motion-handler event))

(defun mouse-focus-install-handler ()
  "Install mouse focus.
Don't use this explicitely, use `turn-on-mouse-focus' instead."
  (setq mouse-focus-original-mouse-motion-handler mouse-motion-handler)
  (setq mouse-motion-handler
		#'mouse-focus-mouse-motion-handler))

(defun mouse-focus-remove-handler ()
    "Deinstall mouse focus.
Don't use this explicitely, use `turn-off-mouse-focus' instead."
  (setq mouse-motion-handler
		#'mouse-focus-original-mouse-motion-handler))

;;###autoload
(defun turn-on-mouse-focus ()
  "Turn on the focus follows mouse mode."
  (interactive)
  (unless mouse-focus-activep
	(mouse-focus-install-handler)
	(setq mouse-focus-activep t)))

;;###autoload
(defun turn-off-mouse-focus ()
  "Turn off the focus follows mouse mode."
  (interactive)
  (when mouse-focus-activep
	(mouse-focus-remove-handler)
	(setq mouse-focus-activep nil)))

(provide 'mouse-focus)

;;; mouse-focus.el ends here