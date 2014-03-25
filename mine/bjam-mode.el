;; *****************************************************************************
;;
;;  bjam-mode.el
;;  Font-lock support for Boost Jam (bjam) files
;;
;;  Copyright (C) 2009, Per Nordlöw <per.nordlow@gmail.com>
;;
;; *****************************************************************************
;;
;;  This is free software; you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation; either version 2, or (at your option)
;;  any later version.
;;
;;  bjam-mode.el is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;  General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with GNU Emacs; see the file COPYING.  If not, write to the
;;  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;;  Boston, MA 02111-1307, USA.
;;
;; *****************************************************************************
;;
;;  Borrowed a lot from makefile-mode in make-mode.el. Look in that
;;  for inspirations to improvements.
;;
;;  To add font-lock support for Jam files, simply add the line
;;  (require 'bjam-mode) to your .emacs file.
;;
;; *****************************************************************************

;; Sadly we need this for a macro.
(eval-when-compile
  (require 'imenu)
  (require 'dabbrev)
  (require 'add-log)
  (require 'font-lock-extras)
  )

(defconst bjam-imenu-generic-expression
  `(
    ;; Creates an executable file. See the section called “Programs”.
    ("Executables" ,(concat "^\\(exe\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Creates an library file. See the section called “Libraries”.
    ("Libraries" ,(concat "^\\(lib\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Installs built targets and other files. See the section called “Installing”.
    ("Installs" ,(concat "^\\(install\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Creates an alias for other targets. See the section called “Alias”.
    ("Aliases" ,(concat "^\\(alias\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Specialized rules for testing. See the section called “Testing”.
    ("Tests" ,(concat "^\\(compile\\|compile-fail\\|link\\|link-fail\\|run\\|run-fail\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Creates an executable that will be automatically run. See the
    ;; section called “Testing”.
    ("Unit Tests" ,(concat "^\\(unit-test\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Creates an object file. Useful when a single source file must
    ;; be compiled with special properties.
    ("Objects" ,(concat "^\\(obj\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Declares project id and attributes, including project
    ;; requirements. See the section called “Projects”.
    ("Projects" ,(concat "^\\(project\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Assigns a symbolic project ID to a project at a given
    ;; path. This rule must be better documented!
    ("Use Projects" ,(concat "^\\(use-project\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; The explicit rule takes a single parameter—a list of target
    ;; names. The named targets will be marked explicit, and will be
    ;; built only if they are explicitly requested on the command
    ;; line, or if their dependents are built
    ("Explicits" ,(concat "^\\(explicit\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; Sets project-wide constant. Takes two parameters: variable name
    ;; and a value and makes the specified variable name accessible in
    ;; this Jamfile and any child Jamfiles.
    ;; For example: constant VERSION : 1.34.0 ;
    ("Constants" ,(concat "^\\(constant\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; path-constant: Same as constant except that the value is
    ;; treated as path relative to Jamfile location. For example, if
    ;; bjam is invoked in the current directory, and Jamfile in helper
    ;; subdirectory has:
    ;;    path-constant DATA : data/a.txt ;
    ;; then the variable DATA will be set to helper/data/a.txt, and if
    ;; bjam is invoked from the helper directory, then the variable
    ;; DATA will be set to data/a.txt.
    ("Path Constants" ,(concat "^\\(path-constant\\)" "[[:space:]\n]+" "\\([A-Za-z0-9_/.]+\\)" "[[:space:]\n]+" ":") 2)

    ;; http://www.boost.org/doc/libs/1_38_0/doc/html/bbv2/tasks.html#bbv2.reference.precompiled_headers
    ("Precompiled C Headers" "^c-pch[[:space:]\n]+\\([A-Za-z0-9_/.]+\\)[[:space:]\n]+:" 1)
    ("Precompiled C++ Headers" "^cpp-pch[[:space:]\n]+\\([A-Za-z0-9_/.]+\\)[[:space:]\n]+:" 1)

    ("Rules" "^rule[[:space:]\n]+\\([A-Za-z0-9_]+\\)" 1)
    ("Actions" "^actions[[:space:]\n]+\\([A-Za-z0-9_]+\\)" 1)
    )
  "Imenu generic expression for BJam mode.  See `imenu-generic-expression'.")
;; Use: (nth 1 (assoc "Executables" bjam-imenu-generic-expression))

(setq bjam-font-lock-keywords
  (list
    ;; Comment
    (cons "\\b# \\(.*\\)"
          '((1 'font-lock-comment-face t)
            ))

    (cons (nth 1 (assoc "Executables" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-exe-name-face)
            ))

    (cons (nth 1 (assoc "Libraries" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-lib-name-face)
            ))

    (cons (nth 1 (assoc "Installs" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Aliases" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Tests" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Unit Tests" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Projects" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-lib-name-face)
            ))

    (cons (nth 1 (assoc "Use Projects" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-lib-name-face)
            ))

    (cons (nth 1 (assoc "Explicits" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-lib-name-face)
            ))

    (cons (nth 1 (assoc "Constants" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Path Constants" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Precompiled C Headers" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    (cons (nth 1 (assoc "Precompiled C++ Headers" bjam-imenu-generic-expression))
          '((1 'font-lock-builtin-face)
            (2 'font-lock-constant-face)
            ))

    ;; Jam variable references $(foo)
    (cons "$(\\([^ :\\[()\t\r\n]+\\)[)\\[:]"
          '((1 'font-lock-variable-name-face)
            ))
    (cons "<\\(.*\\)>"
          '((1 font-lock-variable-name-face)
            ))

    ;; Jam keywords
    (cons (concat "\\_<"
                  (regexp-opt (list "actions" "bind" "case" "default" "else" "existing" "for" "if"
                                    "ignore" "in" "include" "local" "on" "piecemeal" "quietly" "rule" "switch"
                                    "together" "updated"))
                  "\\_>")
          '((0 'font-lock-keyword-face)
            ))

    ;; Built-in Targets for (Jambase)
    (cons (concat "\\_<"
                  (regexp-opt (list "all" "clean" "dirs" "exe" "files"
                                    "first" "install" "lib" "obj" "shell" "uninstall"
                                    "using" "glob"          ;BJam only
                                    ))
                  "\\_>")
          '((0 'font-lock-builtin-face)
            ))

    ;; Built-in Targets (Warnings)
    (cons (concat "\\_<" (regexp-opt (list "EXIT")) "\\_>")
          '((0 'font-lock-warning-face)
            ))

    ;; Jambase Built-in Variables for (Jambase)
    (cons (concat "\\_<"
                  (regexp-opt (list
                               "ALL_LOCATE_TARGET" "AR" "ARFLAGS" "AS" "ASFLAGS" "AWK" "BCCROOT" "BINDIR" "CC" "CCFLAGS"
                               "C++" "C++FLAGS" "CHMOD" "CP" "CRELIB" "CW" "CWGUSI" "CWMAC" "CWMSL" "DOT" "DOTDOT"
                               "EXEMODE" "FILEMODE" "FORTRAN" "FORTRANFLAGS" "GROUP" "HDRGRIST" "HDRPATTERN" "HDRRULE"
                               "HDRS" "HDRSCAN" "HDRSEARCH" "INSTALL" "JAMFILE" "JAMRULES" "LEX" "LIBDIR" "LINK"
                               "LINKFLAGS" "LINKLIBS" "LOCATE_SOURCE" "LOCATE_TARGET" "LN" "MACINC" "MANDIR" "MKDIR"
                               "MODE" "MSLIB" "MSLINK" "MSIMPLIB" "MSRC" "MSVC" "MSVCNT" "MV" "NEEDLIBS" "NOARSCAN"
                               "OSFULL" "OPTIM" "OWNER" "RANLIB" "RCP" "RELOCATE" "RM" "RSH" "RUNVMS" "SEARCH_SOURCE"
                               "SED" "SHELLHEADER" "SHELLMODE" "SLASH" "SLASHINC" "SOURCE_GRIST" "STDHDRS" "STDLIBPATH"
                               "SUBDIR" "SUBDIRASFLAGS" "SUBDIRC++FLAGS" "SUBDIRCCFLAGS" "SUBDIRHDRS" "SUBDIR_TOKENS"
                               "SUFEXE" "SUFLIB" "SUFOBJ" "UNDEFFLAG" "UNDEFS" "WATCOM" "YACC" "YACCFLAGS" "YACCFILES"))
                  "\\_>")

          '((0 'font-lock-builtin-face)
            ))

    ))

