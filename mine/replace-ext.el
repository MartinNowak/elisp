;;; replace-ext.el --- Extensions to query-replace.
;; Author: Per Nordlöw

(require 'power-utils)
(require 'obarray-utils)
(require 'regexpl)

;; ---------------------------------------------------------------------------

(defsubst build-symbol-regexp (id)
  "Matches an ID as single word symbol (or C identifier). This
mainly mean that it does not allow underscores directly before or
after the match."
  (concat "\\_<" id "\\_>"))

;; In Emacs-Lisp mode minus-sign is not allowed before or after.
;;;###autoload
(defun replace-symbol (&optional source dest start end prompt regexp-flag query history case-fold-replace)
  "Rename a symbol (currently C-style) string symbol (identifier)
 which unique name is determined by SOURCE replacing it with
 DEST."
  (interactive)
  (unless (and source
               dest)
    (let ((common (query-replace-read-args
                   (concat (or prompt
                               (concat "Query replace symbol (case-sensitive)" (when regexp-flag " regexp")))
                           (if (use-region-p) " in region" ""))
                   nil)))
      (setq source (nth 0 common)
            dest (nth 1 common))
      (when (use-region-p)              ;if active region
        (setq start (region-beginning)) ;override
        (setq end (region-end))))       ;override
    )
  (let* ((patt (build-symbol-regexp (if regexp-flag
                                        source ;regexp as is
                                      (regexp-quote source))))
         (case-fold-search case-fold-replace))
    (if query
        (query-replace-regexp patt
                              (concat dest) nil start end)
      (replace-regexp patt
                      (concat dest) nil start end))))

(defun query-replace-symbol (&optional source dest start end prompt regexp-flag history case-fold-replace)
  "See `replace-symbol'."
  (interactive)
  (replace-symbol source dest start end prompt regexp-flag t history case-fold-replace))

;; In Emacs-Lisp mode minus-sign is not allowed before or after.
;;;###autoload
(defun query-replace-symbol-regexp (&optional source dest start end prompt history case-fold-replace)
  "Rename a symbol (currently C-style) regexp which unique name
 is determined by SOURCE replacing it with DEST."
  (interactive)
  (let ((case-fold-search nil))
    (query-replace-symbol source dest start end prompt t history case-fold-replace)))

(global-set-key [(control meta \%)] 'query-replace-regexp)
(global-set-key [(meta \&)]       'query-replace-symbol)
(global-set-key [(control meta \&)] 'query-replace-symbol-regexp)

(define-key-after menu-bar-replace-menu [query-replace-symbol]
  '(menu-item "Replace Symbol String..." query-replace-symbol
              :help "Replace Symbol string interactively, ask about each occurrence")
  'query-replace-regexp)

(define-key-after menu-bar-replace-menu [query-replace-symbol-regexp]
  '(menu-item "Replace Symbol Regexp..." query-replace-symbol-regexp
              :help "Replace Symbol regexp interactively, ask about each occurrence")
  'query-replace-symbol)

;; ---------------------------------------------------------------------------

;;; TODO Integrate `query-replace-from-region'.
;;; TODO Integrate `query-replace-regexp-from-region'.
;;; using (eload 'replace-from-region)
(defun query-replace-dwim ()
  "Call the query replace command you want (Do What I Mean)."
  (interactive)
  (let ((sym (symbol-at-point)))
    (if (use-region-p)
        (if (and sym
                 (eq (region-beginning)
                     (beginning-of-symbol-next-to-point))
                 (eq (region-end)
                     (end-of-symbol-next-to-point)))
            (call-interactively 'query-replace-symbol)
          (call-interactively 'query-replace)
          )
      (call-interactively 'query-replace) ;revert to default
      )))
(global-set-key [(meta ?\%)] 'query-replace-dwim)

;; ---------------------------------------------------------------------------

;; (define-key query-replace-map "\M-e" 'query-replace-edit-string)
;; (define-key query-replace-map "\M-r" 'query-replace-toggle-regexp)

(defun query-replace-toggle-case-fold ()
  (interactive)
  (if case-replace
      (setq case-replace nil)
    (setq case-replace t)
    ))
;; (define-key query-replace-map [(meta c)] 'query-replace-toggle-case-fold)

(provide 'replace-ext)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; replace-ext.el ends here
