;;; repository-root.el --- deduce the repository root directory for a given file

;; Copyright (C) 2008 Avi Rozen

;; Author: Avi Rozen <avi.rozen@gmail.com>
;; Keywords: project, repository, root
;; Version: %Id: 1%

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides a utility for deducing the repository root directory
;; for a given file, based on pre-defined or user provided matching criteria.
;;
;; It is specifically designed to be useful in a heterogeneous environment,
;; where the developer is using several source control tools and types of
;; projects.
;;
;; Once the repository root directory is deduced, it is cached (per buffer) for
;; future reference in subsequent calls to repository-root.
;;
;; In itself this library isn't that useful - it's meant to be used by
;; other libraries that may benefit from knowing where the repository root
;; directory resides (e.g. for limiting search effort).
;;
;; Installation:
;;
;; 1. Put this file in a directory that is a member of load-path, and
;;    byte-compile it (e.g. with `M-x byte-compile-file') for better
;;    performance.
;; 2. Add the following to your ~/.emacs:
;;    (require 'repository-root)
;; 
;; Usage:
;;
;; 1. add repository root matching criterions to the list repository-root-matchers
;;    either directly:
;;       (add-to-list 'repository-root-matchers repository-root-matcher/git)
;;    or via the repository-root customization group.
;;
;;    you should order the matchers in increasing order of matching likelihood:
;;    the matcher most likely to match should be first on the list.
;;
;; 2. use the function (repository-root path) to find the repository root directory 
;;    corresponding to the given path string - this is the first parent directory
;;    that is matched by at least one criterion in repository-root-matchers.
;;
;; Currently, the following repository root matching criterions are supported:
;; 
;; 1. Pre-defined (built-in) matchers (e.g. repository-root-matcher/git).
;;
;; 2. Rules: a matching rule together with path string snippet. The default
;;    rule is that the path string has to match a file or directory in the repository
;;    root directory, but not in any of the repository's sub-directory.
;;
;; 3. Functions: with two input strings (parent-path-to-test path),
;;    that returns non-nil if parent-path-to-test is the repository root directory
;;    corresponding to the given path string.
;;    If the return value is a string, it is treated as the end-result root directory.
;;    This may be useful if you have your own directory search method.
;;

;;; Code:

;; Matching rules:

(defun repository-root-match-string (matcher path)
  "Test if PATH/MATCHER is a valid path (directory or file)."
  (let ((path-to-test (expand-file-name matcher path)))
    (or (file-exists-p path-to-test)
        (file-directory-p path-to-test))))

(defun repository-root-match-regexp-any (re files)
  "Test if RE regexp matches any file/directory name in FILES."
  (when files
    (or (string-match re (car files))
        (repository-root-match-regexp-any re (cdr files)))))

(defun repository-root-match-regexp (re path)
  "Test if regexp RE matches any file/directory name under PATH."
  (repository-root-match-regexp-any re (file-name-all-completions "" path)))

(defun repository-root-rule/root-contains (parent-path-to-test path path-snippet)
  "Test if PATH-SNIPPET exists under PARENT-PATH-TO-TEST.
The first path to match will be returned as the repository root."
  (repository-root-match-string path-snippet parent-path-to-test))

(defun repository-root-rule/all-dirs-contain (parent-path-to-test path path-snippet)
  "Test if PATH-SNIPPET exists under PARENT-PATH-TO-TEST but does not
exist in its parent directory.
This means that all repository directories must contain PATH-SNIPPET."
  (and (repository-root-match-string path-snippet parent-path-to-test)
       (not (repository-root-match-string path-snippet (file-name-directory (directory-file-name parent-path-to-test))))))

(defun repository-root-tail-regexp (re)
  "Construct regular expression from RE to match path string tail."
  (concat ".*\\(" re "\\)/$"))

(defun repository-root-rule/root-dir-regexp (parent-path-to-test path re)
  "Test if RE regexp matches the tail of PARENT-PATH-TO-TEST."
  (string-match (repository-root-tail-regexp re) parent-path-to-test))

(defun repository-root-rule/root-contains-regexp (parent-path-to-test path re)
  "Test if RE regexp matches file(s) under PARENT-PATH-TO-TEST.
The first path to match will be returned as the repository root."
  (repository-root-match-regexp re parent-path-to-test))

(defun repository-root-rule/all-dirs-contain-regexp (parent-path-to-test path re)
  "Test if RE regexp matches file(s) in PARENT-PATH-TO-TEST but does not
match files in its parent directory.
This means that all repository directories must contain at least one file/directory
that matches RE."
  (and (repository-root-match-regexp re parent-path-to-test)
       (not (repository-root-match-regexp re (file-name-directory (directory-file-name parent-path-to-test))))))

;; Predefined matchers: 

(defconst repository-root-matcher/ignore (lambda (parent-path-to-test path) nil)
  "Dummy matching criterion."
  )

(defconst repository-root-matcher/git (cons 'repository-root-rule/root-contains ".git/")
  "Git repository root directory matching criterion."
  )

(defconst repository-root-matcher/hg (cons 'repository-root-rule/root-contains ".hg/")
  "Mercurial repository root directory matching criterion."
  )

(defconst repository-root-matcher/darcs (cons 'repository-root-rule/root-contains "_darcs/")
  "Darcs repository root directory matching criterion."
  )

(defconst repository-root-matcher/debian (cons 'repository-root-rule/root-contains "debian/rules")
  "Debian source package root directory matching criterion."
  )

(defconst repository-root-matcher/autoconf (cons 'repository-root-rule/root-contains-regexp "configure\\(\\.ac\\)?")
  "Autoconf source package root directory matching criterion."
  )

(defconst repository-root-matcher/bk (cons 'repository-root-rule/root-contains "BitKeeper/etc/SCCS/s.config")
  "BitKeeper repository root directory matching criterion."
  )

(defconst repository-root-matcher/arch (cons 'repository-root-rule/root-contains "{arch}/=tagging-method")
  "Arch repository root directory matching criterion."
  )

(defconst repository-root-matcher/bzr (cons 'repository-root-rule/root-contains ".bzr/checkout/format")
  "Bazaar repository root directory matching criterion."
  )

(defconst repository-root-matcher/svn (cons 'repository-root-rule/all-dirs-contain ".svn/entries")
  "Subversion repository root directory matching criterion."
  )

(defconst repository-root-matcher/cvs (cons 'repository-root-rule/all-dirs-contain "CVS/Root")
  "CVS repository root directory matching criterion."
  )

(defconst repository-root-matcher/src (cons 'repository-root-rule/root-dir-regexp "\\(src\\|source\\)")
  "Generic source code root directory matching criterion."
  )

(defconst repository-root-matcher/kernel (cons 'repository-root-rule/root-dir-regexp "/usr/src/linux\[^/\]*")
  "Linux Kernel source tree root directory matching criterion."
  )

;; Customization:

(require 'widget)
(require 'wid-edit)

(defgroup repository-root nil
  "Deduce the repository root directory for a given file."
  :group 'files
  :group 'convenience
  :prefix "repository-root-")


(defvar repository-root-builtin-matchers (apropos-internal "repository-root-matcher/")
  "List of predefined built-in matchers.
Use `repository-root-add-builtin-matcher' to add new items to this list."
  )

