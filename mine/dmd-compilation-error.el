;;; dmd-compilation-error.el --- Parse DMD compilation message.
;;; Author: Per Nordlöw
;;; Commentary:
;;; DMD Compilation Messages Patterns may be needed without having to load
;;; `d-mode' through make compilation for example.
;;; Code:

(require 'compile)
(require 'power-utils)

(defconst dmd-compilation-error-regexp
  (concat "^ *"
          "\\(\\(?:[^@]+@\\)?\\)" ;1: Exception Name: core.exception.AssertError@
          "\\([^(]+?\\)"          ;2: File/Path
          "\\(?:-mixin-[0-9]+\\)?"
          "("
          "\\([0-9]+\\)"                ;3: Line
          ",?\\([0-9]*\\"               ;4: Column
          ")"
          "):"
          "\\s-*"
          "\\(\\(?:Error\\)?\\)"
          "\\(\\(?:Warning\\)?\\)"
          "\\(\\(?:Info\\|Remark\\)?\\)"
          "\\s-*"
          ":?"
          "\\s-*"
          "\\(.*\\)$")
  "Regexp matching a DMD compilation or runtime message.")

(defconst dmd-compilation-error-entry
  `(dmd
    ,dmd-compilation-error-regexp
    2                                ;FILE'th subexpression
    3                                ;LINE'th subexpression
    4                                ;COLUMN'th subexpression
    1                                ;TYPE: 0:info, 1:warning, 2/nil:error
    nil                              ;HYPERLINK/TYPELINK'th named_subexpressions
    ;; HIGHLIGHT...
    (0 'default)
    (1 'error)
    (2 'font-lock-file-name-face)
    (3 'compilation-line-number)
    (4 'compilation-column-number)
    (5 'compilation-error)
    (6 'compilation-warning)
    (7 'compilation-info)
    (8 'font-lock-comment-face))
  "Entry matching a DMD compilation or runtime message.")

(defun dmd-compilation-error-install ()
  "Install dmd-compilation-error."
  ;; TODO Functionize this
  (let ((entry (assq 'dmd
                     compilation-error-regexp-alist-alist)))
    (if entry
        (setcdr entry
                (cdr dmd-compilation-error-entry))
      (add-to-list 'compilation-error-regexp-alist-alist dmd-compilation-error-entry))
    (add-to-list 'compilation-error-regexp-alist 'dmd)))
(dmd-compilation-error-install)

(defun dmd-compilation-error-enable ()
  "Enable dmd-compilation-error."
  (interactive)
  (add-to-list 'compilation-error-regexp-alist 'dmd))

(defun dmd-compilation-error-disable ()
  "Disable dmd-compilation-error."
  (interactive)
  (remove-from-list 'compilation-error-regexp-alist 'dmd))

(provide 'dmd-compilation-error)
;;; dmd-compilation-error.el ends here