;;                                         ; BJam built-in variables
;;      (generic-make-keywords-list
;;       (list
;;        "JAMDATE" "JAMSHELL" "JAMUNAME" "JAMVERSION" "MAC" "NT" "OS" "OS2"
;;        "OSPLAT" "OSVER" "UNIX" "VMS")
;;       'font-lock-constant-face)

;;                                         ; Jam built-in targets
;;      (generic-make-keywords-list
;;       (list
;;        "ALWAYS" "DEPENDS" "ECHO" "INCLUDES" "LEAVES" "LOCATE" "NOCARE"
;;        "NOTFILE" "NOUPDATE" "SEARCH" "TEMPORARY")
;;       'font-lock-builtin-face)

;;                                         ; BJambase rules
;;      (generic-make-keywords-list
;;       (bjam-mode-quote-keywords
;;        (list
;;         "Archive" "As" "Bulk" "Cc" "CcMv" "C++" "Chgrp" "Chmod" "Chown" "Clean" "CreLib"
;;         "Depends" "File" "Fortran" "GenFile" "GenFile1" "HardLink"
;;         "HdrRule" "Install" "InstallBin" "InstallFile" "InstallInto" "InstallLib" "InstallMan"
;;         "InstallShell" "Lex" "Library" "LibraryFromObjects" "Link" "LinkLibraries"
;;         "Main" "MainFromObjects" "MakeLocate" "MkDir" "MkDir1" "Object" "ObjectC++Flags"
;;         "ObjectCcFlags" "ObjectHdrs" "Objects" "Ranlib" "RmTemps" "Setuid" "SubDir"
;;         "SubDirC++Flags" "SubDirCcFlags" "SubDirHdrs" "SubInclude" "Shell" "Undefines"
;;         "UserObject" "Yacc" "Yacc1" "BULK" "FILE" "HDRRULE" "INSTALL" "INSTALLBIN" "INSTALLLIB"
;;         "INSTALLMAN" "LIBRARY" "LIBS" "LINK" "MAIN" "SETUID" "SHELL" "UNDEFINES"
;;         "addDirName" "makeCommon" "makeDirName" "makeGrist" "makeGristedName" "makeRelPath"
;;         "makeString" "makeSubDir" "makeSuffixed" "unmakeDir"))
;;       'font-lock-function-name-face)

(defun bjam-mode-quote-keywords (keywords)
  "Returns a list of expressions that match each element in KEYWORDS.
For generic-mode, each element is quoted. For generic, each element is unchanged."
  (if (featurep 'generic-mode)
      (mapcar 'regexp-quote keywords)
    keywords))

(defvar bjam-mode-abbrev-table nil
  "Abbrev table in use in BJam buffers.")
(if bjam-mode-abbrev-table
    ()
  (define-abbrev-table 'bjam-mode-abbrev-table ()))

(defvar bjam-mode-map
  (let ((map (make-sparse-keymap))
	)
    ;; set up the keymap
    (define-key map "\C-c\C-c" 'comment-region)

    ;; Make menus.
    (define-key map [menu-bar bjam-mode]
      (cons "BJam" (make-sparse-keymap "BJam")))

    ;; Target related
    (define-key map [menu-bar bjam-mode separator1]  '("----"))
    (define-key map [menu-bar bjam-mode pickup-file]
      '(menu-item "Pick File Name as Target" bjam-pickup-filenames-as-targets
		  :help "Scan the current directory for filenames to use as targets"))
    (define-key map [menu-bar bjam-mode function]
      '(menu-item "Insert GNU make function" bjam-insert-gmake-function
		  :help "Insert a GNU make function call"))
    (define-key map [menu-bar bjam-mode pickup]
      '(menu-item "Find Targets and Macros" bjam-pickup-everything
		  :help "Notice names of all macros and targets in BJam"))
    (define-key map [menu-bar bjam-mode complete]
      '(menu-item "Complete Target or Macro" bjam-complete
		  :help "Perform completion on BJam construct preceding point"))
    (define-key map [menu-bar bjam-mode backslash]
      '(menu-item "Backslash Region" bjam-backslash-region
		  :help "Insert, align, or delete end-of-line backslashes on the lines in the region"))

    ;; Motion
    (define-key map [menu-bar bjam-mode separator]  '("----"))

    map)
  "The keymap that is used in BJam mode.")

(defvar bjam-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "_" table)          ;symbol constituent
    (modify-syntax-entry ?. "_" table)          ;word constituent
    (modify-syntax-entry ?/ "_" table)
    (modify-syntax-entry ?+ "w" table)
    (modify-syntax-entry ?# "<" table)          ;comment starter
    (modify-syntax-entry ?\n ">" table)         ;comment ender
    (modify-syntax-entry ?\" "\"" table)
    table))

(defvar bjam-mode-hook nil)

(defvar bjam-indent-size 2
  "Amount to indent by in bjam-mode")

(defvar bjam-case-align-to-colon t
  "Whether to align case statements to the colons")

(defun bjam-indent-line (&optional whole-exp)
  "Indent current line"
  (interactive)
  (let ((indent (bjam-indent-level))
	(pos (- (point-max) (point))) beg)
    (beginning-of-line)
    (setq beg (point))
    (skip-chars-forward " \t")
    (if (zerop (- indent (current-column)))
	nil
      (delete-region beg (point))
      (indent-to indent))
    (if (> (- (point-max) pos) (point))
	(goto-char (- (point-max) pos)))
    ))

(defun bjam-goto-block-start ()
  "Goto the start of the block containing point (or beginning of buffer if not
   in a block"
  (let ((l 1))
    (while (and (not (bobp)) (> l 0))
      (skip-chars-backward "^{}")
      (unless (bobp)
        (backward-char)
        (setq l (cond
                 ((eq (char-after) ?{) (1- l))
                 ((eq (char-after) ?}) (1+ l))
                 )))
      )
    (bobp))
  )

(defun bjam-indent-level ()
  (save-excursion
    (let ((p (point))
          ind
          (is-block-start nil)
          (is-block-end nil)
          (is-case nil)
          (is-switch nil)
          switch-ind)
      ;; see what's on this line
      (beginning-of-line)
      (setq is-block-end (looking-at "^[^{\n]*}\\s-*$"))
      (setq is-block-start (looking-at ".*{\\s-*$"))
      (setq is-case (looking-at (concat _* "case.*:")))

      ;; goto start of current block (0 if at top level)
      (if (bjam-goto-block-start)
          (setq ind 0)
        (setq ind (+ (current-indentation) bjam-indent-size)))

      ;; increase indent in switch statements (not cases)
      (setq is-switch (re-search-backward "^\\s-*switch" (- (point) 100) t))
      (when (and is-switch (not (or is-block-end is-case)))
        (goto-char p)
        (setq ind (if (and bjam-case-align-to-colon
                           (re-search-backward "^\\s-*case.*?\\(:\\)"))
                      (+ (- (match-beginning 1) (match-beginning 0))
                         bjam-indent-size)
                    (+ ind bjam-indent-size)))
        )

      ;; indentation of this line is bjam-indent-size more than that of the
      ;; previous block
      (cond (is-block-start  ind)
            (is-block-end    (- ind bjam-indent-size))
            (is-case         ind)
            (t               ind)
            )
      )))

;;;###autoload
(defun bjam-mode ()
  "Major mode for editing standard Jamfiles."

  (interactive)
  (kill-all-local-variables)

  ;; Font lock.
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults `(bjam-font-lock-keywords nil))

  ;; Add-log.
  ;; (make-local-variable 'add-log-current-defun-function)
  ;; (setq add-log-current-defun-function 'bjam-add-log-defun)

  ;; Imenu.
  (make-local-variable 'imenu-generic-expression)
  (setq imenu-generic-expression bjam-imenu-generic-expression)

  ;; Dabbrev.
  (make-local-variable 'dabbrev-abbrev-skip-leading-regexp)
  (setq dabbrev-abbrev-skip-leading-regexp "<")

  ;; Other abbrevs.
  (setq local-abbrev-table bjam-mode-abbrev-table)

  ;; Filling.
  (make-local-variable 'fill-paragraph-function)
  (when (require 'make-mode nil t)
    (setq fill-paragraph-function 'makefile-fill-paragraph) ;Note: Reuse makefile
    )

  ;; Comment stuff.
  (make-local-variable 'comment-start) (setq comment-start "#")
  (make-local-variable 'comment-end) (setq comment-end "")
  (make-local-variable 'comment-start-skip) (setq comment-start-skip "#+[ \t]*")

  ;; become the current major mode
  (setq major-mode 'bjam-mode)
  (setq mode-name "BJam")

  ;; Activate keymap and syntax table.
  (use-local-map bjam-mode-map)
  (set-syntax-table bjam-mode-syntax-table)

  ;; Indent
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'bjam-indent-line)

  ;; Real TABs are important in makefiles
  (setq indent-tabs-mode t)
  (run-mode-hooks 'bjam-mode-hook)

  (imenu-add-menubar-index)
  )

(provide 'bjam-mode)

;; bjam-mode.el ends here
