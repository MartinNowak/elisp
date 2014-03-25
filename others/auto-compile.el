;;; auto-compile.el --- auto compile support for developers.

;; Copyright (C) 2006 Higepon <higepon@users.sourceforge.jp>

;; Version: 0.0.1
;; Author: Higepon <higepon@users.sourceforge.jp>
;; Maintainer: Higepon <higepon@users.sourceforge.jp>
;; Require : compile.el

;; History

;;; Commentary:

;;; What is auto-compile?
;;; When you are writing "hello.c" source code with Emacs.
;;; After you save file with C-x C-s, "make" command runs automatically on background.
;;; So you have no need to change Window to terminal,enter make command, and back to Emacs.

;;; Install
;; (require 'auto-compile)
;; ;; enable auto-compile for your projects
;; (setq auto-compile-target-path-regexp-list (list "Linux" "FreeBSD" "Foo\/src"))

;;; Variables
(defvar auto-compile-auto-update-gtags t "*update gtags if t")
(defvar auto-compile-target-file-regexp-list (list "\.cpp$" "\.h$" "\.c$" "\.asm$") "*target file type")
(defvar auto-compile-target-path-regexp-list (list "src") "*target file type")

;;; Code
(defun auto-compile-after-save-hook ()
  (if (and (auto-compile-target-path-p) (auto-compile-target-file-type-p))
      (progn
        (if auto-compile-auto-update-gtags
            (auto-compile-update-gtags))
        (auto-compile-do-compile))))

(defun auto-compile-do-compile ()
  (let ((makefile (expand-file-name "Makefile")))
    (if (file-exists-p makefile)
      (auto-compile-silent-compile makefile "make" 'auto-compile-do-compile-finish-function))))

(defun auto-compile-do-compile-finish-function (buffer result)
  (if (string-match "abnormally" result)
      (progn
        (setq compilation-finish-function nil)
        (auto-compile-show-compile-error result))
    (message "[auto-compile]:compile ok.")))

;;; Code utilities
(defun auto-compile-show-compile-error (error)
  "show compile result"
  (replace-regexp-in-string "\n" "" error)
  (message "[auto-compile]:%s" error))

(defun auto-compile-silent-compile (makefile command finish-function)
  "Compile with minimum window height."
  (let ((save-height compilation-window-height))
    (save-current-buffer
      (setq compilation-window-height 1)
      (setq compilation-finish-function finish-function)
      (set-buffer (find-file-noselect makefile))
      (ad-activate-regexp "auto-compile-yes-or-no-p-always-yes")
      (message "[auto-compile]:%s at %s" command makefile)
      (compile command)
      (ad-deactivate-regexp "auto-compile-yes-or-no-p-always-yes")
      (setq compilation-window-height save-height))))

(defun auto-compile-target-path-p ()
  "Current buffer is target?"
  (auto-compile-list-or
   (mapcar (lambda (x) (string-match x (buffer-file-name)))
           auto-compile-target-path-regexp-list)))

(defun auto-compile-target-file-type-p ()
  "Current buffer is source file?"
  (auto-compile-list-or
   (mapcar (lambda (x) (string-match x (buffer-file-name)))
           auto-compile-target-file-regexp-list)))

(defun auto-compile-list-or (list)
  (if (consp list)
      (or (car list) (auto-compile-list-or (cdr list)))))

(defun auto-compile-update-gtags ()
  "Update GTAGS file"
  (let ((status (call-process "global" nil nil nil "-uv")))
    (if (= status 0)
        (message "[auto-compile]:GTAGS updated"))))

(defun auto-compile-cleanup ()
  "Clean up add-hooks for auto-compile.el."
  (remove-hook 'after-save-hook 'auto-compile-after-save-hook)
  (setq compilation-finish-function nil))

(defadvice yes-or-no-p (around auto-compile-yes-or-no-p-always-yes)
  "Return always yes."
  (setq ad-return-value t))

(defadvice compilation-start (around auto-compile-compilation-start)
  (message "[auto-compile]:now compiling")
  ad-do-it)

;;; Code install
(auto-compile-cleanup)
(add-hook 'after-save-hook 'auto-compile-after-save-hook)
(ad-activate-regexp "auto-compile-compilation-start")

(provide 'auto-compile)
