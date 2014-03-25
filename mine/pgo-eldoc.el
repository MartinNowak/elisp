;;; pgo-eldoc.el --- Setup ElDoc (eldoc.el)
;; Author: Per Nordlöw

;;; eldoc - show function arglist or variable docstring in echo area
;;; See: http://www.emacswiki.org/emacs-en/ElDoc

;; Note: Major modes for other languages may use ElDoc by defining an
;; appropriate function as the buffer-local value of
;; `eldoc-documentation-function'.

(when (require 'eldoc nil t)

  (add-hook 'lisp-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'text-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'outline-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'eshell-mode-hook 'turn-on-eldoc-mode)

  ;; update eldoc when `paredit' commands are used
  (eldoc-add-command
   'paredit-backward-delete
   'paredit-close-round
   'paredit-forward
   'paredit-backward)

  (when nil
    ;; Highlight eldoc arguments in `font-lock-variable-name-face'
    (defun ted-frob-eldoc-argument-list (string)
      "Upcase and fontify STRING for use with `eldoc-mode'."
      (propertize (upcase string)
		  'face 'font-lock-variable-name-face))
    (setq eldoc-argument-case 'ted-frob-eldoc-argument-list)

    ;; Highlighting Eldoc Arguments in EmacsLisp

    (defun eldoc-get-arg-index ()
      (save-excursion
	(let ((fn (eldoc-fnsym-in-current-sexp))
	      (i 0))
	  (unless (memq (char-syntax (char-before)) '(32 39)) ; ? , ?'
	    (condition-case err
		(backward-sexp)         ;for safety
	      (error 1)))
	  (condition-case err
	      (while (not (equal fn (eldoc-current-symbol)))
		(setq i (1+ i))
		(backward-sexp))
	    (error 1))
	  (max 0 i))))

    (defun eldoc-highlight-nth-arg (doc n)
      (cond ((null doc) "")
	    ((<= n 0) doc)
	    (t
	     (let ((i 0))
	       (mapconcat
		(lambda (arg)
		  (if (member arg '("&optional" "&rest"))
		      arg
		    (prog2
			(if (= i n)
			    (put-text-property 0 (length arg) 'face 'underline arg))
			arg
		      (setq i (1+ i)))))
		(split-string doc) " ")))))

    (defadvice eldoc-get-fnsym-args-string (around highlight activate)
      ""
      (setq ad-return-value (eldoc-highlight-nth-arg ad-do-it
						     (eldoc-get-arg-index))))
    ;;(ad-remove-advice eldoc-get-fnsym-args-string 'before highlight)
    )
  )

;;; eldoc-extension.el --- Some extension for eldoc
(when nil
  (append-to-load-path (elsub "eldoc-extension"))
  (require 'eldoc-extension nil t)
  )

;; Note: TODO: defadvice doesn't work when eldoc-display-message-no-interference-p is compiled so I override it for now! UGLY!
(when nil
  (if t
      (defun eldoc-display-message-no-interference-p ()
        (and eldoc-mode
             (not isearch-mode)           ;Note: I added this line!
             (not executing-kbd-macro)
             (not (and (boundp 'edebug-active) edebug-active))
             ;; Having this mode operate in an active minibuffer/echo area causes
             ;; interference with what's going on there.
             (not cursor-in-echo-area)
             (not (eq (selected-window) (minibuffer-window)))))
    (defadvice eldoc-display-message-no-interference-p (around not-during-isearch)
      "Prevent eldoc from displaying during isearch."
      (unless isearch-mode ad-do-it))
    (ad-activate 'eldoc-display-message-no-interference-p)))

;; See: http://www.emacswiki.org/cgi-bin/wiki/CEldocMode
(when nil
  (when (eload 'c-eldoc (elsub "others") "c-eldoc.el")
    (add-hook 'c-mode-common-hook 'c-turn-on-eldoc-mode)
    (setq c-eldoc-includes "`pkg-config gtk+-2.0 --cflags` -I./ -I../ -I/../.. -I/../../..")
    ))

;;; ======== ElDoc ToolTips ========

;;;###autoload
(defun tooltip-show-at-point (string &optional point face border-color border-width)
  "Show a tooltip for completion at POINT.
Inspired by `completion-show-tooltip' and
`tooltip-help.el'. Reuse `th-show-tooltip-for-point' instead."
  (interactive "d")
  (let ((point-pos (save-excursion
                     (let ((sym-bounds (bounds-of-symbol-at-point)))
                       (when sym-bounds
                         (goto-char (car sym-bounds))
                         (get-point-pixel-position))))))
    (let* ((window-column (mod (- (current-column) (window-hscroll))
                               (window-width)))
           (window-row (save-excursion
                         (save-restriction
                           (widen)
                           (narrow-to-region (window-start) (or point
                                                                (point)))
                           (goto-char (point-min))
                           (1+ (vertical-motion (buffer-size))))))
           (x (- (car point-pos) 10))
           (y (+ (cdr point-pos) 60))
           (face (or face 'default))      ;default face to `default'
           (font (face-attribute face :family))
           (fg (face-attribute face :foreground))
           (bg (face-attribute face :background))
           params
           )
      (setq params (tooltip-set-param params 'foreground-color fg))
      (setq params (tooltip-set-param params 'border-color (or border-color fg)))
      (setq params (tooltip-set-param params 'background-color bg))
      (setq params (tooltip-set-param params 'font font))
      (setq params (tooltip-set-param params 'internal-border-width 2))
      (setq params (tooltip-set-param params 'border-width (or 1 border-width)))
      (setq params (tooltip-set-param params 'left x))
      (setq params (tooltip-set-param params 'top y))
      (cond ((fboundp 'x-show-tip)
             (x-show-tip string
                         (selected-frame)
                         params
                         nil
                         x y)
             )
            ;;(t (message string))
            ))))

;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/33266e0f5f3097a1
(when nil          ;NOTE: Disabled for now because this is annoying!
  (defadvice eldoc-print-current-symbol-info (after eldoc-show-tooltip activate)
    (when (and (boundp 'eldoc-mode) eldoc-mode) ;only in buffers that have eldoc activated
      (let* ((sym (eldoc-current-symbol))
             (doc (or (eldoc-get-fnsym-args-string sym)
                      (eldoc-get-var-docstring sym))))
        ;;(when doc (tooltip-show-at-point doc))
        (when doc (pos-tip-show doc))
        )))
  (ad-activate 'eldoc-print-current-symbol-info))

(defun eldoc-tooltips ()
  "Put the `help-echo' text property on symbols with
`eldoc-get-fnsym-args-string'."
  (let ((buffer-modified-p (buffer-modified-p)))
    (save-excursion
      (goto-char (point-min))
      (let (sym help-echo)
        (while (re-search-forward "[(']" nil t)
          (when (and (setq sym (eldoc-current-symbol))
                     (setq help-echo (or (eldoc-get-fnsym-args-string sym)
                                         (eldoc-get-var-docstring sym))))
            (put-text-property (1- (point))
                               (save-excursion (forward-sexp 1) (point))
                               'help-echo
                               help-echo)))))
    (restore-buffer-modified-p buffer-modified-p)))
;;(add-hook 'emacs-lisp-mode-hook 'eldoc-tooltips)

(provide 'pgo-eldoc)
