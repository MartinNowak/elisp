;;; vc-states.el --- Multi-File Version of `vc-state'.
;;; see: http://stackoverflow.com/questions/13710433/multi-file-version-of-vc-state/13730286#13730286

(require 'vc-roots)
(require 'fcache)

(defconst vc-git-state-translation
  '((?\ . up-to-date)                    ;or `unmodified'
    (?M . edited)                        ;`modified'
    (?A . added)
    (?D . removed)                      ;`deleted'
    (?C . copied)
    (?U . edited)
    (?T . edited)
    (?? . unregistered)                  ;`unknown', `untracked'
    (?! . ignored))
  "Git State Codes Table.")

(defun vc-git--state-char-code (code-x code-y)
  "For documentation see git status --help."
  (cdr (assq code-y vc-git-state-translation)))
(defun vc-git-state-string-code (str)
  (cons (directory-file-name (substring str 3))
        (vc-git--state-char-code (elt str 0) (elt str 1))))

(defconst vc-bzr-state-translation
  '(("+N " . added)
    ("-D " . removed)                   ;`deleted'
    (" M " . edited)                    ;file text modified
    ("  *" . edited)                    ;execute bit changed
    (" M*" . edited)                    ;text modified + execute bit changed
    ("I  " . ignored)
    (" D " . missing)
    ;; For conflicts, should we list the .THIS/.BASE/.OTHER?
    ("C  " . conflicted)
    ("?  " . unregistered)
    ;; No such state, but we need to distinguish this case.
    ("R  " . renamed)
    ("RM " . renamed)
    ;; For a non existent file FOO, the output is:
    ;; bzr: ERROR: Path(s) do not exist: FOO
    ("bzr" . not-found)
    ;; If the tree is not up to date, bzr will print this warning:
    ;; working tree is out of date, run 'bzr update'
    ;; ignore it.
    ;; FIXME: maybe this warning can be put in the vc-dir header...
    ("wor" . not-found)
    ;; Ignore "P " and "P." for pending patches.
    ("P  " . not-found)
    ("P. " . not-found)
    )
  "Bzr State Codes Table.
Copied from function `vc-bzr-after-dir-status'.")
(defun vc-bzr-state-string-code (str)
  (cons (directory-file-name (substring str 4))
        (cdr (assoc (substring str 0 3) vc-bzr-state-translation))))

(defconst vc-svn-state-1-translation
  '((?A . added)
    (?C . conflicted)
    (?I . ignored)
    (?M . edited)                       ;`modified'
    (?D . removed)                      ;`deleted'
    (?R . replaced)
    (?X . unversioned-external)         ;an unversioned directory created by an externals definition
    (?? . unregistered)                 ;item is not under version control
    (?~ . edited)
    (?! . missing)                      ;missing (removed by non-svn command) or incomplete
    )
  "Subversion State Codes First Column Table.
Copied from function `vc-svn-after-dir-status'.
Do `svn status --help' for more documentation.")
(defconst vc-svn-state-file-or-directory-properties
  '((?C . properties-conflicted)
    (?M . properties-modified)
    ) "Subversion State Codes Second Column Table.
 Modifications of a file's or directory's properties.")
(defconst vc-svn-state-working-copy-directory-lock-status
  '((?\  . wcd-unlocked)
    (?L . wcd-locked)
    ) "Subversion State Codes Third Column Table.")

(defun vc-svn-state-string-code (str)
  (cons (directory-file-name (substring str 8))
        (cdr (assq (string-to-char str) vc-svn-state-1-translation))))

(defconst vc-hg-state-translation
  '((?M . edited)                       ;`modified'
    (?A . added)
    (?R . removed)                      ;`deleted'
    (?C . up-to-date)                   ;`clean'
    (?! . missing)                      ;deleted by non-hg command, but still tracked
    (?? . unregistered)                 ;`untracked', `not-tracked'
    (?I . ignored)
    )
  "Mercurial State Codes (character in string) Table.")
(defun vc-hg-state-string-code (str)
  (cons (directory-file-name (substring str 2))
        (cdr (assq (string-to-char str) vc-hg-state-translation))))

(defconst vc-mtn-state-translation
  '((?M . edited)
    (?? . unregistered))
  "Monotone State Codes (character in string) Table.")
(defun vc-mtn-state-string-code (str)
  (cons (directory-file-name (substring str 2))
        (cdr (assq (string-to-char str) vc-mtn-state-translation))))

(defconst vc-darcs-state-translation
  '((?a . added)
    (?M . edited)
    (?? . unregistered))
  "DARCS State Codes (character in string) Table.")
(defun vc-darcs-state-string-code (str)
  (cons (directory-file-name (substring str 4))
        (cdr (assq (string-to-char str) vc-darcs-state-translation))))

(defun process-lines-filtered (program filter &rest args)
  "Do `process-lines' and then apply FILTER on each line."
  (with-temp-buffer
    (let ((status (apply 'call-process program nil (current-buffer) nil args)))
      (unless (eq status 0)
        (error "%s exited with status %s" program status))
      (goto-char (point-min))
      (let (lines)
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position)
                       (line-end-position))))
            (setq lines (cons (funcall filter line) lines)))
          (forward-line 1))
        (nreverse lines)))))

