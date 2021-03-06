;;; git-pnw.el --- A user interface for git

;; Copyright (C) 2005, 2006, 2007 Alexandre Julliard <julliard@winehq.org>

;; Version: 1.0

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; This file contains an interface for the git version control
;; system. It provides easy access to the most frequently used git
;; commands. The user interface is as far as possible identical to
;; that of the PCL-CVS mode.
;;
;; To install: put this file on the load-path and place the following
;; in your .emacs file:
;;
;;    (require 'git)
;;
;; To start: `M-x git-status'
;;
;; TODO
;;  - portability to XEmacs
;;  - better handling of subprocess errors
;;  - hook into file save (after-save-hook)
;;  - diff against other branch
;;  - renaming files from the status buffer
;;  - creating tags
;;  - fetch/pull
;;  - switching branches
;;  - revlist browser
;;  - git-show-branch browser
;;  - menus
;;

(eval-when-compile (require 'cl))
(require 'ewoc)
(require 'log-edit)

;;;; Customizations
;;;; ------------------------------------------------------------

(defgroup git nil
  "A user interface for the git versioning system."
  :group 'tools)

(defcustom git-committer-name nil
  "User name to use for commits.
The default is to fall back to the repository config,
then to `add-log-full-name' and then to `user-full-name'."
  :group 'git
  :type '(choice (const :tag "Default" nil)
                 (string :tag "Name")))

(defcustom git-committer-email nil
  "Email address to use for commits.
The default is to fall back to the git repository config,
then to `add-log-mailing-address' and then to `user-mail-address'."
  :group 'git
  :type '(choice (const :tag "Default" nil)
                 (string :tag "Email")))

(defcustom git-commits-coding-system nil
  "Default coding system for the log message of git commits."
  :group 'git
  :type '(choice (const :tag "From repository config" nil)
                 (coding-system)))

