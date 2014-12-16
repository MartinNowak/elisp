;;; newcomment-ext.el --- Extensions to newcomment.el.
;; Author: Per Nordlöw

(require 'paredit)
(require 'newcomment)
(require 'cc-assist)
(require 'rx)

(defvar comment-dwim-repeats 0
  "Repeat counter for `comment-dwim-really'.")

;; TODO If comment on line use that syntax.
;; `comment-search-forward' and `comment-search-backward' to `line-comment-position'
(defun comment-dwim-really (arg)
  "Wrapper for `comment-dwim' that formats multi-line comments in
Doxygen-style in modes supported by Doxygen, currently c-mode,
c++-mode, java-mode and csharp-mode."
  (interactive "*P")
  (setq comment-dwim-repeats (if (eq last-command
                                     this-command)
                                 (1+ comment-dwim-repeats)
                               0))
  (let ((keycomb (faze (symbol-function-keys-string this-command) 'keycomb)))
    (cond ((use-region-p)
           (if paredit-mode
               (paredit-comment-dwim arg)
             (comment-dwim arg)))
          (paredit-mode
           (paredit-comment-dwim arg))
          ((cc-derived-mode-p)
           (cond ((looking-at (rx (* space) eol))
                  (comment-dwim nil))
                 ((c-insert-general-multiline-comment)
                  ;; Do nothing
                  )
                 (t
                  (if (c-beginning-of-topmost-intro-p)
                      (progn
                        ;; TODO Support standing before, inside and between comment and definition.
                        (skip-ws-forward)
                        (thing-nearest-point 'defun)
                        (c-indent-command)
                        (insert (c-block-comment-start) "  */\n") (c-indent-command)
                        (forward-line -1) (eol) (backward-char 3)
                        (message "Doxygen Class/Function Comment"))
                    (cond ((>= comment-dwim-repeats 3)
                           (message "Nothing more to comment")
                           )
                          ((= comment-dwim-repeats 2)
                           (comment-kill nil)
                           (comment-kill nil)
                           (comment-region (line-beginning-position)
                                           (line-end-position))
                           (message "Line Commented Out"))
                          ((= comment-dwim-repeats 1)
                           (unless (looking-back (rx bol (* space) "//" (* space)))
                             (c-insert-doxygen-line-comment)
                             (message "Doxygen Line Comment. Press (%s) to comment out line" keycomb)))
                          (t
                           (comment-dwim arg)
                           (message "Line Comment. Press (%s) gives Doxygen Line Comment " keycomb))))))
           )
          (t
           (comment-dwim arg)
           ))))

;; TODO Call c-insert-doxygen-line-comment if we are standing after a variable declaration/definition.
(defun c-end-of-doxygen-line-comment ()
  "Go to end of enhanced (Doxygen) line comments."
  (when (cc-derived-mode-p)
    (unless (looking-back (rx space))
      (re-search-forward (concat "/*\\**" "[<!]*"
                                 "\\("
                                 _*
                                 "\\_<" ;text already present
                                 "\\|"
                                 " "
                                 "\\)")))))

(defadvice comment-dwim (after end-of-c-doxygen-line activate)
  "Adjust cursor to correct position of enhanced comments."
  (c-end-of-doxygen-line-comment))
(ad-deactivate 'comment-dwim)

(defun c-adjust-comments ()
  (setq comment-start "/*"
        comment-end "*/"))

(add-hook 'c-mode-hook 'c-adjust-comments)
(add-hook 'c++-mode-hook 'c-adjust-comments)
(add-hook 'd-mode-hook 'c-adjust-comments)
(add-hook 'flex-mode-hook 'c-adjust-comments)

(add-hook 'lisp-mode-hook (lambda () (local-set-key [(control c) (\;)] 'comment-region)))
(add-hook 'emacs-lisp-mode-hook (lambda () (local-set-key [(control c) (meta \;)] 'comment-region)))
(add-hook 'sh-mode-hook (lambda ()
                          ;; override shell mode case statement template insertion
                          (local-set-key [(control c) (\;)] 'comment-region)
                          (local-set-key [(control c) (meta \;)] 'uncomment-region)
                          ))

;;(eload 'c-comment-edit)             ;Edit C comments
(global-set-key [(control c) (\;)] 'comment-region)
(global-set-key [(control c) (meta \;)] 'uncomment-region)
(global-set-key [(meta \;)] 'comment-dwim)

(provide 'newcomment-ext)
