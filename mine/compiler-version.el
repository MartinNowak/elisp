;;; compiler-version.el --- Lookup Compiler Version.
;; Author: Per Nordlöw

(require 'power-utils)

(defvar cached-compiler-versions
  (make-hash-table :test 'equal)
  "Versions of Compilers")

(defun get-compiler-version (compiler)
  "Ask COMPILER for its version or nil if COMPILER executable is missing."
  (when (executable-find compiler)
    (cond ((string-match "gcc" compiler)
           (string-trim (shell-command-to-string (concat compiler " -dumpversion"))))
          ((string-match "clang" compiler)
           (let ((str (shell-command-to-string (concat compiler " --version"))))
             (progn (string-match "clang version \\([0-9-\.]+\\)" str)
                    (match-string 1 str))))
          ((string-match "dmd" compiler)
           (let ((str (shell-command-to-string compiler)))
             (progn (string-match "DMD\\(32\\|64\\) D Compiler v\\([0-9\.]+\\)" str)
                    (match-string 2 str)))))))

(defun compiler-version (compiler)
  "Cached version of `get-compiler-version'."
  (or (gethash compiler cached-compiler-versions)
      (puthash compiler
               (get-compiler-version compiler)
               cached-compiler-versions)))
;; Use: (compiler-version "gcc")
;; Use: (compiler-version "clang")
;; Use: (compiler-version "dmd")
(defun gcc-version (&optional compiler) (compiler-version (or compiler "gcc")))
(defun clang-version (&optional compiler) (compiler-version (or compiler "clang")))
(defun dmd-version (&optional compiler) (compiler-version (or compiler "dmd")))
;; Use: (gcc-version)
;; Use: (clang-version)
;; Use: (dmd-version)
(defun compiler-version-at-least (version &optional compiler)
  "Return non-nil if GCC COMPILER has at least version VERSION-STRING."
  (let ((version-installed (compiler-version compiler)))
    (when version-installed
      (inversion->= (version-to-list version-installed)
                    (cond ((stringp version)
                           (version-to-list version))
                          ((numberp version)
                           (version-to-list (number-to-string version)))
                          ((listp version)
                           version))))))
;; Use: (compiler-version-at-least "4.7" "gcc")
;; Use: (compiler-version-at-least "4.8.1" "gcc")
;; Use: (compiler-version-at-least "4.8.2" "gcc")
;; Use: (compiler-version-at-least "3.4" "clang")
;; Use: (compiler-version-at-least "3.3" "clang")
;; Use: (compiler-version-at-least "3.2" "clang")
;; Use: (compiler-version-at-least "3.1" "clang")
;; Use: (compiler-version-at-least "3.0" "clang")
;; Use: (compiler-version-at-least "2.065" "dmd")
(defun gcc-version-at-least (version &optional compiler) (compiler-version-at-least version (or compiler "gcc")))
(defun clang-version-at-least (version &optional compiler) (compiler-version-at-least version (or compiler "clang")))
(eval-when-compile
  (when (executable-find "gcc-4.7") (assert-nil (gcc-version-at-least "4.8" "gcc-4.7")))
  (when (executable-find "gcc-4.7") (assert-t   (gcc-version-at-least "4.7" "gcc-4.7")))
  (when (executable-find "gcc-4.7") (assert-nil (gcc-version-at-least 4.8 "gcc-4.7")))
  (when (executable-find "gcc-4.7") (assert-t   (gcc-version-at-least 4.7 "gcc-4.7"))))

(provide 'compiler-version)
