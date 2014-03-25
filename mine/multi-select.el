;;; multi-select.el --- Provides multiple noncontiguous selections.

;; This file is NOT part of Emacs.

;; Copyright (C) 2005, Steve Yegge <steve.yegge at gmail dot com>
;; Parts Copyright (C) Lawrence Mitchell <wence@gmx.li>
;; Filename: multi-select.el
;; Version: 0.9 (pending XEmacs support for version 1.0)
;; Author: Steve Yegge <stevey at gmail dot com>
;; Created: April 10th 2005

;; COPYRIGHT NOTICE

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.
;; http://www.gnu.org/copyleft/gpl.html
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs. If you did not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave., Cambridge, MA 02139, USA.

;; Commentary:
;;
;; Multi-select provides functionality similar to that of multi-region.el
;; and the mouse-secondary functions in mouse.el.  You can make multiple,
;; noncontiguous selections using either the mouse or keyboard commands.
;; You can also make selections by specifying a regular expression to
;; highlight, either programatically or interactively.
;;
;; Multi-selections are independent of the normal Emacs region and the
;; mouse-secondary selection.  However, this package offers several nice
;; utilities for handling the multi-selections like normal regions.

;; Installation:
;;
;; Copy multi-select.el into your Emacs load-path.  Then put the following
;; line somewhere in your .emacs file:
;;
;; (autoload 'multi-select-mode "multi-select" nil t)
;;
;; Typing M-x multi-select-mode will turn the feature on and off.
;; If you want multi-select turned on when you start Emacs, add this line
;; after the autoload line above:
;;
;; (multi-select-mode t)
;;
;; The mouse behavior is easier to use than explain, so you may want
;; to just turn the mode on and start experimenting.  Each command has
;; some documentation viewable with M-x describe-function [command].

;; Usage:  (with default mouse bindings)
;;
;;  C-M-mouse-1 single-click:  starts a new multi-selection at the click
;;                             (deselects any multi-selection there first)
;;  C-M-mouse-1 double-click:  select current word
;;  C-M-mouse-1 triple-click:  select current line
;;  C-M-mouse-1 quadruple-click:  select current defun
;;                                (or paragraph in text-/fundamental-mode)
;;  C-M-mouse-1 drag:  multi-select-track-mouse-drag
;;  C-M-mouse-3 single click:  multi-select-extend-selection
;;
;; Other available commands:
;;
;;  M-w:  multi-select-kill-ring-save
;;    If any multi-selections are active in the buffer, copies them to
;;    both the kill-ring and the window-system clipboard.  With a prefix
;;    arg (i.e. C-u <any number> before invoking the command), it will
;;    prompt you for a delimiter string to insert between the selections.
;;    The selections are concatenated to become a single kill-ring item.
;;
;;  C-M-m r:  multi-select-mark-by-regexp
;;    A powerful command that lets you specify multi-selections using a
;;    regular expression.  You can instruct it to highlight the entire
;;    match-string, a specific sub-group, or each individual sub-group.
;;
;;  C-M-m a:  multi-select-mark-region
;;  C-M-m d:  multi-select-unmark-region
;;  C-M-m e:  multi-select-eval-on-selections (eval expr on each selection)
;;  C-M-m g:  multi-select-cancel-all (analogous to C-g for normal region)
;;  C-M-m k:  multi-select-kill-selections (like M-w but deletes the text)
;;  C-M-m x:  multi-select-execute-command (call command on each selection)
;;  C-M-m w:  multi-select-wrap-selections (add prefix/suffix to selections)
;;  C-M-m m:  multi-select-toggle-auto-merge
;;  C-M-m q:  quit multi-select mode

;; Examples:
;;
;; C-u -1 C-M-m r <pre>\(\w+\).+\s-+\(.+\)</pre>
;;  - selects first and last word of the contents every <pre> tag
;;    (provided the contents don't span multiple lines)
;;
;; C-M-m x M-x upcase-region
;;  - converts all multi-selections in buffer to uppercase
;;
;; C-u M-w C-q C-j --- C-q C-j <RET>
;;  - saves all multi-selections to kill-ring as a single item,
;;    with selections separated by "---" on a line by itself
;;
;; C-u C-M-m w foo <RET> bar <RET>
;;  - prepends "foo" and appends "bar" to every multi-selection

;; Reporting bugs:  report any bugs to steve.yegge at gmail dot com

;; To Do:
;;  - get working in XEmacs if possible (that, or remove XEmacs stuff)
;;    - will require factoring out mouse and event code

;;; History:
;; Inspired by (and borrows from) multi-region.el by Lawrence Mitchell
;; http://www.ph.ed.ac.uk/~p0198183/multi-region.el

;;; Code:

(require 'mouse)
(require 'custom)
(require 'cl)  ;; sorry, but I'm way too lazy to use raw elisp...

(when (featurep 'xemacs)
  (require 'overlay))

;; silence byte compiler about our dynamically scoped vars
(eval-when-compile
  (defvar start-window nil)
  (defvar start-point nil)
  (defvar click-count nil)
  (defvar this-overlay nil))

;;; User-customizable settings

(defgroup multi-select nil
  "Support for multiple, non-contiguous selections with the mouse."
  :group 'editing)

(defface multi-select-region-face
  '((((type tty) (class color))
     (:background "cyan" :foreground "black"))
    (((class color) (background light))
     (:background "lightblue"))
    (((class color) (background dark))
     (:background "darkblue"))
    (t (:inverse-video t)))
  "Face used to highlight multi-selections."
  :group 'multi-select)

(defcustom multi-select-leave-selections-after-copy nil
  "If nil (the default), \\[multi-select-kill-ring-save] will turn off
all selections after saving the text to the kill ring.  If non-nil,
the selections will remain."
  :group 'multi-select
  :type 'boolean)

(defcustom multi-select-auto-merge-selections t
  "If non-nil, automatically merge any adjacent selections into
a single selection."
  :group 'multi-select
  :type 'boolean)

(defvar multi-select-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'multi-select-mark-region)
    (define-key map "d" 'multi-select-unmark-region)
    (define-key map "e" 'multi-select-eval-on-selections)
    (define-key map "g" 'multi-select-cancel-all)
    (define-key map "k" 'multi-select-kill-selections)
    (define-key map "m" 'multi-select-toggle-auto-merge)
    (define-key map "q" 'multi-select-mode) ; toggles it off
    (define-key map "r" 'multi-select-mark-by-regexp)
    (define-key map "w" 'multi-select-wrap-selections)
    (define-key map "x" 'multi-select-execute-command)
    (define-key map "u" 'multi-select-undo-selection)
    map)
  "Keymap for multi-select commands.")

(defvar multi-select-bindings
  (if (featurep 'xemacs)
      (list
       (cons '(control meta button1) 'multi-select-start-selection)
       (cons '(control meta button3) 'multi-select-extend-selection)
       (cons '(control meta button2) 'multi-select-kill-selections)
       (cons '(meta w)               'multi-select-kill-ring-save))
    (list
     (cons [C-M-down-mouse-1] 'multi-select-start-selection)
     (cons [C-M-mouse-3]      'multi-select-extend-selection)
     (cons [C-M-mouse-2]      'multi-select-kill-selections)
     (cons "\M-w"             'multi-select-kill-ring-save)))
  "Key bindings to enable for multi-select-mode.")

(defvar multi-select-prefix-key [(control meta m)]
  "Key sequence that begins a multi-select keymap command.")

;;; end user-configurable settings

(defvar multi-select-mode nil
  "Non-nil when multi-select-mode is turned on globally.
Don't set this variable directly; use \\[multi-select-mode].")

;; list of all completed multi-selections in buffer
(defvar multi-select-overlay-list nil "For internal use only.")
(make-variable-buffer-local 'multi-select-overlay-list)

;; used to track when we've clicked once but haven't completed the selection
(defvar multi-select-start-pos nil "For internal use only.")
(make-variable-buffer-local 'multi-select-start-pos)

;; tracks last set of overlays added or removed
(defvar multi-select-last-select-op nil)

;;; helper functions for enabling mode and options

(defun multi-select-enable (noisy)
  (setq multi-select-mode t)
  (multi-select-install-bindings)
  (if noisy (message "Multi-select mode enabled.")))

(defun multi-select-disable (noisy)
  (setq multi-select-mode nil)
  (multi-select-remove-bindings)
  (multi-select-cancel-all)
  (if noisy (message "Multi-select mode disabled.")))

(defun multi-select-mode (&optional enable)
  "Toggle global multi-select mode.

Called interactively with ENABLE prefix argument, turn on multi-select
if arg is positive, off if arg is negative, and toggle if arg is zero."
  (interactive "p")
  (setq multi-select-last-select-op nil)
  (if (or (and current-prefix-arg
               (numberp enable)
               (plusp enable))
          (not multi-select-mode))
      (multi-select-enable (interactive-p))
    (multi-select-disable (interactive-p))))

(defun multi-select-install-bindings ()
  (define-key global-map multi-select-prefix-key multi-select-map)
  (dolist (pair multi-select-bindings nil)
    (global-set-key (car pair) (cdr pair))))

(defun multi-select-remove-bindings ()
  (define-key global-map multi-select-prefix-key nil)
  (dolist (pair multi-select-bindings nil)
    (global-unset-key (car pair))))

(defun multi-select-toggle-auto-merge ()
  "Toggles auto-merging of adjacent selections.  It can be useful to
turn off auto-merging temporarily if you want to be able to, for
instance, select and process adjacent lines separately."
  (interactive)
  (setq multi-select-auto-merge-selections
        (not multi-select-auto-merge-selections))
  (if (called-interactively-p 'any)
      (message (concat "Multi-select auto-merge "
                       (if multi-select-auto-merge-selections
                           "enabled" "disabled")))))

;;; Accessor functions for getting at the sub-selections.

(defun multi-select-get-combined-substring (&optional sort delim noprops)
  "Retrieve the concatenated text of all multi-selections in current buffer.

The selections are concatenated in the order they were created.  Passing a
non-nil value for SORT will first sort them by the buffer positions of their
starting points.
If DELIM is passed, it's used as a separator between the selections.
If NOPROPS is non-nil, the result doesn't include text properties."
  (mapconcat 'identity
             (multi-select-get-substrings sort noprops)
             (or delim "")))

(defun multi-select-get-substrings (&optional sort noprops)
  "Return a list containing the text of each multi-selection
in the current buffer.  Return the empty string if there are none.

The strings are obtained via buffer-substring, unless NOPROPS is
non-nil, in which case buffer-substring-no-properties is used.

The strings are returned in the order the subselections were created.
A non-nil SORT will sort the overlays by starting buffer position
first.  Sorting doesn't affect the order of the actual internal list."
  (mapcar (lambda (overlay)
            (funcall
             (if noprops
                 #'buffer-substring-no-properties
               #'buffer-substring)
             (overlay-start overlay)
             (overlay-end overlay)))
          (multi-select-get-overlays sort)))

(defun multi-select-get-overlays (&optional sort)
  "Return a copy of the internal, buffer-local list of overlays
corresponding to the multi-selections.  If SORT is non-nil, the
overlays will be sorted in order of increasing buffer position
of their starting points.  Result can be nil."
  (let ((overlays (reverse multi-select-overlay-list)))
    (and overlays sort
         (setq overlays
               (sort overlays #'(lambda (o1 o2)
                                  (< (overlay-start o1)
                                     (overlay-start o2))))))
    overlays))

;;; Functions to create, delete, update and find multi-selections.

(defun multi-select-deselect-in-range (beg end &optional skip)
  "Clear any multi-selections that overlap the range BEG...END.
BEG and END are buffer positions in the current buffer.
SKIP is an optional overlay to avoid deselecting, if found in range."
  (and multi-select-overlay-list
       (let ((targets (union (overlays-at beg)
                             (overlays-in beg end))))
         (mapc (lambda (ovl)
                 (unless (eq ovl skip)
                   (multi-select-cancel-selection ovl)))
               targets)
         (setq multi-select-last-select-op (cons 'remove targets)))))

(defun multi-select-cancel-selection (selection)
  "Delete an existing multi-selection, represented as an overlay.
Typically called when a new selection touches an old one; the old one
is canceled.  Operates only in current buffer."
  (when (multi-select-overlay-p selection)
    (delete-overlay selection)
    (setq multi-select-last-select-op (cons 'remove (list selection)))
    (setq multi-select-overlay-list
          (remove selection multi-select-overlay-list))))

;; for compatibility with multi-region.el
(defalias 'multi-select-unmark-region 'multi-select-cancel-selection)

(defun multi-select-cancel-all ()
  "Turn off any existing multi-selections in current buffer."
  (interactive)
  (setq multi-select-start-pos nil)
  (setq multi-select-last-select-op (cons 'remove multi-select-overlay-list))
  (when multi-select-overlay-list
    (mapc #'delete-overlay multi-select-overlay-list)
    (setq multi-select-overlay-list nil))
  (multi-select-purge-overlays))

;; until I'm reasonably certain there are no remaining bugs that can leave
;; orphaned overlays in the buffer, make sure cancel-all gets them all.
(defun multi-select-purge-overlays ()
  (let ((ovls (overlays-in (point-min) (point-max))))
    (dolist (ovl ovls nil)
      (if (multi-select-overlay-p ovl)
          (delete-overlay ovl)))))

(defun multi-select-set-start-point (start-point)
  "Put multi-select-start-pos marker at START-POINT.
Creates multi-select-start-pos marker if necessary."
  (if multi-select-start-pos
      (set-marker multi-select-start-pos start-point)
    (setq multi-select-start-pos (make-marker))))

(defun overlay-zero-width-p (overlay)
  "Return t if overlay-start and overlay-end are same position."
  (and overlay (eq (overlay-start overlay)
                   (overlay-end overlay))))

(defun multi-select-overlay-p (overlay)
  "Return true if this overlay was created by multi-select.
True if a 'multi-select property exists on the overlay."
  (and overlay (overlayp overlay)
       (overlay-get overlay 'multi-select)))

(defun multi-select-start-new-overlay (pos)
  "Create and return a zero-width multi-select overlay at POS.
The overlay is placed at the front of the internal overlay list."
  (let ((overlay (make-overlay (point) (point))))
    (overlay-put overlay 'face 'multi-select-region-face)
    (overlay-put overlay 'multi-select t) ; mark it as our own
    (setq multi-select-overlay-list
          (cons overlay multi-select-overlay-list))
    overlay))

(defun multi-select-create-selection (start end &optional overlay)
  "Add an overlay for the specified region.
Deselect any selections that overlap the new selection.  In
transient-mark-mode, also turn off the standard Emacs region
selection.  Passing in the optional overlay will use that
overlay, rather than create a new one.  Returns the new overlay."
  (and multi-select-start-pos
       (set-marker multi-select-start-pos nil))
  (let ((ovl (or overlay
                 (multi-select-start-new-overlay start))))
    (move-overlay ovl start end)
    (multi-select-deselect-in-range start end ovl)
    (setq multi-select-last-select-op (cons 'add (list ovl)))

    (if multi-select-auto-merge-selections
        (multi-select-merge-adjacent-selections))

    (when (and (boundp 'transient-mark-mode)
               transient-mark-mode)
      (deactivate-mark))
    ovl))

(defun multi-select-determine-active-overlay (click-count start-point)
  "Figure out whether to create a new overlay or re-use the last one."
  (let ((overlay (car-safe multi-select-overlay-list)))
    (cond
     ;; if there's no overlay at all, we have to create one
     ((null overlay)
      (multi-select-start-new-overlay start-point))

     ;; single/double/triple-click:  only re-use an overlay if it's empty
     ((plusp click-count)
      (if (overlay-zero-width-p overlay)
          overlay
        (multi-select-start-new-overlay start-point)))

     ;; else the active overlay to extend is first in the list
     (t overlay))))

(defun multi-select-find-closest-overlay (pos)
  "Figure out closest multi-select sub-region to buffer position POS.
If there are no selected sub-regions in the current buffer, return nil.
Otherwise return the overlay that has one of its endpoints closest to POS."
  (let ((dist (* (point-max) 2))
        overlay)
    (mapc
     #'(lambda (ol)
         (let ((beg (overlay-start ol))
               (end (overlay-end ol)))
           (if (numberp beg)
               (let ((d1 (abs (- beg pos)))
                     (d2 (abs (- end pos))))
                 (cond
                  ((and (< d1 d2) (< d1 dist))
                   (setq dist d1)
                   (setq overlay ol))
                  ((and (< d2 d1) (< d2 dist))
                   (setq dist d2)
                   (setq overlay ol)))))))
     multi-select-overlay-list)
    overlay))

;; Walk overlay list with 2 pointers, merging adjacent overlays.
;; Assumes overlay list is well-formed (i.e. no overlapping overlays).
(defun multi-select-merge-adjacent-selections ()
  "Consolidate any adjacent selections in current buffer."
  ;; sort overlays by buffer-position order before iterating
  (let* ((current (multi-select-get-overlays t)))
    (while current
      (let ((next (cdr current)))
        (when next
          (let ((ovl1 (car current))
                (ovl2 (car next)))
            (if (zerop (- (overlay-end ovl1) (overlay-start ovl2)))
                (let ((start (overlay-start ovl1)))
                  (multi-select-cancel-selection ovl1)
                  (move-overlay ovl2 start (overlay-end ovl2))))))
        (setq current next)))))

;;; Commands and functions for creating selections.

(defun multi-select-start-selection (start-event)
  "Begin a multi-selection, and update it as mouse is dragged.
This must be bound to a button-down mouse event."
  (interactive "e")
  (let* ((echo-keystrokes 0)
         (start-window (posn-window   (event-start start-event)))
         (start-point  (posn-point    (event-start start-event)))
         (click-count  (event-click-count start-event))
         this-overlay)
    (select-window start-window)
    (setq this-overlay
          (multi-select-determine-active-overlay click-count start-point))
    (cond
     ((= click-count 1)
      (multi-select-deselect-in-range start-point start-point)
      (multi-select-set-start-point start-point)) ; imcomplete region

     ;; double/triple click:  make an initial selection of one word/line.
     ((or (= click-count 2) (= click-count 3))
      (let* ((range (mouse-start-end start-point start-point
                                     (1- click-count))))
        (multi-select-create-selection (car range)
                                       (nth 1 range)
                                       this-overlay)))
     ;; quadruple: select defun (or paragraph in text/fundamental modes)
     ((= click-count 4)
      (if (or (string= mode-name "Fundamental")
              (string= mode-name "Text"))
          (multi-select-mark-paragraph)
        (multi-select-mark-defun))))

    ;; in all cases, read events until button is released
    (multi-select-track-mouse-drag)))

(defun multi-select-track-mouse-drag ()
  "For internal use by multi-select.el.
Read mouse-drag events, updating selection, until button is released."
  (let*    ((bounds (window-edges start-window))  ; (left top right bottom)
            (top (nth 1 bounds))
            (bottom (if (window-minibuffer-p start-window)
                        (nth 3 bounds)
                      (1- (nth 3 bounds)))) ;; don't count the mode line
            event end end-point)

    (track-mouse
      (while (mouse-movement-p (setq event (read-event)))
        (setq end (event-end event)
              end-point (posn-point end))
        (cond
         ((and (eq (posn-window end) start-window) ; moving in original window?
               (integer-or-marker-p end-point))
          (when (or (/= start-point end-point)
                    (null (marker-position multi-select-start-pos)))
            (let* ((range (mouse-start-end start-point end-point click-count))
                   (beg (car range))
                   (end (nth 1 range)))
              (multi-select-create-selection beg end this-overlay))))
         (t
          (let ((mouse-row (cdr (cdr (mouse-position)))))
            (cond
             ((null mouse-row))
             ((< mouse-row top)
              (mouse-scroll-subr start-window (- mouse-row top)
                                 this-overlay start-point))
             ((>= mouse-row bottom)
              (mouse-scroll-subr start-window (1+ (- mouse-row bottom))
                                 this-overlay start-point))))))))

    ;; when we get here, button has been released
    (if (consp event) ;; did we read any events at all?

        ;; if we haven't moved the mouse, put the point there
        (if (marker-position multi-select-start-pos)
            (progn
              (mouse-set-point event)
              (multi-select-cancel-selection this-overlay))

          ;; otherwise copy all selections to the window-system clipboard.
          ;; Hopefully nobody'll mind if I commandeer the SECONDARY slot.
          (x-set-selection
           'SECONDARY
           (multi-select-get-combined-substring t))))))

(defun multi-select-extend-selection (click)
  "Move the endpoint of the most appropriate multi-selection
to where you clicked.

The appropriate sub-region is determined as follows:

  - if you just did a multi-select single-click in the buffer, that's
    used as the starting point, and this click completes the selection.

  - otherwise find the selection closest to where you clicked,
    and move the closer of that selection's endpoints there.

This allows you to create new selections or modify existing ones with
reasonably fine-grained control."
  (interactive "e")
  (let* ((posn (event-start click))
         (click-point  (posn-point posn))
         (start-window (posn-window posn))
         start-point)
    (when (numberp click-point)
      (select-window start-window)
      (setq start-point (and multi-select-start-pos
                             (marker-position multi-select-start-pos)))
      (if start-point
          ;; pairing with a single click to complete a subregion
          (let* ((overlay (multi-select-determine-active-overlay 1 click-point))
                 (beg (min start-point click-point))
                 (end (max start-point click-point)))
            (multi-select-create-selection beg end overlay))

        ;; ...else we're modifying nearest completed subregion, if any.
        ;; we clicked either before or after the sub-region's midpoint.
        ;; If before, modify start-point, else modify end-point.
        (let ((overlay (multi-select-find-closest-overlay click-point)))
          (and overlay
               (let* ((p1 (overlay-start overlay))
                      (p2 (overlay-end overlay))
                      (mid (+ p1 (/ (- p2 p1) 2)))
                      (beg (if (< click-point mid) click-point p1))
                      (end   (if (< click-point mid) p2 (1+ click-point))))
                 (multi-select-create-selection beg end overlay))))))))

(defun multi-select-mark-by-regexp (regexp)
  "Multi-select matches for given a regular expression.

In Transient Mark mode, operate on the contents of the current Emacs
region.  Otherwise, operate from point to the end of the buffer.

Default behavior if there is no prefix argument, or the prefix
arg is 0:   highlight the entire match if there are no capturing
groups in the regexp, else highlight the first matching group.

A positive prefix arg selects a single parenthesized group in the
regexp to highlight in the matched text.  Groups are numbered from 1.

A negative prefix arg specifies that all matching groups should be
highlighted in the matched text.  Text not matched by any of the
sub-groups is not selected.  Note that 'shy' groups using ?: are
not counted."
  (interactive "sMulti-select regexp: ")
  (let ((beg (point))
        (end (if (and (boundp 'transient-mark-mode)
                      transient-mark-mode
                      mark-active)
                 (mark)
               (point-max)))
        (count 0)
        (changes nil)
        (group (cond
                ((null current-prefix-arg) 0)
                ((plusp current-prefix-arg) current-prefix-arg)
                (t -1)))) ; highlight all groups

    (save-restriction
      (narrow-to-region beg end)
      (while (re-search-forward regexp nil t)
        (cond
         ((plusp group)
          ;; highlight specified match group
          (progn
            (push
             (multi-select-create-selection (match-beginning group)
                                            (match-end group))
             changes)
            (incf count)))
         ((minusp group)
          ;; highlight all match groups
          (let ((ptr (match-data)) beg end)
            (while ptr
              (setq beg (car ptr) end (cadr ptr))
              (if (markerp beg) (setq beg (marker-position beg)))
              (if (markerp end) (setq end (marker-position end)))
              (push (multi-select-create-selection beg end) changes)
              (setq ptr (cddr ptr))
              (incf count))))
         (t
          ;; highlight first group if there was one, else whole match
          (let ((g (if (match-beginning 1) 1 0)))
            (push (multi-select-create-selection (match-beginning g)
                                                 (match-end g))
                  changes)
            (incf count))))))
    (setq multi-select-last-select-op (cons 'add changes))
    (message "Selected %d region%s." count
             (if (= 1 count) "" "s"))))

(defun multi-select-mark-region (beg end)
  "Add a multi-selection in place of the current region."
  (interactive "r")
  (multi-select-create-selection beg end))

(defun multi-select-mark-defun ()
  "Multi-select the current defun.  If the newly-created selection
overlaps any other multi-selections, they are deselected."
  (interactive)
  (save-excursion
    (let (beg)
      (beginning-of-defun)
      (setq beg (point))
      (end-of-defun)
      (multi-select-create-selection beg (point)))))

(defun multi-select-mark-paragraph ()
  "Multi-select the current paragraph.  If the newly-created selection
overlaps any other multi-selections, they are deselected."
  (interactive)
  (save-excursion
    (let (beg)
      (backward-paragraph 1)
      (setq beg (point))
      (forward-paragraph 1)
      (multi-select-create-selection beg (point)))))

;;; Commands and functions for operating on existing selections.

(defun multi-select-kill-ring-save (&optional delim)
  "Save the concatenation of all multi-selections to the kill ring.
If there are no multi-selections, call kill-ring-save.

This function deselects all the selections after saving them to the kill
ring, unless `multi-select-leave-selections-after-copy' is non-nil.

It won't save the exact same text to the kill-ring twice in a row --
if you invoke it twice without changing the existing multi-selection,
then it does nothing the second time.

If `interprogram-cut-function' is non-nil, also saves the text for a
window system cut and paste.

With a prefix arg, prompts for a delimiter string to place between the
selections in the kill-ring.  When called non-interactively, DELIM is
used as the delimiter; it defaults to the empty string.

A convenient way to use this function is to rebind your key sequence
for kill-ring-save to multi-select-kill-ring-save.  It will save the
multi-selection if there is one, else invoke kill-ring save."
  (interactive)

  ;; if requested, read delimiter to use between kills
  (if (and current-prefix-arg (not delim))
      (setq delim (read-string "String for separating selections: ")))

  (let ((last-kill (car-safe kill-ring))
        (text (multi-select-get-combined-substring t delim)))
    (cond
     ;; default to kill-ring-save if there are no multi-selections
     ((zerop (length text))
      (call-interactively 'kill-ring-save))

     ;; don't save same text twice
     ((string= last-kill text)
      (message "Already saved text of current multi-selection."))

     ;; else stuff it all onto the clipboard
     (t (kill-new text)
        (let ((len (length multi-select-overlay-list)))
          (message "Saved %d selection%s, %d chars total."
                   len
                   (if (= len 1) "" "s")
                   (length text)))
        (unless multi-select-leave-selections-after-copy
          (multi-select-cancel-all))))))

(defun multi-select-kill-selections (&optional delim)
  "Kill all multi-selections.

Works just like `multi-select-kill-ring-save', but also deletes the
text.  It's undoable in one step.

With a prefix arg, prompts for a delimiter string to place between the
selections in the kill-ring.  When called non-interactively, DELIM is
used as the delimiter; it defaults to the empty string."
  (interactive)

  ;; if requested, read delimiter to use between kills
  (if (and current-prefix-arg (not delim))
      (setq delim (read-string "String for separating selections: ")))

  (if (null multi-select-overlay-list)
      (message "No multi-selections.")

    (let (spans)
      ;; make a list of the regions to delete
      (mapc #'(lambda (overlay)
                (setq spans
                      (append
                       (list (cons (overlay-start overlay)
                                   (overlay-end overlay)))
                       spans)))
            (multi-select-get-overlays t))

      ;; turn off all the selections, so the overlay isn't saved along
      ;; with the killed text
      (multi-select-cancel-all)

      ;; kill the regions, disabling insertion of undo boundaries.
      ;; The first kill is done normally, and the rest are appended
      ;; to the first kill, so it's all one blob in the kill ring.
      (undo-boundary)
      (flet ((undo-boundary () nil))
        (let ((count 0))
          (dolist (span spans nil)
            (unless (zerop count)
              (setq last-command 'kill-region)) ;; forces append
            (kill-region (car span) (cdr span))
            (if delim
                (kill-append delim nil))
            (incf count))))
      (undo-boundary))))

;; this is more or less copied directly from multi-region.el
(defun multi-select-execute-command (&optional arg cmd)
  "Perform a command on all active multi-selections.
ARG gets passed through as `current-prefix-arg' to the command
called.  If CMD is non-nil, call that, rather than prompting for
one."
  (interactive "P")
  (setq cmd (or cmd (key-binding (read-key-sequence " " t))))
  (when (eq cmd 'execute-extended-command)
    (setq cmd (read-command "M-x ")))
  (setq current-prefix-arg arg)
  (dolist (ov (multi-select-get-overlays t))
    (let ((start (overlay-start ov))
          (end (overlay-end ov)))
      (save-excursion
        ;; Ensure that we only operate on the marked region.  The
        ;; other alternative, to narrow to the marked region, looks
        ;; ugly when performing commands like ispell-region, however,
        ;; it's failsafe, whereas this version assumes that package
        ;; authors respect transient-mark-mode.
        (let ((transient-mark-mode t)
              (zmacs-regions t))
          (push-mark start nil t)
          (goto-char end)
          (command-execute cmd)))))
  (when (fboundp 'deactivate-mark)
    (deactivate-mark))
  (when (fboundp 'zmacs-deactivate-region)
    (zmacs-deactivate-region))
  (multi-select-cancel-all))

(defun multi-select-eval-on-selections (expr)
  "Evaluates EXPR, a lisp expression, on each active multi-selection.
The buffer will be narrowed to the region corresponding to the selection,
and the point and mark will be at the beginning and end of the region.
Equivalent to calling \\[eval-expression] on each successive selection
after narrowing to it."
  (interactive "xEval on selections: ")
  (let ((ovls (multi-select-get-overlays t)))
    (if (null ovls)
        (message "No multi-selections.")
      (save-excursion
        (dolist (ovl ovls (multi-select-cancel-all))
          (save-restriction
            (narrow-to-region (overlay-start ovl) (overlay-end ovl))
            (goto-char (point-min))
            (set-mark (point-max))
            (eval expr)))))))

(defun multi-select-wrap-selections ()
  "Inserts a prefix and suffix around every multi-selection.
Prompts for both prefix and suffix."
  (interactive)
  (let ((ovls (multi-select-get-overlays t)))
    (if (null ovls)
        (message "No multi-selections.")
      (let (prefix suffix)
        (setq prefix (read-string "Prepend string (return for none): "))
        (setq suffix (read-string "Append string (return for none): "))
        (if (and (null prefix) (null suffix))
            (message "Nothing to do!")
          (save-excursion
            (dolist (ovl ovls (multi-select-cancel-all))
              (when prefix
                (goto-char (overlay-start ovl))
                (insert prefix))
              (when suffix
                (goto-char (overlay-end ovl))
                (insert suffix)))))))))

(defun multi-select-undo-selection ()
  "Undo the last select or deselect.  It's a toggle.
The support is incomplete, so use at your own risk."
  (interactive)
  (if (not multi-select-last-select-op)
      (message "Nothing to undo")
    (let ((changes nil))
      (if (eq (car multi-select-last-select-op) 'add)
          (progn
            (dolist (ovl (cdr multi-select-last-select-op)
                         (message "Undoing last multi-selection"))
              (push ovl changes)
              (delete-overlay ovl))
            (setq multi-select-last-select-op (cons 'remove changes)))
        (dolist (ovl (cdr multi-select-last-select-op)
                     (message "Redoing last multi-selection"))
          (push
           (multi-select-create-selection (overlay-start ovl)
                                          (overlay-end ovl))
           changes))
        (setq multi-select-last-select-op (cons 'add changes))))))

(provide 'multi-select)

;;; multi-select.el ends here
