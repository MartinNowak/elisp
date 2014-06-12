;;; charedit.el --- Insert char Do What I mean (DWIM).
;; Author: Per Nordlöw

;; C-h och F1 Display Mode-Local  Operations When `mark-active-p'.
;;; TODO: Use (recent-keys),
;;; TODO: Use: (command-history), `last-command', `last-command-event', `this-command'.

;;; TODO: for single and double quote inserts:
;;; Check if we are inside a and exit in that case. using `.*-comment-p'. `.*-string-p'.

(require 'power-utils)

(defun char-wrap-region (beg &optional end)
  "Wrap current-region with BEG and END chars.
END defaults to BEG."
  (save-excursion
    (let ((beg-point (region-beginning))
          (end-point (region-end)))
      (goto-char beg-point) (insert-char beg 1)
      (let ((end (or end
                     (cadr (assq beg charedit-pair-alist))
                     beg)))
        (goto-char (1+ end-point))
        (insert-char end 1)))))

(defun string-wrap-region (beg &optional end)
  "Wrap current-region with BEG and END strings.
END defaults to BEG."
  (save-excursion
    (let ((beg-point (region-beginning))
          (end-point (region-end)))
      (goto-char beg-point) (insert beg)
      (goto-char (+ (length beg) end-point)) (insert (or end beg)))))

(defconst charedit-pair-alist
  '(
    (?\{ ?\} brace)
    (?\[ ?\] hook)
    (?\( ?\) paren)
    (?\$ ?\$ dollar)
    (?< ?> angle)
    (?\' ?\' single-quote)
    (?\" ?\" double-quote)
    (?\` ?\' grave-and-quote)
    )
  "Describes how first character should be paired (with second)
  and its symbolic naming.")

(defun quoty-command-activate ()
  "Return non-nil if some other mode handles smart quoting."
  (or (and (fboundp 'electric-pair-mode)
           electric-pair-mode)
      (and (fboundp 'autopair-mode)
           autopair-mode)
      (and (fboundp 'smartparens-mode)
           smartparens-mode)))

(defun charedit-single-quote-region ()
  (interactive)
  (if (quoty-command-activate)
      (self-insert-command 1)
    (if (use-region-p) (char-wrap-region ?\') (self-insert-command 1))))
(defun charedit-matlab-double-quote-region ()
  (interactive)
  (if (use-region-p) (char-wrap-region ?\') (insert ?\' ?\') (backward-char)))
(defun charedit-lisp-single-quote-region ()
  (interactive)
  (if (use-region-p) (char-wrap-region ?\` ?\') (self-insert-command 1)))

(defun charedit-double-quote-region ()
  (interactive)
  (if (quoty-command-activate)
      (self-insert-command 1)
    (if (use-region-p) (char-wrap-region ?\") (self-insert-command 1))))

(defun charedit-org-italic-region ()
  (interactive)
  (if (use-region-p) (char-wrap-region ?\/) (self-insert-command 1)))
(defun charedit-org-boldify-region ()
  (interactive)
  (if (use-region-p) (char-wrap-region ?\*) (self-insert-command 1)))
(defun charedit-org-fixify-region ()
  (interactive)
  (if (use-region-p) (char-wrap-region ?\=) (self-insert-command 1)))

(defun charedit-html-italic-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "<i>" "</i>") (self-insert-command 1)))
(defun charedit-html-boldify-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "<b>" "</b>") (self-insert-command 1)))
(defun charedit-html-fixify-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "<tt>" "</tt>") (self-insert-command 1)))
(defun charedit-html-codify-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "<code>" "</code>") (self-insert-command 1)))
(defun charedit-html-emphasize-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "<em>" "</em>") (self-insert-command 1)))

(defun charedit-tex-italic-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textit{" "}") (self-insert-command 1)))
(defun charedit-tex-bold-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textbf{" "}") (self-insert-command 1)))
(defun charedit-tex-fixed-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\texttt{" "}") (self-insert-command 1)))
(defun charedit-tex-smallcaps-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textsc{" "}") (self-insert-command 1)))
(defun charedit-tex-emphasize-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\emph{" "}") (self-insert-command 1)))
(defun charedit-tex-normal-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textnormal{" "}") (self-insert-command 1)))
(defun charedit-tex-roman-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textrm{" "}") (self-insert-command 1)))
(defun charedit-tex-up-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\textup{" "}") (self-insert-command 1)))
(defun charedit-tex-calligraphic-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "\\mathcal{" "}") (self-insert-command 1)))

(defun charedit-tex-double-quote-region ()
  (interactive)
  (if (use-region-p) (string-wrap-region "``" "''")
    (if (fboundp 'TeX-insert-quote)
        (TeX-insert-quote nil)
      (TeX-insert-quote nil))
    ))

(defun charedit-tex-dot-alt ()
  (interactive)
  (let* ((keys (recent-keys))
         (keys-l (length keys)))
    (if (and (eq (aref keys (- keys-l 1)) ?\.)
             (eq (aref keys (- keys-l 2)) ?\.)
             (eq (aref keys (- keys-l 3)) ?\.)
             )
        (progn
          (undo 2)
          (insert "\\ldots")
          (message "Converted ... to \\ldots"))
      (self-insert-command 1))))
(defun charedit-tex-dot ()
  "Convert ... before point to \\dots."
  (interactive)
  (if (looking-back (rx ?. ?.))
      (progn
        (replace-match "\\\\ldots")
        (message "Converted triple-dot to \\ldots"))
    (self-insert-command 1)))

(defun charedit-enable ()
  "Enables charedit-mode."
  (interactive)
  (when (memq major-mode '(emacs-lisp-mode lisp-interaction-mode scheme-mode
                                           texinfo-mode tex-mode latex-mode LaTeX-mode))
    (local-set-key [?\'] 'charedit-lisp-single-quote-region)
    )

  ;; most modes use double-quotes for strings
  (unless (memq major-mode '(paredit-mode ;paredit already does this for us
                             tex-mode latex-mode LaTeX-mode ;AUCTEX has its own
                             matlab-mode))
    (local-set-key [?\"] 'charedit-double-quote-region)
    )

  (when (memq major-mode '(octave-mode matlab-mode matlab-shell-mode))
    (local-set-key [?\'] 'charedit-single-quote-region)
    (local-set-key [?\"] 'charedit-matlab-double-quote-region) ;Matlab doesn't support double-quotes at all so insert pairs of single quotes instead.
    )

  (when (memq major-mode cc-derived-modes)
    ;; NOTE: Disabled in favor of smartparens
    ;; (local-set-key [?\'] 'charedit-single-quote-region)
    ;; (local-set-key [?\"] 'charedit-double-quote-region)
    )

  (when (memq major-mode '(org-mode))
    (local-set-key [?\/] 'charedit-org-italic-region)
    (local-set-key [?\*] 'charedit-org-boldify-region)
    (local-set-key [?\=] 'charedit-org-fixify-region)

    (local-set-key [?i] 'charedit-org-italic-region)
    (local-set-key [?b] 'charedit-org-boldify-region)
    (local-set-key [?t] 'charedit-org-fixify-region)
    )

  (when (memq major-mode '(html-mode nxml-mode nxhtml-mode))
    (local-set-key [?i] 'charedit-html-italic-region)
    (local-set-key [?b] 'charedit-html-boldify-region)
    (local-set-key [?t] 'charedit-html-fixify-region)
    (local-set-key [?c] 'charedit-html-codify-region)
    (local-set-key [?e] 'charedit-html-emphasize-region)
    )

  (when (memq major-mode '(tex-mode latex-mode LaTeX-mode))
    (local-set-key [?\.] 'charedit-tex-dot)
    (local-set-key [?\"] 'charedit-tex-double-quote-region) ;AUCTEX has its own

    ;; (local-set-key [?\/] 'charedit-tex-italic-region)
    ;; (local-set-key [?\*] 'charedit-tex-bold-region)
    ;; (local-set-key [?\=] 'charedit-tex-fixed-region)

    (local-set-key [?i] 'charedit-tex-italic-region)
    (local-set-key [?b] 'charedit-tex-bold-region)
    (local-set-key [?t] 'charedit-tex-fixed-region)
    (local-set-key [?C] 'charedit-tex-smallcaps-region)
    (local-set-key [?e] 'charedit-tex-emphasize-region)
    (local-set-key [?n] 'charedit-tex-normal-region)
    (local-set-key [?r] 'charedit-tex-roman-region)
    (local-set-key [?u] 'charedit-tex-up-region)
    (local-set-key [?a] 'charedit-tex-calligraphic-region)
    )
  )

(defun charedit-define-key (mode-syms key function &optional syntax)
  "Define KEY as DEF in all KEYMAPS.
If SYNTAX is non-nil call FUNCTION only when KEY is pressed inside that syntax.
SYNTAX is either `string', `comment', `code' or `nil' for all."
  (let ((command `(lambda ()
                    (interactive)
                    (if (and (region-active-p)
                             (or (null ',syntax)
                                 (at-syntax-p ',syntax)))
                        (call-interactively ',function)
                      (self-insert-command 1)))))
    (dolist (sym mode-syms)
      (let ((keymap (intern-soft (concat (symbol-name sym) "-mode-map"))))
        (when keymap
          (define-key (symbol-value keymap) `[(control c) (control j) (,key)] function)
          (define-key (symbol-value keymap) `[,key] command)
          )))))

(defconst charedit-prefix-key [(control j)] "")

(defun charedit-setup-map ()
  (let ((prefix charedit-prefix-key))
    (global-unset-key prefix)
    (define-prefix-command 'charedit-map nil
      "Charedit-"
      ;; (if t
      ;;     "Outline: Hide-[q,t,o,c,l,d], Show-[a,e,i,k,s], Move-[u,n,p,f,b,^,v,<,>,RET]"
      ;;   "Outline:\n  - Hide-[q,t,o,c,l,d]\n  - Show-[a,e,i,k,s]\n  - Move-[u,n,p,f,b,^,v,<,>,RET]")
      )
    (global-set-key prefix charedit-map)
    (unless (keymapp charedit-map) (setq charedit-map (make-sparse-keymap)))
    ))
(charedit-setup-map)

(defun charedit-local-set-key (key function &optional syntax)
  "Define KEY as DEF in all KEYMAPS.
If SYNTAX is non-nil call FUNCTION only when KEY is pressed inside that syntax.
SYNTAX is either `string', `comment', `code' or `nil' for all."
  (let ((command `(lambda ()
                    (interactive)
                    (if (and (region-active-p)
                             (or (null ',syntax)
                                 (at-syntax-p ',syntax)))
                        (call-interactively ',function)
                      (self-insert-command 1)))))
    (local-set-key charedit-prefix-key nil)
    (define-key charedit-map `[(,key)] function) ;C-j KEY
    (local-set-key `[(control c) (control j) (,key)] function) ;C-c C-j KEY
    (local-set-key `[(meta \?) (,key)] function)
    (local-set-key `[(meta \§) (,key)] function)
    (local-set-key `[,key] command)     ;KEY
    ))

(defun charedit-add-hooks ()
  (interactive)
  (charedit-setup-map)
  (add-hook 'c-mode-common-hook 'charedit-enable t)
  ;; (add-hook 'c-mode-hook 'charedit-enable t)
  ;; (add-hook 'c++-mode-hook 'charedit-enable t)
  ;; (add-hook 'd-mode-hook 'charedit-enable t)
  (add-hook 'ada-mode-hook 'charedit-enable t)

  (add-hook 'emacs-lisp-mode-hook 'charedit-enable t)
  (add-hook 'lisp-interaction-mode-hook 'charedit-enable t)
  (add-hook 'scheme-mode-hook 'charedit-enable t)

  (add-hook 'matlab-mode-hook 'charedit-enable t)
  (add-hook 'matlab-shell-mode-hook 'charedit-enable t)
  (add-hook 'octave-mode-hook 'charedit-enable t)
  (add-hook 'org-mode-hook 'charedit-enable t)

  (add-hook 'html-mode-hook 'charedit-enable t)
  (add-hook 'nxml-mode-hook 'charedit-enable t)
  (add-hook 'nxhtml-mode-hook 'charedit-enable t)

  (add-hook 'texinfo-mode-hook 'charedit-enable t)
  (add-hook 'tex-mode-hook 'charedit-enable t)
  (add-hook 'latex-mode-hook 'charedit-enable t)
  (add-hook 'LaTeX-mode-hook 'charedit-enable t))

(require 'cc-patterns)

(defun tune-lexical-whitespace (start end old-len)
  "Tune whitspace between lexical elements."
  ;; Use `c-forward-token-balanced' and `c-backward-token-balanced'.
  ;; Reuse semantic-lex and relex-isearch.el and cc electric.
  ;; (when (eq last-command 'self-insert-command)
  ;;   (message "start:%s end:%s old-len:%s"
  ;;            start end old-len)
  ;;   (when (memq major-mode cc-derived-modes)
  ;;     (cond ((looking-back (rx (: (group (in ?\) ?{ ?}))
  ;;                                 (* space))))
  ;;            (fixup-whitespace))
  ;;           ((looking-back (eval `(rx (: (group (| ,@(c-op-assignment)))
  ;;                                        (* space)))))
  ;;            (save-excursion
  ;;              (goto-char (match-beginning 1))
  ;;              (fixup-whitespace))
  ;;            (insert " ")
  ;;            ))))
  )

(add-hook 'after-change-functions 'tune-lexical-whitespace t)

(provide 'charedit)
