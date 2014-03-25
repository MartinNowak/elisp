;;; pgo-completion-ui.el --- Setup Completion UI.
;; Author: Per Nordlöw

;;; completion-ui.el --- in-buffer completion user interface
;;; See: http://www.emacswiki.org/cgi-bin/wiki/CompletionUI

(when (require 'completion-ui nil t)

  (when (require 'dabbrev nil t)
    (defun dabbrev--wrapper (prefix maxnum)
      "Wrapper around `dabbrev--find-all-completions'
  to pass to `completion-define-minor-mode'."
      (dabbrev--reset-global-variables)
      (let ((completions (dabbrev--find-all-expansions prefix nil)))
        (when maxnum
          (setq completions
                (butlast completions (- (length completions) maxnum))))
        (mapcar (lambda (word) (substring word (length prefix)))
                completions)))
    ;; (setq completion-function 'dabbrev--wrapper)
    )
  ;; Use: (dabbrev--wrapper "dabb" nil)

  (defun etags--wrapper (prefix maxnum)
    "Wrapper around a call to `all-completions' using
  `tags-complete-tag' to pass to `completion-define-minor-mode'."
    (let ((completions (all-completions prefix 'tags-complete-tag)))
      (when maxnum
        (setq completions
              (butlast completions (- (length completions) maxnum))))
      (mapcar (lambda (word) (substring word (length prefix)))
              completions)))
  ;;(setq completion-function 'etags--wrapper)
  ;; Use: (etags--wrapper "vobj" nil)

  (defun semantic-prefix-wrapper ()
    "Return prefix at point that Semantic would complete."
    (when (semantic-idle-summary-useful-context-p)
      (let ((prefix (semantic-ctxt-current-symbol (point))))
        (setq prefix (nth (1- (length prefix)) prefix))
        (set-text-properties 0 (length prefix) nil prefix)
        prefix)))

  (defun semantic-completion-wrapper (prefix maxnum)
    "Return list of Semantic completions for PREFIX at point.
     Optional argument MAXNUM is the maximum number of completions to
     return."
    (when (semantic-idle-summary-useful-context-p)
      (let* (
	     ;; don't go loading in oodles of header libraries for minor
	     ;; completions if using auto-completion-mode
	     ;; FIXME: don't do this iff the user invoked completion manually
	     (semanticdb-find-default-throttle
	      (when (and (featurep 'semanticdb-find)
		         auto-completion-mode)
	        (remq 'unloaded semanticdb-find-default-throttle)))

	     (ctxt (semantic-analyze-current-context))
	     (acomp (semantic-analyze-possible-completions ctxt)))
        (when (and maxnum (> (length acomp) maxnum))
	  (setq acomp (subseq acomp 0 (1- maxnum))))
        (mapcar 'semantic-tag-name acomp))))

  (defun completion-setup-semantic ()
    "Setup Semantic Completion-UI support."
    (interactive)
    (setq completion-function 'semantic-completion-wrapper)
    (setq completion-prefix-function 'semantic-prefix-wrapper)
    (setq auto-completion-override-syntax-alist '((?. . (add word))))
    (define-key completion-map "." 'completion-self-insert))
  )

(provide 'pgo-completion-ui)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-completion-ui.el ends here
