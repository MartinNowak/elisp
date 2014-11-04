;;; vc-and-ediff.el --- Setup Integration with Version Control Systems (VCS) and (E)Diff
;; Author: Per Nordlöw

(require 'file-utils)

(when t
  ;; WARNING: Needed to avoid error when loading vc-hooks+.
  ;; WARNING: This does not help.
  (defvar vc-buffer-backend nil)
  (eval-after-load "vc-hooks" '(progn (require 'vc-hooks+ nil t)))
  )

(add-to-list 'vc-directory-exclusion-list ".wact")

;; Unified Interface to Comparison: Windows, Buffers, Files, Directory, Trees
(global-unset-key [(meta v)])
(define-key global-map [(meta v)] 'vc-prefix-map)

;; Add an explanation to VC Interface.
;; Note: This is equal like (define-prefix-command 'vc-prefix-map nil "Version
;; Control (VC): a,b,c,d,g,h,i,l,L,m,r,s,u,v,+,=,D,~") but works on an existing
;; keymap:
(add-to-list 'vc-prefix-map "Version Control (VC): a,b,c,d,g,h,i,l,L,m,r,s,u,v,+,=,D,~" t) ;

(global-set-key [(meta v)] vc-prefix-map)
(define-key vc-prefix-map [?D] 'vc-delete-file)

(define-key vc-menu-map [vc-delete-file]
  `(menu-item ,(purecopy "Delete") vc-delete-file
              :help ,(purecopy "Delete file")))

;; TODO Fetch list of selections and apply operation to each of them.
;; (define-key vc-dir-mode-map [?D] 'vc-delete-file)

(require 'vc-ediff-head)

;; TODO Also see M-x vc-resolve-conflicts -- pop up an ediff-merge
;; session on a file with conflict markers

(require 'vc-prompt-register)

;; ---------------------------------------------------------------------------

(defun vc-ensure-checked-in ()
  "Query for Version Control Update."
  (interactive)
  (if (file-exists-p (format "%s,v" buffer-file-name))
      (progn (vc-checkin buffer-file-name nil "")
             (setq buffer-read-only t)  ;replaces `vc-toggle-read-only'
             (message "Checked in"))
    (message "You need to check this in! M-x vc-use") (ding)))
;;(add-hook 'after-save-hook 'vc-ensure-checked-in)

(defun vc-use ()
  (interactive)
  (vc-register)
  (setq buffer-read-only t)  ;replaces `vc-toggle-read-only'
  )

;; ---------------------------------------------------------------------------

(defalias 'vc-mv-file 'vc-rename-file)
(defalias 'vc-move-file 'vc-rename-file)

;; Version Control Icon
;;
;; Overlay Icons:
;; - See: http://tortoisesvn.net/node/138
;; - locate -r "/icons/.*/.*/emblems"
;;
;; See: http://www.emacswiki.org/cgi-bin/wiki/VcIcon
;; Display a coloured square indicating the vc status of the current file
;;
;; ToDo: You’ll need to add (:eval (vc-icon)) to your mode-line-format
;; somewhere, instead of the existing (vc-mode vc-mode) might be an
;; option.
;;
;; Bug: this puts the colour of your mode-line background behind the
;; icon (so that it will shine through if the icon has
;; transparency). Unfortunately, it also does this if it’s currently
;; computing the icon for the modeline of an ‘inactive’ window
;; (i.e. one other than the current one). I couldn’t figure out a way
;; to get round this, but on my Emacs at least, the difference in
;; colour for that few pixels is unnoticeably small anyway.
(defun vc-buffer-status-image ()
  "Return an image indicating the vc status of the current buffer's file."
  (let ((icon (if (vc-workfile-unchanged-p buffer-file-name)
                  (elsub "tortoise-svn-icons/NormalIcon.png")
                (elsub "tortoise-svn-icons/ModifiedIcon.png")))
        (bg-colour (face-attribute 'mode-line :background)))
    (propertize
     "  "
     'display (find-image `((:type png :file ,icon :ascent center :background ,bg-colour))))))
;; Use: (vc-buffer-status-image)

;; ---------------------------------------------------------------------------
;; Git Interfaces

;; yet another git emacs mode for newbies
;; \see http://files.taesoo.org/git-emacs/git-emacs.html

