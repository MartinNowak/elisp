;;; pgo-keys.el --- Setup Keys.
;; Author: Per Nordlöw

;; Borland IDE Style Keybindings
;;
;; Buffer Creation
;; Buffer Saving (Borland Pascal Style)
;;
;; (global-set-key [(f3)] 'find-file)
;; (global-set-key [(shift f3)] 'find-file-read-only)
;; (global-set-key [(shift f3)] 'find-file-read-only)
;; Buffer Splitting and Maximization (Borland Pascal Style)
;; (global-set-key [(f4)] 'kill-buffer)
;; (global-set-key [(control f4)] 'delete-frame)
;; (global-unset-key [(f5)])
;; (global-set-key [(f5)] 'delete-other-windows)
;; (global-set-key [(control f5)] 'split-window-vertically)
;; (global-set-key [(control shift f5)] 'make-frame-command)
;; (global-set-key [(meta 10)] 'save-buffers-kill-emacs)
;; (global-set-key [(control f10)] 'tmm-menubar)

;; ToDo: Ask google groups about this
(defun pnw/kmacro-apply-on-region-lines-or-end-and-call-macro (arg &optional no-repeat)
  (interactive)
  (if (use-region-p)
      (apply-macro-to-region-lines)
    (kmacro-end-and-call-macro 0)))

;; Cool Stuff Keys
(global-set-key [(control shift f1)] 'view-emacs-FAQ)
(global-set-key [(shift f5)] 'list-colors-display)

;; Closing

(Xlaunch
 (global-set-key [(delete)] "\C-d"))


(setq next-line-add-newlines nil)

;; meta-g is now a prefix key and should not be bound.
;;(global-set-key [(meta g)] 'goto-line)

;;(global-set-key [(control x) (p)] 'query-replace-regexp)
;;(global-set-key [(control x) (p)] 'replace-string)

;; Shortcuts for commands in net-utils.el.
(global-set-key [(control c) (shift ?l)] 'nslookup-host)
(defalias 'ping-host 'ping)
;;(global-set-key [(control c) (shift ?p)] 'ping)

(global-set-key [(shift f1)]
                (lambda () (interactive) (manual-entry (current-word))))

;;; ===========================================================================

(global-set-key [(control ?j)] 'newline)

;; Mode switching
(global-set-key [(control ?c) (control ?m) (?h)] 'hexl-mode)
(global-set-key [(control ?c) (control ?m) (?m)] 'normal-mode)

;; Delete
(global-set-key [del] 'delete-char)

;; Keypad Home and End
(global-set-key [        (kp-home)] 'beginning-of-line)
(global-set-key [         (kp-end)] 'end-of-line)
(global-set-key [(control kp-home)] 'beginning-of-buffer)
(global-set-key [(control  kp-end)] 'end-of-buffer)

;; Buffer navigation through control plus shift navigation letters.
;; (global-set-key [(control shift ?a)] 'beginning-of-buffer)
;; (global-set-key [(control shift ?e)] 'end-of-buffer)
;; (global-set-key [(control shift ?p)] 'scroll-down)
;; (global-set-key [(control shift ?n)] 'scroll-up)

;; Deactived for good support under Mac OS X (PNw).
;;(global-set-key [home] 'beginning-of-line)
;;(global-set-key [end] 'end-of-line)

;; The following lines were added when Emacs was installed on Mac OS X.
;;(global-set-key [(meta ?O) ?H] 'beginning-of-line)
;;(global-set-key [(meta ?O) ?F] 'end-of-line)
;;(global-set-key [(meta ?O) ?H] 'beginning-of-line)
;;(global-set-key [(meta ?O) ?F] 'end-of-line)

(global-set-key [(control c) (? )] 'fixup-whitespace)

;; Windows/Dos Style Copy and Paste Selection
(global-set-key [(shift insert)]
                (lambda () (interactive)
                   (insert (x-get-selection))))
(global-set-key [(control insert)]
                (lambda () (interactive)
                   (x-own-selection (buffer-substring (point) (mark)))))

;; I want alt backspace to mean this.
(global-set-key [(meta backspace)] 'backward-kill-word)

;; Keybindings for Customize Interface
(progn
  ;; (global-set-key [(control c) (meta c) (meta a)] 'customize-apropos)
  ;; (global-set-key [(control c) (meta c) (meta f)] 'customize-face)
  ;; (global-set-key [(control c) (meta c) (meta g)] 'customize-group)
  ;; (global-set-key [(control c) (meta c) (meta v)] 'customize-variable)
  (global-unset-key [(shift control meta ?c)])
  (define-prefix-command 'customize-map nil "Customize: [a,f,F,g,G,v,V,o,O]")
  ;;(global-set-key [(shift control meta ?c)] 'customize-map)
  (global-set-key [(control ?x) (?c)] 'customize-map)
  (define-key customize-map [(?a)] 'customize-apropos)
  (define-key customize-map [(?f)] 'customize-face)
  (define-key customize-map [(?F)] 'customize-face-other-window)
  (define-key customize-map [(?g)] 'customize-group)
  (define-key customize-map [(?G)] 'customize-group-other-window)
  (define-key customize-map [(?v)] 'customize-variable)
  (define-key customize-map [(?V)] 'customize-variable-other-window)
  (define-key customize-map [(?o)] 'customize-option)
  (define-key customize-map [(?O)] 'customize-option-other-window)
  )

;; (when (fboundp 'find-thing-at-point)
;;   (global-set-key [(meta ?.)] 'find-thing-at-point))

(defun pop-tag-mark-safe ()
  (interactive)
  (if (ring-empty-p find-tag-marker-ring)
      (progn
        (message "No previous locations for find-tag invocation")
        (ding))
    (let ((marker (ring-remove find-tag-marker-ring 0)))
      (if (marker-buffer marker)
          (progn
            (switch-to-buffer (marker-buffer marker) t)
            (goto-char (marker-position marker))
            (set-marker marker nil nil))
        (message "The marked buffer has been deleted")))))
(global-set-key [(meta ?*)] 'pop-tag-mark-safe)

(global-set-key [(meta shift ?f)] 'forward-sentence)
(global-set-key [(meta shift ?b)] 'backward-sentence)

;;(define-key global-map [escape] 'keyboard-escape-quit) ;Single escape instead of knocking 3 times
(global-set-key [(control meta ?g)] 'keyboard-escape-quit) ;Also to C-M-g

(global-set-key [(control meta backspace)] 'backward-kill-sexp)
(global-set-key [(control meta delete)] 'kill-sexp)

(global-set-key [(control c) (m)] 'man)

;;(global-set-key (kbd "<down-mouse-3>") 'cedet-m3-menu)

(defun icicle-locate-file-pnw ()
  (interactive)
  (let ((icicle-hide-common-match-in-Completions-flag t))
    (call-interactively #'icicle-locate-file)))

;; Emacs-Lisp
(when nil
  (dolist (map `(,emacs-lisp-mode-map
                 ,lisp-mode-map
                 ,lisp-interaction-mode-map))
    (define-key map [(meta return)] 'eval-last-sexp)
    (define-key map [(control meta return)] 'pp-eval-last-sexp)
    (define-key map [(control meta ?:)] 'pp-eval-expression)))

(global-set-key [(meta return)] 'eval-last-sexp)
(global-set-key [(control meta return)] 'pp-eval-last-sexp)
(global-set-key [(control meta ?:)] 'pp-eval-expression)

(global-set-key [(control x) (control y)] 'find-library)
(global-set-key [(control x) (control l)] 'icicle-locate-file-pnw)
(define-key dired-mode-map [(control x) (control l)] 'icicle-locate-file-pnw)

(global-set-key [(control shift meta ?p)] 'previous-buffer)
(global-set-key [(control shift meta ?n)] 'next-buffer)

(provide 'pgo-keys)
