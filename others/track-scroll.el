;;; track-scroll.el --- Enable direct scrolling with the mouse
;; $Id: track-scroll.el,v 1.3 2005/02/08 22:08:46 ska Exp $
;; Copyright (C) 2003 by Stefan Kamphausen
;; Author:
;;           Stefan Kamphausen <mail@skamphausen.de>
;; Keywords: mouse, gui, user

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

;; TrackScroll on the Web:
;; Main page:
;; http://www.skamphausen.de/software/skamacs/track-scroll.html
;; German intro:
;; http://www.skamphausen.de/xemacs/lisp/track-scroll.html

;; GNU Emacs comes with mouse-drag.el which implements a feature I've
;; been wanting for years but doesn't work with XEmacs. *grr*
;; Loading this file enables the dragging of the window using the
;; middle mouse button. Holding the control key at the same time calls
;; a different function which behaves more like the scrollbar does.
;; It's probably best to just try it yourself and see what happens.
;; This abandons drag and drop functionality which is usually called
;; when dragging the middle mouse button

;; After Garret came up with a third function introducing a third kind
;; of behaviour I at least got rid of the hardcoded keys.
;; Nevertheless, I'd much prefer _one_ backend function (which would
;; probably be a mixture of track-scroll-drag-scalable and
;; track-scroll-fullwin) with a smart scaling factor function which
;; would reflect the three scrolling mechanisms.

;; Problems:
;; - horizontal scrolling
;; - customizable sensitivities for both directions?
;; - what about info (and others?) that override the mouse-track
;;   setting for their buffers? I really hate info for that.