;; WARNING: Disturbs commit behaviour of standard VC.
(when (require 'git-emacs nil t)
  (when (require 'hictx nil t)
    (defadvice git--status-view-prev-meaningful-line (after git--status-view-prev-meaningful-line-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'git--status-view-prev-meaningful-line)
    (defadvice git--status-view-next-meaningful-line (after git--status-view-next-meaningful-line-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'git--status-view-next-meaningful-line)
    )
  )

;;; Magit - (require 'magit nil t). \see https://vimeo.com/2871241
(autoload 'magit-status "magit" "Magit Status." t) ;control Git from Emacs.
(global-set-key [(control x) (?g)] 'magit-status)
(setq magit-omit-untracked-dir-contents t)

;; EGG - (require 'egg nil t)
(when nil
  (defun egg-elbuild ()
    "Rebuild egg."
    (interactive)
    (let ((default-directory (elsub "egg/")))
      (compile "git pull; " t))
    (byte-recompile-directory (elsub "egg") 0 t))
  (append-to-load-path (elsub "egg"))         ;egg
  (autoload 'egg-status "egg" "Egg Status." t) ;Emacs Got Git (Magit with enhanced User Interface)
  (autoload 'egg-minor-mode "egg" "Egg Minor Mode." t))
;;(append-to-load-path (elsub "egg"))

;; ---------------------------------------------------------------------------
;; Subversion (SVN)
;; Short Tutorial: See: http://xtalk.msk.su/~ott/en/writings/emacs-vcs/EmacsPSVN.html

(when (require 'psvn nil t)
  ;; Setting this to nil will make M-x svn-status run without the -v
  ;; option at the command line.
  (setq svn-status-verbose nil)
  ;; Setting this automatically performs the toggle that you can do
  ;; with _ when in the *svn-status* buffer, so that you only see
  ;; files with a status that has changed in your working directory.
  (setq svn-status-hide-unmodified t)
  )

;; ---------------------------------------------------------------------------

;; diffstat.el --- a mode for showing the summary of diff
(when (require 'diffstat nil t)
  (add-hook 'diff-mode-hook (lambda () (local-set-key "\C-c\C-l" 'diffstat)))
  )

;; ---------------------------------------------------------------------------

(when (eload 'vc-jump)    ;See: http://www.emacswiki.org/emacs-en/VC-Jump
  (add-hook 'vc-dir-mode-hook
            (lambda ()
              (when (boundp 'vc-dir-mode-map)
                (define-key vc-dir-mode-map [?j] 'vc-jump))) t)
  )
(eload 'vc-darcs)                       ;VC backend for the darcs revision control system

(eload 'vc-roots)

;; ---------------------------------------------------------------------------

(when nil
  (unless (ignore-errors (load-file-if-exist (elsub "dvc/build/dvc-load.el")))
    (message "Could not load DVC"))    ;C-x V

  (when (require 'clearcase nil t)) ;(Rationals) ClearCase/Emacs integration. Homepage: http://members.verizon.net/kevin.a.esler/EmacsClearCase/
  (when (require 'vc-clearcase nil t))

  (when (require 'source-safe nil t)
    ;; Specify where your source-safe executable is located
    ;; ToDo: Do we still need backslash in Windows Paths?
    ;;(setq ss-program "C:\\Program Files\\Microsoft Visual Studio\\Common\\VSS\\win32\\SS.exe")
    ;;(setq ss-program "S:\\WinNT\\SS.exe")

    ;; Specify where your working directories are.
    ;; The slashes need to be escaped a couple of times; the drive name
    ;; needs to start with a '^' so that the REGEXP stuff works right
    ;; (the comments in source-safe.el explain this).
    (setq ss-project-dirs
          '(("^C:\\\\mw\\\\src\\\\" . "$/src/")
            ("^C:\\\\mw\\\\docs\\\\" . "$/docs/")
            (("^D:\\\\OCI\\\\" . "$/PurifyW/"))))
    ;;
    ;; (autoload 'ss-diff "source-safe"
    ;;  "Compare the current buffer to the version of the file under SourceSafe.
    ;;   If NON-INTERACTIVE, put the results in a buffer and switch to that buffer;
    ;;   otherwise run ediff to view the differences." t)
    ;;
    ;; (autoload 'ss-get "source-safe"
    ;; "Get the latest version of the file currently being visited." t)
    ;;
    ;; (autoload 'ss-checkout "source-safe"
    ;; "Check out the currently visited file so you can edit it." t)
    ;;
    ;; (autoload 'ss-lock "source-safe"
    ;; "Check out, but don't get the latest version of the file currently being visited." t)
    ;;
    ;; (autoload 'ss-uncheckout "source-safe"
    ;; "Un-checkout the curently visited file." t)
    ;;
    ;; (autoload 'ss-update "source-safe"
    ;; "Check in the currently visited file." t)
    ;;
    ;; (autoload 'ss-checkin "source-safe"
    ;; "Check in the currently visited file." t)
    ;;
    ;; (autoload 'ss-branch "source-safe"
    ;; "Branch off a private, writable copy of the current file for you to work on." t)
    ;;
    ;; (autoload 'ss-unbranch "source-safe"
    ;; "Delete a private branch of the current file.  This is not undoable." t)
    ;;
    ;; (autoload 'ss-merge "source-safe"
    ;; "Check out the current file and merge in the changes that you have made." t)
    ;;
    ;; (autoload 'ss-history "source-safe"
    ;; "Show the checkin history of the currently visited file." t)
    ;;
    ;; (autoload 'ss-status "source-safe"
    ;; "Show the status of the current file." t)
    ;;
    ;; (autoload 'ss-locate "source-safe"
    ;; "Find a file the the current project." t)
    ;;
    ;; (autoload 'ss-submit-bug-report "source-safe"
    ;; "Submit a bug report, with pertinent information." t)
    ;;
    ;; (autoload 'ss-help "source-safe"
    ;; "Describe the SourceSafe mode." t)
    ;;
    ;; (autoload 'ss-baseline-merge nil nil)
    ;; (autoload 'ss-baseline-diff nil nil)
    )

  ;; Bazaar (bzr) - a Distributed Revision Control System (DRCS)
  (when (require 'bazaar nil t))

  ;; CVS
  (global-set-key (kbd "C-x v D") 'cvs-update)
  (add-hook 'cvs-mode-hook
            (lambda ()
              (local-set-key "E" 'cvs-mode-idiff) ;imitate psvn.el
              ))
;;; (add-hook 'cvs-mode-hook
;;;           (lambda ()
;;;             (define-key cvs-mode-map [f3] 'cvs-mode-find-file)))

  ;; git - a Distributed Revision Control System (DRCS)
  ;; See: EmacsWiki: Git: http://www.emacswiki.org/cgi-bin/wiki/Git
  ;; Fetched from here: http://git.kernel.org/?p=git/git.git;a=tree;hb=HEAD;f=contrib/emacs
  (when (require 'git nil t))
  (when (require 'git-blame nil t))

  ;; darcs - a Distributed Revision Control System (DRCS)
  (when (require 'darcs nil t))
  (when (require 'vc-darcs nil t)
    (add-to-list 'vc-handled-backends 'DARCS)
    )

  ;; Visual Source Safe (vss)
  (when (require 'vc-vss nil t))

  ;; Call SVN/CVS/GIT/Bazaar examine from current directory.
  (defun pnw-vc-status (directory)
    "Check Version Control Status in DIRECTORY. If DIRECTORY
contains the sub-directory
-  \"CVS/\" then call CVS using function `cvs-examine'
- \".svn/\" then call Subversion using function `svn-status'
- \".bzr/\" then call Bazaar using function `bzr-status'
- \".git/\" then call Git using function `git-status'"
    (interactive "DStatus Directory: ")
    (let ((dir (file-name-as-directory directory))) ;assure slash at the end
      (if (file-exists-p (concat dir "CVS/"))
          (cvs-status dir nil)
        (if (file-exists-p (concat dir ".svn/"))
            (svn-status dir)
          (if (file-exists-p (concat dir ".git/"))
              (git-status dir)
            (if (file-exists-p (concat dir ".bzr/"))
                (bzr-status dir)
              (vc-status-below dir nil) ;default to general handler
              ))))))
  ;; Replaced by vc-dir
  ;;(global-set-key [(control c) (e)] 'pnw-vc-status)

  ;; ---------------------------------------------------------------------------

  ;; Note: I disable this for now! ToDo: Notify dradams about this problem.
  (when nil
    (require 'vc- nil t)
    (eval-after-load "vc" '(progn (require 'vc+ nil t)))
    )

  )

(load (elsub "gitconfig-mode/gitconfig.elc"))

;;; Ignore Whitespae. See: http://stackoverflow.com/questions/13464749/how-can-i-get-ediff-mode-to-stop-highlighting-lines-that-differ-only-by-whitespa
(setq-default ediff-ignore-similar-regions t)
(setq-default ediff-highlight-all-diffs nil)
;;(setq ediff-use-last-dir t)
;;(setq ediff-diff-options "-w")         ; turn off whitespace checking:

;;; https://stackoverflow.com/questions/1680750/is-there-any-way-to-get-ediff-to-not-open-its-navigation-interface-in-an-externa
(setq-default ediff-window-setup-function 'ediff-setup-windows-plain)

(provide 'vc-and-ediff)
