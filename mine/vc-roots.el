;;; vc-roots.el --- Handle VC Root Directories.
;; Author: Per Nordlöw
;; TODO: Reuse refactor out presentation logic from tscan.el by supporting a custom list/tree of directories just to show.

(require 'fcache)
(require 'vc-dir)
(require 'directory-has)

(defvar vc-roots-buffer-name "*vc-roots*"
  "VC Root Directories Buffer Name.")

(defvar vc-roots-db nil
  "List of VC Root Directories.
An entry is either a string path or a (ROOT-DIR BACKENDS-SYMBOL-LIST")
;;(add-to-list 'desktop-globals-to-save 'vc-roots-db)
;;(delete-list-members 'desktop-globals-to-save 'vc-roots-db)

(defun vc-root-id (vc-root)
  "Return Id Part of VC Root VC-ROOT Directory ROOT."
  (first vc-root))
(defun vc-root-type (vc-root)
  "Return Type Part of VC Root VC-ROOT Directory ROOT."
  (second vc-root))
(defun vc-root-origin (vc-root)
  "Return Type Part of VC Root VC-ROOT Directory ROOT."
  (third vc-root))
(defun make-vc-root (id type origin)
  "Return a newly created VC Root Specification."
  (list id type origin))

(defun vc-root-path (vc-root)
  "Return Path part of VC Vc-Root Directory ROOT."
  (let* ((id (vc-root-id vc-root))
         (name (cond ((stringp id)
                      id)
                     ((fcachep id)
                      (fcache-full-fname id)))))
    name))

;; vc-directory-exclusion-list (".wact" "SCCS" "RCS" "CVS" "MCVS" ".svn" ".git" ".hg" ".bzr" "_MTN" "_darcs" "{arch}")
(defconst vc-backend-dir-type
  '(("SCCS" SCCS)                       ;SCCS
    ("RCS" RCS)                         ;RCS
    ("CVS" CVS)                         ;CVS
    ("MCVS" MCVS)                       ;MCVS
    (".svn" SVN)                        ;Subversion
    (".git" Git)                        ;Git
    (".hg" Hg)                          ;Mercurial
    (".bzr" Bzr)                        ;Bzr
    ("_MTN" Mtn)                        ;Monotone
    (".mtn" Mtn)                        ;Monotone
    ("_darcs" Darcs)                    ;Darcs
    ("{arch}" Arch)                     ;Arch
    (".wact" WACT)                      ;WACT
    )
  "Alist mapping VC directory name to type.")
;; Use: (assoc "CVS" vc-backend-dir-type)

(defun file-vc-root-directory-p (&optional directory)
  "Return VC-Type of DIRECTORY if it is a Version Control (VC) Root Directory."
  (let (case-fold-search)               ;Note: Case-Sensitive!
    (let ((directory (or directory
                         default-directory))
          (hit (directory-has-any-p directory vc-directory-exclusion-list)))
      (and hit
           (cond ((member directory '("RCS" "CVS" ".svn"))
                  ;; trace-directory-upwards-r
                  nil)
                 (t
                  (let* ((vc-dir (abbreviate-file-name (directory-file-name (file-name-directory hit))))
                         (vc-backend-symbol (cadr (assoc (file-name-sans-directory hit) vc-backend-dir-type))))
                    (when nil           ;NOTE: Disabled because this takes too long.
                      (add-to-list 'vc-roots-db (make-vc-root vc-dir
                                                              vc-backend-symbol
                                                              (vc-origin vc-dir vc-backend-symbol))))
                    vc-backend-symbol)))))))
;; Use: (file-vc-root-directory-p (elsub "nxhtml/"))
;; Use: (file-vc-root-directory-p (elsub "~/elisp/structured-haskell-mode/"))
;; Use: (file-vc-root-directory-p (elsub "mine"))
;; Use: (file-vc-root-directory-p "/bin/ls")
;; Use: (file-vc-root-directory-p "~/ware/ctags/")
;; Use: (file-vc-root-directory-p "~/cognia/")

(defun vc-roots-inspect-directory (&optional directory)
  (file-vc-root-directory-p directory)
  ;; TODO: nil is needed for correct behaviour when `vc-roots-inspect-directory' is
  ;; added to `find-directory-functions'.
  nil)

(defun file-under-vc-directory-p (file &optional dir multi halt-dir)
  "Return Bottom-Most Parenting Version Control Root as (VC-ROOT-DIRECTORY . VC-ROOT-BACKEND-SYMBOL).
If MULTI is non-nil return a list of all version controlled
parenting directories of FILE as (VC-ROOT-DIR . BACKEND-SYMBOL).
Possible values for VC-ROOT-BACKEND-SYMBOL are found in `vc-backend-dir-type'."
  (let (case-fold-search                           ;Note: Case-Sensitive!
        (dir (or dir (file-name-directory file)))) ;get file directory
    (trace-directory-upwards-r 'file-vc-root-directory-p dir multi halt-dir)))
;; Use: (file-under-vc-directory-p "~/cognia/vec2f.h")
;; Use: (file-under-vc-directory-p "~/cognia/nxhtml")
;; Use: (file-under-vc-directory-p (elsub "yasnippet"))
;; Use: (file-under-vc-directory-p "~/cognia/semnet/preg.hpp")
;; Use: (file-under-vc-directory-p "~/cognia/f.j")
;; Use: (file-under-vc-directory-p "~/cognia/")
;; Use: (file-under-vc-directory-p (elsub "nxhtml/autostart.el"))
;; Use: (file-under-vc-directory-p (elsub "nxhtml/autostart.el") nil t)
;; Use: (file-under-vc-directory-p (elsub "others"))
;; Use: (file-under-vc-directory-p (elsub "mine"))
;; Use: (file-under-vc-directory-p (elsub "yasnippet"))
;; Use: (file-under-vc-directory-p (elsub "yasnippet/"))
;; Use: (file-under-vc-directory-p (elsub "nxhtml/autostart.el"))
;; Use: (file-under-vc-directory-p (elsub "nxhtml/autostart.el"))
;; Use: (file-under-vc-directory-p (elsub "nxhtml/autostart.el") nil t)

(defun vc-roots-reset ()
  "Clear Internal Database of all VC Root Directories."
  (setq vc-roots-db nil))

(defun vc-roots-log-subs (parent)
  (let ((subs (directory-files-of-types parent 'Version-Controlled-Directory)))
    (dolist (sub subs)
      (when sub
        (file-vc-root-directory-p (expand-file-name sub parent))))))
(defun vc-roots-log-defaults ()
  (vc-roots-log-subs "~/")
  (vc-roots-log-subs "~/texmf/tex")
  (vc-roots-log-subs "~/bin")
  (vc-roots-log-subs "~/.gdb")
  (vc-roots-log-subs "~/alt")
  (vc-roots-log-subs "~/cognia")
  (vc-roots-log-subs "~/cognia/deps")
  (vc-roots-log-subs (elsub "others"))
  (vc-roots-log-subs "~/ware")
  (vc-roots-log-subs "~/Work/unique-ware")
  (vc-roots-log-subs "~/Work")
  (vc-roots-log-subs "~/FOI")
  (vc-roots-log-subs "~/Work/MATLAB")
  )
(eval-when-compile
  (vc-roots-reset)
  ;;(vc-roots-log-defaults)
  )

;;; Hooks when visiting directories
(setq find-directory-functions
      (delete 'file-vc-root-directory-p find-directory-functions))
(add-to-list 'find-directory-functions 'vc-roots-inspect-directory)
(add-hook 'vc-dir-mode-hook 'file-vc-root-directory-p)
(add-hook 'dired-mode-hook 'file-vc-root-directory-p)

(defun vc-roots-sort ()
  (setq vc-roots-db
        (sort vc-roots-db
              (lambda (root-spec-1
                       root-spec-2)
                ;; TODO: Replace with `fcache-path-lessp' function
                (string-lessp (vc-root-path root-spec-1)
                              (vc-root-path root-spec-2))))))

(defun vc-roots-list ()
  "List All Logged VC Root Directories."
  (interactive)
  (vc-roots-sort)
  (save-current-buffer
    (let ((buf (get-buffer-create vc-roots-buffer-name)))
      (pop-to-buffer buf)
      (setq buffer-read-only nil)
      (erase-buffer)
      (dolist (vc-root vc-roots-db)
        (if (listp vc-root)
            (let* ((path (vc-root-path vc-root))
                   (type (vc-root-type vc-root))
                   (origin (vc-root-origin vc-root)))
              (let ((beg (point)))
                (insert path
                        " ["
                        (propertize
                         (if (symbolp type) (symbol-name type) type)
                         'face 'font-lock-type-face)
                        ;; (mapconcat
                        ;;  (lambda (type)
                        ;;    (propertize
                        ;;     (if (symbolp type) (symbol-name type) type)
                        ;;     'face 'font-lock-type-face))
                        ;;  (symbol-name (vc-root-type vc-root)) ",")
                        "]"
                        "\n")
                (make-text-button beg (+ beg (length path))
                                  'face 'font-lock-directory-name-face
                                  'target vc-root))) ;TODO: Link executes (vc-dir DIR)
          (insert (propertize vc-root 'face 'font-lock-directory-name-face) "\n")))
      (setq buffer-read-only t)
      (goto-char (point-min)))))
(defalias 'list-vc-roots 'vc-roots-list)
(define-key vc-prefix-map [?R] 'vc-roots-list)

(defun vc-roots-status ()
  "Status All Logged VC Root Directories."
  (interactive)
  (save-window-excursion
    (dolist (vc-root vc-roots-db)
      (vc-dir (vc-root-path vc-root)))))
(define-key vc-prefix-map [?S] 'vc-roots-status)

;;; ==================================================================================================

(defun vc-svn-origin (root-directory)
  "Show Origin of Subversion (SVN) ROOT-DIRECTORY."
  (let ((default-directory root-directory))
    (replace-regexp-in-string
     (rx (: (* anything) "URL: "
            (group (+ any)) "\n"
            (* anything)))
     "\\1"
     (shell-command-to-string (concat "pushd " root-directory "; svn info")) ;TODO: Replace with call-process
     )))
;; Use: (vc-svn-origin "~/elisp/ruby-mode")

(defun vc-git-origin (root-directory)
  "Show Origin of Git ROOT-DIRECTORY."
  (let ((default-directory root-directory))
    (when (> (length (shell-command-to-string (concat "pushd " root-directory "; git remote"))) 0)
      (replace-regexp-in-string
       (rx (: (* anything) "Fetch URL: "
              (group (+ any)) "\n"
              (* anything)))
       "\\1"
       (shell-command-to-string (concat "pushd " root-directory "; git remote show origin")) ;TODO: Replace with call-process
       ))))
;; Use: (vc-git-origin "~/elisp")
;; Use: (benchmark-run 100 (vc-git-origin "~/elisp"))
;; Use: (vc-git-origin "~/elisp/icicles")

(defun vc-origin (root-directory &optional backend)
  "Return origin of directory ROOT."
  (case backend
    (RCS)
    (CVS )
    (SVN (vc-svn-origin root-directory))
    (SCCS)
    (Bzr )
    (Git (vc-git-origin root-directory))
    (Hg )
    (Mtn )
    (Arch)
    (DARCS )))
;; Use: (vc-origin "~/elisp/icicles" 'Git)
(defalias 'vc-remote-url 'vc-origin)

;;; ==================================================================================================

(defun vc-git-remote (root-directory)
  (ignore-errors (cscan-file (expand-file-name ".git/config" root-directory) "[remote \"origin\"]")))

(defun vc-bzr-remote (root-directory)
  (ignore-errors (cscan-file (expand-file-name ".bzr/branch/branch.conf" root-directory) "parent_location = ")))

(defun vc-hg-remote (root-directory)
  (ignore-errors (cscan-file (expand-file-name ".hg/hgrc" root-directory) "default = ")))

(defun vc-svn-remote (root-directory)
  (ignore-errors (cscan-file (expand-file-name ".svn/entries" root-directory)
                             (rx
                              ;;bol (+ (in "0-9")) (* "\n")
                              bol (| "https" "svn") "://"
                              )
                             nil t)))

(defun vc-cvs-remote (root-directory)
  (ignore-errors (cscan-file (expand-file-name "CVS/Root" root-directory) (rx (| ":ext:"
                                                                       ":pserver:")) 0 t)))

(defun vc-remote (root-directory &optional backend)
  "Return remote of directory ROOT if exists, nil otherwise."
  (let* ((root (file-under-vc-directory-p (file-name-as-directory root-directory)))
         (backend (or backend (cdr root))))
    (case backend
      (RCS)
      (CVS)
      (SVN (vc-svn-remote root-directory))
      (SCCS)
      (Bzr (vc-bzr-remote root-directory))
      (Git (vc-git-remote root-directory))
      (Hg (vc-hg-remote root-directory))
      (Mtn)
      (Arch)
      (DARCS))))

;;; ==================================================================================================

(defun vc-roots-clear-cached-states-under (&optional directory)
  "Clear all cached statuses (`vc-states') for all VC roots under DIRECTORY.
DIRECTORY defaults to `default-directory'."
  (setq vc-roots-db (delq nil
                          (mapcar
                           (lambda (vc-root)
                             (let* ((path (vc-root-path vc-root)))
                               (if (directory-has-file-p (or directory
                                                             default-directory) path)
                                   (vc-states-forget-directory path)
                                 vc-root)))
                           vc-roots-db))))
(when nil
  (progn (vc-roots-clear-cached-states-under "~/elisp/mine") nil)
  (progn (vc-roots-reset)
         (vc-roots-log-defaults)
         (vc-roots-clear-cached-states-under "~/cognia")))

(defun vc-roots-states-get (&optional directory)
  (let ((vc-type (file-under-vc-directory-p directory)))
    (when vc-type
      (vc-states-get directory))))
;; (vc-roots-states-get (elsub "others"))

(defun vc-remote-origin-p (directory)
  "Return non-nil if DIRECTORY has a remote origin."
  (or (vc-git-remote directory)
      (vc-bzr-remote directory)
      (vc-hg-remote directory)
      (vc-svn-remote directory)
      (vc-cvs-remote directory)
      ))
;; (vc-remote-origin-p "~/elisp/icicles")

(defun vc-roots-pull ()
  "Update All Logged VC Root Directories."
  (interactive)
  (message "Pulling/Updating all VC Dirs...")
  (save-window-excursion
    (dolist (vc-root vc-roots-db)
      (let* ((id (vc-root-id vc-root))
             (dir (vc-root-path vc-root)))
        (when (vc-remote-origin-p dir)
          (when (ignore-errors (vc-dir dir))
            (let ((default-directory dir))
              (vc-pull)
              (let ((pull-process (get-buffer-process vc-dir-process-buffer)))
                (setcdr (cdr vc-root) pull-process))))))))
  (message "Pulling/Updating of all VC Dirs done"))
(defalias 'vc-roots-update 'vc-roots-pull)
(define-key vc-prefix-map [?P] 'vc-roots-pull)
(define-key vc-prefix-map [?U] 'vc-roots-update)

(provide 'vc-roots)