;;; Code:
(require 'mouse)
;; The control modifier is currently hard coded :-(
;; UPDATE: no it isn't anymore after the arrival of track-scroll-alist
;(global-set-key '[(control button2)] 'mouse-track)

(defgroup track-scroll nil
  "Scrolling buffers with the mouse but without the scrollbars."
  :tag "TrackScroll"
  :link '(url-link :tag "Home Page"
                   "http://www.skamphausen.de/software/skamacs/")
  :link '(emacs-commentary-link
          :tag "Commentary in track-scroll.el" "track-scroll.el")
  :prefix "track-scroll-"
  :group 'environment
  :group 'mouse)

(defcustom track-scroll-drag-handlers-alist
  '(([(button2)] . track-scroll-drag)
    ([(control button2)] . track-scroll-fullwin)
    ([(shift control button2)] . track-scroll-drag-scalable))
  "An alist of modifiers and the function to call.
The modifiers are given in the format returned by `event-modifiers'."
  :type '(repeat
          (cons (vector :tag "event modifiers" sexp)
                (function :tag "scrolling function")))
  :group 'track-scroll)

(defcustom track-scroll-drag-scalable-factor 0.5
  "The scaling factor for `track-scroll-drag-scalable'.
See that function for a description."
  :type 'number
  :group 'track-scroll)

(defcustom track-scroll-drag-scalable-print nil
  "Controls whether to print the new line number in the echo area.
This is only done for `track-scroll-drag-scalable'."
  :type 'boolean
  :group 'track-scroll)

;; Remove default handler and install our own version which handles
;; mouse button2 different
(remove-hook 'mouse-track-drag-hook
             'default-mouse-track-drag-hook)
(add-hook 'mouse-track-drag-hook
             'track-scroll-mouse-track-drag-hook)

;; The replacement for default-mouse-track-drag-hook
(defun track-scroll-mouse-track-drag-hook (event click-count was-timeout)
  "A mouse dragging handler that enables scrolling the window.
This is just a slightly modified copy of
`default-mouse-track-drag-hook'. which calls a drag and drop routine
when dragging with button2."
  (cond ((default-mouse-track-event-is-with-button event 1)
     (default-mouse-track-deal-with-down-event click-count)
     (default-mouse-track-set-point event default-mouse-track-window)
     (default-mouse-track-cleanup-extent)
     (default-mouse-track-next-move default-mouse-track-min-anchor
       default-mouse-track-max-anchor
       default-mouse-track-extent)
     t)
    ((default-mouse-track-event-is-with-button event 2)
     (track-scroll event))))


;; This is needed to recognize whether the dragging has just started
;; (otherwise I missed something)
(add-hook 'mouse-track-up-hook
          'track-scroll-finalize)

(defun track-scroll-finalize (event click-count)
  (setq track-scroll-new t))

;; Some variables for keeping the state
(defvar track-scroll-new t)
(defvar track-scroll-start-point nil)
(defvar track-scroll-start-ypos nil)
(defvar track-scroll-start-col nil)
(defvar track-scroll-event-window nil)

;; the main function called from the mouse-track function
(defun track-scroll (event)
  "Calls one of the different drag handlers.
The handlers are defined in `track-scroll-drag-handlers-alist'."
  (funcall
   (cdr (assoc (vector (event-modifiers event))
               track-scroll-drag-handlers-alist))
    event))

(defun track-scroll-fullwin (event)
  "Scroll the window taking it's height as 100%.
This has the sideffect that when you start dragging the mouse
the window is scrolled to the approriate percentage of that starting
position before the fluent scrolling starts. This can be confusing but
is nice for quick movements."
  (when track-scroll-new
    (setq track-scroll-new nil)
    (setq track-scroll-event-window (event-window event))
    (select-window track-scroll-event-window)
    (setq track-scroll-start-col (current-column)))
  (when (eq (event-window event) track-scroll-event-window)
    (let* ((pos (event-window-y-pixel event))
           (perc (* 100 (/ (float pos)
                           (window-pixel-height))))
           (newpoint (floor
                      (+ (point-min)
                         (/ (* perc (- (point-max) (point-min)))
                            100))))
           (window (event-window event)))
      (goto-char newpoint (window-buffer window))
      (beginning-of-line)
      (move-to-column (if (> (point-at-eol
                              track-scroll-start-col))
                          track-scroll-start-col
                        0))
      (recenter (/ (window-height) 2) window))))


(defun track-scroll-drag (event)
  "Drag the window's contents.
This means actually grabbing a character and moving it around a
little. That also means that you can only scroll a part according to
your window size.

It behaves very similar to GNU Emacs `mouse-drag-drag'."
  (when track-scroll-new
    (setq track-scroll-new nil)
    (setq track-scroll-event-window (event-window event))
    (select-window track-scroll-event-window)
    (setq track-scroll-start-point (event-closest-point event)))
  (when (eq (event-window event) track-scroll-event-window)
    (let* ((currpoint (event-closest-point event)))
      (if currpoint
          (let* ((oldline (line-number track-scroll-start-point))
                 (newline (line-number currpoint))
                 (linediff (- newline oldline))
                 (window (event-window event)))
            (condition-case nil
                (progn
                  (scroll-down linediff))
              (error nil)))))))


;; These functions were mainly written by Garret Jones and adapted for
;; track-scroll.el by Stefan
(defun track-scroll-point-at-bol-number (line)
  (save-excursion
    (goto-line line)
    (point)))

(defun track-scroll-drag-scalable (event)
  "Drag the window's contents with a customizable speed.
This takes the pixel distance between the starting point of the
dragging and the current position, scales it using
`track-scroll-drag-scalable-factor' and translates that to a new
linenumber to be used as the top of the window.
The linenumber will be printed to the echo area when
`track-scroll-drag-scalable-print' is t."

  (when track-scroll-new
      (progn
        (setq track-scroll-new nil)
        (setq track-scroll-event-window (event-window event))
        (select-window track-scroll-event-window)
        (setq track-scroll-start-line
              (line-number (window-start)))
        (setq track-scroll-start-ypos (cddr (mouse-pixel-position)))))

  (when (eq (event-window event) track-scroll-event-window)
    (let* ((yposdiff
            (- track-scroll-start-ypos
               (cddr (mouse-pixel-position))))
           (newtopline
            (- track-scroll-start-line
               (floor (* track-scroll-drag-scalable-factor
                         yposdiff))))
             (window (event-window event)))
      (condition-case nil
          (progn
            (when track-scroll-drag-scalable-print
              (message
               (concat "line " (number-to-string newtopline))))
            (set-window-start
             window (track-scroll-point-at-bol-number newtopline)))
          (error nil)))))
;; end of Garrets functions

;; This version _tries_ to do horizontal scrolling, but it's not
;; really working well
;; If you intent to fix this you'll probably know how to enable it as
;; well... 
(defun track-scroll-drag-h (event)
  "Same as `track-scroll-drag' but tries to do some horizontal
  scrolling which isn't really working well."
  (if track-scroll-new
      (progn
        (setq track-scroll-new nil)
        (setq track-scroll-event-window (event-window event))
        (select-window track-scroll-event-window)
        (setq track-scroll-start-point (event-closest-point event))
        (setq track-scroll-start-col
              (save-excursion
                (goto-char track-scroll-start-point)
                (current-column)))
        ))
  (if (eq (event-window event) track-scroll-event-window)
      (let* ((currpoint (event-closest-point event)))
        (if currpoint
            (let* ((oldline (line-number track-scroll-start-point))
                   (newline (line-number currpoint))
                   (linediff (- newline oldline))
                   (oldcol track-scroll-start-col)
                   (newcol (save-excursion
                             (goto-char currpoint)
                             (current-column)))
                   (coldiff (- newcol oldcol))
                   (window (event-window event)))
              (condition-case nil
                  (progn
                    (scroll-down linediff)
                    ;; FIXME: sensitivity customizable
                    (cond
                     ((< coldiff -1)
                      (scroll-right coldiff))
                     ((> coldiff 1)
                      (scroll-left (- 0 coldiff)))
                     t nil
                     ))
                (error nil)))))))


;; before we finish set all keybindings from the customized variable
(mapcar #'(lambda (item)
            (define-key global-map
              (car item)
             'mouse-track))
        track-scroll-drag-handlers-alist)

(provide 'track-scroll)