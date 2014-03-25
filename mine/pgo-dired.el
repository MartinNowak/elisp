;;; pgo-dired.el --- Setup dired.
;; Author: Per Nordlöw

(require 'uproj)
(require 'filedb)

;; ---------------------------------------------------------------------------

(defvar file-icon-cache
  (make-hash-table :size 1031           ;TODO: Is this a good default value?
                   :test 'equal)
  "Hash table that maps filenames to icon images.")

;; (mailcap-extension-to-mime "\.sh")
(defun insert-file-icon (filename &optional pos skip-overlay)
  "Insert icon of FILENAME in front of POS in the current buffer.
POS defaults to point."
  (interactive "fFile: ")
  (let* ((mime-type (mailcap-extension-to-mime
                     (file-name-extension filename t)))
         (icon-file
          (if mime-type (concat "/usr/share/icons/gnome/16x16/mimetypes/gnome-mime-"
                                (replace-regexp-in-string "/" "-" mime-type) ".png")))
         overlay)
    (unless (and icon-file (file-exists-p icon-file))
      (setq icon-file "/usr/share/icons/gnome/16x16/mimetypes/empty.png")) ;default icon
    (unless (delq nil (mapcar (lambda (o) (overlay-get o 'put-image))
                              (overlays-in (point) (1+ (point)))))
      ;; TODO: Use hash-table from mime-type to object returned by `create-image'.
      (put-image (create-image icon-file) (or pos (point)))
      (unless skip-overlay
        (setq overlay
              (car (delq nil (mapcar (lambda (o) (and (overlay-get o 'put-image) o))
                                     (overlays-in (point) (1+ (point)))))))
        (overlay-put overlay 'file filename)
        (overlay-put overlay 'icon-file icon-file)))))
;; Use: (insert-file-icon "/bin/ls")
;; Use: (insert-file-icon "~/sample.sh")

(defun dired-insert-file-icons ()
  "Insert icons before file names in the dired buffer."
  (interactive)
  (dired-map-dired-file-lines
   (lambda (filename)
     (insert-file-icon filename (dired-move-to-filename))
     )))
;; Note: Good idea but does not yet work together with openwith.el.
;;(add-hook 'dired-after-readin-hook 'dired-insert-file-icons)
;;(remove-hook 'dired-after-readin-hook 'dired-insert-file-icons)

;; ---------------------------------------------------------------------------

;; Extensions to dired mode
(when nil
  (eval-after-load "dired" '
    (eload 'dired+)
    ;; Note: skip fancy decoration
    (remove-hook 'dired-mode-hook
                 (lambda ()
                   (set (make-local-variable 'font-lock-defaults)
                        (cons '(dired-font-lock-keywords diredp-font-lock-keywords-1) ; Two levels.
                              (cdr font-lock-defaults)))))
    ))

;; Create and unpack tar files
(when (eload 'dired-tar))

;;; Sorting
;; (eload 'dired-explore)
;; (eload 'dired-lis)
;; (eload 'dired-sort)
(add-hook 'dired-load-hook
          (lambda ()
            (eload 'dired-sort-menu)
            (eload 'dired-sort-menu+)
            ))

(when nil
  (when (eload 'diredful)       ;See: http://www.emacswiki.org/emacs-en/Diredful
    )


  ;; dired-isearch.el --- isearch in Dired
  (when (eload 'dired-isearch)
    ;; (define-key dired-mode-map (kbd "C-s") 'dired-isearch-forward)
    ;; (define-key dired-mode-map (kbd "C-r") 'dired-isearch-backward)
    ;; (define-key dired-mode-map (kbd "ESC C-s") 'dired-isearch-forward-regexp)
    ;; (define-key dired-mode-map (kbd "ESC C-r") 'dired-isearch-backward-regexp)
    )

  ;; See: EmacsWiki:DiredDetails: http://www.emacswiki.org/cgi-bin/wiki/DiredDetails
  (when nil
    (eval-after-load "dired" '(eload 'dired-details))
    (eval-after-load "dired" '(eload 'dired-details+))
    )

  ;; dired-extension.el --- Some extension for dired
  ;;(eload 'dired-extension)

  ;; provide some dired goodies and dired-jump at C-x C-j
  (load "dired-x")

  (add-hook 'dired-load-hook
            (lambda ()
              (load "dired-column-widths.el")))

  ;; dired-single.el -- reuse the current dired buffer to visit another directory
  (when (eload 'dired-single)
    )

  ;; Omitting Git-ignored files in Emacs dired
  ;; See: http://www.newartisans.com/blog_files/git.omit.in.emacs.dired.php#unique-entry-id-71
  ;; WARNING: ENCODING OF EMACS LISP CODE ONE THIS PAGE INCORRECT!
  (add-hook 'dired-load-hook (lambda nil (load "dired-x" t)))
  (eval-after-load "dired-x"
    '(progn
       (defvar dired-omit-regexp-orig (symbol-function 'dired-omit-regexp))

       (defun dired-omit-regexp ()
         (let ((file (expand-file-name ".git"))
               parent-dir)
           (while (and (not (file-exists-p file))
                       (progn
                         (setq parent-dir
                               (file-name-directory
                                (directory-file-name
                                 (file-name-directory file))))
                         ;; Give up if we are already at the root dir.
                         (not (string= (file-name-directory file)
                                       parent-dir))))
             ;; Move up to the parent dir and try again.
             (setq file (expand-file-name ".git" parent-dir)))
           ;; If we found a change log in a parent, use that.
           (if (file-exists-p file)
               (let ((regexp (funcall dired-omit-regexp-orig)))
                 (assert (stringp regexp))
                 (concat
                  regexp
                  (if (> (length regexp) 0)
                      "\\|" "")
                  "\\("
                  (mapconcat
                   (lambda (str)
                     (concat "^"
                             (regexp-quote
                              (substring str 13
                                         (if (= ?/ (aref str (1- (length str))))
                                             (1- (length str))
                                           nil)))
                             "$"))
                   (split-string (shell-command-to-string
                                  "git clean -d -x -n")
                                 "\n" t)
                   "\\|")
                  "\\)"))
             (funcall dired-omit-regexp-orig))))))
  )

(eload 'runner)                  ;improved "open with" suggestions for dired

(provide 'pgo-dired)
