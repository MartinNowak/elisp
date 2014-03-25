;;; hangul.el --- Korean Hangul input method

;; Author: Jihyun Cho <likesylph@gmail.com>
;; Keywords: multilingual, input method, Korean, Hangul

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This file is to implement the following hangul automata:
;; - Hangul 2-Bulsik input method
;; - Hangul 3-Bulsik input method

;;; Code:

(require 'quail)

(defconst hangul-djamo-table
  '((cho . ((1 . (1))
            (7 . (7))
            (18 . (18))
            (21 . (21))
            (24 . (24))))
    (jung . ((39 . (31 32 51))
             (44 . (35 36 51))
             (49 . (51))))
    (jong . ((1 . (1 21))
             (4 . (24 30))
             (9 . (1 17 18 21 28 29 30))
             (18 . (18 21))
             (21 . (21))))))

(defconst hangul2-keymap
  '(17 48 26 23 7 9 30 39 33 35 31 51 49 44 32 36 18 1 4 21 37 29 24 28 43 27))

(defconst hangul3-keymap
  '(2 183 24 15 14 8220 120 39 126 8221 43 44 41 46 74 119 30 22 18 78 83 68 73 85 79 52 110 44 62 46 33 10
    7 63 27 12 5 11 69 48 55 49 50 51 34 45 56 57 29 16 6 13 54 3 28 20 53 26 40 58 60 61 59 42 23 79
    71 86 72 66 84 96 109 115 93 116 122 113 118 121 21 67 4 70 99 74 9 1 101 17 37 92 47 8251))

(defvar hangul-queue
  (make-list 6 0))

(defsubst notzerop (number)
  (not (zerop number)))

(defsubst alphap (char)
  (or (and (>= char ?A) (<= char ?Z))
      (and (>= char ?a) (<= char ?z))))

