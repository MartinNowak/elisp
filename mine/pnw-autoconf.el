;;; pnw-autoconf.el --- mode for editing Autoconf configure.in files

;; Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008
;; Free Software Foundation, Inc.

;; Author: Dave Love <fx@gnu.org>
;; Keywords: languages

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides fairly minimal font-lock, imenu and indentation support
;; for editing configure.in files.  Only Autoconf syntax is processed.
;; There is no attempt to deal with shell text -- probably that will
;; always lose.

;; This is specialized for configure.in files.  It doesn't inherit the
;; general M4 stuff from M4 mode.

;; There is also an autoconf-mode.el in existence.  That appears to be
;; for editing the Autoconf M4 source, rather than configure.in files.

;;; Code:

(eval-when-compile (require 'cl))
(require 'filedb)
(require 'tscan)

(defvar font-lock-syntactic-keywords)

(defvar autoconf-mode-map nil
  "Keymap used in Shell-Script mode.")
(setq autoconf-mode-map
  (let ((map (make-sparse-keymap))
	(menu-map (make-sparse-keymap)))

    (define-key map [menu-bar autoconf] (cons "Autoconf" menu-map))

    ;;(define-key menu-map [sh-s0] '("--"))

    ;; Insert
    (define-key menu-map [autoconf-macro]
      '(menu-item "Macro..." autoconf-macro
		  :help "Insert a macro call"))
    map))

(defvar autoconf-macro-files ()
  "List of Autoconf files currently online."
  )

(defvar autoconf-macro-list ()
  "List of Autoconf macros currently online."
  )

(defconst autoconf-macro-defun-regexp
  (concat "^AC_DEFUN(\\[\\([[:alnum:]_-]*\\)\\]")
  "Matches an Autoconf macro AC_DEFUN definition."
  )

(defun autoconf-scan-macro-definition (filename)
  "Scan macro defintions from FILENAME and return them as a list
of strings."
  (let ((defs `(,filename)))
    (with-temp-buffer
      (insert-file-contents-literally filename)
      (while (re-search-forward autoconf-macro-defun-regexp nil t)
        (let ((def (match-string-no-properties 1)))
          (save-excursion
            ;; try to find the doc string
            (let ((def
                   (if (re-search-backward
                        (concat "^" "\\(?:dnl\\|#\\)" "[[:space:]]*" "\\(?:Usage:\\)?" "[[:space:]]*"
                                "\\(" (regexp-quote def)
                                "\\(?:" "[[:space:]]*" "(" ".*" ")" "\\)?" "\\)" "\\.?" "$") nil t)
                       (progn
                         ;; ToDo: Use forward-sexp() instead here.
                         (match-string-no-properties 1 )        ;use comment doc declaration
                         )
                     ;;(message "No doc comment found for %s in file %s" def filename)
                     def)))                      ;otherwise default to @c AC_DEFUN argument
              (setq defs (nconc defs `(,def))))))))
    defs))
;; Use: (autoconf-scan-macro-definition "/usr/share/aclocal/gettext.m4")
;; Use: (autoconf-scan-macro-definition "/usr/share/aclocal/lib-link.m4")
;; Use: (autoconf-scan-macro-definition "/usr/share/aclocal/inttypes_h.m4")
;; Use: (autoconf-scan-macro-definition "/usr/share/aclocal/fontutil.m4")
;; Use: (autoconf-scan-macro-definition "/usr/share/aclocal/freetype2.m4")

