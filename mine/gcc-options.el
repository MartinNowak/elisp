;;; gcc-options.el --- Fetch, Parse and Read GCC Options.

(require 'power-utils)
(require 'multi-read)

(when nil
  (defun gcc-help (&optional exec help-string)
    "Return list of (WARNING-FLAG WARNING-DOC) supported by compiler executable EXEC."
    (let ((gcc (or exec "gcc"))
          (warnings))
      (with-temp-buffer
        (shell-command (concat gcc " --help=" help-string) (current-buffer))
        (goto-char (point-min))
        (while (and (re-search-forward "^[[:space:]]+\\(-[^[:space:]]+\\)[[:space:]]*\\(.*\\)$" nil t)
                    (match-length 1)
                    (match-length 2))
          (setq warnings (cons (cons (match-string-no-properties 1)
                                     (match-string-no-properties 2))
                               warnings))))
      (reverse warnings)))
  (defun gcc-warnings (&optional exec) (gcc-help exec "warnings"))
  (defun gcc-targets (&optional exec) (gcc-help exec "targets"))
  (defun gcc-params (&optional exec) (gcc-help exec "params"))
  (defun gcc-optimizers (&optional exec) (gcc-help exec "optimizers")))
;; Use: (gcc-warnings "gdc")
;; Use: (gcc-targets "gdc")
;; Use: (gcc-params "gdc")
;; Use: (gcc-optimizers "gdc")
;; Use: (gcc-optimizers "gcc")

(defun gcc-cpp-defines ()
  (shell-command-to-string "gcc -dM -E -x c /dev/null"))
;; Use: (gcc-cpp-defines)

(defun gcc-cpp-defines-list ()
  (split-string (gcc-cpp-defines) "\n"))
;; Use: (gcc-cpp-defines-list)

(defun gcc-options (&optional type exec)
  "Get Compiler options of TYPE as list of (OPTION/FLAG . DOC)."
  (let* ((type (if type (capitalize type)
                 "Warnings"))
         (buffer (concat "*GCC " type "*"))
         hits)
    (get-buffer-create buffer)
    (with-current-buffer buffer
      (erase-buffer)
      (call-process-shell-command (or exec "gcc")
                                  nil buffer t (concat "--help=" type))
      (goto-char (point-min))
      (forward-line 1)                  ;skip header
      (while (re-search-forward (concat "^  \\([^[:space:]]*\\)[[:space:]]+")
                                nil t)
        (let ((flag-string (match-string 1))
              (doc-start (point)))
          (let* ((doc-end (if (re-search-forward "^  \\([^[:space:]]\\)" nil t)
                              (progn (beginning-of-line)
                                     (backward-char)
                                     (point))
                            (progn (goto-char (point-max))
                                   (point))))
                 (doc-string (when doc-end
                               (replace-regexp-in-string
                                "\n[[:space:]]+"
                                " "
                                (buffer-substring doc-start doc-end)))))
            (setq hits (cons (cons
                              flag-string
                              (when (not (string-equal doc-string
                                                       "This switch lacks documentation"))
                                doc-string))
                             hits)))
          ))
      (reverse hits))))
;; Use: (gcc-options "Warnings" "gcc")
;; Use: (gcc-options "Optimizers")
;; Use: (gcc-options "Target")
;; Use: (gcc-options "Params")

(defun icicle-find-gcc-option-help (cand)
  "Get help (documentation) for GCC Option candidate CAND."
  (let ((entry (if (boundp 'gcc-option-candidates)
                   (assoc cand gcc-option-candidates)
                 cand)))
    (message (cond ((stringp entry)
                    entry)
                   ((consp entry)
                    (if (cdr entry)
                        (concat (faze (car entry) 'var)
                                ": "
                                (faze (cdr entry) 'doc))
                      (car entry))))))
  (sit-for 4))

(defun read-gcc-options (&optional type exec)
  (let* ((options (gcc-options type exec))
         (icicle-candidate-help-fn 'icicle-find-gcc-option-help)
         (gcc-option-candidates options))
    (completing-read (concat "GCC " type ": ") options)))
;;; Use: (read-gcc-options "Warnings")
;;; Use: (read-gcc-options "Warnings" "gcc-4.6")
;;; Use: (read-gcc-options "Warnings" "gcc-4.7")
;;; Use: (read-gcc-options "Target")
;;; Use: (read-gcc-options "Params")
;;; Use: (read-gcc-options "Optimizers")
;;; Use: (read-gcc-options "Optimizers" "gcc-4.3")

(provide 'gcc-options)
