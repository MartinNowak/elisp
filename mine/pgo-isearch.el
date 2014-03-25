;;; pgo-isearch.el --- Set Incremental Search (isearch)
;; Author: Per Nordlöw

(require 'lex-utils)

;; We always have arrows so if we want Ctrl-F as Windows Style Search Shortcut
;;(global-set-key [(control f)] 'isearch-forward)

;; Note: Emacs 23.1 now has a light version of this logic as default.
(defcustom pnw/use-minibuf-isearch t
  "Flags whether or not to load minibuf-isearch upon startup." :type 'boolean :group 'pnw-options)

;; minibuf-isearch.el - Minibuffer Incremental Search
;; See: http://www.sodan.org/~knagano/emacs/minibuf-isearch/
(if pnw/use-minibuf-isearch
    (when (require 'minibuf-isearch nil t)
      ))

;; lazy-search.el --- Lazy Search
(when (require 'lazy-search nil t)
  ;;(global-set-key [(control shift s)] 'lazy-search-menu)
  )

(global-set-key [(control shift s)] 'multi-isearch-buffers)
(global-set-key [(control shift meta s)] 'multi-isearch-buffers-regexp)

;; ----------------------------------------------------------------------------
;; Extension to isearch mode

(defun isearch-yank-regexp (regexp)
  "Pull REGEXP into search regexp."
  (let ((isearch-regexp nil)) ;; Temporary (Dynamic) Bind regexp state to preserve state of original global variable.
    (isearch-yank-string regexp))
  (if (not isearch-regexp)
      (isearch-toggle-regexp)))
(defun isearch-yank-symbol ()
  "Put symbol at current point into search string."
  (interactive)
  (let ((sym (find-tag-default)))
    (if (null sym)
        (message "No symbol at point")
      (isearch-yank-regexp
       (concat "\\_<" (regexp-quote sym) "\\_>")))))
(define-key isearch-mode-map "\C-\M-w" 'isearch-yank-symbol)

;; ----------------------------------------------------------------------

(defun isearch-beginning-of-buffer ()
  "Move isearch point to the beginning of the buffer."
  (interactive)
  (goto-char (point-min))
  (isearch-repeat-forward))
(defun isearch-end-of-buffer ()
  "Move isearch point to the end of the buffer."
  (interactive)
  (goto-char (point-max))
  (isearch-repeat-backward))
(define-key isearch-mode-map "\M-<" 'isearch-beginning-of-buffer)
(define-key isearch-mode-map "\M->" 'isearch-end-of-buffer)

(define-key isearch-mode-map             "\t" 'isearch-complete)
(define-key minibuffer-local-isearch-map "\t" 'isearch-complete-edit)

(add-hook 'isearch-mode-end-hook
          (lambda ()
            ;; On typing C-RET
            (when (eq last-input-event 'C-return)
              ;; Set the point at the beginning of the search string
              (if (and isearch-forward isearch-other-end)
                  (goto-char isearch-other-end))
              ;; Don't push the search string into the search ring
              (if isearch-regexp
                  (setq regexp-search-ring (cdr regexp-search-ring))
                (setq search-ring (cdr search-ring))))))
(define-key isearch-mode-map [(control return)] 'isearch-exit)

;; From: http://blog.zenspider.com/archives/2007/02/new_category_emacs.html
;; This adds an extra keybinding to interactive search (C-s) that
;; runs occur on the current search string/regexp, immediately
;; showing all hits in the entire buffer. I use it all the time
;; now.
(define-key isearch-mode-map (kbd "C-o")
  (lambda ()
    (interactive)
    (let ((case-fold-search isearch-case-fold-search))
      (occur (if isearch-regexp isearch-string
               (regexp-quote isearch-string))))))


(provide 'pgo-isearch)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-isearch.el ends here