(defun hangul-character (cho jung jong)
  (if (zerop (+ cho jung jong))
      (throw 'exit-input-loop nil)
      (or
       (decode-char
        'ucs
        (if (and (/= cho 0) (/= jung 0))
            (+ #xac00
               (* 588
                  (- cho
                     (cond ((< cho 3) 1)
                           ((< cho 5) 2)
                           ((< cho 10) 4)
                           ((< cho 20) 11)
                           (t 12))))
               (* 28 (- jung 31))
               (- jong
               (cond ((< jong 8) 0)
                     ((< jong 19) 1)
                     ((< jong 25) 2)
                     (t 3))))
            (+ #x3130
               (cond ((/= cho 0) cho)
               ((/= jung 0) jung)
               ((/= jong 0) jong)))))
       "")))

(defun hangul-insert-character (&rest queue)
  (quail-delete-region)
  (let ((first (car queue)))
    (insert
     (hangul-character
      (+ (nth 0 first) (hangul-djamo 'cho (nth 0 first) (nth 1 first)))
      (+ (nth 2 first) (hangul-djamo 'jung (nth 2 first) (nth 3 first)))
      (+ (nth 4 first) (hangul-djamo 'jong (nth 4 first) (nth 5 first))))))
  (move-overlay quail-overlay (overlay-start quail-overlay) (point))
  (dolist (elt (cdr queue))
    (insert
     (hangul-character
      (+ (nth 0 elt) (hangul-djamo 'cho (nth 0 elt) (nth 1 elt)))
      (+ (nth 2 elt) (hangul-djamo 'jung (nth 2 elt) (nth 3 elt)))
      (+ (nth 4 elt) (hangul-djamo 'jong (nth 4 elt) (nth 5 elt)))))
    (move-overlay quail-overlay (1+ (overlay-start quail-overlay)) (point))))

(defun hangul-djamo (jamo char1 char2)
  (let* ((jamo (cdr (assoc jamo hangul-djamo-table)))
         (char1 (cdr (assoc char1 jamo))))
    (if char1
        (let ((i (length char1)))
          (or (catch 'found
                (while (> i 0)
                  (if (= char2 (nth (1- i) char1))
                      (throw 'found i))
                  (setf i (1- i))))
              0))
        0)))

(defsubst hangul2-input-method-jaum (char)
  "2-Bulsik Jaum"
  (if (cond ((zerop (nth 0 hangul-queue))
             (setf (nth 0 hangul-queue) char))
            ((and (zerop (nth 1 hangul-queue))
                  (zerop (nth 2 hangul-queue))
                  (notzerop (hangul-djamo 'cho (nth 0 hangul-queue) char)))
             (setf (nth 1 hangul-queue) char))
            ((and (zerop (nth 4 hangul-queue))
                  (notzerop (nth 2 hangul-queue))
                  (/= char 8)
                  (/= char 19)
                  (/= char 25)
                  (numberp
                   (hangul-character
                    (+ (nth 0 hangul-queue) (hangul-djamo 'cho (nth 0 hangul-queue) (nth 1 hangul-queue)))
                    (+ (nth 2 hangul-queue) (hangul-djamo 'jung (nth 2 hangul-queue) (nth 3 hangul-queue)))
                    char)))
             (setf (nth 4 hangul-queue) char))
            ((and (zerop (nth 5 hangul-queue))
                  (notzerop (hangul-djamo 'jong (nth 4 hangul-queue) char))
                  (numberp
                   (hangul-character
                    (+ (nth 0 hangul-queue) (hangul-djamo 'cho (nth 0 hangul-queue) (nth 1 hangul-queue)))
                    (+ (nth 2 hangul-queue) (hangul-djamo 'jung (nth 2 hangul-queue) (nth 3 hangul-queue)))
                    (+ (nth 4 hangul-queue) (hangul-djamo 'jong (nth 4 hangul-queue) char)))))
             (setf (nth 5 hangul-queue) char)))
      (hangul-insert-character hangul-queue)
      (hangul-insert-character hangul-queue (setq hangul-queue (list char 0 0 0 0 0)))))

(defsubst hangul2-input-method-moum (char)
  "2-Bulsik Moum"
  (if (cond ((zerop (nth 2 hangul-queue))
             (setf (nth 2 hangul-queue) char))
            ((and (zerop (nth 3 hangul-queue))
                  (zerop (nth 4 hangul-queue))
                  (notzerop (hangul-djamo 'jung (nth 2 hangul-queue) char)))
             (setf (nth 3 hangul-queue) char)))
      (hangul-insert-character hangul-queue)
      (let ((next-char (list 0 0 char 0 0 0)))
        (cond ((notzerop (nth 5 hangul-queue))
               (setf (nth 0 next-char) (nth 5 hangul-queue))
               (setf (nth 5 hangul-queue) 0))
              ((notzerop (nth 4 hangul-queue))
               (setf (nth 0 next-char) (nth 4 hangul-queue))
               (setf (nth 4 hangul-queue) 0)))
        (hangul-insert-character hangul-queue (setq hangul-queue next-char)))))

(defsubst hangul3-input-method-cho (char)
  (if (cond ((and (zerop (nth 0 hangul-queue))
                  (zerop (nth 4 hangul-queue)))
             (setf (nth 0 hangul-queue) char))
            ((and (zerop (nth 1 hangul-queue))
                  (notzerop (hangul-djamo 'cho (nth 0 hangul-queue) char)))
             (setf (nth 1 hangul-queue) char)))
      (hangul-insert-character hangul-queue)
      (hangul-insert-character hangul-queue (setq hangul-queue (list char 0 0 0 0 0)))))

(defsubst hangul3-input-method-jung (char)
  (if (cond ((and (zerop (nth 2 hangul-queue))
                  (zerop (nth 4 hangul-queue)))
             (setf (nth 2 hangul-queue) char))
            ((and (zerop (nth 3 hangul-queue))
                  (notzerop (hangul-djamo 'jung (nth 2 hangul-queue) char)))
             (setf (nth 3 hangul-queue) char)))
      (hangul-insert-character hangul-queue)
      (hangul-insert-character hangul-queue (setq hangul-queue (list 0 0 char 0 0 0)))))

(defsubst hangul3-input-method-jong (char)
  (if (cond ((and (zerop (nth 4 hangul-queue))
                  (notzerop (nth 0 hangul-queue))
                  (notzerop (nth 2 hangul-queue))
                  (numberp
                   (hangul-character
                    (+ (nth 0 hangul-queue) (hangul-djamo 'cho (nth 0 hangul-queue) (nth 1 hangul-queue)))
                    (+ (nth 2 hangul-queue) (hangul-djamo 'jung (nth 2 hangul-queue) (nth 3 hangul-queue)))
                    char)))
             (setf (nth 4 hangul-queue) char))
            ((and (zerop (nth 5 hangul-queue))
                  (notzerop (hangul-djamo 'jong (nth 4 hangul-queue) char))
                  (numberp
                   (hangul-character
                    (+ (nth 0 hangul-queue) (hangul-djamo 'cho (nth 0 hangul-queue) (nth 1 hangul-queue)))
                    (+ (nth 2 hangul-queue) (hangul-djamo 'jung (nth 2 hangul-queue) (nth 3 hangul-queue)))
                    (+ (nth 4 hangul-queue) (hangul-djamo 'jong (nth 4 hangul-queue) char)))))
             (setf (nth 5 hangul-queue) char)))
      (hangul-insert-character hangul-queue)
      (if (zerop (apply '+ hangul-queue))
          (hangul-insert-character (setq hangul-queue (list 0 0 0 0 char 0)))
          (hangul-insert-character hangul-queue (setq hangul-queue (list 0 0 0 0 char 0))))))

(defun hangul2-input-method-internal (key)
  (let ((char (+ (nth (1- (% key 32)) hangul2-keymap)
                 (cond ((or (= key ?O) (= key ?P)) 2)
                       ((or (= key ?E) (= key ?Q) (= key ?R) (= key ?T) (= key ?W)) 1)
                       (t 0)))))
    (if (< char 31)
        (hangul2-input-method-jaum char)
        (hangul2-input-method-moum char))))

(defun hangul2-input-method (key)
  "2-Bulsik input method"
  (if (or buffer-read-only (not (alphap key)))
      (list key)
      (quail-setup-overlays nil)
      (let ((input-method-function nil)
            (echo-keystrokes 0)
            (help-char nil))
        (setq hangul-queue (make-list 6 0))
        (hangul2-input-method-internal key)
        (unwind-protect
             (catch 'exit-input-loop
               (while t
                 (let ((seq (read-key-sequence nil))
                       key)
                   (cond ((and (stringp seq)
                               (= 1 (length seq))
                               (setq key (aref seq 0))
                               (alphap key))
                          (hangul2-input-method-internal key))
                         ((and (stringp seq)
                               (= (aref seq 0) ?\d))
                          (let ((i 5))
                            (while (and (> i 0) (zerop (nth i hangul-queue)))
                              (setq i (1- i)))
                            (setf (nth i hangul-queue) 0))
                          (hangul-insert-character hangul-queue))
                         (t
                          (throw 'exit-input-loop (listify-key-sequence seq)))))))
          (quail-delete-overlays)))))

(defun hangul3-input-method-internal (key)
  (let ((char (nth (- key 33) hangul3-keymap)))
    (cond ((and (> char 92) (< char 123))
           (hangul3-input-method-cho (- char 92)))
          ((and (> char 65) (< char 87))
           (hangul3-input-method-jung (- char 35)))
          ((< char 31)
           (hangul3-input-method-jong char))
          (t
           (setq hangul-queue (make-list 6 0))
           (insert (decode-char 'ucs char))
           (move-overlay quail-overlay (point) (point))))))

(defun hangul3-input-method (key)
  "3-Bulsik input method"
  (if (or buffer-read-only (< key 33) (>= key 127))
      (list key)
      (quail-setup-overlays nil)
      (let ((input-method-function nil)
            (echo-keystrokes 0)
            (help-char nil)
            (hangul-queue (make-list 6 0)))
        (hangul3-input-method-internal key)
        (unwind-protect
             (catch 'exit-input-loop
               (while t
                 (let ((seq (read-key-sequence nil))
                       key)
                   (cond ((and (stringp seq)
                               (= 1 (length seq))
                               (setq key (aref seq 0))
                               (and (>= key 33) (< key 127)))
                          (hangul3-input-method-internal key))
                         ((and (stringp seq)
                               (= (aref seq 0) ?\d))
                          (let ((i 5))
                            (while (and (> i 0) (zerop (nth i hangul-queue)))
                              (setq i (1- i)))
                            (setf (nth i hangul-queue) 0))
                          (if (zerop (apply '+ hangul-queue))
                              (throw 'exit-input-loop (listify-key-sequence seq))
                              (hangul-insert-character hangul-queue)))
                         (t
                          (throw 'exit-input-loop (listify-key-sequence seq)))))))
          (quail-delete-overlays)))))

(defun hangul2-input-activate (&optional arg)
  "Activate Hangul 2-Bulsik input method."
  (if (and arg
           (< (prefix-numeric-value arg) 0))
      (unwind-protect
           (progn
             (quail-hide-guidance)
             (quail-delete-overlays)
             (setq describe-current-input-method-function nil))
        (kill-local-variable 'input-method-function))
      (setq inactivate-current-input-method-function 'hangul2-input-inactivate)
      (setq describe-current-input-method-function 'hangul2-input-help)
      (quail-delete-overlays)
      (if (eq (selected-window) (minibuffer-window))
          (add-hook 'minibuffer-exit-hook 'quail-exit-from-minibuffer))
      (set (make-local-variable 'input-method-function)
           'hangul2-input-method)))

(defun hangul2-input-inactivate ()
  "Inactivate Hangul 2-Bulsik input method."
  (interactive)
  (hangul2-input-activate -1))

(defun hangul2-input-help ()
  (interactive)
  (with-output-to-temp-buffer "*Help*"
    (princ "\
Input method: hangul2 (mode line indicator:한2)

New Hangul 2-Bulsik input method.")))

(defun hangul3-input-activate (&optional arg)
  "Activate Hangul 3-Bulsik input method."
  (if (and arg
           (< (prefix-numeric-value arg) 0))
      (unwind-protect
           (progn
             (quail-hide-guidance)
             (quail-delete-overlays)
             (setq describe-current-input-method-function nil))
        (kill-local-variable 'input-method-function))
      (setq inactivate-current-input-method-function 'hangul3-input-inactivate)
      (setq describe-current-input-method-function 'hangul3-input-help)
      (quail-delete-overlays)
      (if (eq (selected-window) (minibuffer-window))
          (add-hook 'minibuffer-exit-hook 'quail-exit-from-minibuffer))
      (set (make-local-variable 'input-method-function)
           'hangul3-input-method)))

(defun hangul3-input-inactivate ()
  "Inactivate Hangul 3-Bulsik input method."
  (interactive)
  (hangul3-input-activate -1))

(defun hangul3-input-help ()
  (interactive)
  (with-output-to-temp-buffer "*Help*"
    (princ "\
Input method: hangul3 (mode line indicator:한3)

New Hangul 3-Bulsik input method.")))

(register-input-method "korean-hangul" "UTF-8" 'hangul2-input-activate "한2"
                       "Hangul 2-Bulsik Input")

(register-input-method "korean-hangul3" "UTF-8" 'hangul3-input-activate "한3"
                       "Hangul 3-Bulsik Input")

(provide 'hangul)

;;; hangul.el ends here
