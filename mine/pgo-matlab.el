;;; pgo-matlab.el --- Setup Matlab IDE Integration.
;; Author: Per Nordlöw
;; See: http://blogs.mathworks.com/desktop/2009/09/14/matlab-emacs-integration-is-back/

(setq matlab-shell-running-matlab-release (or "R2012a"
                                              (when (string-match "MATLAB/\\(.*\\)-"
                                                                  (executable-find "matlab"))
                                                (match-string 1))))

(defcustom matlab-root-directory (or (getenv "MATLAB_ROOT")
                                     (expand-file-name (concat "~/MATLAB/"
                                                               matlab-shell-running-matlab-release)))
  "Root directory for MATLAB installation."
  :group 'matlab)

(let ((root matlab-root-directory))
  (setq mlint-program (expand-file-name "bin/glnxa64/mlint" root))
  (add-to-list 'exec-path (concat root "/bin"))
  (add-to-list 'exec-path (concat root "/bin/glnxa64"))
  (setenv "PATH" (concat root "/bin:"
                         root "/bin/glnxa64:"
                         (getenv "PATH"))))

(load-file-if-exist (elsub "matlab/matlab-load.el"))

;;; Override
(setq matlab-shell-input-ring-size 200
      matlab-shell-command-switches '("-nodesktop -nosplash"))

(defun matlab-comment-dwim (arg)
  "MATLAB Comment Do What I Mean (DWIM)."
  (interactive "*P")
  (if (use-region-p)
      ;; TODO: if whole region begins with whitespace plus comment
      ;; character uncomment-region
      (comment-dwim arg)
    (matlab-comment))
  )

(defun matlab-mark-sexp (&optional arg allow-extend trim)
  "Matlab specific `mark-sexp'.
If TRIM is non-nil mark end is not extended to a complete line."
  (interactive "P\np")
  (cond ((and allow-extend
              (or (and (eq last-command this-command) (mark t))
                  (use-region-p)))
         (setq arg (if arg (prefix-numeric-value arg)
                     (if (< (mark) (point)) -1 1)))
         (set-mark
          (save-excursion
            (goto-char (mark))
            (matlab-forward-sexp arg)
            (unless trim
              (when (and (looking-back "end[[:space:]]*")
                         (looking-at "[[:space:]]*\n"))
                (move-end-of-line nil) (forward-char)))
            (point))))
        (t
         (push-mark
          (save-excursion
            (matlab-forward-sexp (prefix-numeric-value arg))
            (unless trim
              (when (and (looking-back "end[[:space:]]*")
                         (looking-at "[[:space:]]*\n"))
                (move-end-of-line nil) (forward-char)))
            (point))
          nil t))))

(defun pnw/matlab-mode-hook ()
  ;; Work MATLAB
  (dolist (dir '("~/Work/MATLAB/"))
    (when (file-directory-p dir)
      (add-to-list 'matlab-mode-install-path dir)))
  (setq fill-column 79                  ;where auto-fill should wrap
        matlab-auto-fill nil
        matlab-return-add-semicolon nil
        matlab-shell-command "matlab"
        ;;matlab-indent-function t
        matlab-show-mlint-warnings t
        ;; mlint-programs `(,(expand-file-name "bin/glnxa64/mlint" matlab-root-directory)
        ;;                  ,(expand-file-name "bin/glnx86/mlint" matlab-root-directory))
        mlint-programs `(,(expand-file-name "bin/glnxa64/mlint" matlab-root-directory))
        matlab-highlight-cross-function-variables t)
  (let ((km matlab-mode-map))
    (define-key km [(control ?c) (control ?x)] 'matlab-shell-save-and-go)
    (define-key km [(meta ?\()] 'c-insert-parens)
    (define-key km [(meta control ?\ )] 'matlab-mark-sexp)
    (define-key km [(control ?h) (?f)] 'matlab-shell-describe-command)
    (define-key km [(control ?h) (?v)] 'matlab-shell-describe-variable)
    (define-key km [(control ?h) (?a)] 'matlab-shell-apropos)
    (define-key km [(meta \;)] 'matlab-comment-dwim)
    (define-key km [(control meta ?:)] 'matlab-eval-expression)
    (define-key km [(meta \;)] 'matlab-comment-dwim)
    )

  ;;  (turn-on-auto-fill)
  )

;; Matlab Addons
(when (require 'matlab nil t)

  ;; MATLAB-Specific Expression Evaluation
  (defun matlab-eval-expression (arg)
    "Evaluate MATLAB Expression ARG and print value in the echo area."
    (interactive (list
                  (let ((def (when (region-active-p)
                               (string-strip (buffer-substring (region-beginning)
                                                               (region-end))))))
                    (read-string (format "MATLAB Eval%s: "
                                         (if def (format " (default %s)" (faze def 'string)) ""))
                                 nil
                                 'matlab-eval-expression-history
                                 def))))
    (message (replace-regexp-in-string
              ;; strip ending whitespace and prompt
              (concat "[[:space:]\n]*"
                      ">>"
                      "[[:space:]\n]*"
                      "\\'"
                      )
              "" (matlab-shell-collect-command-output arg))))
  (defvar matlab-eval-expression-history nil "MATLAB Expression Evaluation History.")

  (when (require 'desktop nil t)
    (add-to-list 'desktop-globals-to-save 'matlab-eval-expression-history t))
  (define-key matlab-mode-map [(meta ?:)] 'matlab-eval-expression)

  (defun matlab-shell-mode-extras-hook ()
    (let ((km matlab-shell-mode-map))
      (define-key km [(meta ?\()] 'c-insert-parens)
      (define-key km [(meta control ?\ )] 'matlab-mark-sexp)
      (define-key km [(control ?h) (?f)] 'matlab-shell-describe-command)
      (define-key km [(control ?h) (?v)] 'matlab-shell-describe-variable)
      (define-key km [(control ?h) (?a)] 'matlab-shell-apropos)
      (define-key km [(control meta ?:)] 'matlab-eval-expression)
      (define-key km [(meta ?:)] 'matlab-eval-expression)
      )
    )
  (add-hook 'matlab-shell-mode-hook
            'matlab-shell-mode-extras-hook)

  ;; Debug Behaviour
  ;;(add-hook 'matlab-shell-mode-hook 'matlab-shell-dbclear-error)
  (add-hook 'matlab-shell-mode-hook 'matlab-shell-dbstop-error)
  (defalias 'run-matlab 'matlab-shell)
  (global-set-key [(control c) (M)] 'matlab-shell)

  (when (require 'hictx nil t)
    (defadvice matlab-beginning-of-defun (after matlab-beginning-of-defun-ctx-flash activate) (when (called-interactively-p 'any) (hictx-defun-afpt))) (ad-activate 'matlab-beginning-of-defun)
    (defadvice matlab-end-of-defun (after matlab-end-of-defun-ctx-flash activate) (when (called-interactively-p 'any) (hictx-defun-bfpt))) (ad-activate 'matlab-end-of-defun)
    (defadvice matlab-forward-sexp (after matlab-forward-sexp-ctx-flash activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt))) (ad-activate 'matlab-forward-sexp)
    (defadvice matlab-backward-sexp (after matlab-backward-sexp-ctx-flash activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'matlab-backward-sexp)
    (defadvice matlab-forward-sexp-safe (after matlab-forward-sexp-safe-ctx-flash activate) (when (called-interactively-p 'any) (hictx-sexp-bfpt))) (ad-activate 'matlab-forward-sexp)
    (defadvice matlab-backward-sexp-safe (after matlab-backward-sexp-safe-ctx-flash activate) (when (called-interactively-p 'any) (hictx-sexp-afpt))) (ad-activate 'matlab-backward-sexp)
    (defadvice matlab-find-other-window-file-line-column (after matlab-find-other-window-file-line-column-ctx-flash activate) (hictx-line)) (ad-activate 'matlab-find-other-window-file-line-column)
    )

  ;; MLint
  (when (require 'mlint nil t)
    (add-hook 'matlab-mode-hook 'mlint-minor-mode t)

    ;; easier keys. TODO: Perhaps use M-g n/p as well?
    (let ((map mlint-minor-mode-map))
      (define-key map [(control meta ?,) (n)] 'mlint-next-buffer)
      (define-key map [(control meta ?,) (p)] 'mlint-prev-buffer)
      (define-key map [(control meta ?,) (N)] 'mlint-next-buffer-new)
      (define-key map [(control meta ?,) (P)] 'mlint-prev-buffer-new)
      (define-key map [(control meta ?,) (g)] 'mlint-buffer)
      (define-key map [(control meta ?,) (c)] 'mlint-clear-warnings)
      (define-key map [(control meta ?,) (?\ )] 'mlint-show-warning)
      (define-key map [(control meta ?,) (f)] 'mlint-fix-warning)
      (define-key map [(control meta ?,) (o)] 'mlint-mark-ok)

      (define-key map [(control meta ?,) (control meta n)] 'mlint-next-buffer)
      (define-key map [(control meta ?,) (control meta p)] 'mlint-prev-buffer)
      (define-key map [(control meta ?,) (control meta N)] 'mlint-next-buffer-new)
      (define-key map [(control meta ?,) (control meta P)] 'mlint-prev-buffer-new)
      (define-key map [(control meta ?,) (control meta g)] 'mlint-buffer)
      (define-key map [(control meta ?,) (control meta c)] 'mlint-clear-warnings)
      (define-key map [(control meta ?,) (control meta ?\ )] 'mlint-show-warning)
      (define-key map [(control meta ?,) (control meta f)] 'mlint-fix-warning)
      (define-key map [(control meta ?,) (control meta o)] 'mlint-mark-ok)
      )

    (when (require 'hictx nil t)
      (defadvice mlint-prev-buffer (after mlint-prev-buffer-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'mlint-prev-buffer)
      (defadvice mlint-next-buffer (after mlint-next-buffer-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'mlint-next-buffer)
      (defadvice mlint-prev-buffer-new (after mlint-prev-buffer-new-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'mlint-prev-buffer-new)
      (defadvice mlint-next-buffer-new (after mlint-next-buffer-new-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'mlint-next-buffer-new)
      )

    (when (and (require 'repeatable nil t)
               (load-file-if-exist (elsub "cedet/eieio/linemark.elc")))
      (repeatable-command-advice mlint-next-buffer)
      (repeatable-command-advice mlint-prev-buffer)
      (repeatable-command-advice mlint-next-buffer-new)
      (repeatable-command-advice mlint-prev-buffer-new)
      ))

  (defun matlab-eval-expression (eval-expression-arg &optional eval-expression-insert-value)
    "Evaluate MATLAB Expression."
    (interactive)
    )


  (autoload 'matlab-mode "matlab" "Matlab Editing Mode" t)
  (autoload 'matlab-shell "matlab" "Interactive Matlab mode." t)

  (add-hook 'matlab-mode-hook 'pnw/matlab-mode-hook)


  (add-to-list 'auto-mode-alist '(".*[mM]atlab.*/.*\\.m\\'" . matlab-mode))
  (add-to-list 'auto-mode-alist '("\\.m$" . matlab-mode))

  ;; Semantic Matlab
  (when nil
    (when (require 'semantic nil t)
      (when (require 'semantic-matlab nil t)
        (when (require 'semanticdb-matlab nil t)
          ))))
  (when (and (boundp 'semantic-mode)
             (require 'srecode nil t))
    (ignore-errors
     (matlab-cedet-setup)))

  )
(load-file-if-exist (elsub "ska-skel-matlab.el"))

(provide 'pgo-matlab)