(defcustom git-append-signed-off-by nil
  "Whether to append a Signed-off-by line to the commit message before editing."
  :group 'git
  :type 'boolean)

(defcustom git-reuse-status-buffer t
  "Whether `git-status' should try to reuse an existing buffer
if there is already one that displays the same directory."
  :group 'git
  :type 'boolean)

(defcustom git-per-dir-ignore-file ".gitignore"
  "Name of the per-directory ignore file."
  :group 'git
  :type 'string)


(defface git-status-face
  '((((class color) (background light)) (:foreground "purple"))
    (((class color) (background dark)) (:foreground "purple")) ;CVS: pink
    )
  "Git mode face used to highlight added and modified files."
  :group 'git)

(defface git-unmerged-face
  '((((class color) (background light)) (:foreground "red" :bold t))
    (((class color) (background dark)) (:foreground "red" :bold t))
    )
  "Git mode face used to highlight unmerged files."
  :group 'git)

(defface git-unknown-face
  '((((class color) (background light)) (:foreground "goldenrod" :bold t))
    (((class color) (background dark)) (:foreground "goldenrod" :bold t))
    )
  "Git mode face used to highlight unknown files."
  :group 'git)

(defface git-uptodate-face
  '((((class color) (background light)) (:foreground "grey60"))
    (((class color) (background dark)) (:foreground "grey60"))
    )
  "Git mode face used to highlight up-to-date files."
  :group 'git)

(defface git-ignored-face
  '((((class color) (background light)) (:foreground "grey60"))
    (((class color) (background dark)) (:foreground "grey60"))
    )
  "Git mode face used to highlight ignored files."
  :group 'git)

(defface git-mark-face
  '((((class color) (background light)) (:foreground "red" :bold t))
    (((class color) (background dark)) (:foreground "red" :bold t))
    )
  "Git mode face used for the file marks."
  :group 'git)

(defface git-header-face
  '((((class color) (background light)) (:foreground "blue"))
    (((class color) (background dark)) (:foreground "blue"))
    )
  "Git mode face used for commit headers."
  :group 'git)

(defface git-separator-face
  '((((class color) (background light)) (:foreground "brown"))
    (((class color) (background dark)) (:foreground "brown"))
    )
  "Git mode face used for commit separator."
  :group 'git)

(defface git-permission-face
  '((((class color) (background light)) (:foreground "green" :bold t))
    (((class color) (background dark)) (:foreground "green" :bold t))
    )
  "Git mode face used for permission changes."
  :group 'git)


;;;; Utilities
;;;; ------------------------------------------------------------

(defconst git-log-msg-separator "--- log message follows this line ---")

(defvar git-log-edit-font-lock-keywords
  `(("^\\(Author:\\|Date:\\|Parent:\\|Signed-off-by:\\)\\(.*\\)$"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))
    (,(concat "^\\(" (regexp-quote git-log-msg-separator) "\\)$")
     (1 font-lock-comment-face))))

(defun git-get-env-strings (env)
  "Build a list of NAME=VALUE strings from a list of environment strings."
  (mapcar (lambda (entry) (concat (car entry) "=" (cdr entry))) env))

(defun git-call-process-env (buffer env &rest args)
  "Wrapper for call-process that sets environment strings."
  (if env
      (apply #'call-process "env" nil buffer nil
             (append (git-get-env-strings env) (list "git") args))
    (apply #'call-process "git" nil buffer nil args)))

(defun git-call-process-env-string (env &rest args)
  "Wrapper for call-process that sets environment strings,
and returns the process output as a string."
  (with-temp-buffer
    (and (eq 0 (apply #' git-call-process-env t env args))
         (buffer-string))))

(defun git-run-process-region (buffer start end program args)
  "Run a git process with a buffer region as input."
  (let ((output-buffer (current-buffer))
        (dir default-directory))
    (with-current-buffer buffer
      (cd dir)
      (apply #'call-process-region start end program
             nil (list output-buffer nil) nil args))))

(defun git-run-command-buffer (buffer-name &rest args)
  "Run a git command, sending the output to a buffer named BUFFER-NAME."
  (let ((dir default-directory)
        (buffer (get-buffer-create buffer-name)))
    (message "Running git %s..." (car args))
    (with-current-buffer buffer
      (let ((default-directory dir)
            (buffer-read-only nil))
        (erase-buffer)
        (apply #'git-call-process-env buffer nil args)))
    (message "Running git %s...done" (car args))
    buffer))

(defun git-run-command (buffer env &rest args)
  (message "Running git %s..." (car args))
  (apply #'git-call-process-env buffer env args)
  (message "Running git %s...done" (car args)))

(defun git-run-command-region (buffer start end env &rest args)
  "Run a git command with specified buffer region as input."
  (message "Running git %s..." (car args))
  (unless (eq 0 (if env
                    (git-run-process-region
                     buffer start end "env"
                     (append (git-get-env-strings env) (list "git") args))
                  (git-run-process-region
                   buffer start end "git" args)))
    (error "Failed to run \"git %s\":\n%s" (mapconcat (lambda (x) x) args " ") (buffer-string)))
  (message "Running git %s...done" (car args)))

(defun git-run-hook (hook env &rest args)
  "Run a git hook and display its output if any."
  (let ((dir default-directory)
        (hook-name (expand-file-name (concat ".git/hooks/" hook))))
    (or (not (file-executable-p hook-name))
        (let (status (buffer (get-buffer-create "*Git Hook Output*")))
          (with-current-buffer buffer
            (erase-buffer)
            (cd dir)
            (setq status
                  (if env
                      (apply #'call-process "env" nil (list buffer t) nil
                             (append (git-get-env-strings env) (list hook-name) args))
                    (apply #'call-process hook-name nil (list buffer t) nil args))))
          (display-message-or-buffer buffer)
          (eq 0 status)))))

(defun git-get-string-sha1 (string)
  "Read a SHA1 from the specified string."
  (and string
       (string-match "[0-9a-f]\\{40\\}" string)
       (match-string 0 string)))

(defun git-get-committer-name ()
  "Return the name to use as GIT_COMMITTER_NAME."
  ; copied from log-edit
  (or git-committer-name
      (git-config "user.name")
      (and (boundp 'add-log-full-name) add-log-full-name)
      (and (fboundp 'user-full-name) (user-full-name))
      (and (boundp 'user-full-name) user-full-name)))

(defun git-get-committer-email ()
  "Return the email address to use as GIT_COMMITTER_EMAIL."
  ; copied from log-edit
  (or git-committer-email
      (git-config "user.email")
      (and (boundp 'add-log-mailing-address) add-log-mailing-address)
      (and (fboundp 'user-mail-address) (user-mail-address))
      (and (boundp 'user-mail-address) user-mail-address)))

(defun git-get-commits-coding-system ()
  "Return the coding system to use for commits."
  (let ((repo-config (git-config "i18n.commitencoding")))
    (or git-commits-coding-system
        (and repo-config
             (fboundp 'locale-charset-to-coding-system)
             (locale-charset-to-coding-system repo-config))
      'utf-8)))

(defun git-get-logoutput-coding-system ()
  "Return the coding system used for git-log output."
  (let ((repo-config (or (git-config "i18n.logoutputencoding")
                         (git-config "i18n.commitencoding"))))
    (or git-commits-coding-system
        (and repo-config
             (fboundp 'locale-charset-to-coding-system)
             (locale-charset-to-coding-system repo-config))
      'utf-8)))

(defun git-escape-file-name (name)
  "Escape a file name if necessary."
  (if (string-match "[\n\t\"\\]" name)
      (concat "\""
              (mapconcat (lambda (c)
                   (case c
                     (?\n "\\n")
                     (?\t "\\t")
                     (?\\ "\\\\")
                     (?\" "\\\"")
                     (t (char-to-string c))))
                 name "")
              "\"")
    name))

(defun git-get-top-dir (dir)
  "Retrieve the top-level directory of a git tree."
  (let ((cdup (with-output-to-string
                (with-current-buffer standard-output
                  (cd dir)
                  (unless (eq 0 (call-process "git" nil t nil "rev-parse" "--show-cdup"))
                    (error "cannot find top-level git tree for %s." dir))))))
    (expand-file-name (concat (file-name-as-directory dir)
                              (car (split-string cdup "\n"))))))

;stolen from pcl-cvs
(defun git-append-to-ignore (file)
  "Add a file name to the ignore file in its directory."
  (let* ((fullname (expand-file-name file))
         (dir (file-name-directory fullname))
         (name (file-name-nondirectory fullname))
         (ignore-name (expand-file-name git-per-dir-ignore-file dir))
         (created (not (file-exists-p ignore-name))))
  (save-window-excursion
    (set-buffer (find-file-noselect ignore-name))
    (goto-char (point-max))
    (unless (zerop (current-column)) (insert "\n"))
    (insert "/" name "\n")
    (sort-lines nil (point-min) (point-max))
    (save-buffer))
  (when created
    (git-run-command nil nil "update-index" "--add" "--" (file-relative-name ignore-name)))
  (git-update-status-files (list (file-relative-name ignore-name)) 'unknown)))

; propertize definition for XEmacs, stolen from erc-compat
(eval-when-compile
  (unless (fboundp 'propertize)
    (defun propertize (string &rest props)
      (let ((string (copy-sequence string)))
        (while props
          (put-text-property 0 (length string) (nth 0 props) (nth 1 props) string)
          (setq props (cddr props)))
        string))))

;;;; Wrappers for basic git commands
;;;; ------------------------------------------------------------

(defun git-rev-parse (rev)
  "Parse a revision name and return its SHA1."
  (git-get-string-sha1
   (git-call-process-env-string nil "rev-parse" rev)))

(defun git-config (key)
  "Retrieve the value associated to KEY in the git repository config file."
  (let ((str (git-call-process-env-string nil "config" key)))
    (and str (car (split-string str "\n")))))

(defun git-symbolic-ref (ref)
  "Wrapper for the git-symbolic-ref command."
  (let ((str (git-call-process-env-string nil "symbolic-ref" ref)))
    (and str (car (split-string str "\n")))))

(defun git-update-ref (ref newval &optional oldval reason)
  "Update a reference by calling git-update-ref."
  (let ((args (and oldval (list oldval))))
    (push newval args)
    (push ref args)
    (when reason
     (push reason args)
     (push "-m" args))
    (eq 0 (apply #'git-call-process-env nil nil "update-ref" args))))

(defun git-read-tree (tree &optional index-file)
  "Read a tree into the index file."
  (apply #'git-call-process-env nil
         (if index-file `(("GIT_INDEX_FILE" . ,index-file)) nil)
         "read-tree" (if tree (list tree))))

(defun git-write-tree (&optional index-file)
  "Call git-write-tree and return the resulting tree SHA1 as a string."
  (git-get-string-sha1
   (git-call-process-env-string (and index-file `(("GIT_INDEX_FILE" . ,index-file))) "write-tree")))

(defun git-commit-tree (buffer tree head)
  "Call git-commit-tree with buffer as input and return the resulting commit SHA1."
  (let ((author-name (git-get-committer-name))
        (author-email (git-get-committer-email))
        (subject "commit (initial): ")
        author-date log-start log-end args coding-system-for-write)
    (when head
      (setq subject "commit: ")
      (push "-p" args)
      (push head args))
    (with-current-buffer buffer
      (goto-char (point-min))
      (if
          (setq log-start (re-search-forward (concat "^" (regexp-quote git-log-msg-separator) "\n") nil t))
          (save-restriction
            (narrow-to-region (point-min) log-start)
            (goto-char (point-min))
            (when (re-search-forward "^Author: +\\(.*?\\) *<\\(.*\\)> *$" nil t)
              (setq author-name (match-string 1)
                    author-email (match-string 2)))
            (goto-char (point-min))
            (when (re-search-forward "^Date: +\\(.*\\)$" nil t)
              (setq author-date (match-string 1)))
            (goto-char (point-min))
            (while (re-search-forward "^Parent: +\\([0-9a-f]+\\)" nil t)
              (unless (string= head (match-string 1))
                (setq subject "commit (merge): ")
                (push "-p" args)
                (push (match-string 1) args))))
        (setq log-start (point-min)))
      (setq log-end (point-max))
      (goto-char log-start)
      (when (re-search-forward ".*$" nil t)
        (setq subject (concat subject (match-string 0))))
      (setq coding-system-for-write buffer-file-coding-system))
    (let ((commit
           (git-get-string-sha1
            (with-output-to-string
              (with-current-buffer standard-output
                (let ((env `(("GIT_AUTHOR_NAME" . ,author-name)
                             ("GIT_AUTHOR_EMAIL" . ,author-email)
                             ("GIT_COMMITTER_NAME" . ,(git-get-committer-name))
                             ("GIT_COMMITTER_EMAIL" . ,(git-get-committer-email)))))
                  (when author-date (push `("GIT_AUTHOR_DATE" . ,author-date) env))
                  (apply #'git-run-command-region
                         buffer log-start log-end env
                         "commit-tree" tree (nreverse args))))))))
      (and (git-update-ref "HEAD" commit head subject)
           commit))))

(defun git-empty-db-p ()
  "Check if the git db is empty (no commit done yet)."
  (not (eq 0 (call-process "git" nil nil nil "rev-parse" "--verify" "HEAD"))))

(defun git-get-merge-heads ()
  "Retrieve the merge heads from the MERGE_HEAD file if present."
  (let (heads)
    (when (file-readable-p ".git/MERGE_HEAD")
      (with-temp-buffer
        (insert-file-contents ".git/MERGE_HEAD" nil nil nil t)
        (goto-char (point-min))
        (while (re-search-forward "[0-9a-f]\\{40\\}" nil t)
          (push (match-string 0) heads))))
    (nreverse heads)))

(defun git-get-commit-description (commit)
  "Get a one-line description of COMMIT."
  (let ((coding-system-for-read (git-get-logoutput-coding-system)))
    (let ((descr (git-call-process-env-string nil "log" "--max-count=1" "--pretty=oneline" commit)))
      (if (and descr (string-match "\\`\\([0-9a-f]\\{40\\}\\) *\\(.*\\)$" descr))
          (concat (substring (match-string 1 descr) 0 10) " - " (match-string 2 descr))
        descr))))

;;;; File info structure
;;;; ------------------------------------------------------------

; fileinfo structure stolen from pcl-cvs
(defstruct (git-fileinfo
            (:copier nil)
            (:constructor git-create-fileinfo (state name &optional old-perm new-perm rename-state orig-name marked))
            (:conc-name git-fileinfo->))
  marked              ;; t/nil
  state               ;; current state
  name                ;; file name
  old-perm new-perm   ;; permission flags
  rename-state        ;; rename or copy state
  orig-name           ;; original name for renames or copies
  needs-refresh)      ;; whether file needs to be refreshed

(defvar git-status nil)

(defun git-clear-status (status)
  "Remove everything from the status list."
  (ewoc-filter status (lambda (info) nil)))

(defun git-set-files-state (files state)
  "Set the state of a list of files."
  (dolist (info files)
    (unless (eq (git-fileinfo->state info) state)
      (setf (git-fileinfo->state info) state)
      (setf (git-fileinfo->rename-state info) nil)
      (setf (git-fileinfo->orig-name info) nil)
      (setf (git-fileinfo->needs-refresh info) t))))

(defun git-state-code (code)
  "Convert from a string to a added/deleted/modified state."
  (case (string-to-char code)
    (?M 'modified)
    (?? 'unknown)
    (?A 'added)
    (?D 'deleted)
    (?U 'unmerged)
    (t nil)))

(defun git-status-code-as-string (code)
  "Format a git status code as string."
  (case code
    ('modified (propertize "Modified" 'face 'git-status-face))
    ('unknown  (propertize "Unknown " 'face 'git-unknown-face))
    ('added    (propertize "Added   " 'face 'git-status-face))
    ('deleted  (propertize "Deleted " 'face 'git-status-face))
    ('unmerged (propertize "Unmerged" 'face 'git-unmerged-face))
    ('uptodate (propertize "Uptodate" 'face 'git-uptodate-face))
    ('ignored  (propertize "Ignored " 'face 'git-ignored-face))
    (t "?       ")))

(defun git-rename-as-string (info)
  "Return a string describing the copy or rename associated with INFO, or an empty string if none."
  (let ((state (git-fileinfo->rename-state info)))
    (if state
        (propertize
         (concat "   ("
                 (if (eq state 'copy) "copied from "
                   (if (eq (git-fileinfo->state info) 'added) "renamed from "
                     "renamed to "))
                 (git-escape-file-name (git-fileinfo->orig-name info))
                 ")") 'face 'git-status-face)
      "")))

(defun git-permissions-as-string (old-perm new-perm)
  "Format a permission change as string."
  (propertize
   (if (or (not old-perm)
           (not new-perm)
           (eq 0 (logand ?\111 (logxor old-perm new-perm))))
       "  "
     (if (eq 0 (logand ?\111 old-perm)) "+x" "-x"))
  'face 'git-permission-face))

(defun git-fileinfo-prettyprint (info)
  "Pretty-printer for the git-fileinfo structure."
  (insert (concat "   " (if (git-fileinfo->marked info) (propertize "*" 'face 'git-mark-face) " ")
                  " " (git-status-code-as-string (git-fileinfo->state info))
                  " " (git-permissions-as-string (git-fileinfo->old-perm info) (git-fileinfo->new-perm info))
                  "  " (git-escape-file-name (git-fileinfo->name info))
                  (git-rename-as-string info))))

(defun git-insert-fileinfo (status info &optional refresh)
  "Insert INFO in the status buffer, optionally refreshing an existing one."
  (let ((node (and refresh
                   (git-find-status-file status (git-fileinfo->name info)))))
    (setf (git-fileinfo->needs-refresh info) t)
    (when node   ;preserve the marked flag
      (setf (git-fileinfo->marked info) (git-fileinfo->marked (ewoc-data node))))
    (if node (setf (ewoc-data node) info) (ewoc-enter-last status info))))

(defun git-run-diff-index (status files)
  "Run git-diff-index on FILES and parse the results into STATUS.
Return the list of files that haven't been handled."
  (let ((refresh files))
    (with-temp-buffer
      (apply #'git-run-command t nil "diff-index" "-z" "-M" "HEAD" "--" files)
      (goto-char (point-min))
      (while (re-search-forward
              ":\\([0-7]\\{6\\}\\) \\([0-7]\\{6\\}\\) [0-9a-f]\\{40\\} [0-9a-f]\\{40\\} \\(\\([ADMU]\\)\0\\([^\0]+\\)\\|\\([CR]\\)[0-9]*\0\\([^\0]+\\)\0\\([^\0]+\\)\\)\0"
              nil t 1)
        (let ((old-perm (string-to-number (match-string 1) 8))
              (new-perm (string-to-number (match-string 2) 8))
              (state (or (match-string 4) (match-string 6)))
              (name (or (match-string 5) (match-string 7)))
              (new-name (match-string 8)))
          (if new-name  ; copy or rename
              (if (eq ?C (string-to-char state))
                  (git-insert-fileinfo status (git-create-fileinfo 'added new-name old-perm new-perm 'copy name) refresh)
                (git-insert-fileinfo status (git-create-fileinfo 'deleted name 0 0 'rename new-name) refresh)
                (git-insert-fileinfo status (git-create-fileinfo 'added new-name old-perm new-perm 'rename name)) refresh)
            (git-insert-fileinfo status (git-create-fileinfo (git-state-code state) name old-perm new-perm) refresh))
          (setq files (delete name files))
          (when new-name (setq files (delete new-name files)))))))
  files)

(defun git-find-status-file (status file)
  "Find a given file in the status ewoc and return its node."
  (let ((node (ewoc-nth status 0)))
    (while (and node (not (string= file (git-fileinfo->name (ewoc-data node)))))
      (setq node (ewoc-next status node)))
    node))

(defun git-run-ls-files (status files default-state &rest options)
  "Run git-ls-files on FILES and parse the results into STATUS.
Return the list of files that haven't been handled."
  (let ((refresh files))
    (with-temp-buffer
      (apply #'git-run-command t nil "ls-files" "-z" "-t" (append options (list "--") files))
      (goto-char (point-min))
      (while (re-search-forward "\\([HMRCK?]\\) \\([^\0]*\\)\0" nil t 1)
        (let ((state (match-string 1))
              (name (match-string 2)))
          (git-insert-fileinfo status (git-create-fileinfo (or (git-state-code state) default-state) name) refresh)
          (setq files (delete name files))))))
  files)

(defun git-run-ls-unmerged (status files)
  "Run git-ls-files -u on FILES and parse the results into STATUS."
  (with-temp-buffer
    (apply #'git-run-command t nil "ls-files" "-z" "-u" "--" files)
    (goto-char (point-min))
    (let (unmerged-files)
      (while (re-search-forward "[0-7]\\{6\\} [0-9a-f]\\{40\\} [123]\t\\([^\0]+\\)\0" nil t)
        (let ((node (git-find-status-file status (match-string 1))))
          (when node (push (ewoc-data node) unmerged-files))))
      (git-set-files-state unmerged-files 'unmerged))))

(defun git-get-exclude-files ()
  "Get the list of exclude files to pass to git-ls-files."
  (let (files
        (config (git-config "core.excludesfile")))
    (when (file-readable-p ".git/info/exclude")
      (push ".git/info/exclude" files))
    (when (and config (file-readable-p config))
      (push config files))
    files))

(defun git-update-status-files (files &optional default-state)
  "Update the status of FILES from the index."
  (unless git-status (error "Not in git-status buffer."))
  (let* ((status git-status)
         (remaining-files
          (if (git-empty-db-p) ; we need some special handling for an empty db
              (git-run-ls-files status files 'added "-c")
            (git-run-diff-index status files))))
    (git-run-ls-unmerged status files)
    (when (or (not files) remaining-files)
      (let ((exclude-files (git-get-exclude-files)))
        (setq remaining-files (apply #'git-run-ls-files status remaining-files 'unknown "-o"
                                     (concat "--exclude-per-directory=" git-per-dir-ignore-file)
                                     (mapcar (lambda (f) (concat "--exclude-from=" f)) exclude-files)))))
    ; mark remaining files with the default state (or remove them if nil)
    (when remaining-files
      (if default-state
          (ewoc-map (lambda (info)
                      (when (member (git-fileinfo->name info) remaining-files)
                        (git-set-files-state (list info) default-state))
                      nil)
                    status)
        (ewoc-filter status
                     (lambda (info files)
                       (not (member (git-fileinfo->name info) files)))
                     remaining-files)))
    (git-refresh-files)
    (git-refresh-ewoc-hf status)))

(defun git-marked-files ()
  "Return a list of all marked files, or if none a list containing just the file at cursor position."
  (unless git-status (error "Not in git-status buffer."))
  (or (ewoc-collect git-status (lambda (info) (git-fileinfo->marked info)))
      (list (ewoc-data (ewoc-locate git-status)))))

(defun git-marked-files-state (&rest states)
  "Return marked files that are in the specified states."
  (let ((files (git-marked-files))
        result)
    (dolist (info files)
      (when (memq (git-fileinfo->state info) states)
        (push info result)))
    result))

(defun git-refresh-files ()
  "Refresh all files that need it and clear the needs-refresh flag."
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-map
   (lambda (info)
     (let ((refresh (git-fileinfo->needs-refresh info)))
       (setf (git-fileinfo->needs-refresh info) nil)
       refresh))
   git-status)
  ; move back to goal column
  (when goal-column (move-to-column goal-column)))

(defun git-refresh-ewoc-hf (status)
  "Refresh the ewoc header and footer."
  (let ((branch (git-symbolic-ref "HEAD"))
        (head (if (git-empty-db-p) "Nothing committed yet"
                (git-get-commit-description "HEAD")))
        (merge-heads (git-get-merge-heads)))
    (ewoc-set-hf status
                 (format "Directory:  %s\nBranch:     %s\nHead:       %s%s\n"
                         default-directory
                         (if branch
                             (if (string-match "^refs/heads/" branch)
                                 (substring branch (match-end 0))
                               branch)
                           "none (detached HEAD)")
                         head
                         (if merge-heads
                             (concat "\nMerging:    "
                                     (mapconcat (lambda (str) (git-get-commit-description str)) merge-heads "\n            "))
                           ""))
                 (if (ewoc-nth status 0) "" "    No changes."))))

(defun git-get-filenames (files)
  (mapcar (lambda (info) (git-fileinfo->name info)) files))

(defun git-update-index (index-file files)
  "Run git-update-index on a list of files."
  (let ((env (and index-file `(("GIT_INDEX_FILE" . ,index-file))))
        added deleted modified)
    (dolist (info files)
      (case (git-fileinfo->state info)
        ('added (push info added))
        ('deleted (push info deleted))
        ('modified (push info modified))))
    (when added
      (apply #'git-run-command nil env "update-index" "--add" "--" (git-get-filenames added)))
    (when deleted
      (apply #'git-run-command nil env "update-index" "--remove" "--" (git-get-filenames deleted)))
    (when modified
      (apply #'git-run-command nil env "update-index" "--" (git-get-filenames modified)))))

(defun git-run-pre-commit-hook ()
  "Run the pre-commit hook if any."
  (unless git-status (error "Not in git-status buffer."))
  (let ((files (git-marked-files-state 'added 'deleted 'modified)))
    (or (not files)
        (not (file-executable-p ".git/hooks/pre-commit"))
        (let ((index-file (make-temp-file "gitidx")))
          (unwind-protect
            (let ((head-tree (unless (git-empty-db-p) (git-rev-parse "HEAD^{tree}"))))
              (git-read-tree head-tree index-file)
              (git-update-index index-file files)
              (git-run-hook "pre-commit" `(("GIT_INDEX_FILE" . ,index-file))))
          (delete-file index-file))))))

(defun git-do-commit ()
  "Perform the actual commit using the current buffer as log message."
  (interactive)
  (let ((buffer (current-buffer))
        (index-file (make-temp-file "gitidx")))
    (with-current-buffer log-edit-parent-buffer
      (if (git-marked-files-state 'unmerged)
          (message "You cannot commit unmerged files, resolve them first.")
        (unwind-protect
            (let ((files (git-marked-files-state 'added 'deleted 'modified))
                  head head-tree)
              (unless (git-empty-db-p)
                (setq head (git-rev-parse "HEAD")
                      head-tree (git-rev-parse "HEAD^{tree}")))
              (if files
                  (progn
                    (git-read-tree head-tree index-file)
                    (git-update-index nil files)         ;update both the default index
                    (git-update-index index-file files)  ;and the temporary one
                    (let ((tree (git-write-tree index-file)))
                      (if (or (not (string= tree head-tree))
                              (yes-or-no-p "The tree was not modified, do you really want to perform an empty commit? "))
                          (let ((commit (git-commit-tree buffer tree head)))
                            (condition-case nil (delete-file ".git/MERGE_HEAD") (error nil))
                            (condition-case nil (delete-file ".git/MERGE_MSG") (error nil))
                            (with-current-buffer buffer (erase-buffer))
                            (git-set-files-state files 'uptodate)
                            (git-run-command nil nil "rerere")
                            (git-refresh-files)
                            (git-refresh-ewoc-hf git-status)
                            (message "Committed %s." commit)
                            (git-run-hook "post-commit" nil))
                        (message "Commit aborted."))))
                (message "No files to commit.")))
          (delete-file index-file))))))


;;;; Interactive functions
;;;; ------------------------------------------------------------

(defun git-mark-file ()
  "Mark the file that the cursor is on and move to the next one."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let* ((pos (ewoc-locate git-status))
         (info (ewoc-data pos)))
    (setf (git-fileinfo->marked info) t)
    (ewoc-invalidate git-status pos)
    (ewoc-goto-next git-status 1)))

(defun git-unmark-file ()
  "Unmark the file that the cursor is on and move to the next one."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let* ((pos (ewoc-locate git-status))
         (info (ewoc-data pos)))
    (setf (git-fileinfo->marked info) nil)
    (ewoc-invalidate git-status pos)
    (ewoc-goto-next git-status 1)))

(defun git-unmark-file-up ()
  "Unmark the file that the cursor is on and move to the previous one."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let* ((pos (ewoc-locate git-status))
         (info (ewoc-data pos)))
    (setf (git-fileinfo->marked info) nil)
    (ewoc-invalidate git-status pos)
    (ewoc-goto-prev git-status 1)))

(defun git-mark-all ()
  "Mark all files."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-map (lambda (info) (setf (git-fileinfo->marked info) t) t) git-status)
  ; move back to goal column after invalidate
  (when goal-column (move-to-column goal-column)))

(defun git-unmark-all ()
  "Unmark all files."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-map (lambda (info) (setf (git-fileinfo->marked info) nil) t) git-status)
  ; move back to goal column after invalidate
  (when goal-column (move-to-column goal-column)))

(defun git-toggle-all-marks ()
  "Toggle all file marks."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-map (lambda (info) (setf (git-fileinfo->marked info) (not (git-fileinfo->marked info))) t) git-status)
  ; move back to goal column after invalidate
  (when goal-column (move-to-column goal-column)))

(defun git-next-file (&optional n)
  "Move the selection down N files."
  (interactive "p")
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-goto-next git-status n))

(defun git-prev-file (&optional n)
  "Move the selection up N files."
  (interactive "p")
  (unless git-status (error "Not in git-status buffer."))
  (ewoc-goto-prev git-status n))

(defun git-next-unmerged-file (&optional n)
  "Move the selection down N unmerged files."
  (interactive "p")
  (unless git-status (error "Not in git-status buffer."))
  (let* ((last (ewoc-locate git-status))
         (node (ewoc-next git-status last)))
    (while (and node (> n 0))
      (when (eq 'unmerged (git-fileinfo->state (ewoc-data node)))
        (setq n (1- n))
        (setq last node))
      (setq node (ewoc-next git-status node)))
    (ewoc-goto-node git-status last)))

(defun git-prev-unmerged-file (&optional n)
  "Move the selection up N unmerged files."
  (interactive "p")
  (unless git-status (error "Not in git-status buffer."))
  (let* ((last (ewoc-locate git-status))
         (node (ewoc-prev git-status last)))
    (while (and node (> n 0))
      (when (eq 'unmerged (git-fileinfo->state (ewoc-data node)))
        (setq n (1- n))
        (setq last node))
      (setq node (ewoc-prev git-status node)))
    (ewoc-goto-node git-status last)))

(defun git-add-file ()
  "Add marked file(s) to the index cache."
  (interactive)
  (let ((files (git-get-filenames (git-marked-files-state 'unknown))))
    (unless files
      (push (file-relative-name (read-file-name "File to add: " nil nil t)) files))
    (apply #'git-run-command nil nil "update-index" "--add" "--" files)
    (git-update-status-files files 'uptodate)))

(defun git-ignore-file ()
  "Add marked file(s) to the ignore list."
  (interactive)
  (let ((files (git-get-filenames (git-marked-files-state 'unknown))))
    (unless files
      (push (file-relative-name (read-file-name "File to ignore: " nil nil t)) files))
    (dolist (f files) (git-append-to-ignore f))
    (git-update-status-files files 'ignored)))

(defun git-remove-file ()
  "Remove the marked file(s)."
  (interactive)
  (let ((files (git-get-filenames (git-marked-files-state 'added 'modified 'unknown 'uptodate))))
    (unless files
      (push (file-relative-name (read-file-name "File to remove: " nil nil t)) files))
    (if (yes-or-no-p
         (format "Remove %d file%s? " (length files) (if (> (length files) 1) "s" "")))
        (progn
          (dolist (name files)
            (when (file-exists-p name) (delete-file name)))
          (apply #'git-run-command nil nil "update-index" "--remove" "--" files)
          (git-update-status-files files nil))
      (message "Aborting"))))

(defun git-revert-file ()
  "Revert changes to the marked file(s)."
  (interactive)
  (let ((files (git-marked-files))
        added modified)
    (when (and files
               (yes-or-no-p
                (format "Revert %d file%s? " (length files) (if (> (length files) 1) "s" ""))))
      (dolist (info files)
        (case (git-fileinfo->state info)
          ('added (push (git-fileinfo->name info) added))
          ('deleted (push (git-fileinfo->name info) modified))
          ('unmerged (push (git-fileinfo->name info) modified))
          ('modified (push (git-fileinfo->name info) modified))))
      (when added
        (apply #'git-run-command nil nil "update-index" "--force-remove" "--" added))
      (when modified
        (apply #'git-run-command nil nil "checkout" "HEAD" modified))
      (git-update-status-files (append added modified) 'uptodate))))

(defun git-resolve-file ()
  "Resolve conflicts in marked file(s)."
  (interactive)
  (let ((files (git-get-filenames (git-marked-files-state 'unmerged))))
    (when files
      (apply #'git-run-command nil nil "update-index" "--" files)
      (git-update-status-files files 'uptodate))))

(defun git-remove-handled ()
  "Remove handled files from the status list."
  (interactive)
  (ewoc-filter git-status
               (lambda (info)
                 (not (or (eq (git-fileinfo->state info) 'ignored)
                          (eq (git-fileinfo->state info) 'uptodate)))))
  (unless (ewoc-nth git-status 0)  ; refresh header if list is empty
    (git-refresh-ewoc-hf git-status)))

(defun git-setup-diff-buffer (buffer)
  "Setup a buffer for displaying a diff."
  (let ((dir default-directory))
    (with-current-buffer buffer
      (diff-mode)
      (goto-char (point-min))
      (setq default-directory dir)
      (setq buffer-read-only t)))
  (display-buffer buffer)
  (shrink-window-if-larger-than-buffer))

(defun git-diff-file ()
  "Diff the marked file(s) against HEAD."
  (interactive)
  (let ((files (git-marked-files)))
    (git-setup-diff-buffer
     (apply #'git-run-command-buffer "*git-diff*" "diff-index" "-p" "-M" "HEAD" "--" (git-get-filenames files)))))

(defun git-diff-file-merge-head (arg)
  "Diff the marked file(s) against the first merge head (or the nth one with a numeric prefix)."
  (interactive "p")
  (let ((files (git-marked-files))
        (merge-heads (git-get-merge-heads)))
    (unless merge-heads (error "No merge in progress"))
    (git-setup-diff-buffer
     (apply #'git-run-command-buffer "*git-diff*" "diff-index" "-p" "-M"
            (or (nth (1- arg) merge-heads) "HEAD") "--" (git-get-filenames files)))))

(defun git-diff-unmerged-file (stage)
  "Diff the marked unmerged file(s) against the specified stage."
  (let ((files (git-marked-files)))
    (git-setup-diff-buffer
     (apply #'git-run-command-buffer "*git-diff*" "diff-files" "-p" stage "--" (git-get-filenames files)))))

(defun git-diff-file-base ()
  "Diff the marked unmerged file(s) against the common base file."
  (interactive)
  (git-diff-unmerged-file "-1"))

(defun git-diff-file-mine ()
  "Diff the marked unmerged file(s) against my pre-merge version."
  (interactive)
  (git-diff-unmerged-file "-2"))

(defun git-diff-file-other ()
  "Diff the marked unmerged file(s) against the other's pre-merge version."
  (interactive)
  (git-diff-unmerged-file "-3"))

(defun git-diff-file-combined ()
  "Do a combined diff of the marked unmerged file(s)."
  (interactive)
  (git-diff-unmerged-file "-c"))

(defun git-diff-file-idiff ()
  "Perform an interactive diff on the current file."
  (interactive)
  (let ((files (git-marked-files-state 'added 'deleted 'modified)))
    (unless (eq 1 (length files))
      (error "Cannot perform an interactive diff on multiple files."))
    (let* ((filename (car (git-get-filenames files)))
           (buff1 (find-file-noselect filename))
           (buff2 (git-run-command-buffer (concat filename ".~HEAD~") "cat-file" "blob" (concat "HEAD:" filename))))
      (ediff-buffers buff1 buff2))))

(defun git-log-file ()
  "Display a log of changes to the marked file(s)."
  (interactive)
  (let* ((files (git-marked-files))
         (coding-system-for-read git-commits-coding-system)
         (buffer (apply #'git-run-command-buffer "*git-log*" "rev-list" "--pretty" "HEAD" "--" (git-get-filenames files))))
    (with-current-buffer buffer
      ; (git-log-mode)  FIXME: implement log mode
      (goto-char (point-min))
      (setq buffer-read-only t))
    (display-buffer buffer)))

(defun git-log-edit-files ()
  "Return a list of marked files for use in the log-edit buffer."
  (with-current-buffer log-edit-parent-buffer
    (git-get-filenames (git-marked-files-state 'added 'deleted 'modified))))

(defun git-append-sign-off (name email)
  "Append a Signed-off-by entry to the current buffer, avoiding duplicates."
  (let ((sign-off (format "Signed-off-by: %s <%s>" name email))
        (case-fold-search t))
    (goto-char (point-min))
    (unless (re-search-forward (concat "^" (regexp-quote sign-off)) nil t)
      (goto-char (point-min))
      (unless (re-search-forward "^Signed-off-by: " nil t)
        (setq sign-off (concat "\n" sign-off)))
      (goto-char (point-max))
      (insert sign-off "\n"))))

(defun git-setup-log-buffer (buffer &optional author-name author-email subject date msg)
  "Setup the log buffer for a commit."
  (unless git-status (error "Not in git-status buffer."))
  (let ((merge-heads (git-get-merge-heads))
        (dir default-directory)
        (committer-name (git-get-committer-name))
        (committer-email (git-get-committer-email))
        (sign-off git-append-signed-off-by))
    (with-current-buffer buffer
      (cd dir)
      (erase-buffer)
      (insert
       (propertize
        (format "Author: %s <%s>\n%s%s"
                (or author-name committer-name)
                (or author-email committer-email)
                (if date (format "Date: %s\n" date) "")
                (if merge-heads
                    (format "Parent: %s\n%s\n"
                            (git-rev-parse "HEAD")
                            (mapconcat (lambda (str) (concat "Parent: " str)) merge-heads "\n"))
                  ""))
        'face 'git-header-face)
       (propertize git-log-msg-separator 'face 'git-separator-face)
       "\n")
      (when subject (insert subject "\n\n"))
      (cond (msg (insert msg "\n"))
            ((file-readable-p ".dotest/msg")
             (insert-file-contents ".dotest/msg"))
            ((file-readable-p ".git/MERGE_MSG")
             (insert-file-contents ".git/MERGE_MSG")))
      ; delete empty lines at end
      (goto-char (point-min))
      (when (re-search-forward "\n+\\'" nil t)
        (replace-match "\n" t t))
      (when sign-off (git-append-sign-off committer-name committer-email)))))

(defun git-commit-file ()
  "Commit the marked file(s), asking for a commit message."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (when (git-run-pre-commit-hook)
    (let ((buffer (get-buffer-create "*git-commit*"))
          (coding-system (git-get-commits-coding-system))
          author-name author-email subject date)
      (when (eq 0 (buffer-size buffer))
        (when (file-readable-p ".dotest/info")
          (with-temp-buffer
            (insert-file-contents ".dotest/info")
            (goto-char (point-min))
            (when (re-search-forward "^Author: \\(.*\\)\nEmail: \\(.*\\)$" nil t)
              (setq author-name (match-string 1))
              (setq author-email (match-string 2)))
            (goto-char (point-min))
            (when (re-search-forward "^Subject: \\(.*\\)$" nil t)
              (setq subject (match-string 1)))
            (goto-char (point-min))
            (when (re-search-forward "^Date: \\(.*\\)$" nil t)
              (setq date (match-string 1)))))
        (git-setup-log-buffer buffer author-name author-email subject date))
      (log-edit #'git-do-commit nil #'git-log-edit-files buffer)
      (setq font-lock-keywords (font-lock-compile-keywords git-log-edit-font-lock-keywords))
      (setq buffer-file-coding-system coding-system)
      (re-search-forward (regexp-quote (concat git-log-msg-separator "\n")) nil t))))

(defun git-find-file ()
  "Visit the current file in its own buffer."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let ((info (ewoc-data (ewoc-locate git-status))))
    (find-file (git-fileinfo->name info))
    (when (eq 'unmerged (git-fileinfo->state info))
      (smerge-mode 1))))

(defun git-find-file-other-window ()
  "Visit the current file in its own buffer in another window."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let ((info (ewoc-data (ewoc-locate git-status))))
    (find-file-other-window (git-fileinfo->name info))
    (when (eq 'unmerged (git-fileinfo->state info))
      (smerge-mode))))

(defun git-find-file-imerge ()
  "Visit the current file in interactive merge mode."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let ((info (ewoc-data (ewoc-locate git-status))))
    (find-file (git-fileinfo->name info))
    (smerge-ediff)))

(defun git-view-file ()
  "View the current file in its own buffer."
  (interactive)
  (unless git-status (error "Not in git-status buffer."))
  (let ((info (ewoc-data (ewoc-locate git-status))))
    (view-file (git-fileinfo->name info))))

(defun git-refresh-status ()
  "Refresh the git status buffer."
  (interactive)
  (let* ((status git-status)
         (pos (ewoc-locate status))
         (cur-name (and pos (git-fileinfo->name (ewoc-data pos)))))
    (unless status (error "Not in git-status buffer."))
    (git-run-command nil nil "update-index" "--refresh")
    (git-clear-status status)
    (git-update-status-files nil)
    ; move point to the current file name if any
    (let ((node (and cur-name (git-find-status-file status cur-name))))
      (when node (ewoc-goto-node status node)))))

(defun git-status-quit ()
  "Quit git-status mode."
  (interactive)
  (bury-buffer))

;;;; Major Mode
;;;; ------------------------------------------------------------

(defvar git-status-mode-hook nil
  "Run after `git-status-mode' is setup.")

(defvar git-status-mode-map nil
  "Keymap for git major mode.")

(defvar git-status nil
  "List of all files managed by the git-status mode.")

(unless git-status-mode-map
  (let ((map (make-keymap))
        (diff-map (make-sparse-keymap)))
    (suppress-keymap map)
    (define-key map "?"   'git-help)
    (define-key map "h"   'git-help)
    (define-key map " "   'git-next-file)
    (define-key map "a"   'git-add-file)
    (define-key map "c"   'git-commit-file)
    (define-key map "d"    diff-map)
    (define-key map "="   'git-diff-file)
    (define-key map "f"   'git-find-file)
    (define-key map "\r"  'git-find-file)
    (define-key map "g"   'git-refresh-status)
    (define-key map "i"   'git-ignore-file)
    (define-key map "l"   'git-log-file)
    (define-key map "m"   'git-mark-file)
    (define-key map "M"   'git-mark-all)
    (define-key map "n"   'git-next-file)
    (define-key map "N"   'git-next-unmerged-file)
    (define-key map "o"   'git-find-file-other-window)
    (define-key map "p"   'git-prev-file)
    (define-key map "P"   'git-prev-unmerged-file)
    (define-key map "q"   'git-status-quit)
    (define-key map "r"   'git-remove-file)
    (define-key map "R"   'git-resolve-file)
    (define-key map "T"   'git-toggle-all-marks)
    (define-key map "u"   'git-unmark-file)
    (define-key map "U"   'git-revert-file)
    (define-key map "v"   'git-view-file)
    (define-key map "x"   'git-remove-handled)
    (define-key map "\C-?" 'git-unmark-file-up)
    (define-key map "\M-\C-?" 'git-unmark-all)
    ; the diff submap
    (define-key diff-map "b" 'git-diff-file-base)
    (define-key diff-map "c" 'git-diff-file-combined)
    (define-key diff-map "=" 'git-diff-file)
    (define-key diff-map "e" 'git-diff-file-idiff)
    (define-key diff-map "E" 'git-find-file-imerge)
    (define-key diff-map "h" 'git-diff-file-merge-head)
    (define-key diff-map "m" 'git-diff-file-mine)
    (define-key diff-map "o" 'git-diff-file-other)
    (setq git-status-mode-map map)))

;; git mode should only run in the *git status* buffer
(put 'git-status-mode 'mode-class 'special)

(defun git-status-mode ()
  "Major mode for interacting with Git.
Commands:
\\{git-status-mode-map}"
  (kill-all-local-variables)
  (buffer-disable-undo)
  (setq mode-name "git status"
        major-mode 'git-status-mode
        goal-column 17
        buffer-read-only t)
  (use-local-map git-status-mode-map)
  (let ((buffer-read-only nil))
    (erase-buffer)
  (let ((status (ewoc-create 'git-fileinfo-prettyprint "" "")))
    (set (make-local-variable 'git-status) status))
  (set (make-local-variable 'list-buffers-directory) default-directory)
  (run-hooks 'git-status-mode-hook)))

(defun git-find-status-buffer (dir)
  "Find the git status buffer handling a specified directory."
  (let ((list (buffer-list))
        (fulldir (expand-file-name dir))
        found)
    (while (and list (not found))
      (let ((buffer (car list)))
        (with-current-buffer buffer
          (when (and list-buffers-directory
                     (string= fulldir (expand-file-name list-buffers-directory))
                     (string-match "\\*git-status\\*$" (buffer-name buffer)))
            (setq found buffer))))
      (setq list (cdr list)))
    found))

(defun git-status (dir)
  "Entry point into git-status mode."
  (interactive "DSelect directory: ")
  (setq dir (git-get-top-dir dir))
  (if (file-directory-p (concat (file-name-as-directory dir) ".git"))
      (let ((buffer (or (and git-reuse-status-buffer (git-find-status-buffer dir))
                        (create-file-buffer (expand-file-name "*git-status*" dir)))))
        (switch-to-buffer buffer)
        (cd dir)
        (git-status-mode)
        (git-refresh-status)
        (goto-char (point-min)))
    (message "%s is not a git working tree." dir)))

(defun git-help ()
  "Display help for Git mode."
  (interactive)
  (describe-function 'git-status-mode))

(provide 'git)
;;; git.el ends here
