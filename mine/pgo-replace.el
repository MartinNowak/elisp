;; coding: utf-8
;;; pgo-replace.el --- Setup up Replace, Swap, Reorganize.

;; regexpl.el --- Search and replace list of patterns and replacements.
;; (regexpl-search-replace-list '(("stopwatch" . "timer")
;;                                ("watch" . "wristwatch")))
(when (eload 'regexpl)
  (defalias 'parallel-query-replace-regexp 'regexpl-search-replace-list)
  (defalias 'multiple-query-replace-regexp 'regexpl-search-replace-list)
  ;; (global-set-key [(meta ?\¤)] 'regexpl-search-replace-list)
  ;; ToDo: Design regexpl-search-query-replace-list.
  ;; Use:(regexpl-search-replace-list '(("STR1" . "STR2") ("STR2" . "STR1")))
  )

;; See: http://www.emacswiki.org/emacs-en/SwappingText
;; This is simple version of regexpl.
;; ToDo: Move logic for mark-active to regexpl.
;; ToDo: Define and use `read-string-non-empty'.
(defun swap-strings (str1 str2 &optional beg end interactive-replace)
  "Swap all occurrencies of STR1 with STR2.
Optionally perform replace in region from BEG to END if they are
defined. If INTERACTIVE-REPLACE is non-nil do interactive
swap-replacements."
  (interactive "sFirst String (non-empty): \nsSecond String (non-empty): \nr")
  (if (use-region-p)
      (setq deactivate-mark t)
    (setq beg (point-min)
          end (point-max)))
  (if (string-equal str1 str2)
      (message "First and second are equal - nothing to do")
    (goto-char beg)
    (while (re-search-forward
            (concat "\\(?:\\b\\(" (regexp-quote str1) "\\)\\|\\("
                    (regexp-quote str2) "\\)\\b\\)") end t)
      (if (match-string 1)
          (replace-match str2 t t)
        (replace-match str1 t t)))))
;; (global-set-key [(meta ?¤)] 'swap-strings)

;; Note: This can be accomplished with ReplaceRegexp and an evaluated
;; Emacs Lisp replacement in Emacs 22 as follows:
;; C-M-% STR1\|STR2 RET \,(if (string= "STR1" \1) "STR2" "STR1") RET

;; iedit.el --- Edit multiple regions with the same content simultaneously.
;; See: http://permalink.gmane.org/gmane.emacs.sources/3381
(when (eload 'iedit nil nil "http://www.mail-archive.com/gnu-emacs-sources@gnu.org/msg01875/iedit.el")
  (define-key global-map (kbd "C-;") 'iedit-mode)
  )

(eload 'ireplace)         ;replace functions invoked from isearch-mode
(eload 'mapreplace)       ;mapping replace commands for GNU Emacs

;; replace+.el --- Extensions to `replace.el'.
(defcustom pnw/use-replace+ nil
  "Flags whether or not to use replace+ upon startup." :type
  'boolean :group 'pnw-options)
(when pnw/use-replace+
  (eval-after-load "replace"
    '(when (eload 'replace+)
       ;; Note: Disabled because its really annoying and slow!
       ;; Completion for Query Replace

       ;; Warning: Gives (error "Required feature `highlight' was not provided")
       (toggle-replace-w-completion -1)
       )))

(provide 'pgo-replace)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-replace.el ends here
