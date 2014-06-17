;;; do-on-save.el --- Perform Operations (Compile, Load, Test, Debug, etc.) upon Saving Buffer.
;; Author: Per Nordlöw

;;; TODO: Notify if byte-compile-file changed generated .elc
;;; Here are some alternative solutions:
;;; See: http://www.emacswiki.org/cgi-bin/wiki/AutoCompileInit

(require 'read-char-spec)
(require 'filedb)

;; TODO: Check if .elc needs rebuild using .el (using filedb.el interface).
(defun query-byte-compile (&optional prompt)
  "Ask the user whether to byte-compile the current buffer
if its name ends in `.el' and the `.elc' file also exists."
  (let ((name buffer-file-name))
    (and name
         (string-match "\\.el$" name)
         (not (or (and custom-file      ;if custom-file is set
                       ;; prevent it from being byte-compiled
                       (string-equal (expand-file-name custom-file)
                                     (expand-file-name name)))
                  (string-equal (file-name-nondirectory name) "ede-projects.el")))
         (when (or (not prompt)
                   (y-or-n-p (format "Byte-compile %s? " name)))
           ;; (byte-recompile-file name)
           (byte-compile-file name)
           ))))
;; Use: (query-byte-compile t)

(defun query-load-buffer (&optional prompt)
  "Ask the user whether to load byte-compiled version of current
buffer if its name ends in `.el'."
  (let ((name buffer-file-name))
    (and name
         (string-match "\\.el$" name)
         (not (or (string-match "dotemacs.el$" name)
                  (string-equal (file-name-nondirectory name) "ede-projects.el")))
         (let ((cname (concat name "c")))
           (if (file-exists-p cname)
               (when (or (not prompt)
                         (y-or-n-p (format "Load %s? " cname)))
                   (load-file cname)))))))
;; Use: (query-load-buffer t)

(defun query-test-buffer (&optional prompt)
  "Ask the user to run all Unit Tests related to the current
buffer."
  (let ((name buffer-file-name))
    (and name
         (string-match "\\.el$" name)
         (when (fboundp 'elk-test-run-buffer)
           (let ((elk-name (concat (file-name-sans-extension name) ".elk")))
             (if (file-exists-p elk-name)
                 (when (or (not prompt)
                           (y-or-n-p (format "Run Tests in %s? " elk-name)))
                   (save-excursion
                     (split-window-vertically)
                     (other-window 1)
                     (find-file elk-name)
                     (shrink-window-if-larger-than-buffer)
                     (elk-test-run-buffer)))))))))
;; Use: (query-test-buffer t)

(defconst do-on-save-spec
  '((?c ?c "Compile (implies Save)")
    (?l ?l "Load (implies Save and Load)")
    (?t ?t "Test (implies Save, Compile and Load)")
    (?d ?d "Debug (implies Save)")
    (?p ?p "Profile (implies Save)")
    (?q nil "Quit"))
  "`read-char-spec' SPECIFICATION.")
;; Use: (read-char-spec "Do on save" do-on-save-spec)

(defun do-on-save-elisp ()
  "Unless current buffer is the `custom-file' do stuff with it."
  (let ((name buffer-file-name))
    (when (and (or (not custom-file)
                   (not (equal (expand-file-name name)
                               (expand-file-name custom-file)))) ;unless we are (auto-) saving custom-file
               (not (string-equal (file-name-nondirectory name)
                                  "ede-projects.el")))
      (case (read-char-spec "Do on save" do-on-save-spec)
        (?c
         (query-byte-compile))
        (?l
         (when (query-byte-compile)     ;if compilation is successful
           (query-load-buffer) ;we probably want to reload byte-compiled version
           ))
        (?t
         (when (query-byte-compile)     ;if compilation is successful
           (query-load-buffer) ;we probably want to reload byte-compiled version
           (query-test-buffer)))
        ))))

(defun do-on-save-x-resource-generic ()
  (when (and (string-equal (file-name-sans-directory buffer-file-name)
                           ".Xdefaults")
             (executable-find-auto-install-on-demand "xrdb"))
    (let ((ch ?u))
      (case (read-char-spec "Do on save" `((,ch ,ch "Update X State (xrdb))")
                                           (?q nil "Quit")))
        (ch
         (call-process "xrdb" nil nil nil buffer-file-name)
         )))))

(defun do-on-save-xmodmap-generic ()
  (when (and (string-equal (downcase (file-name-sans-directory buffer-file-name))
                           ".xmodmap")
             (executable-find-auto-install-on-demand "xmodmap"))
    (let ((ch ?u))
      (case (read-char-spec "Do on save" `((,ch ,ch "Update X Keyboard State (xmodmap))")
                                           (?q nil "Quit")))
        (?u
         (call-process "xmodmap" nil nil nil buffer-file-name)
         )))))

(defun do-on-save-xml ()
  (when (and (or (eq major-mode 'xml-mode)
                 (string-suffix-p ".xml" (downcase (file-name-sans-directory buffer-file-name))))
             (executable-find-auto-install-on-demand "xmllint"))
    (let ((ch ?l))
      (case (read-char-spec "Do on save" `((,ch ,ch "Run xmllint on buffer)")
                                           (?q nil "Quit")))
        (?l
         (call-process "xmllint" nil nil nil buffer-file-name)
         )))))

(defun do-on-save-python ()
  (when (and (or (eq major-mode 'python-mode)
                 (string-suffix-p ".py" (downcase (file-name-sans-directory buffer-file-name))))
             (executable-find-auto-install-on-demand "pyflakes"))
    ;; TODO: Call it and only show it if exit status is non-zero.
    (case (read-char-spec "Do on save" `((?f ?f "Run pyflakes on buffer)")
                                         (?l ?l "Run pylint on buffer)")
                                         (?q nil "Quit")))
      (?f
       (compile (concat "pyflakes " buffer-file-name) t)
       )
      (?l
       (compile (concat "pylint -f parseable " buffer-file-name) t)
       ))
    ))

(defvar mode-specific-after-save-buffer-hooks nil
  "Alist (MAJOR-MODE . HOOK) of after-save-buffer hooks
specific to major modes.")

(defun run-mode-specific-after-save-buffer-hooks ()
  "Run hooks in `mode-specific-after-save-buffer-hooks' that match the
current buffer's major mode.  To be put in `after-save-buffer-hooks'."
  (let ((hooks mode-specific-after-save-buffer-hooks))
    (while hooks
      (let ((hook (car hooks)))
        (if (eq (car hook) major-mode)
            (funcall (cdr hook))))
      (setq hooks (cdr hooks)))))

(setq mode-specific-after-save-buffer-hooks
      '((emacs-lisp-mode . do-on-save-elisp)
        (lisp-mode . do-on-save-elisp)
        ;; (x-resource-generic-mode . do-on-save-x-resource-generic)
        ;; (xmodmap-generic-mode . do-on-save-xmodmap-generic)
        ;; (xml-mode . do-on-save-xml)
        ;; (nxml-mode . do-on-save-xml)
        ;; (python-mode . do-on-save-python)
        ))

(add-hook 'after-save-hook 'run-mode-specific-after-save-buffer-hooks t)

(provide 'do-on-save)
