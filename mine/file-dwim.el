;;; file-dwim.el --- Execute (Buffer/File) DWIM.
;; Author: Per Nordlöw

;; TODO:
;; - c-mode and c++-mode: Auto-Build buffer-file-name into a temporary
;; sub-directory (if it contains a main function otherwise ask completing-read
;;                   projects that use current buffer) .temp-builds and run it from there

;; - IN `file-dwim' (let ((eval-window (current-window)) ;TODO: Restore this
;; - somewhere else through a global variable and `select-window'.

;; - Separate strace output from ordinary output into a separate buffers using
;; - the flag -o "/tmp/emacs-strace-output" and display using split-window.

;; - Query user for [sl]trace options typically
;;   - Category of system calls completed using scanning executable ELF file for
;;     called symbols. Reuse ELF scanning logic from my auto-build.el. See strace
;;   - Forked or Not
;; -
;; - man page for details.

;; C-x on when on a function in elisp-mode first asks for file defaulting to
;; current and then asks to evaluation function defaulting to
;; using (thing-at-point 'defun) and `bounds-of-defun-bfpt'.

(require 'compile)
(require 'file-execute)
(require 'filedb)
(require 'file-utils)
(require 'main-function)
(require 'multi-read)

;; ---------------------------------------------------------------------------

;; TODO: Do `process-send-string' by binding it locally in `process-buffer'.
(defun file-dwim (filename &optional op args display-output compilation-window source-file build-type working-directory)
  "Apply operation (Operate) OP on FILENAME.
If op is `ask' read it.
If op is `try-last' try getting the last cached.
Optionally display output buffer if DISPLAY-OUTPUT is non-nil.
Optional COMPILATION-WINDOW gives the window where FILENAME was compiled."
  (interactive (list (read-file-name (format "Do (default %s): "
                                             (file-name-nondirectory (buffer-file-name)))
                                     nil buffer-file-name t
                                     (file-name-nondirectory buffer-file-name))))
  (if (url-ops filename)
      (let* ((op (or (and op
                          (not (eq op 'ask)))
                     (read-file-op filename nil nil (eq op 'try-last)))) ;ask for operation if not defined
             (opfun (or (file-op filename op)  ;operation value
                        (file-op filename :execute))) ;default to execute
             (win (current-window)) ;TODO: Restore this somewhere else through a global variable and `select-window'.
             )
        (let ((opfun (if (and (listp opfun)
                              (eq (car opfun) 'quote))
                         (eval opfun)   ;(quote OPFUN) => OPFUN
                       opfun)))
          (if (and opfun                ;if predefined operation
                   (symbolp opfun)
                   (fboundp opfun)      ;and it is a function
                   (functionp opfun)    ;and it is a anonymous function (lambda)
                   )
              (funcall opfun filename build-type compilation-window working-directory args) ;call it
            (file-execute filename nil args display-output compilation-window source-file nil nil build-type working-directory)
            )))
    (message "File %s has no operations" (faze filename 'file))))
(global-set-key [(control c) (f)] 'file-dwim)

(defun execute-region (&optional region flag)
  "Execute REGION."
  (let* ((region (or region
                     (cons (region-beginning)
                           (region-end))))
         (start (car region))
         (end (cdr region)))
    (cond ((eq major-mode 'sh-mode)
           (sh-execute-region start end flag))
          ((eq major-mode 'emacs-lisp-mode)
           (eval-region start end t))
          ((eq major-mode 'matlab-mode)
           (when (fboundp 'matlab-shell-run-region)
             (matlab-shell-run-region start end)))
          ((cc-derived-mode-p)
           (message "TODO: Execute region by copying region in an main stub compile and execute it."))
          (t
           (message "Execute region not supported in %s" (faze major-mode 'mode))))))

;; ---------------------------------------------------------------------------

;; TODO: If prefix display all the output buffers simultaneously in
;; side-by-side windows. Ask Google Groups on functions for displaying
;; many windows in a grid at the same time.
;; TODO: Return nil for now marked files.
(defun dired-marked-files-dwim (&optional arg)
  "Execute current file or all marked (or next ARG) files."
  (interactive "P")
  (mapcar (lambda (file)
              (file-dwim file))
          (dired-get-marked-files nil arg)))

;; TODO: Use `(url-ops FILENAME)' and input result it to `read-char-spec'.
;; TODO: Do we need special handling for ELF files?
;; TODO: Input !, X performs the same action on all remaining files.
(defun dired-operate-on-file (&optional arg)
  "Operate on current file or all marked (or next ARG) files."
  (interactive "P")
  (mapcar (lambda (filename)
              (if (and (file-executable-p filename) ;if executable
                       (not (file-directory-p filename))
                       (or (file-elf-p filename)
                           (file-match filename 'Script))
                       (y-or-n-p (message "Execute %s? " (faze filename 'file))))
                  (file-dwim filename)   ;execute it
                (find-file filename))) ;otherwise open it (read-only)
          (dired-get-marked-files nil arg)))

(defun dired-custom-dired-mode-hook ()
  (define-key dired-mode-map [(meta return)] 'dired-marked-files-dwim)
  (define-key dired-mode-map [(meta shift return)] 'dired-operate-on-file)
  )
(add-hook 'dired-mode-hook 'dired-custom-dired-mode-hook)

;; ---------------------------------------------------------------------------

(defvar eval-dwim-history nil "History of evaluated files.")
(add-to-history 'eval-dwim-history nil)

;;; TODO: Integrate with https://github.com/syohex/emacs-quickrun
(defun eval-dwim (&optional arg process-language try-last)
  "Do What I Mean at Point.
If regions is active evaluate it, otherwise if
`symbol-name-at-point' is an existing file evalute it, otherwise
evaluate buffer file."
  (interactive "P")
  ;; (message "FIME: Force english environment!") (sit-for 1)
  (if (and (eq major-mode 'dired-mode)
           (ignore-errors (dired-get-marked-files)) ;TODO: Better way to get number of marked files?
           )
      (dired-marked-files-dwim arg)
    (if (use-region-p)                  ;if mark is active
        (execute-region)                ;execute marked region
      (let* ((buffer-file buffer-file-name)
             (default-file (or (when buffer-file
                                 (file-name-nondirectory buffer-file))
                               (let ((symbol (symbol-name-at-point)))
                                 (when (and symbol
                                            (file-exists-p symbol))
                                   symbol))))
             (last-filename (car eval-dwim-history)))
        (let* ((filename (or (when try-last
                               last-filename)
                             (read-file-name (format "Eval%s: "
                                                     (if default-file (format " (default %s)" default-file) ""))
                                             nil buffer-file t
                                             default-file)))
               (builder (file-op filename :build nil 'name-recog)) ;TODO: Make use of `builder' (normally a string such as "wine").
               (process-environment
                (cons (concat "LANGUAGE=" (or process-language "en")) ;default to english compilation language
                      process-environment))
               )
          (add-to-history 'eval-dwim-history filename)
          (if builder                   ;if builder defined
              (progn
                ;;(save-some-buffers (not compilation-ask-about-save)) ;`compile' does this for us
                (let ((on-success (lambda (filename)
                                    (file-dwim filename 'ask))))
                  (file-build filename on-success try-last))
                )
            (file-dwim filename (if try-last
                                    'try-last
                                  'ask))))))))
(global-set-key [(control c) (e)] 'eval-dwim)
(add-hook 'c-mode-common-hook
          (lambda ()
            (local-set-key [(control c) (control c)] 'eval-dwim)))
(global-set-key [(control return)] 'eval-dwim)
(global-set-key [(f12)] 'eval-dwim)

;; TODO: Activate this and merge interfaces!
;;(add-hook 'sh-mode-hook (lambda () (define-key sh-mode-map "\C-c\C-x" 'eval-dwim)))

(defun reeval-dwim (&optional arg process-language)
  (interactive "P")
  (eval-dwim arg process-language t))
(global-set-key [(control c) (E)] 'reeval-dwim)
(global-set-key [(control f12)] 'reeval-dwim)
(global-set-key [(control shift return)] 'reeval-dwim)

(defun display-main-function-eval-tip (&optional filename)
  "If FILENAME contains a main function hint about how to evaluate FILENAME."
  (interactive)
  (unless filename (setq filename buffer-file-name))
  (when (and filename
             (file-editable-regular-p filename))
    (let* ((pmain (propertize "main" 'face 'font-lock-function-name-face))
           (pfile (propertize (file-name-nondirectory filename) 'face 'font-lock-file-name-face))
           (key-string (symbol-function-keys-string 'eval-dwim))
           (mess (format "Eval %s() in %s using %s"
                         pmain pfile key-string)))
     (cond ((file-c-main-function filename)
            (message mess))
           ((file-go-main-function filename)
            (message mess))
           ((file-haskell-main-function filename)
            (message mess))))))
(add-hook 'find-file-hook 'display-main-function-eval-tip t)
;;(add-hook 'after-save-hook 'display-main-function-eval-tip t)
(remove-hook 'after-save-hook 'display-main-function-eval-tip)

(when nil
  (defadvice find-file (after main-tip (filename &optional wildcards))
    "Use advice instead of hook because we cannot currently detect
all kinds of non-interactive calls to `find-file-hook'."
    (when (called-interactively-p 'any)
      (display-main-function-eval-tip filename)))
  (ad-activate 'find-file))

(add-hook 'c-mode-hook
          (lambda ()
             (define-key c-c-menu [c-execute-buffer]
               `(menu-item "Evaluate (Run) File" eval-dwim :help "Build and Run (Buffer) File")))
          t)

(add-hook 'c++-mode-hook
          (lambda ()
             (define-key c-c++-menu [c++-execute-buffer]
               `(menu-item "Evaluate (Run) File" eval-dwim :help "Build and Run (Buffer) File")))
          t)

(add-hook 'objc-mode-hook
          (lambda ()
             (define-key c-objc-menu [c++-execute-buffer]
               `(menu-item "Evaluate (Run) File" eval-dwim :help "Build and Run (Buffer) File")))
          t)

(define-key menu-bar-file-menu [execute-buffer]
  `(menu-item "Evaluate (Run) File" eval-dwim :help "Build and Run (Buffer) File"))

;; ---------------------------------------------------------------------------

(provide 'file-dwim)