(defun autoconf-assert-macros ()
  "Assert Autoconf macros has been loaded into
`autoconf-macro-list'."
  (unless autoconf-macro-files        ;if not yet built
    (message "Scanning for Autoconf macros...")
    (setq autoconf-macro-files        ;build it
          (append
           (directory-files "/usr/share/aclocal/" t "\\.m4\\'")
           (if (file-exists-p "/usr/local/share/aclocal/")
               (directory-files "/usr/local/share/aclocal/" t "\\.m4\\'"))
           (if (file-exists-p "/usr/share/autoconf-archive/")
               (directory-files "/usr/share/autoconf-archive/" t "\\.m4\\'"))
           (if (file-exists-p "~/alt/share/aclocal/")
               (directory-files "~/alt/share/aclocal/" t "\\.m4\\'"))
           ))
    (delete-duplicates autoconf-macro-files)
    (setq autoconf-macro-list (mapcar 'autoconf-scan-macro-definition autoconf-macro-files))
    (message "Scanning for Autoconf macros done.")
    autoconf-macro-list)
  )
;; Use: (setq autoconf-macro-files nil)
;; Use: (autoconf-assert-macros)

(add-hook 'autoconf-mode-hook 'autoconf-assert-macros)

(defun autoconf-macro ()
  (interactive)
  (insert (completing-read "Autoconf macro to insert: " autoconf-macro-list))
  )
;; Test (autoconf-macro)

(defvar autoconf-mode-hook nil
  "Hook run by `autoconf-mode'.")

(defconst autoconf-font-lock-syntactic-keywords
  '(("\\<dnl\\>" 0 '(11))))

(defconst autoconf-definition-regexp
  "AC_\\(SUBST\\|DEFINE\\(_UNQUOTED\\)?\\)(\\[*\\(\\sw+\\)\\]*")

(defvar autoconf-font-lock-keywords
  `(("\\_<A[CHMS]_\\sw+" . font-lock-keyword-face)
    (,autoconf-definition-regexp
     3 font-lock-function-name-face)
    ;; Are any other M4 keywords really appropriate for configure.in,
    ;; given that we do `dnl'?
    ("changequote" . font-lock-keyword-face)))

(defvar autoconf-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" "." table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?# "<" table)
    table))

(defvar autoconf-imenu-generic-expression
  (list (list nil autoconf-definition-regexp 3)))

;; It's not clear how best to implement this.
(defun autoconf-current-defun-function ()
  "Function to use for `add-log-current-defun-function' in Autoconf mode.
This version looks back for an AC_DEFINE or AC_SUBST.  It will stop
searching backwards at another AC_... command."
  (save-excursion
    (with-syntax-table (copy-syntax-table autoconf-mode-syntax-table)
      (modify-syntax-entry ?_ "w")
      (if (re-search-backward autoconf-definition-regexp
			      (save-excursion (beginning-of-defun) (point))
			      t)
	  (match-string-no-properties 3)))))

;;;###autoload
(defun autoconf-mode ()
  "Major mode for editing Autoconf configure.in files."
  (interactive)
  (kill-all-local-variables)
  (use-local-map autoconf-mode-map)
  (setq major-mode 'autoconf-mode)
  (setq mode-name "Autoconf")
  (set-syntax-table autoconf-mode-syntax-table)
  (set (make-local-variable 'parens-require-spaces) nil) ; for M4 arg lists
  (set (make-local-variable 'defun-prompt-regexp)
       "^[ \t]*A[CM]_\\(\\sw\\|\\s_\\)+")
  (set (make-local-variable 'comment-start) "dnl ")
  (set (make-local-variable 'comment-start-skip) "\\(?:\\<dnl\\|#\\) +")
  (set (make-local-variable 'font-lock-syntactic-keywords)
       autoconf-font-lock-syntactic-keywords)
  (set (make-local-variable 'font-lock-defaults)
       `(autoconf-font-lock-keywords nil nil (("_" . "w"))))
  (set (make-local-variable 'imenu-generic-expression)
       autoconf-imenu-generic-expression)
  (set (make-local-variable 'imenu-syntax-alist) '(("_" . "w")))
  (set (make-local-variable 'indent-line-function) #'indent-relative)
  (set (make-local-variable 'add-log-current-defun-function)
	#'autoconf-current-defun-function)
  (run-mode-hooks 'autoconf-mode-hook))

(provide 'pnw-autoconf-mode)

;; arch-tag: 4f44778f-2ab3-49a1-a103-f0acb9df2de4
;;; autoconf.el ends here
