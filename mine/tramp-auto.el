;;; tramp-auto.el --- Auto-Raising Priviligies using TRAMP.
;; Author: Per Nordlöw
;; See: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/25024cc86611ea35#

(require 'tramp)

;; ---------------------------------------------------------------------------

(defun find-file-root-maybe (dirname &optional uid)
  (when (and (file-directory-p dirname) ;directory
             (not (file-accessible-directory-p dirname))) ;not accessible by current user
    ;; TODO: ...
    ))

;; ---------------------------------------------------------------------------

;;; TODO: Support bright backgrounds using thise format
(when nil
 '((((class color) (min-colors 88) (background dark)) (:foreground "DarkGreen"))
   (((class color) (min-colors 88) (background light)) (:foreground "LightGreen"))))
(defun find-file-root-buffer-background-warning ()
  "Change the buffer background to signal that we are editing
file as root."
  (set (make-local-variable 'face-remapping-alist)
       '((default (:background "#400000")))))

(defun find-file-root-header-warning ()
  "*Display a warning in header line of the current buffer.
   This function is suitable to add to `find-file-root-hook'."
  (when (string-match "^/su\\(do\\)?:" default-directory)
    (let* ((warning "EDITING FILE AS ROOT!")
           (space (+ 6 (- (frame-width) (length warning))))
           ;;(bracket (make-string (/ space 2) ?-))
           (bracket " -------- ")
           (warning (concat bracket warning bracket)))
      (setq header-line-format
            (propertize warning 'face 'trailing-whitespace)))))

(defun tramp-sudo-warn ()
  "Add visual warnn/hint user about current buffer privilegies."
  (when (string-match "^/su\\(do\\)?:" default-directory)
    ;;(setq mode-line-format (format-mode-line mode-line-format 'font-lock-warning-face))
    (find-file-root-header-warning)
    ;;(find-file-root-buffer-background-warning)
    ))

(add-hook 'find-file-hooks 'tramp-sudo-warn)
(add-hook 'dired-mode-hook 'tramp-sudo-warn)

;; ---------------------------------------------------------------------------

;; TODO: Make this work better.
;; TODO: When opening existing unreadable files/dir owned by UID use some
;; TRAMP-hook, for example /root/.bashrc.

(defvar post-ro-edit-hook nil
  "Hooks to run first time a root-read-only buffer gets modified.")

(defun post-ro-edit-hook ()
  "Hook run when the user tries to modify a read-only buffer file owned by root."
  (when (buffer-file-name)
    (if (y-or-n-p-with-timeout (format "Reopen the file %s of buffer %s as root to edit (defaulting to no in 1 seconds)? "
                                       (faze (buffer-file-name) 'file)
                                       (faze (buffer-name) 'buffer))
                               1 nil)
        (let ((p (point)))
          (let ((sudo-url (concat "/sudo::" buffer-file-name)))
            ;; TODO: If sudo-url is already opened in another buffer switch to that buffer
            ;;(message "vis:%s" (find-buffer-visiting sudo-url))
            (find-alternate-file sudo-url)) ;open with sudo instead
          (goto-char p) ;goto same point in reopened file so that pending changes occurr at right position
          (unwind-protect (run-hooks 'post-ro-edit-hook))
          )
      ;; TODO: drop-all pending buffers inserts
      (setq buffer-read-only t) (message "Made buffer read-only")
      (remove-hook 'first-change-hook 'post-ro-edit-hook t) ;NOTE: This prevents infinite loop of calling `post-ro-edit-hook'.
      )))

(defun find-file-auto-raise-privs ()
  "If current buffer is read-only, but writable by root, raise priviligies."
  (interactive "")
  (when (and buffer-read-only                         ;buffer is readonly
             buffer-file-name                         ;buffer is a file
             (not (file-writable-p buffer-file-name)) ;file it is not writable
             (= (nth 2 (file-attributes buffer-file-name)) 0)) ;file is owned by root
    (setq buffer-read-only nil) ;make it writable so that `before-change-functions' is run
    (add-hook 'first-change-hook 'post-ro-edit-hook nil t) ;activate before-change-hook locally in this buffer
    ))
;;(add-hook 'find-file-hook 'find-file-auto-raise-privs)
(remove-hook 'find-file-hook 'find-file-auto-raise-privs)

;; ---------------------------------------------------------------------------

(when nil
  (defvar find-file-root-prefix
    (if (featurep 'xemacs) "/[sudo/root@localhost]" "/sudo:root@localhost:" )
    "*The filename prefix used to open a file with `find-file-root'.")

  (defvar find-file-root-history nil
    "History list for files found using `find-file-root'.")
  (when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'find-file-root-history t))

  (defvar find-file-root-hook nil
    "Normal hook for functions to run after finding a \"root\" file.")

  (defun find-file-root ()
    "*Open a file as the root user.
   Prepends `find-file-root-prefix' to the selected file name so that it
   maybe accessed via the corresponding tramp method."
    (interactive)
    (if (require 'tramp nil t)
        (let* ( ;; We bind the variable `file-name-history' locally so we can
               ;; use a separate history list for "root" files.
               (file-name-history find-file-root-history)
               (name (or buffer-file-name default-directory))
               (tramp (and (tramp-tramp-file-p name)
                           (tramp-dissect-file-name name)))
               path dir file)
          ;; If called from a "root" file, we need to fix up the path.
          (when tramp
            (setq path (tramp-file-name-path tramp)
                  dir (file-name-directory path)))
          (when (setq file (read-file-name "Find file as root (UID = 0): " dir path))
            (find-file (concat find-file-root-prefix file))
            ;; If this all succeeded save our new history list.
            (setq find-file-root-history file-name-history)
            ;; allow some user customization
            (run-hooks 'find-file-root-hook)))
      (error "TRAMP could no be loaded")))

  (defun find-file-hook-root-header-warning ()
    (when (and buffer-file-name (string-match "root@localhost" buffer-file-name))
      (find-file-root-header-warning)))
  (add-hook 'find-file-hook 'find-file-hook-root-header-warning)

  (global-set-key [(control x) (control shift f)] 'find-file-root)

  (defvar find-file-root-log "~/.emacs.d/find-file-root-log"
    "*ChangeLog in which to log changes to system files.")
  (defun find-file-root-log-do-it()
    "Add an entry for the current buffer to `find-file-root-log'."
    (let ((add-log-mailing-address "root@localhost")
          (add-log-full-name "")
          (add-log-file-name-function 'identity)
          (add-log-buffer-file-name-function
           (lambda () ;; strip tramp prefix
             (tramp-file-name-localname
              (tramp-dissect-file-name
               (or buffer-file-name default-directory)))
             )))
      (add-change-log-entry nil find-file-root-log 'other-window)))

  (defun find-file-root-log-on-save ()
    "*Prompt for a log entry in `find-file-root-log' after saving a root file.
   This function is suitable to add to `find-file-root-hook'."
    (add-hook 'after-save-hook 'find-file-root-log-do-it 'append 'local))
  ;; TODO: This is really annoying. Disable for now.
  ;;(add-hook 'find-file-root-hook 'find-file-root-log-on-save)
  )

;; ---------------------------------------------------------------------------

(when nil
  (defcustom pnw/tramp-hosts
    '("apollo frej buddha speed jb bahjan")
    "List of known hosts." :type 'boolean :group 'pnw-options)

  (defun pnw/tramp ()
    "Open my home directory on an other host.
A list of possible hosts can be given by `pnw/tramp-hosts'"
    (interactive)
    (let ((host (completing-read "Host: " pnw/tramp-hosts))
          (user-name (user-login-name)))
      (find-file (concat "/ssh:" user-name "@" host ":~/"))))

  (progn
    (defvar find-file-root-method "sudo::"
      "*The Tramp method to use for opening files with `find-file-root'.")
    (defvar find-file-root-user   "root"
      "*The user to su to when opening files with `find-file-root'.")
    (defun find-file-root (file)
      "Open FILE sued to a different user.
Uses the method specified in `find-file-root-method' and the user from
`find-file-root-user'."
      (interactive "FFind file (as root): ")
      (require 'tramp nil t)
      (find-file
       (concat "/" find-file-root-method find-file-root-user "@localhost]" file)))
    (global-set-key [(control x) (control shift f)] 'find-file-root)
    ))

(provide 'tramp-auto)
