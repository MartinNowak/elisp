;;; multi-dir.el --- Multi Directory File Operations.
;; Author: Per Nordlöw

(defun file-nondirectory-compare (a b)
  (string< (file-name-nondirectory a)
           (file-name-nondirectory b)))

(defun simplify-sorted-file-names (filenames)
  "Remove directories of the unique names in FILES."
  (let ((f filenames))            ;filenames iterator
    (while f            ;while next element
      (let ((g (cdr f)))
        (while (and g          ;while next element and
                    (string= (file-name-nondirectory (car f)) ;current local equals
                             (file-name-nondirectory (car g)))) ;next local
          (setq g (cdr g)))     ;forward next
        (when (eq (cdr f) g)   ;if no duplicates
          (setcar f (file-name-nondirectory (car f)))) ;strip path
        (setq f g)))
    filenames))
;; (simplify-sorted-file-names '("/opt/g++" "/opt/gcc" "/alt/g++" "/alt/gcc")) => '("g++" "gcc" "g++" "gcc")
;; (simplify-sorted-file-names '("/opt/gcc" "/alt/gcc" "/bin/gcc" "/gnu/gcc"))

(defun multi-directory-files-helper (directories &optional full match nosort use-dcache)
  (delete-dups directories)
  (let ((files))
    (dolist (directory directories)
      (when (file-accessible-directory-p directory)
        (setq files
              (append files             ;use: `append' or `nconc'
                      (if use-dcache
                          (fcache-dir-files directory full (or match
                                                               directory-files-no-dot-files-regexp))
                        (directory-files directory full
                                         (or match
                                             directory-files-no-dot-files-regexp) nosort))))))
    files))
;; (bench (multi-directory-files-helper exec-path nil nil t))
;; (bench (multi-directory-files-helper exec-path nil nil t t))

(defun multi-directory-files (directories &optional full match nosort predicate)
  "Return a list of names of files in DIRECTORY.
Set DIRECTORY to `exec-path' to read an executable similar to how
the function `executable-find' works.  FULL can be either `nil,'
`t' or `full-duplicates'."
  (let ((files (multi-directory-files-helper directories full match t t)))
    (setq files (sort files 'file-nondirectory-compare)) ;NOTE: Optimize! This takes more half the time!
    (when predicate
      (if full
          (setq files (delq nil (mapcar
                                 `(lambda (file) (when (funcall ',predicate file)
                                                   file))
                                 files)))
        (message "errror: Cannot yet handle non-full predicate case")))
    (cond ((eq full t)                  ;full file name
           files)
          ((eq full 'full-duplicates)          ;unique file name
           (simplify-sorted-file-names files))
          (t                            ;local name
           (delete-dups files)))))
;; (bench (multi-directory-files exec-path))
;; (multi-directory-files (remove "/usr/sbin" (remove "/usr/bin" exec-path)) t "clang")
;; (multi-directory-files exec-path t "clang")
;; (multi-directory-files exec-path 'full-duplicates "clang")
;; (multi-directory-files exec-path t "ccache")
;; (multi-directory-files exec-path t "ccache")
;; (multi-directory-files exec-path 'full-duplicates "ccache")
;; (multi-directory-files exec-path nil "gnome")
;; (multi-directory-files exec-path t "gnome")
;; (multi-directory-files exec-path 'full-duplicates "gnome")
;; (multi-directory-files exec-path t "emacs")
;; (multi-directory-files exec-path 'full-duplicates "emacs")

(defun multi-directory-executable-files (directories &optional full match nosort predicate)
  (multi-directory-files directories full match nosort
                         (lambda (file)
                           (and (file-executable-p file)
                                (file-regular-p file)))))
;; (multi-directory-executable-files (remove "/usr/sbin" (remove "/usr/sbin" (remove "/usr/bin" exec-path))) t nil t)
;; (multi-directory-executable-files (remove "/usr/sbin" (remove "/usr/sbin" (remove "/usr/bin" exec-path))) t "clang" t)

(defun multi-read-file-name (&optional prompt path full match predicate require-match
                                       initial-input hist def inherit-input-method
                                       include-uninstalled)
  "Read a file using PROMPT in the list of directories PATH.
FULL can be either `nil,' `t' or `full-duplicates'."
  (interactive)
  (completing-read (or prompt "Executable: ")
                   (multi-directory-files path full match nil predicate)
                   nil require-match
                   initial-input hist def inherit-input-method))
;; Use: (multi-read-file-name nil exec-path 'full-duplicates "clang" nil t)
1;; Use: (multi-read-file-name nil exec-path nil "gnome" nil t)
;; Use: (multi-read-file-name nil exec-path t "gnome" nil t)
;; Use: (multi-read-file-name "Emacs Library containing \"cc\": " load-path t "cc")

(provide 'multi-dir)
