;;; file-utils.el --- File Utilities.
;; Author: Per Nordlöw

(require 'directory-has)

(eval-when-compile (require 'cl))

(defun file-name-nondirectory-equal (filename key &optional case-fold)
  (if case-fold
      (string= (downcase key)
               (downcase (file-name-nondirectory filename)))
    (string= key
             (file-name-nondirectory filename))))

(defun file-name-match (filename key)
  "Match the string KEY FILENAME."
  (cond
   ((stringp key)
    (string-match (regexp-quote key) filename))
   ((functionp key)
    (funcall key filename))
   ))

(defun file-name-match-regexp (filename key &optional case-fold)
  "Match the regexp KEY with FILENAME."
  (cond
   ((stringp key)
    (let (case-fold-search case-fold)
      (string-match key filename)))
   ((functionp key)
    (funcall key filename))
   ))

(defun file-name-real-p (filename)
  "Return non-nil if FILENAME is not the special directories \".\" or \"..\"."
  (not (string-match directory-files-no-dot-files-regexp filename)))
;; Use: (concat (file-name-real-p "~/pnw") (file-name-real-p ".")

(defsubst file-uid (filename)
  "Return the user id of FILE."
  (nth 2 (file-attributes filename)))
;; Use: (file-uid "/etc/passwd")
;; Use: (file-uid "~")

(defsubst file-gid (filename)
  "Return the group id of FILE."
  (nth 3 (file-attributes filename)))
;; Use: (file-gid "/etc/passwd")
;; Use: (file-gid "~")

(defsubst file-has-uid-p (filename &optional uid)
  "Return non-nil if FILENAME is owned by user id UID.
UID defaults to current user"
  (let ((file-uid (nth 2 (file-attributes filename))))
    (and file-uid
         (= file-uid (or uid (user-uid))))))
(defalias 'file-is-owned-by-p 'file-has-uid-p)
;; Use: (file-has-uid-p "/etc/passwd") => nil
;; Use: (file-has-uid-p "/xyz") => nil
;; Use: (file-has-uid-p "~") => t

(defsubst file-modification-time (filename)
  "Return modification time of FILENAME."
  (nth 5 (file-attributes filename)))
;; Use: (progn (touch-file "file-utils.el") (file-modification-time "file-utils.el"))

(defsubst file-older-than (first-filename second-filename)
  "Return non-nil if the file FIRST-FILENAME is newer (by modification) than the file SECOND-FILENAME."
  (let ((t1 (file-modification-time first-filename))
        (t2 (file-modification-time second-filename)))
    (cond ((< (car t1) (car t2))
           t)
          ((== (car t1) (car t2))
           (< (cadr t1) (cadr t2)))
          (t
           nil))))

(defsubst file-newer-than (first-filename second-filename)
  "Return non-nil if the file FIRST-FILENAME is newer (by modification) than the file SECOND-FILENAME."
  (let ((t1 (file-modification-time first-filename))
        (t2 (file-modification-time second-filename)))
    (cond ((> (car t1) (car t2))
           t)
          ((== (car t1) (car t2))
           (> (cadr t1) (cadr t2)))
          (t
           nil))))

(defsubst file-status-change-time (filename)
  "Return status-change time of the file FILENAME."
  (nth 6 (file-attributes filename)))
;; Use: (file-status-change-time "/bin/ls")

(defsubst file-size (filename)
  "Return size of the file FILENAME."
  (nth 7 (file-attributes filename)))
;; Use: (file-size "/bin/ls")

(defsubst file-inode-number (filename)
  "Return inode number of the file FILENAME."
  (nth 10 (file-attributes filename)))
;; Use: (file-inode-number "/bin/ls")
;; Use: (file-inode-number "/bin/grep")
;; Use: (file-inode-number "~/.emacs")
;; Use: (file-inode-number "~/justcxx/Makefile.am")

(defsubst file-device-number (filename)
  "Return file-system device number of the file FILENAME."
  (nth 11 (file-attributes filename)))
;; Use: (file-device-number "/bin/ls")
;; Use: (file-device-number "/bin/grep")
;; Use: (file-device-number "~/.emacs")
;; Use: (file-device-number "~/justcxx/Makefile.am")

(defun file-in-directory-list-p (file dirlist)
  "Returns true if the file specified is contained within one of
the directories in the list. The directories must also exist."
  (let ((dirs (mapcar 'expand-file-name dirlist))
        (filedir (expand-file-name (file-name-directory file))))
    (and
     (file-directory-p filedir)
     (member-if (lambda (x) ; Check directory prefix matches
                  (string-match (substring x 0 (min(length filedir) (length x))) filedir))
                dirs))))

;; ---------------------------------------------------------------------------

(defun file-empty-p (filename)
  "Check if FILENAME is empty."
  (= (file-size filename) 0))
;; Use: (file-empty-p "/bin/ls")
;; Use: (file-empty-p "~/.gksu.lock")

;; ---------------------------------------------------------------------------

(defun get-cwd ()
  "Return the current working directory without containing
directory (local path)."
  (interactive)
  (let ((path (pwd)))
    (let ((idx (string-match "[[:alnum:]_-]+/$" path)))
      (if idx
          (substring path idx (- (string-width path) 1))))))
;; Use: (get-cwd)

;; ---------------------------------------------------------------------------

;; See the functions `file-attributes', `visited-file-modtime', and
;; `set-visited-file-modtime'
(defun touch-file (filename)
  "Touch FILENAME, that is set its modification time (modtime) to
current time. Return t if operation was permitted, nil otherwise."
  (interactive "fFile to touch: ")
  (if (file-writable-p filename)
      (set-file-times filename (current-time))
    ))
;;(set-visited-file-modtime)
;;(current-time)
;; ToDo: Implement!
;; Use: (touch-file "~/.bashrc")
;; Use: (touch-file "/etc/passwd")

;; ---------------------------------------------------------------------------

;; Use:
(when nil
  (file-truename "~/.emacs")
  (file-relative-name "/etc/passwd" "~")

  (file-name-directory "/etc/passwd")
  (file-name-directory "/etc/")
  (file-name-directory "/etc")
  (directory-file-name "/etc/")
  (directory-file-name "/etc//")

  (directory-file-name "/etc/passwd/")
  (file-name-sans-extension "stdio.h")
  (file-name-nondirectory "/etc/passwd")
  (file-name-sans-directory "/etc/passwd")
  )

(defun file-relative-name-to-file (from to)
  (interactive "sFrom: sTo: ")
  (file-relative-name to (file-name-directory from)))
;; Use: (file-relative-name-to-file "~/justcxx/avg/utils.h" "~/justcxx/utils.h")

;; ---------------------------------------------------------------------------

;; Wrappers for UNIX (POSIX) Command Line Tools

(defun directory-disk-usage (dir)
  "Calculate Disk (Space) Usage under directory DIR."
  (interactive "DDirectory: ")
  (shell-command (concat "du -sh " dir)))
(defalias 'directory-size 'directory-disk-usage)
(defalias 'disk-usage 'directory-disk-usage)
(defalias 'du 'directory-disk-usage)

(defun locale ()
  "Get Current Locale."
  (interactive)
  (shell-command (concat "locale")))

(defun directory-disk-free (dir)
  "Calculate Disk (Space) Free under directory DIR."
  (interactive "DDirectory: ")
  (shell-command (concat "df -h " dir)))
(defalias 'disk-free 'directory-disk-free)
(defalias 'df 'directory-disk-free)
(defalias 'mktemp 'make-temp-name)

(defun list-open-files ()
  "List open files."
  (interactive)
  (shell-command (concat "lsof")))
(defalias 'lsof 'list-open-files)

(defun list-usb ()
  "List USB devices."
  (interactive)
  (shell-command (concat "lsusb")))
(defalias 'lsusb 'list-usb)

(defun list-pci ()
  "List PCI devices."
  (interactive)
  (shell-command (concat "lspci")))
(defalias 'lspci 'list-pci)

;; ---------------------------------------------------------------------------

(defun trace-directory-upwards-helper (matcher &optional start-dir multi halt-dir)
  "Recursively search each parent directory (upwards), from
directory START-DIR, for a directory that matches
MATCHER. MATCHER can be either a regexp or a predicate function
that takes the directory of interest as in argument. DEPTH can be
either 'top or 'bottom. If MULTI is non-nil find all parent
directories that match MATCHER and return them as a list starting
with the shallowest, otherwise find the shallowest only as a
string."
  (interactive "dDirectory: \n")
  (if (file-directory-p start-dir)
      (let* ((dir (expand-file-name start-dir))
             (parent (file-name-directory (directory-file-name dir))))
        (cond ((string= nil parent)
               (progn (error "Parent is nil!")
                      nil))
              ((and (stringp halt-dir)
                    (string-equal dir (expand-file-name halt-dir)))
               nil)                     ;halt
              ;; Note: This support (TRAMP-style) remote paths. comparing against "/" is not enough.
              ((string= (file-name-as-directory dir) parent)
               nil) ;at top-level (root) directory: return nil means nothing found.
              ((let* ((match (cond ((stringp matcher)
                                    (string-match matcher (file-name-sans-directory dir)))
                                   ((functionp matcher)
                                    (funcall matcher dir))))
                      (hit (when match
                             (cons dir match))))
                 (if multi
                     (let ((parents (trace-directory-upwards-helper matcher
                                                                    (directory-file-name parent)
                                                                    multi
                                                                    halt-dir)))
                       (append (if (consp hit)
                                   (list hit)
                                 hit)
                               parents))
                   hit)))
              (t
               (trace-directory-upwards-helper matcher
                                               (directory-file-name parent)))))
    (error "%s is not a directory!" start-dir)))
(defun trace-directory-upwards (matcher &optional dir multi halt-dir)
  "See `trace-directory-upwards-helper'."
  (trace-directory-upwards-helper matcher
                                  (expand-file-name (or dir default-directory))
                                  multi halt-dir))
;; Use: (trace-directory-upwards "home" "~/")
;; Use: (trace-directory-upwards "home" "~/" t)
;; Use: (trace-directory-upwards 'file-directory-p "~/justcxx/semnet" t)
;; Use: (trace-directory-upwards 'file-directory-p "~/justcxx/semnet" t "~")
;; Use: (trace-directory-upwards 'file-tags-root-directory-p "~/justcxx/semnet")
;; Use: (trace-directory-upwards 'file-tags-root-directory-p "~/justcxx/semnet" t)
;; Use: (trace-directory-upwards 'file-tags-root-directory-p "/ssh:rsr@150.227.198.29:/")

(defun trace-file-upwards (dir &optional matcher multi regexp-flag recog)
  (interactive "sFilename: ")
  (let ((hits (trace-directory-upwards (cond ((stringp matcher)
                                                `(lambda (dir)
                                                   (if ,regexp-flag
                                                       (directory-files dir t ,matcher)
                                                     (let ((filename (expand-file-name ,matcher dir)))
                                                       (when (file-exists-p filename)
                                                         filename)))))
                                               ((symbolp matcher)
                                                `(lambda (dir)
                                                   (let ((filenames (directory-files dir t)))
                                                     (delq nil
                                                           (mapcar (lambda (filename)
                                                                     (when (file-match filename ',matcher recog)
                                                                       filename))
                                                                   filenames)))))
                                               (t
                                                (error "matcher must be either string or a function.")))
                                         dir
                                         multi)))
    hits))
;; Use: (trace-file-upwards "~/justcxx/semnet/" "GNUmakefile.backup")
;; Use: (trace-file-upwards "~/justcxx/semnet/" "GNUmakefile.backup" t)
;; Use: (trace-file-upwards "~/justcxx/semnet/" "[mM]akefile\\'" nil t)
;; Use: (trace-file-upwards "~/justcxx/semnet/" "[mM]akefile\\'" t t)
;; Use: (trace-file-upwards "~/justcxx/semnet/" 'Makefile t nil 'name-recog)
;; Use: (trace-file-upwards "~/justcxx/semnet/" (fmd-nexpr (fmd-get-type 'Makefile)) t t)

;; name as defined in http://www.emacswiki.org/cgi-bin/wiki/CompileCommand
(defalias 'upwards-find-file 'trace-file-upwards)

;; ---------------------------------------------------------------------------

(defun file-make-executable (filename)
  "Make file executable according to umask if not already executable.
If file already has any execute bits set at all, do not change existing
file modes."
  (let* ((current-mode (file-modes filename))
         (add-mode (logand ?\111 (default-file-modes))))
    (or (null current-mode)
        (/= (logand ?\111 current-mode) 0)
        (zerop add-mode)
        (set-file-modes filename (logior current-mode add-mode)))))

;; ---------------------------------------------------------------------------

(defun find-file-other-window-noselect (filename)
  "Find file FILENAME, in another window without selecting the
window."
  (interactive "F")
  (let ((buf (find-file-noselect filename)))
    (switch-to-buffer-other-window buf)))
;; Use: (find-file-other-window-noselect "gcfsdfdsdsdfdff")

;; ---------------------------------------------------------------------------

;; TODO: Make this stricter by checking file contents aswell by reusing matchers for "GNU GLOBAL GTAGS", etc...!
(defun file-gnu-global-directory-p (dir)
  "Return non-nil if directory DIR contains a GNU GLOBAL
  Database."
  (let (case-fold-search)               ;Note: Case-Sensitive!
    (when (require 'directory-has nil t)
      (directory-has-all-p dir '("GPATH" "GRTAGS" "GSYMS" "GTAGS")))))
;; Use: (symbol-function 'file-gnu-global-directory-p)
(when nil
  (functionp 'file-gnu-global-directory-p)
  (functionp (lambda (x) x))
  (symbolp 'file-gnu-global-directory-p)
  (symbolp (lambda (x) x))
  (message "symbol-function:%s" (symbol-function 'file-gnu-global-directory-p))
  (funcall 'file-gnu-global-directory-p "~/justcxx/")
  (file-gnu-global-directory-p "~/justcxx/vec2f")
  )

;; ---------------------------------------------------------------------------

(defun file-c++-contents-p (file)
  "Return non-nil if file FILENAME contains C++ code.
Typically used to detect C++ header files that have no or
C-like (.h) file extension."
  nil
  )

;; ---------------------------------------------------------------------------

(defun file-ubuntu-mirror-root-directory-p (dir)
  "Return non-nil if directory DIR is an Ubuntu Mirror Root
Directory."
  (let (case-fold-search)               ;Note: Case-Sensitive!
    (when (require 'directory-has nil t)
      (and
       (directory-has-all-p dir '("ubuntu"))
       (directory-has-all-p (file-relative-name "ubuntu" dir)
                            '("dists" "pool" "project"))))))
;; Use: (file-ubuntu-mirror-root-directory-p "~/Skrivbord/se.archive.ubuntu.com/")

(provide 'file-utils)
