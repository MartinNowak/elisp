;;; list-register.el
;; -*- Mode: Emacs-Lisp -*-

;;  $Id: list-register.el,v 1.2 2003/06/27 13:18:05 akihisa Exp $

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Install:

;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;;     (require 'list-register)

;; The latest version of this program can be downloaded from
;; http://www.bookshelf.jp/elc/list-register.el

;; M-x list-register

(defvar list-register-buffer "*reg Output*")
(defvar list-register-edit-buffer "*Edit Register*")

(defvar list-register-mode-map nil "")
(defvar list-register-edit-mode-map nil "")

(or list-register-mode-map
    (let ((map (make-sparse-keymap)))
      (define-key map "e"
        (function list-register-edit-text))
      (define-key map "\C-m"
        (function list-register-insert))
      (define-key map "q"
        (function list-register-quit))
      (define-key map "+"
        (function list-register-increment))
      (define-key map "-"
        (function list-register-decrement))
      
      (setq list-register-mode-map map)
      ))

(or list-register-edit-mode-map
    (let ((map (make-sparse-keymap)))
      (define-key map "\C-c\C-c"
        (function list-register-edit-quit))
      (define-key map "\C-c\C-q"
        (function list-register-edit-cancel))
      (define-key map "\C-c\C-s"
        (function list-register-edit-set-register))
      (setq list-register-edit-mode-map map)
      ))

(defun list-register-quit ()
  (interactive)
  (set-buffer list-register-parent-buffer)
  (condition-case ()
      (delete-window (get-buffer-window list-register-buffer))
    (error ))
  (kill-buffer list-register-buffer))

(defun list-register-change-number (num)
  (let (reg str)
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward "^[ \n]*\\([^\n:]+\\):[ \n]*\\([^:\n]+\\):.+$"
                             (line-end-position) t)
          (progn
            (setq reg (buffer-substring
                       (match-beginning 1) (match-end 1)))
            (setq str (buffer-substring
                       (match-beginning 2) (match-end 2)))))
      (if (string-match "num" str)
          (increment-register num (string-to-char reg))
        (message "Register does not contain a number!"))
      ))
  (list-register-review)
  )

(defun list-register-increment (num)
  (interactive "nIncrement Num: ")
  (list-register-change-number num))
  
(defun list-register-decrement (num)
  (interactive "nDecrement Num: ")
  (list-register-change-number (* -1 num)))

;; edit register
(defun list-register-edit-text-do (reg)
  (switch-to-buffer (get-buffer-create list-register-edit-buffer))
  (erase-buffer)
  (insert-register (string-to-char reg))
  (kill-all-local-variables)
  (make-local-variable 'list-register-edit-reg)
  (setq list-register-edit-reg reg)
  
  (use-local-map list-register-edit-mode-map))

(defun list-register-edit-text ()
  (interactive)
  (let (reg str)
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward "^[ \n]*\\([^\n:]+\\):[ \n]*\\([^:\n]+\\):.+$"
                             (line-end-position) t)
          (progn
            (setq reg (buffer-substring
                       (match-beginning 1) (match-end 1)))
            (setq str (buffer-substring
                       (match-beginning 2) (match-end 2)))))
      (if (string-match "[0-9]+" str)
          (list-register-edit-text-do reg)
        (message "Register does not contain a text!"))
      ))
  )

(defun list-register-edit-quit ()
  (interactive)
  (set-register 
   (string-to-char list-register-edit-reg)
   (buffer-substring (point-min) (point-max)))
  ;;(delete-window (get-buffer-window list-register-edit-buffer))
  (kill-buffer list-register-edit-buffer)
  (switch-to-buffer list-register-buffer)
  (list-register-review)
  )

(defun list-register-edit-set-register (char)
  (interactive "cCopy to register: ")
  (set-register 
   char
   (buffer-substring (point-min) (point-max)))
  ;;(delete-window (get-buffer-window list-register-edit-buffer))
  (kill-buffer list-register-edit-buffer)
  (switch-to-buffer list-register-buffer)
  (list-register-review)
  )

(defun list-register-edit-cancel ()
  (interactive)
  (kill-buffer list-register-edit-buffer)
  (switch-to-buffer list-register-buffer))

(defun list-register-insert ()
  (interactive)
  (let (reg str)
    (save-excursion
      (beginning-of-line)
      (if (re-search-forward "^[ \n]*\\([^\n:]+\\):[ \n]*\\([^:\n]+\\):.+$"
                             (line-end-position) t)
          (progn
            (setq reg (buffer-substring
                       (match-beginning 1) (match-end 1)))
            (setq str (buffer-substring
                       (match-beginning 2) (match-end 2)))))

      (set-buffer list-register-parent-buffer)
      (cond
       ((or
         (string-match "file" str)
         (string-match "conf" str)
         (string-match "pos" str))
        (jump-to-register (string-to-char reg)))
       ((or
         (string-match "num" str)
         (string-match "[0-9]+" str))
        (insert-register (string-to-char reg))
        (condition-case ()
            (delete-window (get-buffer-window list-register-buffer))
          (error ))
        (kill-buffer list-register-buffer)
        ))
      )))

