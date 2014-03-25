;;; windata.el --- convert window configuration to list

;; Copyright 2007 Ye Wenbin
;;
;; Author: wenbinye@gmail.com
;; Version: $Id: windata.el,v 0.0 2007/12/13 00:32:15 ywb Exp $
;; Keywords: 
;; X-URL: not distributed yet

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
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

;;; Commentary:
;; This extension is useful when you want save window configuration
;; between emacs sessions or for emacs lisp programer who want handle
;; window layout.

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'windata)

;;; Code:

(eval-when-compile
  (require 'cl))

(defvar windata-named-winconf nil
  "Name of all window configuration")
(defvar windata-data-function 'windata-data-default
  "Function to save window data.
The data should be persistent permanent.")
(defvar windata-data-restore-function 'windata-data-restore-default
  "Function to restore window data.")

(defvar windata-total-width nil
  "Internal variable.")
(defvar windata-total-height nil
  "Internal variable.")

(defun windata-window-width (win)
  (/ (if (windowp win)
         (window-width win)
       (let ((edge (cadr win)))
         (- (nth 2 edge) (car edge)))) windata-total-width))

(defun windata-window-height (win)
  (/ (if (windowp win)
         (window-height win)
       (let ((edge (cadr win)))
         (- (nth 3 edge) (cadr edge)))) windata-total-height))

(defun windata-data-default (win)
  (buffer-name (window-buffer win)))

(defun windata-data-restore-default (win name)
  (and (get-buffer name)
       (set-window-buffer win (get-buffer name))))

(defun windata-window-tree->list (tree)
  (if (windowp tree)
      (funcall windata-data-function tree)
    (let ((dir (car tree))
          (children (cddr tree)))
      (list (if dir 'vertical 'horizontal)
            (if dir
                (windata-window-height (car children))
              (windata-window-width (car children)))
            (windata-window-tree->list (car children))
            (if (> (length children) 2)
                (windata-window-tree->list (cons dir (cons nil (cdr children))))
              (windata-window-tree->list (cadr children)))))))

(defun windata-list->window-tree (conf)
  (let ((newwin
         (if (eq (car conf) 'horizontal)
             (split-window nil (floor (* (cadr conf) windata-total-width)) t)
           (split-window nil (floor (* (cadr conf) windata-total-height))))))
    (if (listp (nth 2 conf))
        (windata-list->window-tree (nth 2 conf))
      (funcall windata-data-restore-function (selected-window) (nth 2 conf)))
    (select-window newwin)
    (if (listp (nth 3 conf))
        (windata-list->window-tree (nth 3 conf))
      (funcall windata-data-restore-function (selected-window) (nth 3 conf)))))

(defun windata-window-path (tree win &optional path)
  (if (windowp tree)
      (if (eq win tree)
          path)
    (let ((children (cddr tree))
          (i 0)
          conf)
      (while children
        (setq conf (windata-window-path (car children) win (append path (list i))))
        (if conf
            (setq children nil)
          (setq i (1+ i)
                children (cdr children))))
      conf)))

(defun windata-current-winconf ()
  (let ((tree (car (window-tree)))
        (windata-total-width (float (frame-width)))
        (windata-total-height (float (frame-height))))
    (cons (windata-window-tree->list tree)
          (windata-window-path tree (selected-window)))))

(defun windata-restore-winconf (winconf)
  (let ((path (cdr winconf))
        (windata-total-width (float (frame-width)))
        (windata-total-height (float (frame-height)))
        tree)
    (delete-other-windows)
    (windata-list->window-tree (car winconf))
    (setq tree (car (window-tree)))
    (while path
      (setq tree (nth (car path) (cddr tree))
            path (cdr path)))
    (select-window tree)))

 
;; An example
(defun windata-name-winconf (name)
  (interactive "sName of window configuration: ")
  (setq windata-named-winconf
        (cons
         (cons name (windata-current-winconf))
         (delq (assoc name windata-named-winconf) windata-named-winconf))))

(defun windata-restore-named-winconf (name)
  (interactive (list (completing-read "Save named window configuration: "
                                      windata-named-winconf nil t)))
  (windata-restore-winconf (assoc-default name windata-named-winconf)))

(provide 'windata)
;;; windata.el ends here
