;;; multiselect.el --- Select non-contiguous regions
;; $Id: $
;; Copyright (C) 2006 by Stefan Kamphausen
;; Author: Stefan Kamphausen <http://www.skamphausen.de>
;; Keywords: user, gui
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
;; Select non-contiguous regions or lines and later insert the
;; concatenation of these.

;;; ToDo
;; * Testing during daily usage and in Gnu Emacs
;; * Customize at least the face (well, yes, might be overkill).

;;; Code:

(defvar multiselect-overlays ()
  "List of current overlays in a multiselection.")

(defun multiselect-current-overlay nil
  "Temporaryly used variable to hold the current overlay.")

(defun multiselect-add-selection-or-line ()
  "Mark a region or the current line.
Several of these marks are allowed and will stay visible.  When all
desired marks are set the command `multiselect-insert-selection' will
insert the concatenation of all marked regions IN THE ORDER OF
MARKING.  This does not reflect the ordering of the regions within the
buffer."
  (interactive)
  (cond
    ((if (fboundp 'region-exists-p)           ;; XEmacs
       (region-exists-p)
       (and transient-mark-mode mark-active)) ;; GnuEmacs
      (setq multiselect-current-overlay
              (multiselect-create-overlay
               (region-beginning)
               (region-end)))
      (if (fboundp 'zmacs-deactivate-region)
        (zmacs-deactivate-region)             ;XEmacs
        (deactivate-mark)))
    (t
      (setq multiselect-current-overlay
              (multiselect-create-overlay
               (point-at-bol)
               (save-excursion
                 (forward-line)
                 (point-at-bol)))
               )))
  (setq multiselect-overlays
          (cons multiselect-current-overlay multiselect-overlays))
  (setq multiselect-current-overlay nil))

(defun multiselect-create-overlay (begin end)
  "Backend function to create an overlay."
  (let ((overlay (make-overlay begin end (current-buffer) nil t)))
    ;; FIXME: defcustom for the face
    (overlay-put overlay 'face 'highlight)
    overlay))


(defun multiselect-collect-and-remove-overlays ()
  "Iterate over all overlays, remove and concatenate them.
Return the concatenated string."
  (let ((all-selection-string ""))
    (while multiselect-overlays
      (let ((this-ol (car multiselect-overlays)))
        (setq multiselect-overlays (cdr multiselect-overlays))
        (setq all-selection-string
                (concat
                 (buffer-substring
                  (overlay-start this-ol)
                  (overlay-end   this-ol))
                 all-selection-string))
        (delete-overlay this-ol)))
    all-selection-string))

(defun multiselect-insert-selection ()
  "Insert the concatenation of all selections.
The ordering of the concatenation depends on the order of selecting
them not on the order in which they appear in the buffer."
  (interactive)
  (insert (multiselect-collect-and-remove-overlays)))


(defun multiselect-clear-selections ()
  "Just remove the selections."
  (interactive)
  (multiselect-collect-and-remove-overlays))


(defun multiselect-install-default-keybindings ()
  "Install some default bindings using uppercase Y and W.
Sets C-Y to `multiselect-insert-selection'
     C-W to `multiselect-add-selection-or-line'."
  (interactive)
  (global-set-key '[(control Y)] 'multiselect-insert-selection)
  (global-set-key '[(control W)] 'multiselect-add-selection-or-line))


(defun multiselect-remove-newest-selection ()
  (interactive)
  (when multiselect-overlays
    (delete-overlay (car multiselect-overlays))
    (setq multiselect-overlays (cdr multiselect-overlays))))


(provide 'multiselect)

;;; multiselect.el ends here