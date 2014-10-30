;;; pgo-window.el --- Setup Window Operations.
;; Author: Per Nordlöw

;; windata.el --- convert window configuration to list
;; This extension is useful when you want save window configuration
;; between emacs sessions or for emacs lisp programer who want handle
;; window layout.
(require 'windata nil t)
;; Use: (windata-current-winconf)

;; winpoint.el --- Remember buffer positions per-window, not per buffer
(when (and nil
           (require 'winpoint nil t))
  ;;      (window-point-remember-mode 1)
  ;; This option contain a buffer that don't want to restore point.
  ;; `winpoint-non-restore-buffer-list'
  ;; For example, setup *Group* buffer like below:
  ;; (setq winpoint-non-restore-buffer-list '("*Group*"))
  )

;; http://www.emacswiki.org/emacs-en/PerWindowPoint
;;; per-window-point.el --- persisent per-window values of point
(require 'per-window-point nil t)

;; virtual-desktops.el --- allows you to save/restore a frame configuration: windows and buffers.
(when nil
  (when (require 'virtual-desktops nil t)
    (virtual-desktops-mode 1)))

(progn
  (defun select-previous-window ()
    "Select next window."
    (interactive)
    (other-window -1))
  (defun select-next-window ()
    "Select previous window."
    (interactive)
    (other-window 1))
  (when (eload 'repeatable)
    (repeatable-command-advice previous-buffer)
    (repeatable-command-advice next-buffer)
    (repeatable-command-advice other-window)
    (repeatable-command-advice select-previous-window)
    (repeatable-command-advice select-next-window))
  (global-set-key [(control c) (control left)] 'select-previous-window)
  (global-set-key [(control c) (control right)] 'select-next-window)
  (global-set-key [(control c) (left)] 'select-previous-window)
  (global-set-key [(control c) (right)] 'select-next-window)
  ;; (global-set-key [(shift meta p)] 'select-previous-window)
  ;; (global-set-key [(shift meta n)] 'select-next-window)
  ;; (global-set-key [(shift home)] (lambda () 'select-previous-window))
  ;; (global-set-key [(shift end)] (lambda () 'select-next-window))
  )

;; winsize.el --- Interactive window structure editing
(when (require 'winsize nil t)
  ;;(global-set-key [(control x) ?ÂÃ§] 'resize-windows)
  )

;;; Window Operations

(defun message-windows-scroll-to-bottom ()
  (unless (eq (current-buffer)
              (get-buffer "*Messages*"))
   (with-current-buffer "*Messages*"
     (goto-char (point-max))
     (walk-windows (lambda (window)
                     (if (string-equal (buffer-name (window-buffer window)) "*Messages*")
                         (set-window-point window (point-max))))
                   nil t))))
;; (defadvice message (after message-tail activate)
;;   "Goto bottom of *Message* buffer after a message."
;;   (message-windows-scroll-to-bottom))
;; (ad-remove-advice 'message 'after 'message-tail)

(defun switch-to-minibuffer-window ()
  "Switch to minibuffer window (if active).
See http://superuser.com/questions/132225/how-to-get-back-to-an-active-minibuffer-prompt-in-emacs-without-the-mouse"
  (interactive)
  (let ((w (active-minibuffer-window)))
   (when w
     (select-window w))))

(defun select-window-0-or-display-last-messages (&optional arg)
  (interactive "P")
  (or (switch-to-minibuffer-window)
      ;; (active-minibuffer-window)
      ;; (progn
      ;;   (message "xx")
      ;;   (select-window-by-number 0 arg))
      ;; (ignore-errors (inhibit-messages (select-window-by-number 0 arg)))
      (let ((split-height-threshold nil))
        (display-buffer "*Messages*")
        (message-windows-scroll-to-bottom)
        (message "Displaying messages..."))))

;; Window Numbering
(when (ignore-errors
        (and (append-to-load-path
              (elsub "window-numbering"))
             (require 'window-numbering nil t))) ;TODO: Errors in `called-interactively-p' on Emacs 23 but not on 24.
  (let ((map window-numbering-keymap))
    (define-key map "\M-0" 'select-window-0-or-display-last-messages)
    )
  (window-numbering-mode t)
  ;; (window-numbering-clear-mode-line)
  (window-numbering-install-mode-line 0)
  ;; If you want to affect the numbers, use
  ;; window-numbering-before-hook or window-numbering-assign-func. For
  ;; instance, to always assign the calculator window the number 9,
  ;; add the following to your .emacs file:
  (setq window-numbering-assign-func
        (lambda () (when (equal (buffer-name) "*Calculator*") 9)))
  )
(when nil                               ;note: disabled in favor of package `window-numbering'
  (when (require 'window-number nil t)
    (window-number-mode nil)
  ;;; If you like to use the meta key instead of the C-x C-j
  ;;; prefix, add the following:
    (window-number-meta-mode t)
    ))

;;; window-extension.el --- Some extension functions manipulate window.
(when (require 'window-extension nil t)
  )

;;; windresize.el --- resize windows interactively
(when (require 'windresize nil t)
  )

;;; windresize-extension.el --- Some extension functions for `windresize.el'
(when (require 'windresize-extension nil t)
  )

;;; widen-window.el --- Widening selecting window
(when (require 'widen-window nil t)
  )

;;; windconfig.el --- resize windows interactively
(when (require 'windconfig nil t)
  )

;;; sticky-windows.el --- Make windows stay visible
(when nil
  (when (require 'sticky-windows nil t)
    (global-set-key     [(control x) (?0)]        'sticky-window-delete-window)
    (global-set-key     [(control x) (?1)]        'sticky-window-delete-other-windows)
    ;; In addition, `sticky-window-keep-window-visible' might be bound to the currently unused C-x 9 key binding:
    (global-set-key     [(control x) (?9)]        'sticky-window-keep-window-visible)
    ))

;; Always shrink help buffer to fit window contents.
;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/d0db709ef02e4587
(temp-buffer-resize-mode t)
(when nil
  (add-hook 'temp-buffer-show-hook
            (lambda nil
              (when (eq major-mode 'help-mode)
                (shrink-window-if-larger-than-buffer)))))

;; See: http://www.emacswiki.org/emacs-en/WinRing
(when (eload 'winring)
  (winring-initialize)
  (defun iy/winring-jump-or-create (&optional name)
    "Jump to or create configuration by name"
    (interactive)
    (let* ((ring (winring-get-ring))
           (n (1- (ring-length ring)))
           (current (winring-name-of-current))
           (lst (list (cons current -1)))
           index item)
      (while (<= 0 n)
        (push (cons (winring-name-of (ring-ref ring n)) n) lst)
        (setq n (1- n)))
      (setq name
            (or name
                (completing-read
                 (format "Window configuration name (%s): " current)
                 lst nil 'confirm nil 'winring-name-history current)))
      (setq index (cdr (assoc name lst)))
      (if (eq nil index)
          (progn
            (winring-save-current-configuration)
            (delete-other-windows)
            (switch-to-buffer winring-new-config-buffer-name t)
            (winring-set-name name))
        (when (<= 0 index)
          (setq item (ring-remove ring index))
          (winring-save-current-configuration)
          (winring-restore-configuration item)))))
  )

;;(when (eload 'dim-switch-window))

(when (ignore-errors (eload 'winlay)) ;TODO: Remove recursive require error and activate.
  (defadvice toggle-window-split (after shrink-all-windows activate)
    (shrink-window-if-larger-than-buffer))
  (ad-activate 'toggle-window-split)
  )

(when (eload 'transpose-frame))

;; Make window switching a little easier. C-x-o is a pain.
;;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/b7ec9f5a2d155c3e?hl=en
(when (require 'windmove nil t)
  (when nil
    (global-unset-key "\C-t") ;Unbind C-t. I don't really care about transposing chars.
    (define-prefix-command 'ctrl-t-prefix) ;Turn C-t into a prefix key
    ;; And within C-t bind vi-style navigation shortcuts
    ;; to window switching
    (define-key 'ctrl-t-prefix "j" 'windmove-down)
    (define-key 'ctrl-t-prefix "k" 'windmove-up)
    (define-key 'ctrl-t-prefix "h" 'windmove-left)
    (define-key 'ctrl-t-prefix "l" 'windmove-right)
    (global-set-key "\C-t" 'ctrl-t-prefix)
    ))

(provide 'pgo-window)
