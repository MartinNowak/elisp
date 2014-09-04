;;; pgo-icicles.el --- Setup Icicles
;; Author: Per Nordlöw

;; (setq icicle-bind-top-level-commands-flag nil)_

;; Completion: iswitchb, ido, mcomplete, icomplete
;; Completion: icicles replaces all of the above

(defcustom pnw/use-icicles t
  "Flags whether or not to load icicles upon startup." :type 'boolean :group 'pnw-options)

;; TODO: Fix this!
(defvar minibuffer-local-must-match-filename-map minibuffer-local-must-match-map)

;; icicles: replaces ido, mcomplete, icomplete
(when (and window-system
           pnw/use-icicles)

  (when nil
    (when (file-directory-p (elsub "icicles/"))
      (byte-recompile-directory (elsub "icicles/") 0)))

  (when (require 'icicles nil t) ;Note: If an error occurred try loading it again. This is a hack to make Icicles work on Emacs 23.1

    (global-set-key [(meta shift s)] 'icicle-search-generic)

;;;     (icicle-define-command icicle-locate ; Command name
;;;                            "Run the program `locate', then visit files.
;;; Unlike `icicle-locate-file' this command is a wrapper for the program `locate'." ; Doc string
;;;                            find-file                             ; Function to perform the action
;;;                            "File: " (mapcar #'list (split-string (shell-command-to-string (format "%s '%s'" locate-command query)) "\n" t))
;;;                            nil t nil 'locate-history-list nil nil
;;;                            ((query (read-string "Locate: "))))

    ;; To get the behavior you want, you could, for example, set or
    ;; bind `icicle-file-predicate' to a predicate. You can also set
    ;; `icicle-file-match-regexp' and/or
    ;; `icicle-file-no-match-regexp'.
    (defun non-vc-diretory-p (dir)
      "Check that DIR is not a directory containing a Version
Control Database."
      (not (member (file-name-nondirectory dir) vc-directory-exclusion-list)))
    (defalias 'non-vc-directory? 'non-vc-directory-p)
    ;; Use: (non-vc-diretory-p ".git")
    ;; Use: (non-vc-diretory-p "~/justcxx/.git")
    ;; ToDo: (setq icicle-directory-predicate 'non-vc-diretory-p)
    (setq icicle-file-no-match-regexp
          (concat "/" (regexp-opt (append vc-directory-exclusion-list '(".deps" ".backups")))))
    ;; ToDo: Reuse fmd.el logic.

    (defun not-excluded-vc-file-p (file)
      "nil if FILE is in a `vc-directory-exclusion-list' directory."
      (or (not (boundp 'vc-directory-exclusion-list))
          (not (consp vc-directory-exclusion-list))
          (not (let ((case-fold-search completion-ignore-case))
                 (catch 'nevfp
                   (dolist (dir vc-directory-exclusion-list)
                     (when (string-match
                            (concat ".*" dir "\\(/.*\\)?")
                            file)
                       (throw 'nevfp t)))
                   nil)))))
    (defalias 'not-excluded-vc-file? 'not-excluded-vc-file-p)

    (defun my-locate-non-vc-file ()
      "`icicle-locate-file', but excluding stuff in VC directories."
      (interactive)
      (let ((icicle-file-predicate 'not-excluded-vc-file-p))
        (icicle-locate-file)))

    ;; Menu Completion At the Keyboard
    (when (require 'lacarte nil t)
      ;; For convenience, bind a key sequence to
      ;; icicle-execute-menu-commandôòù:

      (global-set-key [?\e (meta x)] 'lacarte-execute-menu-command)

      ;; And youôòùre good to go. Type
      ;; `<ESC> M-xôòù. You are prompted
      ;; for a menu command to execute. Just start typing its
      ;; name. Each menu item s full name, for completion, has its
      ;; parent menu names as prefixes, as shown in the example above:

      ;; Tools > Compare (Ediff) > Two Files...
      )
    )
  )

(when (require 'filedb nil t)
  (defun icicle-describe-file (filename)
    "Describe the file named FILENAME.
If FILENAME is nil, describe the current directory."
    (interactive "FDescribe file: ")
    (unless filename (setq filename  default-directory))
    (help-setup-xref (list #'icicle-describe-file filename) (interactive-p))
    (let ((attrs  (file-attributes filename)))
      (unless attrs (error (format "Cannot open file `%s'" filename)))
      (let* ((type             (nth 0 attrs))
             (numlinks         (nth 1 attrs))
             (uid              (nth 2 attrs))
             (gid              (nth 3 attrs))
             (last-access      (nth 4 attrs))
             (last-mod         (nth 5 attrs))
             (last-status-chg  (nth 6 attrs))
             (size             (nth 7 attrs))
             (permissions      (nth 8 attrs))
             ;; Skip 9: t iff file's gid would change if file were deleted and recreated.
             (inode            (nth 10 attrs))
             (device           (nth 11 attrs))
             (help-text
              (concat (format "Properties of `%s':\n\n" (faze filename 'file))
                      (format "Type:                       %s\n"
                              (cond ((eq t type) "Directory")
                                    ((stringp type) (format "Symbolic link to `%s'" (faze type 'file)))
                                    (t "Normal file")))
                      (when (fboundp 'file-type-names)
                        (format "Content:                    %s\n" (or (file-type-names filename)
                                                                       "Unknown")))
                      (format "Permissions:                %s\n" permissions)
                      (and (not (eq t type)) (format "Size in bytes:              %g\n" size))
                      (format-time-string
                       "Time of last access:        %a %b %e %T %Y (%Z)\n" last-access)
                      (format-time-string
                       "Time of last modification:  %a %b %e %T %Y (%Z)\n" last-mod)
                      (format-time-string
                       "Time of last status change: %a %b %e %T %Y (%Z)\n" last-status-chg)
                      (format "Number of links:            %d\n" numlinks)
                      (format "User ID (UID):              %s\n" uid)
                      (format "Group ID (GID):             %s\n" gid)
                      (format "Inode:                      %S\n" inode)
                      (format "Device number:              %s\n" device))))
        (with-output-to-temp-buffer "*Help*" (princ help-text))
        help-text)))
  (global-set-key [(control ?h) (meta ?f)] 'icicle-describe-file)
  )

;;;###autoload
(defun icicle-pop-tag-mark-pnw ()
  "Like `pop-tag-mark' using `switch-to-buffer'.
By default, Icicle mode remaps all key sequences that are normally
bound to `pop-tag-mark' to `icicle-pop-tag-mark'.  If you do not want
this remapping, then customize option
`icicle-top-level-key-bindings'."
  (interactive)
  (require 'etags)
  (when (ring-empty-p find-tag-marker-ring) (error "No previous locations for find-tag invocation"))
  (let ((marker  (ring-remove find-tag-marker-ring 0)))
    (switch-to-buffer (or (marker-buffer marker) (error "The marked buffer has been deleted")) t)
    (goto-char (marker-position marker))
    (set-marker marker nil nil)))
(global-set-key [(meta ?*)] 'icicle-pop-tag-mark-pnw)

(provide 'pgo-icicles)