(defun repository-root-add-builtin-matcher (matcher)
  "Add MATCHER to list of predefined built-in matchers
`repository-root-builtin-matchers'.
This allows an external library to add its own repository root matchers
to the list that's used to validate customization user input."
  (add-to-list 'repository-root-builtin-matchers matcher))

(defun repository-root-builtin-matcher-p (widget)
  "Check if WIDGET value is a predefined built-in matcher." 
  (let ((matcher (widget-value widget)))
    (if (member matcher repository-root-builtin-matchers)
        nil
      (widget-put widget :error "Matcher unknown (not a member of repository-root-builtin-matchers).")
      widget)))

(defun repository-root-valid-rule-p (widget)
  "Check if WIDGET value is a valid rule.
Specifically validates regular expressions if the rule name
contains the string 'regexp'."
  (let* ((rule (widget-value widget))
         (re (cdr rule)))
    (if (string-match ".*regexp.*" (symbol-name (car rule)))
        (condition-case data
            (prog1 nil
              (string-match (repository-root-tail-regexp re) "")
              (error (widget-put widget :error (error-message-string data))
                     widget))
          nil))))

(defcustom repository-root-matchers nil
  "List of repository root directory matching criterions.
Currently, the following repository root matching criterions are supported:
* Pre-defined (built-in) matchers (e.g. `repository-root-matcher/git').
* Rules: a matching rule together with path string snippet. The default
rule is that the path string has to match a file or directory in the repository
root directory, but not in any of the repository's sub-directory.
* Functions: with two input strings (parent-path-to-test path),
that returns non-nil if parent-path-to-test is the repository root directory
corresponding to the given path string. If the return value is a string,
it is treated as the end-result root directory."
  :group 'repository-root
  :type '(repeat (choice (symbol :tag "Built-in matcher"
                                 :value "repository-root-matcher/ignore"
                                 :validate repository-root-builtin-matcher-p)
                         (cons :tag "Rule"
                               :value (repository-root-rule/root-contains . "")
                               :validate repository-root-valid-rule-p
                               (radio (function-item
                                       :doc "Directory/file exists in root directory only"
                                       repository-root-rule/root-contains)
                                      (function-item
                                       :doc "Directory/file exists in all repository directories."
                                       repository-root-rule/all-dirs-contain)
                                      (function-item
                                       :doc "Regular expression matches file/dir name(s) in root directory only."
                                       repository-root-rule/root-contains-regexp)
                                      (function-item
                                       :doc "Regular expression matches file/dir name(s) in all repository directories."
                                       repository-root-rule/all-dirs-contain-regexp)
                                      (function-item
                                       :doc "Regular expression matches tail of root directory name."
                                       repository-root-rule/root-dir-regexp))
                               (string :tag "File/Directory/Regexp"))
                         function)))

