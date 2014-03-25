;;; repdet.el --- detect repetition in user activity

;; Copyright (C) 2002  ZwaX

;; Author: ZwaX <?>
;; Maintainer: ZwaX <?>
;; Version: 1.0.2
;; Keywords: lisp
;; URL: http://www.emacswiki.org/cgi-bin/wiki.pl?RepetitionDetectionPackage

;; This file is not part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This can be used to define keyboard macros after the event, and to
;; suggest good candidates for saving as keyboard macros.

(require 'elisp-utils)
(require 'loops)

(defgroup repdet nil
  "Detect repetitions in user input."
  :group 'tools)

(defcustom repdet-min-rep 3
  "the minimum number of times a sequence must occur before it is detected"
  :type 'integer
  :group 'repdet)

(defcustom repdet-min-length 7
  "the minimum length of a detected sequence"
  :type 'integer
  :group 'repdet)

(defcustom repdet-max-length 120
  "the maximum length of a detected sequence"
  :type 'integer
  :group 'repdet)

(defcustom repdet-buffer-size 10000
  "the number of input events to keep"
  :type 'integer
  :group 'repdet)

(defcustom repdet-buffer-name "*Detected Repetition Patterns*"
  "if non-nil, the name of a buffer to which to log detected patterns"
  :type 'string
  :group 'repdet)

(defcustom repdet-ignore-adjacent-identical-patterns t
  "if non-nil, if a detected pattern is identical to the previously detected pattern, ignore it"
  :type 'boolean
  :group 'repdet)

(defcustom repdet-show-patterns-in-message-area t
  "if non-nil, show each pattern in the message area as it is detected"
  :type 'boolean
  :group 'repdet)

(defcustom repdet-trim-buffer-delay 1000
  "number of keystrokes to wait before trimming repdet-input-event-list buffer"
  :type 'integer
  :group 'repdet)

(defvar repdet-debug nil
  "set to t for debug windows")

(defvar repdet-recent nil
  "a list containing the most recently detected sequence of repeating keystrokes")

(defvar repdet-events nil
  "list of recent input events")

(defvar repdet-steps-until-trim repdet-trim-buffer-delay)

(defun turn-on-repdet ()
  "Switches repetition detection on"
  (interactive)
  (add-hook 'pre-command-hook 'repdet-pre-command-get-command t))

(defun turn-off-repdet ()
  "Switches repetition detection off"
  (interactive)
  (remove-hook 'pre-command-hook 'repdet-pre-command-get-command))

;; this sets the buffer to be full of junk, so you get an instant
;; indication of how slow things will be once the buffer is full
(let ((i repdet-buffer-size))
  (while (> i 0)
    (setq repdet-events (cons (random 256) repdet-events)
          i (1- i))))

(defun repdet-pre-command-get-command ()
  (let ((keys (this-command-keys))
        (mode major-mode)
        (cmd this-command))

    (if (not (or (eq cmd 'repdet-use-as-macro)
                 (eq cmd 'call-last-kbd-macro)
                 ;; 'keys' seems to be empty after running a keyboard macro?
                 (equal keys "")))
        (progn
          (setq repdet-events (cons keys repdet-events)
                repdet-steps-until-trim (1- repdet-steps-until-trim))
          (if (= 0 repdet-steps-until-trim)
              (progn
                (setq repdet-steps-until-trim repdet-trim-buffer-delay)
                (if (> (length repdet-events) repdet-buffer-size)
                    (setcdr (nthcdr (1- repdet-buffer-size) repdet-events) nil))))))

    ;; (repdet-show-list-for-debugging-purposes)

    (when (and (not (minibufferp))      ;Note: Don't use in minibuffer for now!
               (not executing-kbd-macro))
      (if repdet-debug
          (save-excursion
            (let (deactivate-mark)
              (set-buffer (get-buffer-create "*repdet*"))
              (goto-char (point-min))
              (insert (format "search: keys '%s' cmd '%s'\n" keys cmd)))))
      (let (ret time)
        (setq time (time-eval '(setq ret (loop-find-longest repdet-events
                                                            repdet-min-rep
                                                            repdet-min-length
                                                            repdet-max-length))))
        (if ret
            (let ((previous-sequence repdet-recent))
              (setq repdet-recent (nreverse ret))
              (if (or (not repdet-ignore-adjacent-identical-patterns)
                      (not (equal previous-sequence repdet-recent)))
                  (progn
                    (when repdet-show-patterns-in-message-area
                      ;; (message "%s found sequence: %s" time repdet-recent)
                      (message "Detected sequence of length %d (Press %s to save as macro)"
                               (length repdet-recent)
                               (symbol-function-keys-string 'repdet-use-as-macro)
                               )
                      (sit-for 1)
                      )
                    (if repdet-buffer-name
                        (save-excursion
                          (let (deactivate-mark)
                            (set-buffer (get-buffer-create repdet-buffer-name))
                            (goto-char (point-min))
                            (insert (format "%s : %s\n" (current-time-string)
                                            repdet-recent)))))))))))))

(defun repdet-show-list-for-debugging-purposes ()
  (save-excursion
    (set-buffer "*repdet*")
    (delete-region (point-min) (point-max))
    (insert (format "%s" repdet-events))))

(defun time-eval (expr)
  (let (before after)
    (setq before (float-time))
    (eval expr)
    (format "%.3f" (- (float-time)
                      before))))

(defun repdet-use-as-macro ()
  (interactive)
  (let ((mac "")
        (seq repdet-recent)
        next)
    (while seq
      (setq next (car seq)
            seq (cdr seq))
      (if (stringp mac)
          (if (stringp next)
              (setq mac (concat mac next))
            (if (vectorp next)
                (setq mac (vconcat mac next))
              ;; debugging - shouldn't happen?
              (message "what is type %s doing in macro?" (type-of next))
              (read-char)))
        (if (vectorp mac)
            (setq mac (vconcat mac next))
          ;; debugging - shouldn't happen?
          (message "what is type %s doing in mac?" (type-of mac))
          (read-char))))
    (setq last-kbd-macro mac)
    ;; (insert (format "\n\nmacro: '%s'\n" mac))
    ))

(provide 'repdet)
