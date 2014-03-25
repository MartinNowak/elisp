;;; directory-has.el --- Directory File Relation Predicates.

(require 'elk-test)

;; (file-relative-name "/etc/passwd" "/etc")
;; (file-relative-name "bin" "/etc")
(defun directory-has-file-p (dir file)
  "Return path DIR/FILE if DIR contains FILE."
  (if (file-name-absolute-p file)
      (let* ((dir (expand-file-name (file-name-as-directory dir)))
             (file (expand-file-name file))
             (file (substring file
                              (length
                               (try-completion "" `(,dir ,file))))) ;remove common prefix
             )
        (let ((full (expand-file-name file dir)))
          (when (file-exists-p full)
            full)))
    (let ((full (expand-file-name file dir)))
      (when (file-exists-p full)
        full))))
(eval-when-compile (assert-nonnil (directory-has-file-p "/etc" "passwd")))
(eval-when-compile (assert-nonnil (directory-has-file-p "/etc/" "passwd")))
(eval-when-compile (assert-nil (directory-has-file-p "/etc/" "passwd/")))
(eval-when-compile (assert-nonnil (directory-has-file-p "/etc" "/etc/passwd")))
(eval-when-compile (assert-nil (directory-has-file-p "/etc" "/etc/passwd/")))
(eval-when-compile (assert-nil (directory-has-file-p "/etc" "/etc/bin")))
(eval-when-compile (assert-nil (directory-has-file-p "/etc" "bin")))
(eval-when-compile (assert-nil (directory-has-file-p "/bin/ls" "ls")))
(defun file-under-directory-p (files dir) (directory-has-file-p dir files))

(defun directory-has-files-p (dir files)
  "Check for the precence of the single file or list of files
FILES in the directory DIR.

Return elements of FILES as members of DIR."
  (delete nil (mapcar (lambda (filename) (directory-has-file-p dir filename)) files)))
(defun files-under-directory-p (files dir) (directory-has-files-p dir files))

(eval-when-compile (assert-nil (directory-has-files-p "/etc/passwd" '("passwd" "hosts"))))
;; Use: (directory-has-files-p "/etc/" '("passwd" "hosts"))
;; Use: (directory-has-files-p "~/cognia/vec2f" '("passwd" "hosts"))
;; Use: (directory-has-files-p "~/cognia/" '("GPATH" "GRTAGS" "GSYMS" "GTAGS" "tags" "TAGS"))
;; Use: (directory-has-files-p "~/cognia/" '("tags" "TAGS"))
;; Use: (directory-has-files-p "~/cognia/" "tags")
;; Use: (directory-has-files-p "~/cognia/" nil)

(defun directory-has-all-p (dir file-list)
  "Return t if DIR is a directory and contains all the files in
FILE-LIST, nil otherwise."
  (let ((cont (directory-has-files-p dir file-list)))
    (when (and cont
               (= (length file-list)
                  (length cont)))
      cont)))
(defalias 'dir-all-subs-p 'directory-has-all-p)
;; Use: (directory-has-all-p "/etc/" '("passwd" "hosts")) => '("passwd" "hosts")
;; Use: (directory-has-all-p "~/cognia/vec2f" '("passwd" "hosts")) => nil
;; Use: (directory-has-all-p "~/cognia/" '("GPATH" "GRTAGS"))
;; Use: (directory-has-all-p "~/cognia/" '("GPATH" "GRTAGS" "GSYMS" "GTAGS"))
(defun directory-has-any-p (dir file-list)
  "Return t if DIR is a directory and contains any of the files
in FILE-LIST, nil otherwise."
  (let ((cont (directory-has-files-p dir file-list)))
    (when cont
      (some 'identity cont))))
(defalias 'dir-any-subs-p 'directory-has-any-p)
;; Use: (directory-has-any-p "/etc/" '("hosts" "passwd")) => "passwd"
;; Use: (directory-has-any-p "/etc/" '("passwd" "hostes")) => "passwd"
;; Use: (directory-has-any-p "/etc/" '("passwords" "hostes")) => nil

(provide 'directory-has)