(defun list-register-print-text (arg)
  (interactive "p")
  (let ((x (get-register arg)) (w (- (window-width) 15)))
    (setq str (split-string x "\n"))
    (setq strtmp str)
    (setq lines (format "%4d" (length str)))
    (setq str (mapconcat (lambda (y) y) str " "))
    (if (string-match "^[ \t]*$" str)
        ()
      (insert (format "%s: %s\n" lines
                      (truncate-string
                       (mapconcat (lambda (y) y) strtmp
                                  "^J") w)))
      (setq prev str))))

(defun list-register ()
  (interactive)
  (let ((lst register-alist) val reg st (pbuf (current-buffer)))
    (with-output-to-temp-buffer list-register-buffer
      (set-buffer list-register-buffer)
      (kill-all-local-variables)
      
      (make-local-variable 'list-register-parent-buffer)
      (setq list-register-parent-buffer pbuf)
      
      (use-local-map list-register-mode-map)
      
      (princ "List of register\n")
      (setq st (point))
      (while lst
        (setq reg (car lst))
        (setq lst (cdr lst))
        (princ
         (concat
          ;;"-------------------------------------------------\n"
          (format "%3s" 
                  (single-key-description (car reg)))
          ":"))
        (setq val (get-register (car reg)))
        (cond
         ((numberp val)
          (insert " num:")
          (insert (int-to-string val))
          (insert "\n"))

         ((markerp val)
          (insert " pos:")
          (let ((buf (marker-buffer val)))
            (if (null buf)
                (insert "a marker in no buffer")
              (insert "a buffer position:")
              (insert (buffer-name buf))
              (insert ", position ")
              (insert (int-to-string (marker-position val)))
              (insert "\n"))))

         ((and (consp val) (window-configuration-p (car val)))
          (insert "conf:a window configuration.\n"))

         ((and (consp val) (frame-configuration-p (car val)))
          (insert "conf:a frame configuration.\n"))

         ((and (consp val) (eq (car val) 'file))
          (insert "file:")
          (prin1 (cdr val))
          (insert ".\n"))

         ((and (consp val) (eq (car val) 'file-query))
          (insert "file:a file-query reference: file ")
          (insert (car (cdr val)))
          (insert ", position ")
          (insert (int-to-string (car (cdr (cdr val)))))
          (insert ".\n"))

         ((consp val)
          (setq lines (format "%4d" (length val)))
          (insert (format "%s: %s\n" lines
                          (truncate-string
                           (mapconcat (lambda (y) y) val
                                      "^J") (- (window-width) 15)))))
          
         ((stringp val)
          (list-register-print-text (car reg))
          )
         
         (t
          ;;(insert "Garbage:\n")
          ;;(prin1 val))
          )))
      (sort-lines nil st (point-max))
      (setq buffer-read-only t)
      )
    )
  (pop-to-buffer list-register-buffer)
  )

(defun list-register-review ()
  (let ((pbuf list-register-parent-buffer)
        (cp (current-line)))
    (list-register)
    (next-line (- cp 1))
    (setq list-register-parent-buffer pbuf)))

(defun my-jump-to-register (&optional arg)
  (interactive)
  (let (char)
    (message "Jump to register: ")
    (list-register)
    (setq char (read-char))
    (jump-to-register char arg)))

(defun data-to-resgister (arg)
  (interactive "P")
  (let ((char))
    (message "Copy to register: ")
    (setq char (read-char))
    (cond
     (mark-active
      (if (and
           (not (= (save-excursion (goto-char (region-beginning)) (current-column))
                   (save-excursion (goto-char (region-end)) (current-column))))
           (not (= (save-excursion (goto-char (region-beginning)) (current-line))
                   (save-excursion (goto-char (region-end)) (current-line)))))
          (if (y-or-n-p "Rectangle? ")
              (progn
                (copy-rectangle-to-register
                 char (region-beginning) (region-end) arg))
            (set-register char (buffer-substring (region-beginning) (region-end)))
            (if arg
                (delete-region (region-beginning) (region-end)))
            )))
     (t 
      (message "f)rame w)indow p)oint")
      (let ((c (char-to-string (read-char))))
        (cond
         ((string-match "f" c)
          (frame-configuration-to-register char arg))
         ((string-match "w" c)
          (window-configuration-to-register char arg))
         ((string-match "p" c)
          (point-to-register char arg)))))
     )))

(provide 'list-register)
;;; list-register.el ends here
