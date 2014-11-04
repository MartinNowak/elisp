;;; relex-isearch.el --- Relax Lexical Whitespace in I-Search String.
;; Author: Per Nordlöw
;; TODO Error during redisplay: (eval (replace-regexp-in-string "%" "%%" (gethash (selected-window) which-func-table which-func-unknown))) signalled (wrong-type-argument arrayp nil) [8 times]
;; TODO Merge with flex-isearch.el

(require 'relex)

(defgroup relex-isearch nil
  "Relax Lexical Whitespace in I-Search."
  :group 'tools)

(defun isearch-with-predicate-search-fn (predicate string &optional bound no-error)
  (let* (isearch-search-fun-function
         (search-fun  (isearch-search-fun))
         found
         limit)
    (save-excursion
      (while (and (setq found
                        (funcall search-fun string bound no-error))
                  (not (setq found
                             (and (save-match-data
                                    (funcall predicate)) found)))))
      (setq limit (point)))
    (if found
        (goto-char found)
      (unless (eq no-error t)
        (goto-char limit)
        nil))))

(defun isearch-with-predicate (predicate indicator &optional backward regexp)
  (let ((isearch-search-fun-function
         (lambda nil
             (lambda (string &optional bound no-error)
                 (isearch-with-predicate-search-fn
                  predicate string bound no-error))))
        (isearch-message-prefix-add indicator))
    (isearch-mode (not backward) regexp nil t)))

(defvar isearch-sctx nil
  "I-Search Syntax Context.")

(defvar isearch-sctxs-list
  '((all "All")
    (code "Code")
    (code-&-comment "Code/Comment")
    (code-&-string "Code/String")
    )
  "I-Search Syntax Contexts.")

(defun isearch-skip-strings (&optional backward regexp)
  (interactive)
  (isearch-with-predicate (lambda nil (not (nth 3 (syntax-ppss))))
                          "Code/Comment "
                          backward regexp))
;; Use: (isearch-skip-strings)

(defun isearch-skip-comments (&optional backward regexp)
  (interactive)
  (isearch-with-predicate (lambda nil (not (nth 4 (syntax-ppss))))
                          "Code/String "
                          backward regexp))
;; Use: (isearch-skip-comments)

(defun isearch-skip-strings-and-comments (&optional backward regexp)
  (interactive)
  (isearch-with-predicate (lambda nil (not (or (nth 3 (syntax-ppss))
                                                 (nth 4 (syntax-ppss)))))
                          "Code "
                          backward regexp))
;; Use: (isearch-skip-strings-and-comments)

(defun isearch-cycle-sctx ()
  "Cycle between different search syntax contexts."
  (interactive)
  (cond ((not isearch-sctx)
         (setq isearch-sctx 1))
        ((numberp isearch-sctx)
         (setq isearch-sctx (1+ isearch-sctx))
         (when (eql 3 isearch-sctx)
           (setq isearch-sctx 0)))
        (t
         (error "Unknown format of `isearch-sctx'!")))
  (sit-for 1)
  (isearch-update)
  )

(define-key isearch-mode-map "\M-s" 'isearch-cycle-sctx)

(add-hook 'isearch-mode-end-hook
          (lambda () (setq isearch-sctx nil))) ;clear state when isearch ends

;; ---------------------------------------------------------------------------

(defvar isearch-rlws nil
  "Relax Lexical Whitespace in I-Search String State.")

(defcustom isearch-rlws-default t
  "Relax Lexical Whitespace in I-Search Default String State."
  :group 'relex-isearch)

(defun isearch-toggle-rlws ()
  "Toggle Relaxed Lexical WhiteSpace searching on or off."
  (interactive)
  (setq isearch-rlws (not isearch-rlws))
  (if isearch-rlws (setq isearch-regexp nil)) ;Note: We can't yet combine rlws with regexps
  ;;(if isearch-regexp (setq isearch-word nil)) ;TODO Surround rlws expr with word boundaries
  (setq isearch-success t
        isearch-adjusted t)
  (let ((message-log-max nil))
    (message "%s%s [lexical-whitespace %srelaxed]"
             (isearch-message-prefix nil nil isearch-nonincremental)
             isearch-message
             (if isearch-rlws "" "un")))
  (setq isearch-success t
        isearch-adjusted t)
  (sit-for 1)
  (isearch-update))
(define-key isearch-mode-map "\M-l" 'isearch-toggle-rlws)

;; NOTE: Uses `isearch-mode-end-hook' instead!
(when nil
  ;; clear state when isearch ends
  (defadvice isearch-done (after relax-lws-advice activate) (setq isearch-rlws nil)) (ad-activate 'isearch-done)
  )

(defun relex-isearch-mode-hook ()
  (when isearch-rlws-default
    (when (not (eq (mode-lexer major-mode)
                   'semantic-lex))
      (isearch-toggle-rlws))))
(defun relex-isearch-mode-end-hook ()
  "Clear state when isearch ends."
  (setq isearch-rlws nil))

(defun rlws-isearch-search-fun ()
  "Wrapper for isearch-search-fun that does lexical whitespace
relaxed search if enabled otherwise default to normal
isearch-search-fun."
  (if isearch-rlws
      (if (or isearch-nonincremental
              (eq (length isearch-string)
                  (length (isearch-string-state (car isearch-cmds)))))
          (if isearch-forward 'rlws-search-forward 'rlws-search-backward)
        (if isearch-forward 'rlws-search-forward 'rlws-search-backward))
    (let (isearch-search-fun-function) ;temporarily override global isearch-search-fun-function value
      (isearch-search-fun))))

(defvar relex-isearch-original-search-fun nil
  "Saves the original value of `isearch-search-fun-function' when
  `relex-isearch-mode' is enabled.")

;;;###autoload
(define-minor-mode relex-isearch-mode
  "Relax Lexical Whitespace in I-Search String."
  :init-value nil
  :group 'relex-isearch
  :global nil
  (if relex-isearch-mode
      (progn
        (setq relex-isearch-original-search-fun isearch-search-fun-function)
        (setq isearch-search-fun-function 'rlws-isearch-search-fun) ;Warning: Override Emacs'es isearch-search-fun!
        (add-hook 'isearch-mode-hook 'relex-isearch-mode-hook t)
        (add-hook 'isearch-mode-end-hook 'relex-isearch-mode-end-hook)
	(if (ad-is-advised 'isearch-toggle-regexp)
	    (ad-activate 'isearch-toggle-regexp))
        )
    (setq isearch-search-fun-function relex-isearch-original-search-fun)
    (remove-hook 'isearch-mode-hook 'relex-isearch-mode-hook)
    (remove-hook 'isearch-mode-end-hook 'relex-isearch-mode-end-hook)
    (if (ad-is-advised 'isearch-toggle-regexp)
	(ad-activate 'isearch-toggle-regexp))
    ))

;;;###autoload
(defun turn-on-relex-isearch ()
  (interactive)
  (relex-isearch-mode 1))

;;;###autoload
(defun turn-off-relex-isearch ()
  (interactive)
  (relex-isearch-mode 0))

;;;###autoload
(define-global-minor-mode global-relex-isearch-mode
  relex-isearch-mode
  turn-on-relex-isearch)

(defvar isearch-rlws-cache nil "Isearch whitespace relex cached.")

(defun rlws-update-search-string (string &optional mode multi-line)
  "Update isearch-string whitespace-relexing cache."
  (unless (string-equal string (car isearch-rlws-cache))
    (setq isearch-rlws-cache
          (cons string (relax-lexical-whitespace-in-string string (or mode major-mode) multi-line)))
    ))
;; Use: (rlws-update-search-string "int" 'c-mode t)

;;;###autoload
(defun rlws-search-forward (string &optional bound noerror count)
  "Search forward lexically whitespace relaxed."
  (rlws-update-search-string string major-mode t)
  (re-search-forward (concat (when isearch-word "\\<")
                             (cdr isearch-rlws-cache) ;use the cached relaxed string
                             (when isearch-word "\\>"))
                     bound noerror count))
;;;###autoload
(defun rlws-search-backward (string &optional bound noerror count)
  "Search backward lexically whitespace relaxed."
  (rlws-update-search-string string major-mode t)
  (re-search-backward (concat (when isearch-word "\\<")
                              (cdr isearch-rlws-cache) ;use the cached relaxed string
                              (when isearch-word "\\>"))
                      bound noerror count))

(provide 'relex-isearch)
