;;; tags-update.el - Update tags files.

(require 'cscan)

;; FIXME: When should we use Make and HTML?
(defconst etags-update-command
  "ctags-exuberant --excmd=number --sort=no --links=no -e --languages=MatLab,C,C++,Java,C#,Python,Ruby,Lisp,Sh --extra=+f --file-scope=yes -R"
  "Shell command used to update Exuberant CTags database.")

(defconst ectags-update-command
  "ctags-exuberant --excmd=number --sort=no --links=no --languages=MatLab,C,C++,Java,C#,Python,Ruby,Lisp,Sh --extra=+f --file-scope=yes --fields=afikmnsSt -R"
  "Shell command used to update Vi CTags database.")

(defconst gtags-update-command
  "global -u"
  "Shell command used update GNU GLOBAL tags database.")

(defconst idutils-update-command
  "mkid"
  "Shell command used to update idutils tags database.")

(defconst cscope-update-command
  "cscope -b -q"
  "Shell command used to update a Cscope tags database.")

(defconst cscope-kernel-update-command
  "cscope -b -q -k"
  "Shell command used to update a Linux Kernel Cscope tags
  database.")

(defun tags-update-at (directory &optional tags-type sync-flag)
  "Update tags databas(es) in DIRECTORY. TAGS-TYPE can either
'etags, 'ectags, gtags, 'cscope or 'all."
  (unless directory (setq directory default-directory))
  (let* ((tags-name (if tags-type (symbol-name tags-type) "tags"))
         (tgt-pattern (concat tags-name ":"))
         (use-start-process t)
         )
    ;;(message "Updating %s in %s..." tags-type directory)
    ;; TODO Reuse filedb.el Makefile name pattern here using new function `directory-file-of-type'.
    (cond ((or (cscan-file-maybe (expand-file-name "GNUmakefile" directory) tgt-pattern)
               (cscan-file-maybe (expand-file-name "makefile" directory) tgt-pattern)
               (cscan-file-maybe (expand-file-name "Makefile" directory) tgt-pattern))
           (let* ((buf (concat "*" "make-" tags-name "@" directory))
                  (out-buf (concat buf "-output"))
                  (err-buf (concat buf "-error")))
             (if use-start-process
                 (start-process "make-tags-update" buf "make" (append tags-name))
               (when (require 'shell-command-ext nil t)
                 (if (fboundp 'shell-command-silent-at)
                     (shell-command-silent-at (concat "make " tags-name (unless sync-flag "&"))
                                              directory out-buf err-buf)
                   (shell-command (concat "make -C " directory " " tags-name (unless sync-flag "&"))
                                  out-buf err-buf))))))
          ((eq 'all tags-type)
           (dolist (tags-type '(etags ectags gtags idutils cscope))
             (tags-update-at directory tags-type)) ;recurse
           )
          (t
           (let* ((buf (concat "*" tags-name "@" directory))
                  (out-buf (concat buf "-output"))
                  (err-buf (concat buf "-error"))
                  (cmd (case tags-type
                         ('etags etags-update-command)
                         ('ectags ectags-update-command)
                         ('Exuberant-Ctags ectags-update-command)
                         ('gtags gtags-update-command)
                         ('idutils idutils-update-command)
                         ('cscope cscope-update-command)
                         ('t ectags-update-command)
                         ))
                  (args (split-string cmd)))
             (if use-start-process
                 `(start-process "make-tags-update" ,out-buf ,(car args) ,@(cdr args))
               (when (require 'shell-command-ext nil t)
                 (shell-command-silent-at (concat cmd (unless sync-flag "&")) directory out-buf err-buf))))))))
;; Use: (tags-update-at nil 'ectags)
;; Use: (tags-update-at nil 'all)
;; Use: (tags-update-at "~/justcxx/" 'all)
;; Use: (tags-update-at "~/justcxx/" 'ectags)

(provide 'tags-update)
