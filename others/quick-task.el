;;; quick-task.el --- Execute common tasks quickly

;; Copyright (C) 2007-2008 by Stefan Reichoer

;; Author: Stefan Reichoer, <stefan@xsteve.at>

;; quick-task.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; quick-task.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; quick-task.el provides several features to execute custom emacs functions
;; using very few keystrokes
;; For a function that is needed repeatedly, there is only one keystroke necessary!!

;; quick-task.el respects global and local targets
;; the global targets (stored in quick-task-global-targets) should be defined
;; in your .emacs. These settings are always available.
;; The local settings can be calculated in .quick-task.el files
;; (see the variable quick-task-local-targets)

;; The targets are described as lists of tuples. Each tuple consists
;; of a description (a string) and either a function or a menu, see
;; the usage below for examples.

;; The latest version of quick-task.el can be found at:
;; http://www.xsteve.at/prg/emacs/

;; Usage:
;; put the following in your .emacs:
;; (require 'quick-task)
;; (global-set-key [f8] 'quick-task)

;; Here is an example .quick-task.el file:
;; (setq quick-task-local-targets '(("quick-task-fun" my-quick-task-fun)
;;                                  ("quick-task-menu" my-quick-task-menu)))
;;
;; (defun my-quick-task-fun ()
;;   (interactive)
;;   (message "my-quick-task-fun called!"))
;;
;; (defun my-quick-task-build1 ()
;;   (interactive)
;;   (message "my-quick-task-build1 called!"))
;;
;; (defun my-quick-task-ediff-proj1 ()
;;   (interactive)
;;   (ediff-directories "/mnt/projects/proj1/" "/home/xsteve/projects/proj1/" nil))
;;
;; (defun my-quick-task-scons-proj1 ()
;;   (interactive)
;;   (message "Running scons for proj1")
;;   (let ((default-directory "c:/projekte/proj1/"))
;;     (compile "scons")))
;;
;; (quick-task-define-menu my-quick-task-menu
;;   '(("Build"
;;      ["software" my-quick-task-build1]
;;      ["1: scons proj1" my-quick-task-scons-proj1]
;;      )
;;     ("other"
;;      ["fun" my-quick-task-fun]
;;      )
;;     ["ediff proj1" my-quick-task-ediff-proj1]
;;     ["9: another fun" my-quick-task-fun]
;;     ("find-file"
;;      [open "*e:*~/.emacs"]
;;      [open "*q:*.quick-task.el*/home/stefan/site-lisp/xsteve/.quick-task.el"]
;;      )
;;    ("dired"
;;     [open  "*u:*/media/usb0"]
;;     [open2 "*h:*/media/sda2/hpodder"]
;;     [open  "*d:*~/Desktop"]
;;     )
;;     ))

;; Hitting C-u F8 allows to select a target. The selected target is
;; executed immediately.
;; Hitting F8 executes the previously selected action without asking.

;; The convenience function quick-task-make-quick-task-function
;; defines a function for a single action. This is useful to bind a
;; menu to a key. The following example binds the key F10 to provide
;; the my-quick-task-menu
;; (global-set-key [f10] (quick-task-make-quick-task-function my-quick-task-menu-func my-quick-task-menu))
;; my-quick-task-menu functions can now be accessed by the following keystrokes:
;; F10 b s    :  run my-quick-task-menu
;; F10 b 1    :  run my-quick-task-scons-proj1
;; F10 o f    :  run my-quick-task-fun
;; F10 e      :  run my-quick-task-ediff-proj1
;; F10 9      :  run my-quick-task-fun
;; F10 f e    :  open the file ~/.emacs
;; F10 f q    :  open the file /home/stefan/site-lisp/xsteve/.quick-task.el
;; F10 d u    :  open the dired buffer for /media/usb0/
;; F10 d h    :  open the dired buffer for /media/sda2/hpodder/ in the other window
;; F10 d d    :  open the dired buffer for ~/Desktop/

;; Please contact me, if you find quick-task.el useful, or if you have ideas for improvements.

;;; History:
;;

;;; Code:

(defvar quick-task-quick-task-el-file-name ".quick-task.el")
(defvar quick-task-global-targets nil "A list of global targets for quick-task.")