(defvar repository-root nil
  "Repository root cache.")

(defun repository-root (&optional path)
  "Return the repository root directory corresponding to the
input PATH string. See also `repository-root-and-matcher-index'.
The result is cached (if possible) to speed up subsequent function calls."
  (interactive)
  (unless path
    (setq path (if (and (interactive-p) current-prefix-arg)
		   (read-file-name "Path: ")
		 "")))
  (let* ((cache-allowed (string= path (expand-file-name (buffer-file-name))))
         (cache (when (and cache-allowed
                           (local-variable-p 'repository-root))
                  repository-root))
         (result (if cache
                     cache
                   (car (repository-root-and-matcher-index path)))))
    (when (and (not cache)
               cache-allowed)
      (set (make-local-variable 'repository-root) result))
    result))

(defun repository-root-and-matcher-index (path)
  "Return a cons pair (ROOT . INDEX) containing the repository
ROOT directory corresponding to the input PATH string,
and the numeric, zero-based, matcher INDEX. The matcher INDEX is the
position of the first successful matching criterion in the list
`repository-root-matchers'."
  (unless path
    (setq path ""))
  (setq path (expand-file-name path))
  (let ((current (file-name-as-directory (if (file-directory-p path)
                                             path
                                           (file-name-directory path))))
        (root nil)
        (index 0))
    (while (and (not root) current)
      (let ((count 0)
            (matcher (car repository-root-matchers))
            (matchers (cdr repository-root-matchers))
            (found nil))
        (while (and (not found) matcher)
          ;; handle built-in matchers
          (if (and (symbolp matcher)
                   (not (functionp matcher)))
              (setq matcher (condition-case nil (eval matcher) (error nil))))
          ;; attempt to match
          (setq found
                (cond ((and (consp matcher)
                            (functionp (car matcher))
                            (stringp (cdr matcher)))
                       (apply (car matcher) (list current path (cdr matcher))))
                      ((functionp matcher)
                       (apply matcher (list current path)))
                      (t nil)))
          (unless found
            (setq count (1+ count)
                  matcher (car matchers)
                  matchers (cdr matchers))))
        (if found
            (setq root (if (stringp found) found current)
                  index count)
          (let ((next (file-name-directory (directory-file-name current))))
            (setq current (if (string= next current)
                              nil
                            next))))))
    (cons root index)))

(provide 'repository-root)
