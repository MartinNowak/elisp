;;; indent-dwim.el --- Indent Do What I Mean (DWIM).

(defvar indent-dwim-repeats 0
  "Repeat counter for `indent-dwim'.")

;;; Support 'c-tab-indent-or-complete if bound.
(defun local-adaptive-indent-line (&optional arg region)
  (cond ((cc-derived-mode-p)
         (c-indent-line-or-region arg region))
        ((and (eq major-mode 'python-mode)
              (fboundp 'py-indent-line))
         (py-indent-line))
        (t
         (indent-for-tab-command (if (eq major-mode 'python-mode)
                                     nil
                                   arg)))))

(defun indent-dwim (&optional arg)
  "Indent Do What I Mean (DWIM).
Indent buffer or region (if mark is active)."
  (interactive "P")
  (setq indent-dwim-repeats (if (eq last-command
                                    this-command)
                                (1+ indent-dwim-repeats)
                              0))
  (let ((keycomb (faze last-command-event 'keycomb)))
    (cond ((memq major-mode '(haskell-mode python-mode)) ;indentation-based syntaxes
           (local-adaptive-indent-line arg) ;must not be overridden
           )
          ((use-region-p)               ;mark is active
           (indent-region (region-beginning)
                          (region-end))
           (message "Region indented"))
          ((>= indent-dwim-repeats 3)
           (message "Nothing more to indent"))
          ((= indent-dwim-repeats 2)
           (indent-region (point-min)
                          (point-max))
           (message "Buffer indented")
           (hictx-buffer))
          ((= indent-dwim-repeats 1)
           (let ((bounds (bounds-of-thing-nearest-point 'defun))
                 ;; (bounds (bounds-of-defun-atpt))
                 ;; (bounds (if (list-of-numbers-p bounds)
                 ;;             (cons (car bounds)
                 ;;                   (cadr bounds))
                 ;;           (bounds-of-thing-nearest-point 'defun)))
                 )
             (if bounds
                 (progn
                   (if paredit-mode
                       (paredit-reindent-defun)
                     (indent-region (car bounds)
                                    (cdr bounds)))
                   (message "Function indented. Press %s to indent buffer" keycomb)
                   (hictx-generic (car bounds) (cdr bounds)))
               (message "Could not find function nearest point!"))))
          (t
           (local-adaptive-indent-line)
           (re-search-forward "[[:blank:]]*")
           (message "Line indented. Press %s to indent function" keycomb)
           )
          )))
(global-set-key [(control ?i)] 'indent-dwim)
(global-set-key [(control ?c) (?i)] 'indent-dwim)
(global-set-key [(control meta ?\\)] 'indent-dwim)

(add-hook 'c-mode-common-hook
          (lambda ()
            (local-set-key [(control ?i)] 'indent-dwim)
            ) t)
(add-hook 'python-mode-common-hook
          (lambda ()
            (local-set-key [(control ?i)] 'indent-dwim) ;override `py-indent-line'
            ) t)

(provide 'indent-dwim)
