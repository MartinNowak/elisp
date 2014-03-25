;;; show-help-tty.el --- echo help text when possible on tty displays

;; Copyright (C) 2009, 2010  Dave Love

;; Author: Dave Love <fx@gnu.org>
;; Keywords: extensions, help
;; $Revision: 5 $
;; X-URL: http://www.loveshack.ukfsn.org/emacs/show-help-tty.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Do our best to use `help-echo' text on ttys.  All we can do to
;; correspond as closely as possible to hovering on graphical displays
;; is to use `post-command-hook' and check under point when
;; appropriate.  This is a global mode:  there doesn't seem much point
;; in making it buffer-local.
;;
;; We set `post-command-hook' unconditionally to allow supporting both
;; graphic and tty frames in an Emacs 23 session.  Perhaps it would be
;; better to set it frame-locally in existing tty frames and on
;; creation of new ones via `before-make-frame-hook'.

;;; Code:

(require 'tooltip)

;;;###autoload
(define-minor-mode show-help-tty-mode
  "Toggle Show Help TTY global minor mode.
This enables help text for active areas in buffers to be displayed
on a tty (non-graphic display).  The behaviour is somewhat similar to
that  when `tooltip-mode' is disabled on a graphic display.

After every command, a check is made for a `help-echo' property
on the text at point, and if it is a string, it is shown in the
echo area.  This is not done on a graphic display (on which the
normal tooltip functions are available) or if the last command
was in `show-help-tty-ignored-motion-commands'.  See also Info
node `(emacs)Tooltips'."
  :init-value nil
  (if show-help-tty-mode
      (progn
	(add-hook 'pre-command-hook 'show-help-tty-pre)
	;; We probably want this to come last in the hook functions if
	;; possible, since other hooks could affect the message area.
	(add-hook 'post-command-hook 'show-help-tty 'append))
    (remove-hook 'pre-command-hook 'show-help-tty-pre)
    (remove-hook 'post-command-hook 'show-help-tty)))

(defvar show-help-tty-ignored-motion-commands
  '(widget-forward widget-backward forward-button backward-button
    help-next-ref help-previous-ref)
  "List of commands assumed to print help themselves.
They do the equivalent of `show-help-tty' when they land on a
widget or button with a `help-echo' property.")

(defvar show-help-tty-pre-text nil
  "Records echo area text before a command.
Checked by `show-help-tty'.")

(defun show-help-tty ()
  "Display `help-echo' text at point, if appropriate.
Do so only when display is non-graphic and the current command
isn't in `show-help-tty-ignored-motion-commands'."
  (unless (or (display-graphic-p)
	      (memq this-command '(widget-forward widget-backward
				   forward-button backward-button
				   help-next-ref help-previous-ref)))
    (let ((help (get-char-property (point) 'help-echo)))
      (when (and (stringp help)
		 ;; Check whether the command echoed anything (new),
		 ;; and don't over-write it if so.  Fixme:  Does this
		 ;; always DTRT when switching frames?
		 (equal show-help-tty-pre-text (current-message)))
	(condition-case nil
	    (tooltip-show help t)      ; Emacs 22+ has second arg
	  (error (message "%s" help))) ; All Emacs 21's single-arg
				       ; tooltip-show would do
	(setq show-help-tty-pre-text)))))

(defun show-help-tty-pre ()
  "Added to `pre-command-hook' to record echo area contents."
  (setq show-help-tty-pre-text (current-message)))

(provide 'show-help-tty)
;;; show-help-tty.el ends here
