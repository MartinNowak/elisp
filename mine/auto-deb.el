;;; auto-deb.el --- Auto-Complete and Install Queries of Files provided by Debian/Ubuntu Packages.
;; Author: Per Nordlöw

;; TODO: Call (apt-query-system-executables nil nil t) using `start-process'
;; upon load of auto-deb package and do parsing in completion callback.

;; - Use [[shell:apt-file search -x "^/usr/bin/.*"]]
;; - Build hash-table from regexp to hits.

;; TODO: Convert `re-search-forward' loop into a single call and iterate match-list instead.

;; TODO: Add hash-table for executables along with `apt-executables-cache'. Use
;; it to highlight executables in sh-mode.

(defun auto-deb-parse-output (sbuf &optional file-assoc)
  "Convert dpkg and APT file query output into an alist.
Each element in alist has the format (FILE PACKAGES...) if
FILE-ASSOC is non-nil and (PACKAGE FILES...) otherwise."
  (let (pkgs)
    (save-current-buffer
      (set-buffer sbuf)
      (save-excursion
        (goto-char (point-min))
        ;; Parse packages and their contents
        (while (re-search-forward "^\\(.*\\): \\(.*\\)" nil t)
          (let* ((pname (match-string-no-properties 1)) ;package name
                 (pfile (match-string-no-properties 2)) ;package file
                 )
            (if file-assoc
                (let ((hit (list pfile pname)))
                  (if pkgs
                      (let ((pkg (assoc pfile pkgs)))
                        (if pkg ;if `pfile' already in the package list `pkgs' at `pkg'
                            (setf pkg (nconc pkg (list pname))) ;append package name to that list
                          (setf pkg (nconc pkgs (list hit))))) ;otherwise create new list from hit
                    (setq pkgs (list hit))
                    ))
              (let ((hit (list pname pfile)))
                (if pkgs
                    (let ((pkg (assoc pname pkgs)))
                      (if pkg ;if `pname' already in the package list `pkgs' at `pkg'
                          (setf pkg (nconc pkg (list pfile))) ;append package file to that list
                        (setf pkg (nconc pkgs (list hit))))) ;otherwise create new list from hit
                  (setq pkgs (list hit))
                  )))))
        ;; (when file-status
        ;;   ;; TODO: Call "dpkg-query -l" on all the cars of PKGS.
        ;;   )
        pkgs))))

(defun dpkg-query-file-packages (file-wc &optional no-warn file-assoc)
  "Return list of packages that provide all files that match the filename wildcard string FILE-WC.
Uses `dpkg-query'. If NO-WARN is non-nil suppress any warning
messages."
  (save-window-excursion
    (let* ((sbuf (get-buffer-create "*dpkg-query-buf*"))
           ;; TODO: Use "dpkg-query -W -f='${Status}\n' PKG1 PKG2 ..."
           (status (shell-command (concat "dpkg-query -S " "\"" file-wc "\"") sbuf))
           pkgs)                          ;list of packages
      (if (= status 0)
          (auto-deb-parse-output sbuf file-assoc)
        (unless no-warn
          (message "Warning: %s could not be found in any package" (faze file-wc 'string))
          (sit-for 3)) ;prevent return value from overwriting message
        nil))))
;; Use: (dpkg-query-file-packages "/usr/include/gmp.h")
;; Use: (dpkg-query-file-packages "/usr/include/gmp.h" nil t)
;; Use: (dpkg-query-file-packages "*/gmp.h")
;; Use: (dpkg-query-file-packages "*gmp.h")
;; Use: (dpkg-query-file-packages "*gmp.h" nil t)
;; Use: (dpkg-query-file-packages "qt.h")
;; Use: (dpkg-query-file-packages "libqt4")
;; Use: (dpkg-query-file-packages "grep")
;; Use: (dpkg-query-file-packages "/bin/grepx")

(defun apt-query-file-packages (file-regexp &optional no-warn file-assoc)
  "Return list of packages that provide all files that match the filename regular expression string FILE-REGEXP.
Uses `apt-file'. If NO-WARN is non-nil suppress any warning
messages."
  (when (or (executable-find "apt-file")
            (= 0 (inhibit-messages (apt-install "apt-file")))) ;ensure apt-file is installed
    (save-window-excursion
      (let* ((sbuf (get-buffer-create "*apt-query-buf*"))
             (status (shell-command (concat "apt-file search -x " "\"" file-regexp "\"") sbuf))
             pkgs)                      ;list of packages
        (if (= status 0)
            (auto-deb-parse-output sbuf file-assoc)
          (unless no-warn
            (message "Warning: %s could not be found in any package" (faze file-regexp 'string))
            (sit-for 3))          ;prevent return value from overwriting message
          nil)))))
;; Use: (apt-query-file-packages "^/usr/include/gmp.h$")
;; Use: (apt-query-file-packages "^/usr/include/curl/curl.h$")
;; Use: (apt-query-file-packages ".*/gmp\\.h$")
;; Use: (apt-query-file-packages ".*/gmp\\.h$" nil t)
;; Use: (apt-query-file-packages ".*gmp\.h$")
;; Use: (apt-query-file-packages "qt\\.h$")
;; Use: (apt-query-file-packages "libqt4")
;; Use: (apt-query-file-packages "^/bin/.*grep$")
;; Use: (apt-query-file-packages "^/usr/bin/.*grep$")
;; Use: (apt-query-file-packages "^/bin/grepx$")
;; Use: (apt-query-file-packages "^/usr/include/[^/]*\\.[Hh][hHxp\+]*$") ; all headers directly under /usr/include
;; Use: (apt-query-file-packages "^/usr/include/.*/.*\\.h$")
;; Use: (apt-query-file-packages "canberra")
;; Use: (apt-query-file-packages "listings\\.sty$")
;; Use: (apt-query-file-packages "grep")
;; Use: (apt-query-file-packages "/opcontrol$")

(defun apt-install (pkgs &optional display-output deb-tool query command)
  "Install packages described by the list of strings PKGS."
  (let* ((pkgs (if (stringp pkgs) (list pkgs) pkgs)) ;assert list of packages
         (pkgs-name (format "%s" (if (= (length pkgs) 1)
                                     (car pkgs)
                                   (format "%s" pkgs)))))
    (when (or (not query)
              (y-or-n-p (format "Install %s (using APT)" (faze pkgs-name 'pkg))))
      (if (and
           nil                        ;TODO: Disabled for now!
           (require 'sudo nil t)
           (fboundp 'sudo-start-process))
          (sudo-start-process "apt-install"
                              (append (list "apt-get" "install" "--assume-yes") pkgs)
                              (format "Enter root password to install the packages %s: " (faze pkgs 'file))
                              display-output)
        (with-temp-buffer
          ;;(compilation-start (concat "sudo \"apt-get install -y " pkgs-name "\""))
          (shell-command (concat "gksu \"apt-get install -y " pkgs-name "\"")
                         "*sudo-apt-install-output*"
                         "*sudo-apt-install-error*")
          ;;(cd "/sudo::/")
          ;; (shell-command (concat "sudo apt-get install -y " pkgs-name)
          ;;                "*sudo-apt-install-output*"
          ;;                "*sudo-apt-install-error*")
          )))))
;; Use: (apt-install "markdown" t nil t)
;; Use: (apt-install "bison++" t nil t)
;; Use: (apt-install '("bison++") t nil t)
;; Use: (apt-install '("bison++" "bison++-doc") t nil t)
;; Use: (apt-install '("ogre-docs-nonfree") t nil t)

(defun install-system-files-regexp (file-regexp &optional no-warn file-assoc)
  "Install all Debian/Ubuntu package the provides a file matching the regexp string FILE-REGEXP.
If NO-WARN is non-nil suppress any warning messages."
  (let ((pkgs (apt-query-file-packages file-regexp no-warn file-assoc)))
    (cond ((= (length pkgs) 1)          ;if only package provided
           (let* ((pname (car (car pkgs)))
                  (pfiles (cdr (car pkgs)))
                  (pnum (length pfiles))
                  (pfirst (if (= (length pfiles) 1) (car pfiles) (cadr pfiles))))
             (if (file-exists-p pfirst)
                 pfirst
               (when (y-or-n-p (format "Install Debian/Ubuntu package %s (providing the %s): "
                                       (faze pname 'pkg)
                                       (if (= (length pfiles) 1)
                                           (concat "file " (faze (car pfiles) 'file))
                                         (concat "files " (faze pfiles 'file))
                                         )))
                 (apt-install pkgs t)
                 pname))))
          ((> (length pkgs) 1)     ;if several packages provide the same pattern
           (let ((pname (completing-read
                         (format "Choose Debian/Ubuntu package to install (providing the file pattern %s) : " (faze file-regexp 'string))
                         pkgs)))
             (cond ((stringp pname)
                    (apt-install (list pname) t)
                    )))))))
;; Use: (install-system-files-regexp "curl\\.h")
;; Use: (install-system-files-regexp "gmp\\.h")
;; Use: (install-system-files-regexp "gmpxx\\.h")
;; Use: (install-system-files-regexp "/usr/include/gmp\\.h")
;; Use: (install-system-files-regexp "*/gmp\\.h")
;; Use: (install-system-files-regexp "grep")
;; Use: (install-system-files-regexp "qt[34]")
;; Use: (install-system-files-regexp "py*q")
;; Use: (install-system-files-regexp "/bin/grepx")

(defun require-system-header-file (filename &optional no-warn dirs)
  "Install system include header file FILENAME if it is not present.
If NO-WARN is non-nil suppress any warning messages. If FILENAME
already was present return the full path to it, otherwise return
an alist where each element is of the form (PACKAGE-NAME
HEADER-FILE). If DIRS is a list search those aswell."
  (unless dirs (setq dirs (list "/usr/include"))) ;default to /usr/include
  (when (stringp dirs) (setq dirs (list dirs)))
  (delq nil
        (mapcar
         (lambda (dir)
           (let ((full (expand-file-name filename dir)))
             (if (file-readable-p full) ;if already present
                 full                   ;just return it full path
               ;; otherwise install it
               (install-system-files-regexp (replace-regexp-in-string "\\." "\\\\." full)
                                            no-warn))))
         dirs)))
;; Use: (require-system-header-file "gmp.h")
;; Use: (require-system-header-file "gmpxx.h")
;; Use: (require-system-header-file "curl/curl.h")
;; Use: (require-system-header-file "curl.h")
;; Use: (require-system-header-file "iostream" nil '("/usr/include/c++/4.4"))
;; Use: (require-system-header-file "iostream" nil '("/usr/include/c++/4.5"))
;; Use: (require-system-header-file "gmp.hx")

;; ---------------------------------------------------------------------------

;; TODO: Make work for files in new non-existing directories for
;; example "/etc/mdadm/mdadm.conf".
(defun query-insert-apt-file ()
  "Query auto-install of APT package that provides `buffer-file-name'."
  (interactive)
  (let ((filename (expand-file-name buffer-file-name)))
    (when (and (not (string-match (getenv "HOME") filename)) ;not under home
               (not (string-match "/tmp" filename))          ;nor under /tmp
               (y-or-n-p (format "Install system package(s) providing file %s " filename)))
      (let ((packages (dpkg-query-file-packages filename))))
      )))
(add-hook 'find-file-not-found-functions 'query-insert-apt-file t)

;; NOTE: Deprecated by `query-insert-apt-file' added to
;; `find-file-not-found-functions'.
(when nil
  (defun query-insert-apt-file-if-not-found ()
    "Query auto-install of APT package that provides `buffer-file-name'."
    (interactive)
    (let ((filename buffer-file-name))
      (when (and filename                      ;buffer "has a file"
                 (not (file-exists-p filename)) ;that doesn't exist yet
                 (y-or-n-p (format "Install system package(s) providing file %s " (faze filename 'file))))
        (let ((packages (dpkg-query-file-packages filename))))
        )))
  (add-hook 'find-file-hook 'query-insert-apt-file-if-not-found t))

;; ---------------------------------------------------------------------------

(defun apt-query-system-header-basenames (&optional file-regexp no-warn file-assoc)
  "Return list of packages that provide all system headers whose
basename (without extension) matches the regular expression
FILE-REGEXP."
  (apt-query-file-packages (concat "^/usr/include/"
                                   (or file-regexp "[^/]*")
                                   "\\.[hH][hHxp\+]*$") no-warn file-assoc))
;; Use: (apt-query-system-header-basenames "gtk.*")

;; ---------------------------------------------------------------------------

;; (when nil (regexp-opt '("/bin" "/sbin" "/usr/bin" "/usr/sbin")))
(defconst apt-executables-path-prefix-regexp
  "^/(usr/)?s?bin/")

(defvar apt-executables-cache nil
  "Cached System Executables/Commands queried using APT.")
(eval-when-compile (setq apt-executables-cache nil))
(defun apt-query-executables (&optional file-regexp no-warn file-assoc)
  "Return list of packages that providing system commands whose
names matches the regular expression FILE-REGEXP."
  (if file-regexp
      (message "Querying APT for system commands matching regexp %s..." (faze file-regexp 'string))
    (message "Querying APT for all system commands..."))
  (if (and (not file-regexp)
           file-assoc)
      (or apt-executables-cache
          (setq apt-executables-cache
                (apt-query-file-packages (concat apt-executables-path-prefix-regexp
                                                 (or file-regexp "[^/\t]*")
                                                 "[^\t]*"
                                                 "$") no-warn file-assoc)))
    (apt-query-file-packages (concat apt-executables-path-prefix-regexp
                                     (or file-regexp "[^/\t]*")
                                     "[^\t]*"
                                     "$") no-warn file-assoc)))
;; Use: (apt-query-executables nil nil t)
;; Use: (apt-query-executables "gnome" nil t)
;; Use: (apt-query-executables "grep" nil t)
;; Use: (apt-query-executables "clang" nil t)
;; Use: (apt-query-executables "octave" nil t)
;; Use: (apt-query-executables "s" nil t)

;; ---------------------------------------------------------------------------

;;; TODO: Add advice on `executable-find'.
(defun executable-find-auto-install-on-demand (command &optional pkgs)
  "Execute COMMAND.
If command is not installed query to install it (on demand)."
  (interactive)
  (if (list-of-strings-p command)
      (mapcar 'executable-find-auto-install-on-demand command)
    (or (executable-find command)
        (when (apt-install (or pkgs
                               (caar (apt-query-file-packages (concat "/bin/" command "$")))))
          (executable-find command))
        ;; (apt-install
        ;;  (or pkgs command)                ;default package name to command name
        ;;  display-output deb-tool query)
        )))
;; Use: (executable-find-auto-install-on-demand "markdown")
;; Use: (executable-find-auto-install-on-demand "opcontrol")
;; Use: (executable-find-auto-install-on-demand '("markdown" "markdown"))

;; ---------------------------------------------------------------------------

(require 'multi-dir)

(defun executables-online (&optional prompt path full)
  "Get Executable files present in PATH.
PATH defaults to ."
  )

(defun read-executables-filename (&optional prompt path full match predicate require-match initial-input hist def inherit-input-method include-sans-directory)
  "Read all potential executables (cmd) that have been or can be
installed in `apt-executables-path-prefix-regexp'.
FULL can be either `nil,' `t' or `full-duplicates'."
  (interactive)
  (let* ((cache (when (and (memq system-type '(gnu gnu/linux))
                           (executable-find "apt"))
                  (apt-query-executables nil nil t)))
         (prompt (or prompt (if cache "Executable (in APT): " "Executable: ")))
         (cache (append (when include-sans-directory
                          ;; TODO: Replace with special combination of a new
                          ;; completion-style `completion-sansdir-.*' and partial
                          ;; completion prepended to `completion-styles-cycle-alist'.
                          ;; SEE: https://groups.google.com/forum/?hl=sv#!topic/gnu.emacs.help/LFYZDE3A7dU
                          (mapcar (lambda (entry)
                                    (cons (file-name-sans-directory
                                           (car entry)
                                           ;; (cond ((and (listp entry)
                                           ;;             (stringp (car entry)))
                                           ;;        (car entry))
                                           ;;       ((stringp entry)
                                           ;;        entry))
                                           )
                                          (cdr entry)))
                                  cache))
                        cache))
         )
    (if cache
        (let* ((extra-path (remove "/sbin"
                                   (remove "/bin"
                                           (remove "/usr/sbin"
                                                   (remove "/usr/bin"
                                                           exec-path))))) ;TODO: Sync this with `apt-executables-path-prefix-regexp'.
               (extra-exec (when extra-path
                             (multi-directory-files extra-path t)))
               (hit (completing-read prompt
                                     (append cache extra-exec)
                                     predicate t
                                     initial-input hist def inherit-input-method))
               (full-hit (executable-find hit
                                          )))
          (if (stringp full-hit)
              full-hit
            (assoc full-hit cache)))
      (executable-find
       (multi-read-file-name prompt (or path exec-path) full match predicate require-match initial-input hist def inherit-input-method)))))
;; Use: (read-executables-filename)
;; Use: (read-executables-filename nil nil 'full-executables)

(defun shell-command-auto-install-on-demand  (&optional prompt installed-only executable skip-arguments)
  "Ask for a (potentially uninstalled) execute a command.
If command is not installed query to install it (on demand)."
  (interactive)
  (let* ((full 'full-duplicates)
         (hit (or (executable-find executable)
                  (read-executables-filename prompt nil full nil
                                             (when installed-only
                                               (lambda (elt)
                                                 (file-executable-p (car elt)))) nil nil nil nil nil t)))
         (filename (if (stringp hit) hit (car hit)))
         (package (when (listp hit) (cdr hit)))
         (args (if skip-arguments
                   nil
                 (when filename
                   (read-string (format "Arguments to %s: " (faze filename 'file))))))
         (async t)
         (command (when filename
                    (concat filename " " args (when async " &"))))
         (buffer (if async "*Async Shell Command*" "*Shell Command Output*")))
    (if (or (and filename
                 (file-exists-p filename))
            (and package (apt-install package nil nil t)))
        (progn (shell-command command)
               (display-buffer buffer)
               (with-current-buffer buffer
                 (balance-windows)
                 (shrink-fit-window-of-buffer buffer)
                 (goto-char (point-min))) ;make first line visible
               )
      (message "File %s neither found nor installable" (if filename
                                                           (faze filename 'file)
                                                         "")))))
;; Use: (shell-command-auto-install-on-demand)
;; Use: (shell-command-auto-install-on-demand nil nil "ls")
;; Use: (shell-command-auto-install-on-demand nil nil "ls" t)
;; Use: (shell-command-auto-install-on-demand nil t)

(defun shell-command-on-region-auto-install-on-demand  (&optional prompt installed-only)
  (interactive)
  (let* ((hit (read-executables-filename prompt nil nil nil
                                         (when installed-only
                                           (lambda (elt)
                                             (file-executable-p (car elt))))))
         (filename (if (stringp hit) hit (car hit))))
    (if (file-exists-p filename)
        (shell-command-on-region (region-beginning) (region-end) filename)
      (when (apt-install (cdr hit) nil nil t)
        (shell-command-on-region (region-end) (region-end) filename)))))
;; Use: (shell-command-on-region-auto-install-on-demand)

(defun auto-deb-setup-keybindings ()
  (interactive)
  (global-set-key [(meta ?\!)] 'shell-command-auto-install-on-demand)
  (global-set-key [(meta ?\|)] 'shell-command-on-region-auto-install-on-demand)
  )

;;; WARNING: Overrides behaviour!
(defun read-shell-command (&optional prompt initial-contents hist &rest args)
  "Read a shell command from the minibuffer.
The arguments are the same as the ones of `read-from-minibuffer',
except READ and KEYMAP are missing and HIST defaults
to `shell-command-history'."
  (require 'shell)
  (minibuffer-with-setup-hook
      (lambda ()
        (shell-completion-vars)
        (set (make-local-variable 'minibuffer-default-add-function)
             'minibuffer-default-add-shell-commands))
    (let* ((exec (read-executables-filename (or prompt "Shell Executable: ")
                                            nil 'full-duplicates
                                            nil nil nil initial-contents
                                            ;;minibuffer-local-shell-command-map
                                            (or hist 'shell-command-history)
                                            ;;args
                                            ))
           (args (when exec
                   (read-strings (format "Arguments to %s: " exec)))))
      (mapconcat 'identity (append (list exec) args) " "))))
;; Use: (read-shell-command)
;; (defadvice read-shell-command (around read-shell-command-ctx-flash (prompt &optional initial-contents hist &rest args))
;;   (completing-read-shell-command prompt initial-contents hist args))
;;(ad-activate 'read-shell-command)
;;(ad-disable-advice 'read-shell-command)

;; ---------------------------------------------------------------------------

(provide 'auto-deb)