;; Variables that are meant for .quick-task.el
(defvar quick-task-local-targets nil "A list of global targets for
quick-task.

These targets should be defined in files named `quick-task-quick-task-el-file-name'")

(defvar quick-task-selected-action nil "An action that should be used without prompting.
That variable is meant to be set in a file called `quick-task-quick-task-el-file-name'")

;; TODO: add scons support
;;(defvar quick-task-scons-cmd "scons")

(defvar quick-task-completing-read-function (if (fboundp 'ido-completing-read) 'ido-completing-read 'completing-read))


;; Internal variables
(defvar quick-task-last-selected nil)

(defun quick-task-prepare-menu (menu)
  (mapc (lambda (elt)
          (let ((val (if (listp elt) (quick-task-prepare-menu elt) elt))
                (f-name)
                (f-list)
                (label)
                (cmd))
            (cond ((vectorp val)
                   (setq cmd (aref val 0))
                   (when (memq cmd '(open open2))
                     (setq f-list (mapcar '(lambda (elt) (unless (eq (length elt) 0) elt)) (split-string (aref val 1) "*")))
                     ;; (message "f-list: %S %d" f-list (length f-list))
                     (cond ((eq (length f-list) 1)
                            ;; e.g. "~/.emacs" => ("~/.emacs")
                            (setq f-name (car f-list))
                            (setq label (format "open: %s" f-name)))
                           ((eq (length f-list) 3)
                            ;; e.g. "*e:*~/.emacs" => ("" "e:" "~/.emacs")
                            (setq f-name (nth 2 f-list))
                            (setq label (format "%s open %s" (cadr f-list) f-name)))
                           ((eq (length f-list) 4)
                            ;; e.g. "*e:*.emacs*~/.emacs" => ("" "e:" ".emacs" "~/.emacs")
                            (setq f-name (nth 3 f-list))
                            (setq label (format "%s open %s" (cadr f-list) (nth 2 f-list)))))
                     (aset val 0 label)
                     (aset val 1 (if (eq cmd 'open)
                                     `(lambda () (interactive) (find-file ,f-name))
                                   `(lambda () (interactive) (find-file-other-window ,f-name))))))
                  ((listp val)
                   ;; (message "listp: %S" val)
                   (quick-task-prepare-menu val)))))
        menu))

(put 'quick-task-define-menu 'lisp-indent-function 'defun)
(defmacro quick-task-define-menu (symbol menu)
  `(easy-menu-define ,symbol nil
     "quick-task command menu"
     (append '("quick-task-menu") (quick-task-prepare-menu (copy-tree ,menu t)))))

(defmacro quick-task-make-quick-task-function (function-name action)
  "Create function called FUNCTION-NAME.
The created function can be called interactively and it executes
ACTION via `quick-task-do-action'."
  `(defun ,function-name ()
     ,(format "A quick-task function for `%s'." action)
     (interactive)
     (quick-task-do-action (quote ,action))))

(defun quick-task (force-ask)
  "Execute a quick-task.
This function will either call a custom function or display a custom menu via `tmm-prompt'.

The possibilities are defined in the variables `quick-task-local-targets' and `quick-task-global-targets'."
  (interactive "P")
  (setq quick-task-selected-action nil)
  (when (file-exists-p quick-task-quick-task-el-file-name)
    (load (expand-file-name quick-task-quick-task-el-file-name)))
  (let* ((targets (append (copy-sequence quick-task-local-targets) quick-task-global-targets))
         (selected (if (and quick-task-selected-action (not force-ask))
                       quick-task-selected-action
                     (if (or force-ask (not quick-task-last-selected))
                         (funcall quick-task-completing-read-function "Select quick-task Action: " targets)
                       quick-task-last-selected)))
         (action (or (assoc selected targets) selected))
         (description))
    (if (consp action)
        (progn
          (setq description (car action))
          (setq action (cadr action)))
      (setq description action))
    (unless quick-task-selected-action
      (setq quick-task-last-selected selected))
    ;; (message "quick-task: %s (%s)" action description)
    (quick-task-do-action action)))

(defun quick-task-do-action (action)
  "Executes a quick-task action.
The action can be a menu that was defined via `quick-task-define-menu'
or a function."
  (cond ((and (symbolp action) (condition-case nil (keymapp (eval action)) (error nil)))
         (tmm-prompt (eval action)))
        ((functionp action)
         (funcall action))))

(provide 'quick-task)

;;; arch-tag: 28fd99a7-f451-407a-adf1-c050572dec05
;;; quick-task.el ends here
