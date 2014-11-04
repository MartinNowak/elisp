;;; atags.el --- Unified Interface to Emacs Tags (etags), GNU GLOBAL tags (gtags/global), Exuberant Ctags (Emacs and Vi-style) (ectags.el), Idutils and Cscope.

;; Smarter use of GNU GLOBAL that automatically upon lookup tries to load
;; the most relevant database available (in the current directory or
;; first matching parenting directory.

;; Smarter use of GNU GLOBAL that automatically upon lookup tries to load
;; the most relevant database available (in the current directory or
;; first matching parenting directory.

(require 'filedb)
(require 'tscan)
(require 'tags-update)
(require 'ectags)

;;;###autoload
(defgroup atags nil
  "Unified Interface Tags Interface."
  :group 'tools)

(defvar atags-root-history '()
  "History of root directories that contain an Emacs Tags database.")
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'atags-root-history t))
;; Use: (add-to-list 'atags-root-history "~/justcxx")

(defcustom atags-schedule-delay 3
  "Delay after buffer save when tags update is
  performed. Important: Set this to a value that is at least
  longer than it takes to update tags database(s) in a (project)
  diretory."
  :group 'atags)

(defvar atags-schedule '()
  "Association-List from directory to timer handle for tags update of that directory."
  )

;; ----------------------------------------------------------------------------

(defun ectags-online-p ()
  "Check whether Exuberant Ctags executables (ectags) are in the PATH."
  (interactive)
  (or (executable-find "ectags")
      (executable-find "ctags-exuberant")
      (executable-find "exuberant-ctags")
      ))
(defalias 'ectags-online? 'ectags-online-p)

(defun gtags-online-p ()
  "Check whether GNU GLOBAL executables (global/gtags) are in the PATH."
  (interactive)
  (and (executable-find "global")
       (executable-find "gtags")
       ))
(defalias 'gtags-online? 'gtags-online-p)

(defun idutils-online-p ()
  "Check whether Idutils executables (ctags) is in the PATH."
  (interactive)
  (and (executable-find "mkid")
       (executable-find "gid")
       (executable-find "lid")
       ))
(defalias 'idutils-online? 'idutils-online-p)

(defun cscope-online-p ()
  "Check whether Cscaope executables (cscope) is in the PATH."
  (interactive)
  (and (executable-find "cscope")
       ))
(defalias 'cscope-online? 'cscope-online-p)

(when (and
       (require 'pnw-gtags nil t)
       (gtags-online-p))
  (autoload 'gtags-mode "pnw-gtags" "" t)
  )

;; ----------------------------------------------------------------------------

;; build completion list of symbols
(defun gtags-make-complete-symbol-list ()
  "Make tag name list for completion."
  (interactive)
  (save-excursion
    (message "Making completion list ...")
    (setq gtags-complete-list (make-vector 63 0))
    (set-buffer (generate-new-buffer "*Completions*"))
    (call-process "global" nil t nil "-cs")
    (goto-char (point-min))
    (while (looking-at gtags-symbol-regexp)
      (intern (gtags-match-string 0) gtags-complete-list)
      (forward-line))
    (message "Making completion list ... Done")
    (kill-buffer (current-buffer))))

;; ----------------------------------------------------------------------------

(defun atags-update (&optional dir tags-type multi sync-flag)
  "Update all kinds of tags databases above directory DIR. If
MULTI is either; t update tags in all parent directories, `query'
ask user if there are several alternatives, nil pick the
default (shallowest)."
  (interactive "DDirectory: ")
  (unless dir (setq dir default-directory))
  ;; TODO Find top-most tags directory and schedule with run-with-(idle-)timer
  (let ((entry (assoc dir atags-schedule)))
    (when entry
      (setcdr entry '(nil))))            ;remove timer but keep directory
  (let ((hits (trace-directory-upwards (cond ((memq tags-type '(ectags
                                                                Exuberant-Ctags))
                                              'file-ectags-root-directory-p)
                                             ((memq tags-type '(etags
                                                                Emacs-Ctags))
                                              'file-etags-root-directory-p)
                                             (t
                                              'file-tags-root-directory-p))
                                         (expand-file-name dir) multi)))
    (tags-update-at
     (if multi                          ;if multiple hits
         (caar (last hits))             ;select the top-most
       (car hits))                      ;otherwise only on to choose
     tags-type sync-flag)))
;; Use: (progn (atags-update "~/justcxx/" 'ectags) atags-schedule)
;; Use: (progn (atags-update (elsub "mine/") 'ectags) atags-schedule)
;; Use: (atags-update "~/elisp/mine" 'ectags nil t)

(defun atags-schedule-update-above-directory (&optional dir tags-type multi sync-flag)
  "Update all kinds of tags databases above directory DIR."
  (interactive "DDirectory: ")
  (unless dir (setq dir default-directory))
  ;; TODO Find top-most tags directory and schedule with run-with-(idle-)timer
  (let ((old (assoc dir atags-schedule)) ;old timer
        (new (run-with-timer atags-schedule-delay
                             nil
                             'atags-update dir tags-type multi sync-flag))) ;new timer
    (if old                               ;if already present
        (progn (ignore-errors (cancel-timer (cdr old)))
               (setcdr old new)) ;cancel timer and replace it
      (add-to-list 'atags-schedule `(,dir ,new) t)))) ;append to end
;; Use: (atags-schedule-update-above-directory "~/justcxx/" 'ectags)
;; Use: (atags-schedule-update-above-directory (elsub "mine/") 'ectags)

(defun atags-flush-schedule (dir)
  "Flush schedule in directory DIR."
  )

;; ----------------------------------------------------------------------------

(defun atags-find-root (&optional dir)
  "Prepare Etags and Ctags Interface for a lookup at directory
DIR."
  (unless dir (setq dir default-directory))
  (let ((root-dir (car (trace-directory-upwards 'file-tags-root-directory-p
                                                (expand-file-name dir)))))
    (if root-dir             ;if tags parent directory already present
        ;; use it
        (add-to-list 'atags-root-history root-dir) ;remember it
      ;; otherwise ask the user for another (possibly new) directory
      (let ((tmp-history atags-root-history))
        (add-to-list 'tmp-history dir)   ;add current dir to history
        (setq root-dir (completing-read ;else query dir
                        "Project/Tags (Directory) to visit (empty for new): "
                        tmp-history nil t nil nil nil))))

    (unless root-dir       ;if no parent (super) tags directory found
      (setq root-dir (expand-file-name (read-directory-name "Build Tags at: " dir nil t)))) ;query project (tags) directory
    root-dir))

(defun atags-prepare-etags (&optional dir)
  "Prepare Etags Interface for a lookup at directory DIR."
  (let ((root-dir (atags-find-root dir)))
    (unless (file-etags-root-directory-p root-dir)  ;no etags "TAGS" in project root
      (shell-command-at (concat etags-update-command) root-dir "*etags-output" "*etags-error*"))
    (unless (and tags-file-name
                 (equal root-dir (file-name-directory tags-file-name)))
      (setq tags-file-name (expand-file-name "TAGS" root-dir))))) ;switch to it

(defun atags-prepare-ectags (&optional dir)
  "Prepare ECtags Interface for a lookup at directory DIR."
  (let ((root-dir (atags-find-root dir)))
    (unless (file-ectags-root-directory-p root-dir) ;no ectags "tags" in project root
      (shell-command-at (concat ectags-update-command) root-dir "*ectags-output" "*ectags-error*"))))
;; NOTE: Disabled because we generate tags-file explicitly in
;; `ectags-lazy-completion-table' instead.
;;(add-hook 'ectags-lazy-hook 'atags-prepare-ectags)

(defun atags-prepare-gtags (&optional dir)
  "Prepare GNU GLOBAL Interface for a lookup."
  (let ((root-dir (atags-find-root dir)))
    (unless (file-gtags-root-directory-p root-dir)
      (shell-command-at "gtags " root-dir "*gtags-output" "*gtags-error*")
      )
    (setenv "GTAGSROOT" root-dir)))

;; -----------------

(defun gtags-after-lookup ()
  (delete-other-windows)
  (split-window-vertically)
  )

;; WARNING: Do NOT use this design pattern; this causes really
;; annoying behaviours because rename-file() is used in other basic
;; user-called functions such as save-buffer()
(when nil
  (defadvice rename-file (after make-complete-list activate)
    ;;(atags-schedule-update-above-directory file 'ectags)
    )
  (ad-activate 'rename-file))

(defun rename-file-and-update-tags-tables (file newname &optional ok-if-already-exists)
  "Rename FILE as NEWNAME and if needed update tags database tables."
  ;; ToDo: Call rename-file() here
  (atags-schedule-update-above-directory nil 'ectags)
  )

;;; Replace with hook to `write-file-functions' or `after-save-hook'.
(defun save-buffer-and-update-tags-tables ()
  "Save buffer and if needed update Tags databases above current
directory."
  (interactive)
  (let ((save-flag (buffer-modified-p (current-buffer))))
    (save-buffer)
    (if save-flag
        (atags-schedule-update-above-directory nil 'ectags)
      )))
;;; Replace with hook to `write-file-functions' or `after-save-hook'.
(defun save-some-buffers-and-update-tags-tables ()
  "Save some buffers and if needed update tags database tables above
current directory."
  (interactive)
  (if (equal (save-some-buffers) t)
      (atags-schedule-update-above-directory nil 'ectags)
    ))
(defun save-some-buffers-and-update-tags-tables-and-commit-changes (directory)
  "Save some buffers and if needed update tags database tables above
current directory."
  (interactive "DCommit under: ")
  (save-some-buffers-and-update-tags-tables)
  ;;(vc-commit)
  )

(defadvice tags-query-replace (before atags-prepare activate) (atags-prepare-etags)) (ad-activate 'tags-query-replace)
;;(defadvice find-ectag (before atags-prepare activate) (atags-prepare-ectags)) (ad-activate 'find-ectag)
(defadvice find-tag (before atags-prepare activate) (atags-prepare-etags)) (ad-activate 'find-tag)
(defadvice find-tag-regexp (before atags-prepare activate) (atags-prepare-etags)) (ad-activate 'find-tag-regexp)
(when (functionp 'icicle-find-tag)
  (defadvice icicle-find-tag (before atags-prepare activate) (atags-prepare-etags)) (ad-activate 'icicle-find-tag))
(when (functionp 'icicle-find-first-tag)
  (defadvice icicle-find-first-tag (before atags-prepare activate) (atags-prepare-etags)) (ad-activate 'icicle-find-first-tag))

(add-hook 'gtags-mode-hook
          (lambda ()
            (defadvice gtags-find-tag (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-tag)
            (defadvice gtags-find-rtag (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-rtag)
            (defadvice gtags-find-symbol (before check-gtags-completion activate) (gtags-make-complete-symbol-list)) (ad-activate 'gtags-find-symbol)
            (defadvice gtags-find-pattern (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-pattern)
            (defadvice gtags-find-with-grep (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-with-grep)
            (defadvice gtags-find-with-idutils (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-with-idutils)
            (defadvice gtags-find-file (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-file)
            (defadvice gtags-parse-file (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-parse-file)
            (defadvice gtags-find-tag-from-here (before check-gtags-completion activate) (atags-prepare-gtags)) (ad-activate 'gtags-find-tag-from-here)
            ))

(if nil
    (progn
      (define-key gtags-mode-map "\e*" 'gtags-pop-stack)
      (define-key gtags-mode-map "\e." 'gtags-find-tag)
      (global-set-key [(meta \.)] 'gtags-find-tag)
      (global-set-key [(meta \:)] 'gtags-find-rtag)
      (global-set-key [(meta \,)] 'gtags-find-symbol)

      ;; Use gtags in all modes for now.
      (gtags-mode nil)

      ;; Use gtags only in these modes.
      (add-hook 'c-mode-hook (lambda () (gtags-mode 1)))
      (add-hook 'c++-mode-hook (lambda () (gtags-mode 1)))
      (add-hook 'emacs-lisp-mode-hook (lambda () (gtags-mode 1)))
      (add-hook 'gud-mode-hook (lambda () (gtags-mode 1)))
      (add-hook 'text-mode-hook (lambda () (gtags-mode 1)))
      ))

(global-set-key [(control x) (control s)] 'save-buffer-and-update-tags-tables)
(global-set-key [(f2)] 'save-buffer-and-update-tags-tables)
(global-set-key [(control x) (?s)] 'save-some-buffers-and-update-tags-tables)
(global-set-key [(control x) (?S)] 'save-some-buffers-and-update-tags-tables-and-commit-changes)
(global-set-key [(control f2)] 'save-some-buffers-and-update-tags-tables)

(provide 'atags)
