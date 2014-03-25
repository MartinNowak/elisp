;; kmacro-ext.el --- Extensions to `kmacro'.

(defun kmacro-end-or-call-macro-dwim (arg)
  "Like `kmacro-end-or-call-macro' but in all region lines if
region is active."
  (interactive "p")
  (if (use-region-p)
      (progn
        (when defining-kbd-macro
          (kmacro-end-macro nil))
        (apply-macro-to-region-lines (region-beginning)
                                     (region-end)))
    (cond (defining-kbd-macro
            (kmacro-end-macro arg)
            )
          (last-kbd-macro
           (kmacro-call-macro arg))
          (t
           (ding)
           (let ((m (symbol-function-keys-string
                     'kmacro-start-macro-or-insert-counter)))
             (message "No keyboard macro defined yet. Press %s to initiate one"
                      (if (listp m)
                          (if (== 1 (length m))
                              (car m)
                            m)
                        m))))
          (sit-for 2))))
(when (eload 'repeatable)
  (repeatable-command-advice kmacro-end-or-call-macro-dwim))
(global-set-key [(f4)] 'kmacro-end-or-call-macro-dwim)
(global-set-key [(control x) (e)] 'kmacro-call-macro)

;;; see: http://thbecker.net/free_software_utilities/emacs_lisp/emacros/start_page.html
(when (require 'emacros nil t)
  (defadvice kmacro-end-macro (after name-and-save protect activate compile)
    (emacros-name-last-kbd-macro-add))
  (ad-activate 'kmacro-end-macro)
  (global-set-key [(shift f3)] 'emacros-name-last-kbd-macro-add)
  (global-set-key [(shift f4)] 'emacros-execute-named-macro)
  )

;; See: http://www.emacswiki.org/emacs/KeyboardMacros
(defun smart-macro-query (arg)
  "Prompt for input using minibuffer during kbd macro execution.
    With prefix argument, allows you to select what prompt string to use.
    If the input is non-empty, it is inserted at point."
  (interactive "P")
  (let* ((prompt (if arg (read-from-minibuffer "PROMPT: ") "Input: "))
         (input (minibuffer-with-setup-hook (lambda () (kbd-macro-query t))
                  (read-from-minibuffer prompt))))
    (unless (string= "" input) (insert input)))
  ;; (let* ((query (lambda () (kbd-macro-query t)))
  ;;        (prompt (if arg (read-from-minibuffer "PROMPT: ") "Input: "))
  ;;        (input (unwind-protect
  ;;                   (progn
  ;;                     (add-hook 'minibuffer-setup-hook query)
  ;;                     (read-from-minibuffer prompt))
  ;;                 (remove-hook 'minibuffer-setup-hook query))))
  ;;   (unless (string= "" input) (insert input)))
  )
(global-set-key "\C-xQ" 'smart-macro-query)

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/3486ff19d20200e9#
;; As for making atomic changes to many buffers, this is documented by the
;; `prepare-change-group' function.  I suppose you would need to `prepare'
;; all buffers, because a macro can do about anything to any buffer.
(defun kmacro-call-macro-atomic (arg)
  "Call last keyboard macro.
If an error during execution ask user to revert any changes that
occurred."
  (interactive "P")
  ;; TODO: Warning: This fucks things up!
  ;; (when (and (consp buffer-undo-list)
  ;;            (null (car buffer-undo-list)))
  ;;   (pop buffer-undo-list))
  (atomic-change-group                  ;todo: Query the user if any error occurred.
    (kmacro-call-macro arg)))

(provide 'kmacro-ext)
