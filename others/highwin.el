;;; highwin.el --- highlight the active window.

;; Copyright (c) 2006 Martin Blais

;; Author: Martin Blais <blais@furius.ca>
;; Created: 2006-09-19
;; Version: 0.1
;; Keywords: windows, faces

;; This file is not yet part of any Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this program; if not, write to the Free Software Foundation, Inc.,
;; 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


;;; Commentary:

;; Code used to highlight which is the active window.
;;
;; This defines a function that can be bound to your favourite command for
;; switching windows::

;;   (defadvice other-window (after highwin-advice activate)
;;     (highwin-advice))
;;



;;; Code:

(defface highwin-face
  '((t (:background 
	;;"#f0f0f0"
	"#c0f0c0"
	)))
    "Face used to highlight current line.")

(defvar highwin-nblines 10
  "Number of lines for overlay.")

(defvar highwin-timeout 0.5
  "Time interval to display the highlight for.")

(defvar highwin-overlay
  ;; Dummy initialization
  (make-overlay 1 1)
  "Overlay for highlighting.")

;; Set face-property of overlay
(overlay-put highwin-overlay 'face 'highwin-face)

(defun highwin-advice ()
  (let ((h (/ highwin-nblines 2))
	(buf (current-buffer)))

    (overlay-put highwin-overlay 'window (selected-window))
    (move-overlay highwin-overlay
		  (line-beginning-position (1+ (- h)))
		  (line-beginning-position (+ h 2))
		  buf)

    (if highwin-timeout
	(with-timeout (highwin-timeout)
	  (highwin-unbearably-lightly-levitate))
      (highwin-unbearably-lightly-levitate))
      
    ;; Disable the overlay.
    (move-overlay highwin-overlay (point-min) (point-min) (current-buffer))
    ))

;; Note: this is a rather generic function that could be moved somewhere else.
(defun highwin-unbearably-lightly-levitate (&optional exit-char message)
  "Momentarily wait until a key stroke is pressed.
The pressed key is not consumed and will be acted upon as usual.
This is used to do something after the next key is pressed.
Imagine that you're levitating in a Tibetan buddhist temple and
that you're waiting for the other shoe to drop.  This was
inspired by the implementation of momentary-string-display."
  (let ((inhibit-read-only t)
	;; Don't modify the undo list at all.
	(buffer-undo-list t)
	)
    (unwind-protect
	(let (char)
	  (when exit-char
	    (message (or message "Type %s to continue editing.")
		     (single-key-description exit-char)))
	  (if (integerp exit-char)
	      (condition-case nil
		  (progn
		    (setq char (read-char))
		    (or (eq char exit-char)
			(setq unread-command-events (list char))))
		(error
		 ;; `exit-char' is a character, hence it differs
		 ;; from char, which is an event.
		 (setq unread-command-events (list char))))

	    ;; `exit-char' can be an event, or an event description
	    ;; list.
	    (setq char (read-event))
	    (or (eq char exit-char)
		(eq char (event-convert-list exit-char))
		(setq unread-command-events (list char)))))
      ))
  nil)

(provide 'highwin)



;; One more: essaie `delete-overlay' pour "disable the overlay".
;; Le différence est importante si ton overlay a un `after-string' ou
;; `before-string' ou `display'.


;; `delete-overlay' ne le détruit pas.  Tu peux le `move-overlay' par la suite
;; sans aucun problème.

;; > One more: je comprend pas le condition-case du char/exit-char.
;; > Tu fais (setq unread-command-events (list char)) quand il y a une erreur,
;; > mais la seule opération qui peut signaler une erreur est `read-char', donc
;; > s'il y a erreur, `char' est nil parce qu'il n'a pas encore été affecté.
;; >
;; > À ta place, j'oublierais le `exit-char' et j'utiliserais `sit-for' au lieu
;; > de highwin-unbearably-lightly-levitate.