(defun vc-states (directory &optional backend tree updates)
  "Do `vc-state' on DIRECTORY's files.
If TREE is non-nil status whole tree not just DIRECTORY."
  (let ((default-directory (file-name-as-directory directory)))
    (let ((backend (or backend
                       (cdr (file-under-vc-directory-p directory)))))
      ;;(message "Reading vc-states of %s" directory)
      (case backend
        (RCS)
        (CVS (process-lines-filtered "cvs" 'vc-cvs-state-string-code "-nq" "update"))
        (SVN (process-lines-filtered "svn" 'vc-svn-state-string-code "status"
                                     (if tree "" "-N")
                                     (if updates "-u" "")))
        (SCCS)
        (Bzr (process-lines-filtered "bzr" 'vc-bzr-state-string-code "status" "-S"
                                     (if tree "" ".")))
        (Git (process-lines-filtered "git" 'vc-git-state-string-code "status" "-s" "--ignored"
                                     (if tree "" ".")))
        (Hg (process-lines-filtered "hg" 'vc-hg-state-string-code "status" "-A"))
        (Mtn (process-lines-filtered "mtn" 'vc-mtn-state-string-code "status"))
        (Arch)
        (DARCS (process-lines-filtered "darcs" 'vc-darcs-state-string-code "status"))
        ))))
;; Use: (vc-states "/home/per/Work/justcxx/" nil t nil)
;; Use: (vc-states (elsub "yasnippet") 'SVN)
;; Use: (vc-states (elsub "yasnippet") 'SVN nil t)
;; Use: (vc-states (elsub "yasnippet") 'SVN nil t)
;; Use: (vc-states (elsub "cedet") 'Bzr)
;; Use: (vc-states (elsub "cedet") 'Bzr t)
;; Use: (vc-states (elsub "mine"))
;; Use: (vc-states (elsub "mine") 'Git)
;; Use: (vc-states (elsub "mine") 'Git t)
;; Use: (vc-states (elsub "others") 'Git)
;; Use: (vc-states (elsub "others"))
;; Use: (vc-states (elsub "flex-isearch") 'Hg)
;; Use: (vc-states (elsub "ropemacs") 'Hg)
;; Use: (vc-states (elsub "haskell-mode-alexott") 'DARCS)
;; Use: (vc-states (elsub "haskell-mode-alexott"))
;; Use: (vc-states "~/elisp/" nil t)

(defun vc-states-forget-directory-fcache (fcache)
  (fcache-set-property fcache :vc-states nil)) ;TODO: Better to remove it completely from plist?
(defun vc-states-forget-directory (directory)
  ;;(message "Forgot vc-states of %s" directory)
  (vc-states-forget-directory-fcache (fcache-of directory)))

(defun vc-states-get (directory &optional backend tree updates)
  "Get (Cached) vc-states for DIRECTORY."
  ;;(message "vc-states-get of %s" directory)
  (let* ((fcache (fcache-of directory))
         (prop (if tree
                   :vc-states-tree
                 :vc-states)))
    (or (fcache-get-property fcache prop)
        (let ((hash (alist-to-hash-table
                     (vc-states directory backend tree updates)
                     :test 'equal)))
          ;;(message "Caching vc-states of %s" directory)
          (fcache-set-property fcache prop hash)
          hash))))
(eval-when-compile
  (let ((dir (elsub "haskell-mode-alexott"))
        (fil "Makefile"))
    (assert-eq
     (gethash fil
              (vc-states-get dir))
     (progn (vc-states-forget-directory dir)
            (gethash fil (vc-states-get dir))))))

;; Use: (gethash "xyz" (vc-states-get (elsub "haskell-mode-alexott")))

;; Use: (gethash "icicles" (vc-states-get (elsub "~/elisp/") nil t))
;; Use: (gethash "icicles" (fcache-get-property (fcache-of (elsub "~/elisp/")) :vc-states-tree))
;; Use: (file-relative-name (elsub "icicles/icicles.el") (elsub "others"))

;; Use: (gethash "xyz" (vc-states-get (elsub "~/elisp/")))
;; Use: (file-under-vc-directory-p "~/justcxx/")

(defun directory-cache-vc-state-subs (dirname &optional cached-only noerror match backend tree updates)
  "Scan and Cache VC-states of DIRNAME's sub-files or directories."
  (let* ((dcache (dcache-of dirname))
         (subs (dcache-subs dcache match)))
    (mapc (lambda (state)
            (let ((sub-fcache (gethash (car state) subs)))
              (when sub-fcache
                (fcache-set-property sub-fcache :vc-state (if state ;not every VC explicitly prints up-to-date
                                                              (cdr state)
                                                            'up-to-date) ;so state this explicitly
                                     ))))
          (vc-states dirname backend tree updates))))
;; Use: (directory-cache-vc-state-subs (elsub "mine"))
;; (fcache-get-properties (fcache-of (elsub "mine/dotemacs.el")))
;; (fcache-get-property (fcache-of (elsub "mine/dotemacs.el")) :vc-state)
;; (fcache-get-property (fcache-of (elsub "mine/vc-states.el")) :vc-state)

(provide 'vc-states)
