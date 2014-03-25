;;; pgo-indent.el --- Setup Indentation Extensions
;; Filename: pgo-indent.el
;; Author: Per Nordlöw

(require 'cc-utils)

;; Killing the newline between indented lines removes any extra spaces
;; caused by indentation.
(defadvice kill-line (before check-position activate)
  (if (member major-mode yank-indent-modes)
      (if (and (eolp) (not (bolp)))
          (progn (forward-char 1)
                 (just-one-space 0)
                 (backward-char 1)))))
(ad-activate 'kill-line)

;; ToDo: This does now work because region is not set by the adviced function.
(defadvice browse-kill-ring-insert-and-quit (after indent-region activate)
  (if (member major-mode yank-indent-modes)
      (save-excursion                    ;otherwise point and mark gets swapped
        (let ((mark-even-if-inactive t)) ;Alternative: (let ((transient-mark-mode nil))
          (indent-region (region-beginning)
                         (region-end) nil)))))
(ad-activate 'browse-kill-ring-insert-and-quit)

;; Indenting C Preprocessor (CPP) Statements such as
;; (#ifdef, #else, ...).

;;; TODO: Fix the following bug and enable:
;; Debugger entered--Lisp error: (error "Invalid search bound (wrong side of point)")
;; re-search-forward("^[ 	]*#[ 	]*\\(.*\\)" 536 t)
;; ppindent-region(510 536 0)
;; c-indent-region(510 536)
;; indent-region(510 536 nil)
;; yank(nil)
;; ad-Orig-slick-yank(nil)
;; slick-yank(nil)
;; call-interactively(slick-yank nil nil)
(when (require 'ppindent nil t)
  (setq ppindent-increment 2)          ;ToDo: Inherit from c-style?
  )

;; Guess Indentation offset for C code.
;; http://www.emacswiki.org/emacs-en/GuessOffset
;; See: http://www.emacswiki.org/emacs-en/IndentingC#toc9
(defcustom pnw/use-guess-offset nil
  "Flags whether or not to load guess-offset upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-guess-offset
    (when (require 'guess-offset nil t))
  )
;; Guess Style
;; Attempts to determine the proper values for indent-tabs-mode and the
;; indentation offset by analysing how the file is formatted. (Of course, since
;; smart tabs are tab size-independent, such files do not have an offset.)
(when (append-to-load-path (elsub "guess-style"))
  (eload 'guess-style))
(defcustom pnw/use-guess-style nil
  "Flags whether or not to load guess-style upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-guess-style
    (autoload 'guess-style-set-variable "guess-style" nil t)
  (autoload 'guess-style-guess-variable "guess-style")
  (autoload 'guess-style-guess-all "guess-style" nil t)
  ;; (add-hook 'c-mode-common-hook 'guess-style-guess-all)
  )

;; dtrt-indent.el --- Adapt to foreign indentation offsets
;; Note: Use instead of guess-offset.el
;; Note: Disabled because of error
;; re-search-forward("\\(^\\_ACEOF\\)" nil t)
;; dtrt-indent--skip-to-end-of-match("^\\_ACEOF" nil nil t)
;; dtrt-indent--skip-to-end-of-match(nil nil (("\"" 0 "\"" nil "\\.") ("'" 0 "'" nil "\\.") ("[<][<]\\([^ 	]+\\)" 1 "^\\1" nil) ("(" 0 ")" t) ("\\[" 0 "\\]" t)) nil)
;; ...n
;; dtrt-indent--calc-histogram(shell)
;; dtrt-indent-try-set-offset()
;; dtrt-indent-find-file-hook()
;; run-hooks(find-file-hook)
(defcustom pnw/use-dtrt-indent nil
  "Flags whether or not to load dtrt-indent upon startup." :type 'boolean :group 'pnw-options)
;; (if pnw/use-dtrt-indent
;;     (when (require 'dtrt-indent nil t)
;;       (dtrt-indent-mode 1)
;;       )
;;   )

(provide 'pgo-indent)
