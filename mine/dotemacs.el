;;; package --- Summary coding: mule-utf-8-unix
;; Author: Per Nordlöw (per.nordlow@gmail.com)

;;; TODO http://draketo.de/light/english/emacs/babcore#sec-3-2
;;; Code:

;;; ===========================================================================
;;; Package Management
(when (require 'package nil t)
  (when (boundp 'package-archives)
    (add-to-list 'package-archives
                 '("melpa" . "http://melpa.milkbox.net/packages/") t))
  (package-initialize)
  ;; (package-refresh-contents)
  )
(defun package-install-pnw ()
  "Install my favorites packages."
  (package-install 'load-relative)
  (package-install 'loc-changes)
  (package-install 'dash)
  ;; (package-install 'realgud)
  ;; (package-install 'flycheck)
  ;; (package-install 'flycheck-d-unittest)
  (package-install 'flycheck-haskell)
  (package-install 'flycheck-color-mode-line)
  ;; (package-install 'smartparens)
  )

(defvar pnw-me? (string-equal user-full-name "Per Nordlöw"))
(unless (boundp 'el-root) (defvar el-root "~/elisp" "My Emacs-Lisp Installation Directory."))
(unless (fboundp 'elsub)
  (defun elsub (&optional sub-dir)
    (if sub-dir
        (abbreviate-file-name (expand-file-name sub-dir el-root))
      el-root)))

(progn
  (defun GNUEmacs-21-p () (string-match "GNU Emacs 21" (version)))
  (defmacro GNUEmacs (&rest x) (list 'if (string-match "GNU Emacs" (version)) (cons 'progn x)))
  (defmacro GNUEmacs-21 (&rest x) (list 'if (string-match "GNU Emacs 21" (version)) (cons 'progn x)))
  (defmacro GNUEmacs-21-3 (&rest x) (list 'if (string-match "GNU Emacs 21.3" (version)) (cons 'progn x)))
  (defmacro GNUEmacs-21-3-2 (&rest x) (list 'if (string-match "GNU Emacs 21.3.2" (version)) (cons 'progn x)))
  (defmacro GNUEmacs-21-4 (&rest x) (list 'if (string-match "GNU Emacs 21.4" (version)) (cons 'progn x)))
  (defmacro GNUEmacs->=22 (&rest x) (list 'if emacs>=22-p (cons 'progn x)))
  (defmacro XEmacs (&rest x) (list 'if xemacs-p (cons 'progn x)))
  (defmacro Xlaunch (&rest x) (list 'if (eq window-system 'x) (cons 'progn x)))
  )

;;; Needed by FlyCheck
(let ((tmp (expand-file-name (user-login-name)
                             "/var/tmp")))
  (unless (file-directory-p tmp)
    (make-directory tmp)))

;;; ANTLR
(add-to-list 'auto-mode-alist '("\\.g[1-4]\\'" . antlr-mode)) ;from DGrammar/D.g4

;;; ===========================================================================
;;; CEDET
;;(load-file (elsub "mine/pgo-cedet.elc")) ;WARNING: Need this first!
;;(load-file (elsub "minimal-cedet-config/minimial-cedet-config-pnw.el")) ;WARNING: Need this first!

(load-file (elsub "mine/path-utils.elc"))
(append-to-load-path (elsub "mine"))
(append-to-load-path (elsub "others"))

(require 'faze nil t)
(require 'power-utils nil t)
(require 'def-unless nil t)
(require 'eload nil t)

;;; ECB
(append-to-load-path (elsub "ecb"))

(ignore-errors                          ;ignore error about revering .zsh_history
  (shell-command "ulimit -c 100000000"))      ;Emit core files smaller than 100 Megs

;; Garbage Collector: We have extra ram these days. Use 3 megs of
;; memory to speed up runtime a bit. This shaves off about 1/10 of a
;; second on startup.
(setq-default gc-cons-threshold
              (max 20000000 gc-cons-threshold))
(setq initial-major-mode 'text-mode) ;prevent *scratch* buffer from requring CEDET
;; (iswitchb-mode 1)

(when pnw-me?                           ;I don't need this
  (menu-bar-mode -1)
  (tool-bar-mode -1))

;;; Show function context
(when (which-function-mode 1))
(add-hook 'd-mode-hook (lambda () (which-function-mode 1))) ;TODO Why is this needed?

;;; ===========================================================================
;;; Auto-Reverting
;; It's nice to have Visual Studio C++ behave the same way, so you don't get the
;; annoying "This file has been modified outside of the source editor. Do you
;; want to reload it?" message. Choose Tools->Options->Editor and select
;; "Automatic reload of externally modified files".
(global-auto-revert-mode 1)
(setq-default auto-revert-interval 1)
;; Autorevert Some Buffers
(add-to-list 'revert-without-query "tags" "TAGS") ;Auto-Revert the Auto-Generated files
(add-to-list 'auto-mode-alist '("\\/var/log/messages\\'" . auto-revert-tail-mode))
(add-to-list 'auto-mode-alist '("\\/var/log/syslog\\'" . auto-revert-tail-mode))
(add-to-list 'auto-mode-alist '("\\/var/log/dmesg\\'" . auto-revert-tail-mode))
(add-to-list 'auto-mode-alist '("\\/var/log/Xorg.0.log\\'" . auto-revert-tail-mode))
(when (file-exists-p (elsub "syslog-mode.el"))
  (add-to-list 'auto-mode-alist
               '("\\(messages\\(\\.[0-9]\\)?\\|SYSLOG\\)\\'" . syslog-mode)))

(add-to-list 'debug-ignored-errors "^No further undo information")

(global-set-key (kbd "<down-mouse-3>") 'mouse-major-mode-menu) ;Right-Click does what we expect

;; Toggle display of time, load level, and mail flag in mode line.
(when nil (fset 'yes-or-no-p 'y-or-n-p)) ;replace "yes" and RET with just typing 'y'.  Several emacs actions

;;; ===========================================================================
;;; PEG (Parsing Expression Grammar)
(when (require 'peg nil t))
(when (eload 'peg-mode)
  (add-to-list 'auto-mode-alist '("\\.peg\\'" . peg-mode)))

;;; ===========================================================================
;;; Visual Regexp
(when (append-to-load-path (elsub "visual-regexp"))
  (autoload 'vr/replace "visual-regexp" "Visual Regexp Replace" t)
  (autoload 'vr/query-replace "visual-regexp" "Visual Regexp Query Replace" t)
  (define-key global-map (kbd "C-c r") 'vr/replace)
  (define-key global-map (kbd "C-c q") 'vr/query-replace))

;; TODO Fix bug that occurs when these are not defined.
;; Probably Some package I have added....
(setq warning-suppress-types nil
      byte-compile-warnings t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t
      line-number-mode t
      column-number-mode t
      inhibit-startup-message t
      debug-on-error nil
      apropos-do-all t			;apropos does more but slower
      transient-mark-mode 't
      history-length t
      history-delete-duplicates t
      completion-auto-help t
      completion-styles (quote (basic partial-completion emacs22 initials substring))
      ps-paper-type 'a4
      show-paren-delay 0.25
      confirm-nonexistent-file-or-buffer 'after-completion
      show-paren-style 'parenthesis
      auto-save-timeout 20
      auto-save-interval 60
      display-time-interval 1
      display-time-day-and-date t
      display-time-24hr-format t
      display-time-string-forms
	'(
	  ;;       (substring year -2)
	  year
	  "-" month
	  "-" day
	  " " 24-hours
	  ":" minutes
	  ;;       ":" seconds
	  ;;     (if time-zone " (") time-zone (if time-zone ")")
	  ;;     (if mail " Mail" "")
	  )
	visible-bell nil               ;NOTE: I disabled this because I don't like the flickering.
	ring-bell-function
	(lambda ()
	  ;;(message "Bell ringed at %s" this-command)
	  (unless (memq this-command '(isearch-abort
				       abort-recursive-edit
				       exit-minibuffer keyboard-quit delete-backward-char))
	    (ding)))
	)
(when (and (require 'compile nil t)
           (boundp 'compilation-do-echo-command))
  (setq-default compilation-do-echo-command nil)) ;do echo compilations for now

;; (setq-default frame-background-mode 'dark)
;;(set-frame-font "6x13")
;;(set-default-font "6x13")
;;(set-default-font "7x13")
;;(set-default-font "8x13")
;;(set-default-font "9x15")
;;(set-default-font "Bitstream Vera Sans Mono-8");For Emacs Snapshot GTK

(put 'scroll-left 'disabled nil)
(put 'downcase-region 'disabled nil)

;;; ===========================================================================
;;; Minibuffer
;;(setq enable-recursive-minibuffers pnw-me?)   ;Recursive Minibuffers
;; Show minibuffer recursion depth.
(when (minibuffer-depth-indicate-mode pnw-me?)
  (eload 'mb-depth+)                    ;Indicate minibuffer-depth in prompt
  ;; (when (boundp 'minibuffer-depth-indicate-mode) ;NOTE: for older Emacses
  ;;   (minibuffer-depth-indicate-mode 99))
  )

;;; ===========================================================================
;;; Change Font Type and Size.
;; Control + Scroll changes font size.
(global-set-key [C-mouse-4] 'text-scale-increase)
(global-set-key [C-mouse-5] 'text-scale-decrease)
;; Shift + scroll to change font type
;; (global-set-key [S-mouse-4] 'my-buffer-face-mode-fixed)
;; (global-set-key [S-mouse-5] 'my-buffer-face-mode-variable)
(when nil                               ;deprecated by builtin face-remap
  ;; Zoom frame font size.
  (when (eload 'zoom-frm)
    (define-key ctl-x-map [(control ?+)] 'zoom-in/out)
    (define-key ctl-x-map [(control ?-)] 'zoom-in/out)
    (define-key ctl-x-map [(control ?=)] 'zoom-in/out)
    (define-key ctl-x-map [(control ?0)] 'zoom-in/out)
    (global-set-key (if (boundp 'mouse-wheel-down-event) ; Emacs 22+
                        (vector (list 'control
                                      mouse-wheel-down-event))
                      [C-mouse-wheel])  ; Emacs 20, 21
                    'zoom-in)
    (when (boundp 'mouse-wheel-up-event) ; Emacs 22+
      (global-set-key (vector (list 'control mouse-wheel-up-event))
                      'zoom-out))
    (global-set-key [S-mouse-1]    'zoom-in)
    (global-set-key [C-S-mouse-1]  'zoom-out)
    ;; Get rid of `mouse-set-font' or `mouse-appearance-menu':
    (global-set-key [S-down-mouse-1] nil)
    ))

(tool-bar-mode -1)                        ;tool-bar
(display-time-mode -1)                    ;don't display time in menubar
(temp-buffer-resize-mode 1)               ;Show everything in minibuffer.

(set-scroll-bar-mode 'right)            ;scrollbar position
(horizontal-scroll-bar-mode -1)         ;disabled horizontal scrollbar
(toggle-scroll-bar t)                   ;show scrollbar
(show-paren-mode 1)
(blink-cursor-mode 1)              ;may annoy some users
(when (eload 'bar-cursor)     ;package used to switch block cursor to a bar
  (bar-cursor-mode -1))        ;modifies the variable `cursor-type'
;;Use: (modify-frame-parameters (selected-frame) (list (cons 'cursor-type 'block)))
;;(setq ange-ftp-generate-anonymous-password t) ;Auto-Generate anonymous password

;; Highlight (Operation) Context
(when (eload 'hictx)
  (hictx-add-default-advice))            ;use it
(when (eload 'show-num))

;; Auto Revert Buffer Contents: http://www.emacswiki.org/emacs/AutoRevertMode
(when nil
  (defun inform-revert-modified-file (&optional p1 p2)
    (let ((revert-buffer-function nil))
      (revert-buffer p1 p2)
      (w32-msgbox buffer-file-name "Emacs: Modified file automatically reverted" 'vb-ok-only 'vb-information nil t)
      )
    )
  (setq revert-buffer-function 'inform-revert-modified-file)
  (let ((window (get-buffer-window (current-buffer))))
    (when window
      (hictx-buffer window 'hictx-delete-face hictx-kill-timeout nil nil t))))

;;; ===========================================================================
;;; Highlight Current Symbol
(when (and (append-to-load-path (elsub "highlight-symbol"))
           (require 'highlight-symbol nil t))
  (define-key-after menu-bar-options-menu [highlight-symbol-mode]
    `(menu-item "Highlight Current Symbol" highlight-symbol-mode
                :help "Highlight All Occurrencies of the symbol at cursor"
                :button  (:toggle . highlight-symbol-mode)
                :visible t)
    'oprofile)
  (setq highlight-symbol-idle-delay 0.5)
  (global-set-key [(meta s) (meta p)] 'highlight-symbol-prev)
  (global-set-key [(meta s) (meta n)] 'highlight-symbol-next)
  (global-set-key [(meta p)] 'highlight-symbol-prev)
  (global-set-key [(meta n)] 'highlight-symbol-next)
  ;; TODO Repeatable fails here...
  ;; (repeatable-command-advice highlight-symbol-prev)
  ;; (repeatable-command-advice highlight-symbol-next)
  (when (require 'hictx nil t)
    (defadvice highlight-symbol-prev (after ctx-flash-highlight-symbol-prev activate) (hictx-line)) (ad-activate 'highlight-symbol-prev)
    (defadvice highlight-symbol-next (after ctx-flash-highlight-symbol-next activate) (hictx-line)) (ad-activate 'highlight-symbol-next)
    (defadvice tags-loop-continue (after ctx-flash-highlight-symbol-next activate) (hictx-line nil nil 0.3)) (ad-activate 'tags-loop-continue)
    )
  ;; Note: Replaced by Semantic in a smarter way (currently for C/C++ only, I think).
  (dolist (hook '(c-mode-common-hook ada-mode-hook
                  text-mode-hook outline-mode-hook
                  lisp-mode-hook emacs-lisp-mode-hook
                  sh-mode-hook
                  makefile-mode-hook
                  octave-mode-hook matlab-mode-hook
                  help-mode-hook info-mode-hook
                  file-magic-mode-hook
                  python-mode-hook
                  proced-mode-hook
                  haskell-mode-hook
                  comint-mode
                  ))
    (add-hook hook 'highlight-symbol-mode t)))

;;; ===========================================================================
;;; Highlight signature of current C/C++ function

(when (and (append-to-load-path (elsub "c-eldoc"))
           (require 'c-eldoc nil t))
  (add-hook 'c-mode-hook 'c-turn-on-eldoc-mode)
  (add-hook 'c++-mode-hook 'c-turn-on-eldoc-mode))

;;; ===========================================================================
;;; Hide C Preprocessor ifdef regions
;;; See: https://stackoverflow.com/questions/641045/how-can-i-fold-ifdef-ifndef-blocks-in-emacs

(defface hide-ifdef-shadow-face '((t (:inherit shadow)))
  "Face for shadowing ifdef blocks."
  :group 'hide-ifdef)
(setq hide-ifdef-initially t)

(defconst hide-ifdef-modes '(c-mode-hook
                             c++-mode-hook
                             objc-mode-hook)
  "Modes to activate hide-ifdef inside.")

(defun update-hide-ifdefs ()
  "Update hide-ifdefs."
  (when (memq major-mode hide-ifdef-modes)
    (when (and (boundp 'hide-ifdef-mode)
               hide-ifdef-mode)
      (hide-ifdef-mode -1))
    (hide-ifdef-mode 1)))

(defun setup-hide-ifdef ()
  "Setup hideif."
  ;; TODO `hide-ifdef-env'
  (when nil                             ;note: disabled for now because it's too slow
    (when (or (load-file (elsub "mine/hideif.elc"))
              (require 'hideif nil t))
      (setq-default hide-ifdef-shadow t)
      (setq hide-ifdef-env '((__linux__ . t)
                             (__WORDSIZE . "32")))
      (setq hide-ifdef-define-alist
            `(
              ;; For DMD Sources
              (dmd-source-defines . ,(append '(CCASTSYNTAX CARRAYDECL) ;in parse.c
                                             (cond ((eq system-type 'gnu/linux)
                                                    '(TARGET_LINUX __GNUC__))
                                                   ((eq system-type 'windows-nt)
                                                    '(TARGET_WINDOS NTEXCEPTIONS))
                                                   ((eq system-type 'darwin)
                                                    '(TARGET_OSX))
                                                   ((eq system-type 'gnu/kfreebsd)
                                                    '(TARGET_FREEBSD)))))
              ;; For C/C++ Sources
              (platform-defines . ,(cond ((eq system-type 'gnu/linux)
                                          '(__linux__ HAVE_X_WINDOWS GNU_LINUX))
                                         ((eq system-type 'windows-nt)
                                          '(_WIN32 WINDOWSNT))
                                         ((eq system-type 'darwin)
                                          '(__APPLE__ DARWIN_OS HAVE_NS NS_IMPL_COCOA))
                                         ((eq system-type 'gnu/kfreebsd)
                                          '(__FreeBSD__))
                                         ((eq system-type 'openbsd)
                                          '(__OpenBSD__))
                                         ((or (string-match "sun" (symbol-name system-type))
                                              (eq system-type 'solaris))
                                          '(__sun))))
              (architecture-defines . ,(cond ((eq system-type 'gnu/linux)
                                              '(__linux__))
                                             ))))
      (add-hook 'after-save-hook 'update-hide-ifdefs)
      (hide-ifdef-mode 1)
      (hide-ifdef-use-define-alist 'dmd-source-defines)
      (hide-ifdef-use-define-alist 'platform-defines)
      (hide-ifdef-use-define-alist 'architecture-defines)
      )))

(dolist (hook hide-ifdef-modes)
  (add-hook hook 'setup-hide-ifdef t))

(when nil                               ;TODO What does this do?
  (defun hide-ifdef-region-internal (start end)
    (remove-overlays start end 'face 'hide-ifdef-shadow-face)
    (let ((o (make-overlay start end)))
      (overlay-put o 'face 'hide-ifdef-shadow-face)))
  (defun hif-show-ifdef-region (start end)
    "Everything between START and END is made visible."
    (remove-overlays start end 'face 'pnw/hide-ifdef-region-face))
  ;; NOTE: Deactivated because it does not dynamically update when I
  ;; change #if 0 statments to say #if 1.
  )

;;; ===========================================================================
;;; Smileys
(when (and nil (file-readable-p (elsub "others/autosmiley.el")))
  (dolist (hook '(c-mode-common-hook ada-mode-hook d-mode-hook
                                     text-mode-hook outline-mode-hook
                                     lisp-mode-hook emacs-lisp-mode-hook
                                     sh-mode-hook
                                     makefile-mode-hook
                                     octave-mode-hook matlab-mode-hook
                                     help-mode-hook info-mode-hook
                                     ;;file-magic-mode-hook
                                     python-mode-hook
                                     ;;proced-mode-hook
                                     ;;haskell-mode-hook
                                     ;;comint-mode
                                     ))
    (add-hook hook 'autosmiley-mode t)))

(eval-when-compile (require 'cl))
(require 'rx) ;See: http://www.emacswiki.org/emacs/rx on how to extend `rx'.
(require 'repeatable nil t)
(require 'list-fns nil t)

(when (append-to-load-path (elsub "pcre2el"))
  (autoload 'rxt-global-mode "pcre2el" "Toggle Rxt mode in all buffers." t))

;;; ===========================================================================
;; winner.el --- Restore Old (Undo/Redo) Window Configurations
;; WinnerMode - http://www.emacswiki.org/cgi-bin/wiki/WinnerMode
;; '((kbd "C-x C-<return>")
;;   (kbd "C-x <up>"))

(defun winner-undo-safe ()
  "Variant of `winner-undo' that dings instead of errors."
  (interactive)
  (unless (ignore-errors (winner-undo) t)
    (message "At first window layout") ;; (sit-for 1)
    (ding)))

;;; ===========================================================================
;;; TODO Ugly to copy this here...

(defun winner-redo ()			; If you change your mind.
  "Restore a more recent window configuration saved by Winner mode."
  (interactive)
  (cond
   ((memq last-command '(winner-undo winner-undo-safe))
    (winner-set
     (if (zerop (minibuffer-depth))
         (ring-remove winner-pending-undo-ring 0)
       (ring-ref winner-pending-undo-ring 0)))
    (unless (eq (selected-window) (minibuffer-window))
      (message "Winner undid undo")))
   (t (error "Previous command was not a `winner-undo'"))))
(defun winner-redo-safe ()
  "Variant of `winner-redo' that dings instead of errors."
  (interactive)
  (unless (ignore-errors (winner-redo) t)
    (message "At last window layout") ;; (sit-for 1)
    (ding)))

(when (require 'winner nil t)
  (dolist (def '([(control x) (up)]
                 [(control c) (up)]
                 [(control c) (control up)]
                 [(meta left)]
                 ))
    (define-key winner-mode-map def 'winner-undo-safe))
  (dolist (def '([(control x) (down)]
                 [(control c) (down)]
                 [(control c) (control down)]
                 [(meta right)]
                 ))
    (define-key winner-mode-map def 'winner-redo-safe))
  ;; (when (eload 'repeatable)
  ;;   (repeatable-command-advice winner-undo-safe)
  ;;   (repeatable-command-advice winner-redo-safe))
  (winner-mode 1)
  ;;(add-to-list 'winner-boring-buffers "*Completions*")
  ;;(remove "*Kill Ring*" winner-boring-buffers)
  ;;(remove "*Compile-Log*" winner-boring-buffers)
  )

(progn
  (defun windmove-left-safe ()
    "Variant of `windmove-left' that dings instead of errors."
    (interactive)
    (unless (ignore-errors (windmove-left) t)
      (message "At leftmost window") ;; (sit-for 1)
      (ding)))
  (defun windmove-right-safe ()
    "Variant of `windmove-right' that dings instead of errors."
    (interactive)
    (unless (ignore-errors (windmove-right) t)
      (message "At rightmost window") ;; (sit-for 1)
      (ding)))
  (defun windmove-up-safe ()
    "Variant of `windmove-up' that dings instead of errors."
    (interactive)
    (unless (ignore-errors (windmove-up) t)
      (message "At topmost window") ;; (sit-for 1)
      (ding)))
  (defun windmove-down-safe ()
    "Variant of `windmove-down' that dings instead of errors."
    (interactive)
    (unless (ignore-errors (windmove-down) t)
      (message "At bottommost window") ;; (sit-for 1)
      (ding)))
  (define-key global-map [(shift meta left)] 'windmove-left-safe)
  (define-key global-map [(shift meta right)] 'windmove-right-safe)
  (define-key global-map [(shift meta up)] 'windmove-up-safe)
  (define-key global-map [(shift meta down)] 'windmove-down-safe)
  (when (require 'repeatable nil t)
    (repeatable-command-advice windmove-left-safe)
    (repeatable-command-advice windmove-right-safe)
    (repeatable-command-advice windmove-up-safe)
    (repeatable-command-advice windmove-down-safe)))

;;; ===========================================================================
;;; My Stuff
(require 'power-utils nil t)
(require 'hash-table-utils nil t)
(require 'obarray-utils nil t)
(when (eload 'structed nil "structed.el") ;Structured Navigation and Operation.
  (cc-structed-add-key-bindings))

(add-hook 'before-save-hook 'delete-trailing-whitespace) ;delete the bastards
(add-hook 'after-save-hook
          (lambda () (when (fboundp 'semantic-force-refresh)
                       (semantic-force-refresh))))

;;; Search other file
(when (require 'find-file nil t)
  (defcustom ada-other-file-alist
    '(("\\.ads\\'" (".adb"))
      ("\\.adb\\'" (".ads")))
    "See the description for the `ff-search-directories' variable."
    :type '(repeat (list regexp (choice (repeat string) function)))
    :group 'ff)
  (setq cc-search-directories '("."
				"include" "src"
				"../include" "../src"
                                "root" "backend" "tk"  ;DMD
				"/usr/include" "/usr/local/include/*"
				"/System/Library/Frameworks" "/Library/Frameworks")))

;;; ===========================================================================
;;; Structal (Parenthesises) Editing
;; http://www.emacswiki.org/emacs-en/ParEdit
(autoload 'paredit-mode "paredit" "Minor mode for pseudo-structurally editing Lisp code." t)
(dolist (hook (list
	       ;; 'c-mode-common-hook 'haskell-mode-hook 'maxima-mode-hook 'ielm-mode-hook
	       'emacs-lisp-mode-hook
               ;; NOTE too annoying to here 'lisp-interaction-mode-hook
               'lisp-mode-hook
	       ))
  (add-hook hook (lambda ()
		   (paredit-mode 1)
		   (define-key paredit-mode-map [return] 'paredit-newline)
		   (define-key paredit-mode-map [(meta ?s)] nil) ;NOTE: M-s is now a command prefix for advanced search commands
		   (define-key paredit-mode-map [(shift meta up)] 'paredit-splice-sexp) ;NOTE: M-s is now a command prefix for advanced search commands
		   )))

;;; ===========================================================================
;;; SubWord
(when (and (require 'subword nil t)
           (fboundp 'subword-mode))
  (global-subword-mode 1))

(when nil
  (mapc (lambda (mode) (let ((hook (intern-soft (concat (symbol-name mode) "-mode-hook"))))
                         (when hook (add-hook hook (lambda () (paredit-mode 1))))))
        '(emacs-lisp lisp inferior-lisp))
  (eload 'paredit-extension)            ;Simple extension base on paredit.el
  )

;;; ===========================================================================
;;: smart-op.el --- Insert operators with surrounding spaces smartly.
;;; Previously smart-operator.el by William Xu.
;;; Smart Operator: http://www.emacswiki.org/emacs/SmartOperator
(when (require 'smart-op nil t)
  ;; (and (file-exists-p (elsub "mine/smart-op.el"))
  ;;      (load-file (elsub "mine/smart-op.elc")))
  (add-hook 'c-mode-common-hook 'smart-op-mode t)
  (add-hook 'ada-mode-hook 'smart-op-mode t)
  (add-hook 'python-mode-hook 'smart-op-mode t)
  (add-hook 'ruby-mode-hook 'smart-op-mode t)
  )

;;; ===========================================================================
;;; Structal (Parenthesises) Editing

;;; smartparens
(when (and (prepend-to-load-path (elsub "smartparens"))
           (require 'smartparens nil t)
           (fboundp 'smartparens-mode))
  (require 'smartparens-config)
  (smartparens-global-mode -1)          ;disabled in favour of `autopair'
  )

;;; http://www.emacswiki.org/emacs/AutoPairs
;;; https://github.com/capitaomorte/autopair
;;; http://stackoverflow.com/questions/7718975/intelligent-auto-closing-matching-characters
(when nil                               ;TODO All these disabled in favour of smartparens
  (when (eload 'parenthesis)      ;Insert pair of parenthesis
    (add-hook 'c-mode-common-hook
              (lambda()
                (parenthesis-init)
                (parenthesis-register-keys "{('\"[")))
    ))
(when t
  (append-to-load-path (elsub "autopair")) ;better than `electric-pair-mode'
  (when (fboundp 'electric-pair-mode)
    (electric-pair-mode -1))            ;disable in favor of autopair
  (when (eload 'autopair)
    (autopair-global-mode -1)           ;to enable in all buffers
    (when nil
      (eload 'auto-pair+)
      ;; use paredit instead
      (add-hook 'emacs-lisp-mode-hook (lambda () (setq autopair-dont-activate t)))
      (add-hook 'lisp-interaction-mode-hook (lambda () (setq autopair-dont-activate t)))
      (add-hook 'lisp-mode-hook (lambda () (setq autopair-dont-activate t)))
      ;; prevent the '{' (opening brace) character from being autopaired in C++
      ;; comments use this in your .emacs.
      ;; (add-hook 'c++-mode-hook
      ;; 	      (lambda ()
      ;;             (push ?
      ;;                   (getf autopair-dont-pair :comment))))
      ;; autowrapping
      (progn
        (setq autopair-autowrap t)
        ;; pair backtick and quote
        ;; (add-hook 'emacs-lisp-mode-hook
        ;; 		(lambda ()
        ;;             (push '(?` . ?') (getf autopair-extra-pairs :comment))
        ;;             (push '(?` . ?') (getf autopair-extra-pairs :string))))
        ;; python triple quoting
        (add-hook 'python-mode-hook
                  (lambda ()
                    (setq autopair-handle-action-fns
                          (list #'autopair-default-handle-action
                                #'autopair-python-triple-quote-action)))))
      (when delete-selection-mode
        (put 'autopair-insert-opening 'delete-selection t)
        (put 'autopair-skip-close-maybe 'delete-selection t)
        (put 'autopair-insert-or-skip-quote 'delete-selection t)
        (put 'autopair-extra-insert-opening 'delete-selection t)
        (put 'autopair-extra-skip-close-maybe 'delete-selection t)
        (put 'autopair-backspace 'delete-selection 'supersede)
        (put 'autopair-newline 'delete-selection t)))
    ))
(when (fboundp 'electric-indent-mode) (electric-indent-mode 1))
(when (fboundp 'electric-layout-mode) (electric-layout-mode -1))
(when (fboundp 'electric-pair-mode) (electric-pair-mode 1))
;; See: http://www.emacswiki.org/emacs-en/AutoPairs

(defun c-no-hanging-semi ()
  ;; TODO How do I get information about if comma or semicolon was pressed?
  ;; See: https://stackoverflow.com/questions/27217515/tweaking-emacs-electric-behaviour
  nil)

(add-to-list 'c-hanging-semi&comma-criteria 'c-no-hanging-semi)

(when (append-to-load-path (elsub "Sublain"))
  (require 'sublain nil t)
  )

;; =============== Other ============================================================

(autoload 'browse-apropos-url "browse-apropos-url" "Browse URL Apropos" t)
(autoload 'browse-apropos-url-on-region "browse-apropos-url" "Browse URL Apropos" t)

(when nil (setq emacs-load-start-time (float-time))) ;Log time

;; Icicles
;;(eload 'pgo-icicles)    ;Icicles
(when (eload 'icicles)
  (when pnw-me?
    (icy-mode 1))
  (when (boundp 'icicle-default-in-prompt-format-function)
    (setq-default icicle-default-in-prompt-format-function
                  (lambda (default)
                    (format " (%s)" default)))))

(when nil
  ;; See: http://www.emacswiki.org/emacs/AutoAsyncByteCompile
  (when (require 'auto-async-byte-compile nil t)
    (setq auto-async-byte-compile-exclude-files-regexp "/junk/")
    (add-hook 'emacs-lisp-mode-hook 'enable-auto-async-byte-compile-mode)))
;; See: http://www.emacswiki.org/emacs/AutoRecompile
;; (require 'byte-code-cache nil t) ;Compile files as they're used
;; (require 'elisp-cache nil t)

;; Shrink to fit
(defadvice display-warning (after fit-buffer (type message &optional level buffer-name) activate)
  (shrink-window-if-larger-than-buffer (get-buffer-window (or buffer-name "*Warnings*"))))

(defadvice shrink-window-if-larger-than-buffer (after one-extra-row (&optional window) activate)
  "Add one extra row so we can go to bottom without the window scrolls."
  (let ((buf-n (count-lines (point-min)
                            (point-max)))
        (win-n (window-height)))
    (when (== (1+ buf-n) win-n)
      (enlarge-window 1))))

;;; ===========================================================================
;;; Buffers
(eload 'kill-buffer-ext)
(global-set-key [f5] 'kill-buffer)
(global-set-key [f11] 'toggle-frame-fullscreen)
(global-set-key [(control f11)] 'compile)

(when (require 'uniquify nil t)       ;Append Part of Full Path to Buffer Names
  ;;(setq uniquify-buffer-name-style 'forward)
  (setq uniquify-buffer-name-style 'post-forward ;prevent confusion for new users
	uniquify-separator "@")
  )

(eload 'highlight-chars)                  ;Highlight whitespace of various kinds.
(eload 'naked)
(eload 'subr+)
(eload 'facemenu+)
(eload 'font-lock-menus)
(eload 'emacs-lock+)             ;extensions to standard library `emacs-lock.el'
(eload 'help-fns+)
(eload 'finder+)

;;; ===========================================================================
;;; TODO Disabled because of error: ls-lisp--insert-directory: Symbol's value as variable is void: original-insert-directory
;; (eload 'ls-lisp+)

(eload 'mouse3) ;NOTE: You can also (define-key global-map [remap mouse-save-then-kill] 'mouse-major-mode-menu)
(eload 'mouse+) ;Extensions to `mouse.el'. See: http://www.emacswiki.org/cgi-bin/wiki/MousePlus
(eload 'misc-fns)            ;Miscellaneous non-interactive functions.
(eload 'misc-cmds)           ;Miscellaneous commands (interactive functions).
(eload 'frame-cmds)          ;Frame and window commands (interactive functions).
(eload 'frame-fns)
(eload 'accelerate) ;pump numeric arg for auto-repeated interactive commands
(eload 'lacarte) ;Execute menu items as commands, with completion.
(eload 'strings)   ;Miscellaneous string functions.
(eload 'uuid)       ;cCross-platform UUID generation
(eload 'tooltip-help)                   ;Show help as tooltip.
(eload 'enscript)                       ;Joel's Custom printing functions
(eload 'descr-text+)
(eload 'hide-comnt)
;;(eload 'aes)                  ;Implementation of AES: http://www.emacswiki.org/cgi-bin/wiki/AdvancedEncryptionStandar
(eload 'uproj)                          ;Unified Project Build Interface
(eload 'hexrgb)                         ;Functions to manipulate RGB hex strings
(eload 'ucs-cmds)                       ;Macro to create commands that insert Unicode chars.
(when (eload 'modeline-posn) ; http://www.emacswiki.org/cgi-bin/wiki/ModeLinePosition
  ;; TODO Show argument count from structed.el aswell
  (setq-default modelinepos-style '(" %dch, %dw, %dl"
                                    (abs (- (mark t) (point)))
                                    (count-words-region (mark t) (point))
                                    (count-lines (mark t) (point))))
  (size-indication-mode 1))

;;; ===========================================================================
;;; I-Search
(eval-after-load "isearch" '(eload 'isearch+)) ;Extensions to `isearch.el'
(eload 'replace-from-region)

;;; ===========================================================================
;;; Make it less likely to enable `set-region' logic by accident.
(add-hook 'isearch-mode-hook
	  (lambda ()
	    (define-key isearch-mode-map [(control ? )] nil) ;undefine it
	    (define-key isearch-mode-map [(control shift ? )] 'isearchp-toggle-set-region)
	    (add-to-list 'minor-mode-alist '(case-fold-search " CFS"))
	    ;;(delete-list-members isearchp-initiate-edit-commands 'left-char 'backward-word 'backward-sexp 'left-word)
	    )
	  t)
(when (eload 'relex-isearch)
  (global-relex-isearch-mode -1))
(when (and (append-to-load-path (elsub "flex-isearch"))
           (require 'flex-isearch nil t))
  (setq flex-isearch-auto 'on-failed)
  (turn-on-flex-isearch))

(when nil
  (eval-after-load "info" '(progn (eload 'info+))) ;Extensions to `info.el'.
  (eval-after-load "window" '(progn (eload 'window+)))
  (eval-after-load "ring" '(progn (eload 'ring+))) ;Extensions to `ring.el'
  (eval-after-load "simple" '(progn (eload 'simple+)))
  (eval-after-load "macros" '(progn (eload 'macros+))) ;Extensions to `macros.el'
  (eval-after-load "files" '(progn (eload 'files+)))
  (eval-after-load "menu-bar" '(eload 'menu-bar+)) ;Extensions to `menu-bar.el'.
  (eval-after-load "bindings" '(progn (eload 'bindings+))) ;Extensions to `bindings.el'.
  (eval-after-load "help" '(progn (eload 'help+))) ;Extensions to `help.el'.
  (eval-after-load "help-mode" '(progn (eload 'help-mode+))) ;Extensions to `help-mode.el'.
  (eval-after-load "apropos" '(progn (eload 'apropos+))) ;Extensions to `apropos.el'.
  (require 'apropos-fn+var nil t) ;Apropos for functions and variables
  ;;(eval-after-load "setnu" '(progn (eload 'setnu+)))
  ;;(eload 'filesets+)            ;Extensions to `filesets.el'.
  ;;(eload 'find-func+)           ;Extensions to `find-func.el'.
  ;;(eval-after-load "frame" '(eload 'frame+)) ;Extensions to `frame.el'.
  ;;(eval-after-load "cc-mode" '(progn (eload 'cc-mode+))) ;Extensions to `c-mode.el' & `cc-mode.el'.
  )

;;; ===========================================================================
;;; Diff
(when nil              ;Note: fonts such for dark backgrounds so disable for now
  (when (require 'diff-mode- nil t)))
(add-to-list 'magic-mode-alist `(,(rx (: buffer-start
                                         "diff" (* nonl) "\n"
                                         "--- " (* nonl) "\n"
                                         "+++ " (* nonl) "\n"
                                         "@@" (* nonl) "@@" "\n")) . diff-mode))

;;; ===========================================================================
;;; Simple Interface to Comparison: Windows, Buffers, Files, Directory, Trees

(progn
  (global-set-key [(control meta ?=)] 'compare-windows)
  (define-prefix-command 'compare-map nil
    (if t
        "Compare: Buffers-[b/2,B/3,v], Files-[f,F], Regions-[r,R], Windows-[w], Dir-Trees-[t], Buffer==URL-[u]"
      "Compare:\n  - Buffers-[b/2,B/3]\n  - Files-[f,F]\n  - Regions-[r,R]\n  - Windows-[w]\n  - Dir-Trees-[t]\n  - Buffer==URL-[u]"))
  (global-set-key [(control ?=)] compare-map)
  (unless (keymapp compare-map) (setq compare-map (make-sparse-keymap)))
  (progn
    (define-key compare-map "2" 'ediff-buffers)
    (define-key compare-map "3" 'ediff-buffers3)
    (define-key compare-map "b" 'ediff-buffers)
    (define-key compare-map "B" 'ediff-buffers3)
    (define-key compare-map "e" 'ediff-files)
    (define-key compare-map "f" 'ediff-files)
    (define-key compare-map "r" 'ediff-regions-linewise)
    (define-key compare-map "R" 'ediff-regions-wordwise)
    (define-key compare-map "v" 'vc-ediff-current-buffer-with-head)
    (define-key compare-map "d" 'diff)
    (define-key compare-map "w" 'compare-windows)
    (define-key compare-map "t" 'ediff-trees)
    (define-key compare-map "u" 'ediff-url)
    ))

;;; ===========================================================================
;;; Lightweight alternative to emerge/ediff.
;; (autoload 'smerge-mode "smerge-mode" nil t)
(defun smerge-try-conflicts ()
  "Enter smerge-mode if buffer contains vc merge conflicts.
You can now enter ediff with C-c ^ E."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^<<<<<<< " nil t)
      (smerge-mode 1))))
(global-set-key [(control shift f7)] 'smerge-prev)
(global-set-key [(control shift f8)] 'smerge-next)
(defadvice smerge-prev (after ctx-flash-highlight-symbol-prev activate) (hictx-line)) (ad-activate 'smerge-prev)
(defadvice smerge-next (after ctx-flash-highlight-symbol-prev activate) (hictx-line)) (ad-activate 'smerge-next)

;;(add-hook 'find-file-hooks 'smerge-try-conflicts t)

;;; ===========================================================================
;;; ELP: Emacs Lisp Profiler
(when (require 'elp nil t)
  (defalias 'elp-profile-function 'elp-instrument-function)
  (defalias 'elp-profile-list 'elp-instrument-list)
  (defalias 'elp-profile-package 'elp-instrument-package)
  (defalias 'eprofile-function 'elp-instrument-function)
  (defalias 'eprofile-list 'elp-instrument-list)
  (defalias 'eprofile-package 'elp-instrument-package)
  (global-set-key [(control c) (shift p) (f)] 'elp-instrument-function)
  (global-set-key [(control c) (shift p) (l)] 'elp-instrument-list)
  (global-set-key [(control c) (shift p) (shift p)] 'elp-instrument-package)
  (global-set-key [(control c) (shift p) (F)] 'elp-reset-function)
  (global-set-key [(control c) (shift p) (L)] 'elp-reset-list)
  (global-set-key [(control c) (shift p) (A)] 'elp-reset-all)
  (global-set-key [(control c) (shift p) (s)] 'elp-results)
  )

;;; ===========================================================================
;;; Auto-Highlight Interactive `rx' evals. (rx "@@")
(defun rx-flash-eval-last-sexp-helper ()
  (let* ((exp (preceding-sexp)))
    (when (and (listp exp)
               (eq 'rx (car exp)))
      (let ((str (ignore-errors (rx-to-string (cadr exp)))))
        (when str                       ;if `rx' evaluation possible
          (mapc (lambda (window)        ;; for each window
                  (let ((buffer (window-buffer window)))
                    (unless (string-equal (buffer-name buffer) "*Messages*")
                      (with-current-buffer buffer
                        (save-excursion
                          (goto-char (window-start window)) ;go to visible part of buffeer
                          (while (re-search-forward str (window-end window) t)
                            (when nil
                              (message "window:%s match:%s point:%s"
                                       window
                                       (list (match-beginning 0)
                                             (match-end 0))
                                       (point)))
                            (hictx-match 0 window 'next-error
                                         (* 4 hictx-eval-timeout)
                                         hictx-eval-timeout ;wait for eval flash to finish
                                         t)
                            (goto-char (match-end 0))))))))
                (window-list)))))))
(defadvice eval-last-sexp (after rx-flash-eval-last-sexp activate)
  (when (called-interactively-p 'any)
    (rx-flash-eval-last-sexp-helper)))
(defadvice pp-eval-last-sexp (after rx-flash-pp-eval-last-sexp activate)
  (when (called-interactively-p 'any)
    (rx-flash-eval-last-sexp-helper)))

;;; ===========================================================================
;;; My Extensions
(eload 'replace-pairs)
(eload 'replace-ext)                   ;My Replace Extensions

(eload 'font-lock-extras)             ;Faces (Fonts)

(eload 'obarray-fns)                  ;obarray-manipulating routines
(eload 'tgrep)                         ;Grep and Locate Utilities

(eload 'vc-and-ediff)                  ;Version Control Systems (VCS) and (E)Diff Integration
(eload 'vc-mode-line)
(eload 'do-on-save) ;Perform Operations (Compile, Load, etc.) upon Saving Buffer

(eload 'memoize)                       ;Memoize Elisp Functions

(eload 'tooltip-utils)                ;My tooltip Utilities.
(eload 'pgo-undo)                      ;Undo and Redo
;; (load-file (elsub "mine/trash-settings.elc"))
;;(eload 'trash-settings (elsub "mine") ;Trash
(eload 'trashcans)                     ;Trash
(eload 'shasum)                        ;SHA-Checksums
(eload 'symbol-face)                   ;Symbol Specific Face
(when (eload 'coolock)                 ;Cool Lock
  (coolock-load-in-specific-modes))
;;(eload 'longlines)                      ;Automatically Wrap 1Long Lines
;;(eload 'pgo-linkd nil t)		;Linkd
(eload 'pgo-window)                    ;Window Operations
(eload 'benchmarks)                    ;Various Key Performance Benchmarks of Emacs Lisp
(eload 'pgo-eldoc)                     ;ELDoc
(eload 'process-utils)                 ;Async Handling of Processes
(eload 'alert-tags)                    ;Alert tags
(eload 'primes)                        ;prime number support for Emacs Lisp library code
(eload 'file-execute)                  ;Eval DWIM
(eload 'file-dwim)                     ;Eval DWIM
(eload 'fill-dwim)                      ;Fill DWIM
(eload 'elisp-utils)                   ;Small useful snippets used in development of Emacs Lisp.
(eload 'tab-utils)                     ;Tab Utils
(eload 'rename-dwim)                    ;Renaming Enhancements
(eload 'kmacro-ext)
(eload 'pgo-ffap)                      ;Find File At Point (ffap).
(eload 'fcache)                        ;File System Attribute (Meta-Data) Cache
(eload 'cscan)                         ;Scan File Contents for String or Regexp. Supports clustered sorting of hits.
(eload 'filedb)                        ;(File System) Metadata Database
(eload 'atags)                        ;Unified Interface to Tags
(when (eload 'tscan)                     ;File System Tree Scan and Operate
  (when (fboundp 'tscan-default-global-keybindings)
    (tscan-default-global-keybindings)))
(when (eload 'ectags)                 ;Interface to Exuberant Ctags
  (ectags-default-global-keybindings))
(when nil
  (when (eload 'gtags)                 ;Interface to GNU GLOBAL
    (when nil
      (add-hook 'gtags-mode-hook
                (lambda()
                  (local-set-key (kbd "M-.") 'gtags-find-tag) ; find a tag, also M-.
                  (local-set-key (kbd "M-,") 'gtags-find-rtag)))) ; reverse tag
    ))
(eload 'context-navigate)             ;Navigate in Contexts

;; http://www.emacswiki.org/emacs-en/IndentingC
(eload 'toggle-file-dwim)              ;Toggle (Source) File
(eload 'complete-dwim)
(eload 'pnw-regexps)                    ;Regular Expressions
(eload 'case-utils)                     ;Case Utilities
(eload 'case-dwim)                      ;Case DWIM
(eload 'file-use-region)
(eload 'file-utils)                     ;File Utilities
(eload 'file-xattr)                     ;File Extended Attributes

;; Disabled because it only does normal shell not eshell.
;; (when (require 'multi-eshell nil t)
;;   (global-set-key [(control c) (shift ?s)] 'multi-eshell))
(defun new-eshell ()
  "Start a new instance of eshell."
  (interactive)
  (eshell t))
(defalias 'eshell-new 'new-eshell)
(global-set-key [(control c) (shift ?s)] 'new-eshell)

;; Shell (Commands)
(eload 'shell-command)
(eload 'bash-completion)
(eload 'shell-command-ext)              ;Shell Command
(when nil
  (eload 'background)             ;Interface to background jobs
  (eload 'shell-command)          ;Shell Command. NOTE: Deprecated by my version
  (global-set-key [(meta \!)] 'shell-command)
  (global-set-key [(meta \#)]
                  (if (fboundp 'async-shell-command)
                      'async-shell-command
                    'background))
  ;; BASH completion for the shell buffer
  (autoload 'bash-completion-dynamic-complete "bash-completion" "BASH completion hook")
  (add-hook 'shell-dynamic-complete-functions
            'bash-completion-dynamic-complete)
  (add-hook 'shell-command-complete-functions
            'bash-completion-dynamic-complete)
  (when (require 'shell-command nil t)
    (shell-command-completion-mode 1))
  (when (require 'shell-command-ext nil t))
  ;; shell-command-extension.el --- Some extension for shell-command
  (when (require 'shell-command-extension nil t))
  ;; shell-command-queue.el --- Queue shell commands for execution
  (when (require 'shell-command-queue nil t))
  (defun shell-here ()
    "Open a shell in `default-directory'."
    (interactive)
    (let ((dir (expand-file-name default-directory))
          (buf (or (get-buffer "*shell*") (shell))))
      (goto-char (point-max))
      (if (not (string-equal (buffer-name) "*shell*"))
          (switch-to-buffer-other-window buf))
      (message list-buffers-directory)
      (if (not (string-equal (expand-file-name list-buffers-directory) dir))
          (progn (comint-send-string (get-buffer-process buf)
                                     (concat "cd \"" dir "\"\r"))
                 (setq list-buffers-directory dir)))))
  )
(add-to-list 'auto-mode-alist '("alt/share/.*/functions" . sh-mode))
(add-to-list 'magic-mode-alist '("\\`#compdef" . sh-mode))
(eload 'pgo-eshell)                   ;EShell
(eload 'pgo-ansi-color)

;;; ===========================================================================
;;; FISH Shell
(when (append-to-load-path (elsub "fish"))
  (autoload 'fish-mode "fish-mode" "fish-mode" t)
  (add-to-list 'auto-mode-alist '("\\.fish\\'" . fish-mode))
  (add-to-list 'interpreter-mode-alist '("fish" . fish-mode)))

;;; ===========================================================================
;;; NeoTree
(when (append-to-load-path (elsub "neotree"))
  (autoload 'neotree "neotree" "File Tree Mode" t))

(add-hook 'neotree-mode-hook 'setup-neotree-dired-keys)

(defun setup-neotree-dired-keys ()
  (let ((map neotree-mode-map))
    (define-key map (kbd "N") 'neotree-create-node)
    ;;(define-key map (kbd "C") 'neotree-copy-node)
    (define-key map (kbd "D") 'neotree-delete-node)
    (define-key map (kbd "R") 'neotree-rename-node)))

;;; ===========================================================================
;;; Shell-mode
(defun sh-mode-setup-pnw ()
  ;; Disable imenu for now because it make editing of large shell scripts slow!
  (setq imenu-generic-expression nil))
(remove-hook 'sh-mode-hook 'sh-mode-setup-pnw)

;;; ===========================================================================
;;; Misc
(autoload 'list-callers "list-callers" "List callers of an Elisp function ." t)
;; (global-set-key [(control c) (meta ?.)] 'list-callers)

;;; ===========================================================================
;;; Dired

;; Async and Concurrency
(defcustom dired-async-use-native-commands nil
  "Use native commands in dired-async."
  :group 'dired-async)
(when nil
  (when (and (append-to-load-path (elsub "emacs-async"))
             (require 'async nil t)
             (require 'async-file nil t))
    (eval-after-load "dired-aux"
      '(require 'dired-async nil t)))
  (when (eload 'deferred))
  (when (eload 'later-do))
  ;; async-eval.el: See: http://nschum.de/src/emacs/async-eval/
  (when (eload 'async-eval)
    (defun async-eval-test ()
      (benchmark 10
                 (async-eval
                  (lambda (result) (message "async result: <%s>" result))
                  (let ((sum 0)
                        (i 10000000))
                    (while (> i 0)
                      (setq sum (+ sum i)
                            i (1- i)))
                    sum))
                 ))
    ;; Use: (async-eval-test)
    ))
;;(eload 'pgo-dired)                    ;Setup dired and its extensions.

;; Activate recursive copies and deletes in dired.
(setq dired-recursive-deletes 'top)   ;prompt for top directories
(setq dired-recursive-copies 'top)    ;prompt for top directories
(defalias 'dired-do-move 'dired-do-rename) ;for naming completeness
(load "dired-x" t)
(defun pnw-dired-hook ()
  "Fix dired-mode."
  (local-unset-key [meta ?b])
  (local-set-key [meta ?b] 'backward-word) ;instead of Drew Adam's `diredp-do-bookmark'.
  (define-key dired-mode-map [meta ?b] 'backward-word) ;instead of Drew Adam's `diredp-do-bookmark'.
  (define-key dired-mode-map [delete] 'dired-do-delete) ;like in Nautilus, Explorer, etc.
  (define-key dired-mode-map [(shift delete)] 'dired-do-delete)
  ;; (define-key dired-mode-map [(?h)] 'dired-do-hardlink)
  (when (eload 'dired-efap)
    (define-key dired-mode-map [?E] 'dired-efap))
  (when (eload 'dired-sort-map)
    (when (fboundp 'dired-sort-on-modification-time)
      (dired-sort-on-modification-time))))
(add-hook 'dired-mode-hook 'pnw-dired-hook t)

;; Async Shell Command as default
(when (and (require 'dired-aux nil t)
           (fboundp 'dired-do-async-shell-command))
  (define-key dired-mode-map [?!] 'dired-do-async-shell-command))
(global-set-key [(meta ?!)] 'async-shell-command)

;;; ===========================================================================
;;; FFAP
;; Steal back find-file-at-point
(global-set-key [(control x) (control j)] 'ffap-other-window)
(add-hook 'after-init-hook (lambda () (global-set-key [(control x) (control j)] 'ffap-other-window)))

;;; ===========================================================================
;;; http://www.emacswiki.org/emacs/FindFileAtPoint#toc6
(defvar ffap-file-at-point-line-number nil
  "Variable to hold line number from the last `ffap-file-at-point' call.")
(defadvice ffap-file-at-point (after ffap-store-line-number activate)
  "Search `ffap-string-at-point' for a line number pattern and
save it in `ffap-file-at-point-line-number' variable."
  (let* ((string (ffap-string-at-point)) ;; string/name definition copied from `ffap-string-at-point'
         (name
          (or (condition-case nil
                  (and (not (string-match "//" string)) ; foo.com://bar
                       (substitute-in-file-name string))
                (error nil))
              string))
         (line-number-string
          (and (string-match ":[0-9]+" name)
               (substring name (1+ (match-beginning 0)) (match-end 0))))
         (line-number
          (and line-number-string
               (string-to-number line-number-string))))
    (if (and line-number (> line-number 0))
        (setq ffap-file-at-point-line-number line-number)
      (setq ffap-file-at-point-line-number nil))))
(defadvice find-file-at-point (after ffap-goto-line-number activate)
  "If `ffap-file-at-point-line-number' is non-nil goto this line."
  (when ffap-file-at-point-line-number
    (goto-line ffap-file-at-point-line-number)
    (setq ffap-file-at-point-line-number nil)))

;; Dired bf-mode
(when (append-to-load-path (elsub "bf-mode"))
  (autoload 'bf-mode "bf-mode" "Browse file persistently on dired" t))

;; Edit Filename At Point

;;; ===========================================================================
;;; ELK Unit-Test. May collide with package `test-simple'.

(add-to-list 'auto-mode-alist '("\\.elk\\'" . elk-test-mode))
(let* ((elk (elsub "elk-test/elk-test.elc")))
  (when (file-regular-p elk)
    (autoload 'elk-test-mode "elk-test" "ELK Test" t))
  (defun elk-test-assert-lock ()
    "Highlight assert symbols defined by `elk-test.el'."
    (font-lock-add-keywords
     nil
     (list
      ;; other operators
      (cons
       (regexp-opt '("assert-eq" "assert-eql" "assert-equal"
                     "assert-error" "assert-nil" "assert-nonnil" "assert-t" "assert-that") t)
       '(1 'font-lock-warning-face keep)))))
  (add-hook 'emacs-lisp-mode-hook 'elk-test-assert-lock))

;;; ===========================================================================
;;; SmallTalk

(autoload 'smalltalk-mode "smalltalk-mode" "SmallTalk" t)
(add-to-list 'auto-mode-alist '("\\.st\\'" . smalltalk-mode))

;; duplicate zip files' setup for star files or fall back on archive-mode, which
;; scans file contents to determine type so is safe to use
(push (cons "\\.star\\'"
	    (catch 'archive-mode
	      (dolist (mode-assoc auto-mode-alist 'archive-mode)
		(and (string-match (car mode-assoc) "Starfile.zip")
		     (functionp (cdr mode-assoc))
		     (throw 'archive-mode (cdr mode-assoc))))))
      auto-mode-alist)
(push "\\.star\\'" inhibit-first-line-modes-suffixes)

;;; ===========================================================================
;;; CC-Mode
(eload 'cc-patterns nil "cc-patterns.el") ;C,C++ Patterns
(eload 'cc-assist nil "cc-assist.el") ;Coding Assistance for C,C++, and others.
(when nil                               ;TODO Disabled for now
  (defun recognize-c-mode ()
    "Detect C file."
    (goto-char (point-min))
    (when nil
      (when (re-search-forward (rx bol (* space)
                                   (| "#ifndef"
                                      "#define"
                                      "#include"
                                      ) symbol-end) nil t)
        (dolist (spec auto-mode-alist) ;TODO How do we distinguish C from C++ here?
          ;; (let ((regexp (car spec))
          ;;       (mode (cdr spec))
          ;;       (when (string-match))
          ;;       ))
          )
        t)))
  (add-to-list 'magic-mode-alist '(recognize-c-mode . c-mode)))
(when nil
  (add-hook 'c-mode-common-hook 'c-guess 1) ;NOTE: Disabled because it fails when replacing regexp in dired
  )
(when (and nil
           (require 'guess-offset nil t))
  (add-hook 'c-mode-common-hook 'guess-offset 1))

(when (eload 'move-line-region)
  (move-line-region-setup-keybindings)
  (move-line-region-activate-hictx-advice)
  )

;;; Graphviz dot
(defun graphviz-mode-fix-keybindings ()
  "Correct keybindings in `graphviz-dot-mode'."
  (when (boundp 'graphviz-dot-mode-map)
    (let ((map graphviz-dot-mode-map))
      (define-key map "\C-c\C-c" 'compile)
      (define-key map "\C-c\C-v" 'graphviz-dot-view)
      (define-key map "\C-c\C-p" 'graphviz-dot-preview)
      )))
(when (append-to-load-path (elsub "graphviz-dot-mode"))
  (add-to-list 'auto-mode-alist '("\\.dot\\'" . graphviz-dot-mode))
  (add-to-list 'auto-mode-alist '("\\.gv\\'" . graphviz-dot-mode))
  (autoload 'graphviz-dot-mode "graphviz-dot-mode" "ELK Test" t)
  (add-hook 'graphviz-dot-mode-hook 'graphviz-mode-fix-keybindings t)
  (defalias 'graphviz-mode 'graphviz-dot-mode)
  (defalias 'dot-mode 'graphviz-dot-mode)
  (defalias 'gv-mode 'graphviz-dot-mode))

;;; Generic Mode
(when (require 'generic-x nil t)
  (setq generic-extras-enable-list t) ;enable all generic modes, in fact!
  (setq auto-mode-alist
        (append '(
                  ("Xresources\\'" . x-resource-generic-mode)
                  ("Xmodmap\\'" . x-resource-generic-mode)
                  ("gtags.conf\\'" . generic-mode)
                  ("^XF86Config.*\\'" . default-generic-mode)
                  ("xorg.conf\\'" . default-generic-mode)
                  ("\\.dir_colors\\'" . default-generic-mode)
                  ("\\.screenrc\\'" . default-generic-mode)
                  ("\\.asoundrc\\'" . conf-mode) ;ALSA Configuration
                  ("\\.xscreensaver\\'" . default-generic-mode)
                  ("\\.fonts.cache-[0-9]+\\'" . default-generic-mode)
                  ("\\.gtkrc.*\\'" . default-generic-mode)
                  ("\\.egg-info\\'" . conf-mode)
                  ("/mnt/*/WINDOWS.*/.*\\.inf\\'" . generic-mode)
                  ("\\.doxygen\\'" . default-generic-mode)
                  ("Doxyfile.tmpl\\'" . makefile-mode)
                  ("Doxyfile\\'" . makefile-mode)
                  ("_defconfig\\'" . sh-mode)
                  ("DIR_COLORS\\'" . default-generic-mode)
                  (".dir_colors\\'" . conf-mode)
                  (".subversion/servers\\'" . conf-mode)
                  ("/.hgignore\\'" . conf-mode)
                  ("/.gitignore\\'" . conf-mode)
                  ("/.gitconfig\\'" . conf-mode)
                  ("/.gitmodules\\'" . conf-mode)
                  ("/.cvsignore\\'" . conf-mode)
                  ("/.bazaar/ignore\\'" . conf-mode)
                  ("/openssl.cnf\\'" . conf-mode) ;ALSA Configuration
                  )
                auto-mode-alist))
  (when nil                ;TODO Enable
    (define-generic-mode
        'foo-mode                         ;; name of the mode to create
      '("!!")                           ;; comments start with '!!'
      '("account" "user"
        "password")                     ;; some keywords
      '(("=" . 'font-lock-operator)     ;; '=' is an operator
        (";" . 'font-lock-builtin))     ;; ';' is a a built-in
      '("\\.foo$")                      ;; files for which to activate this mode
      nil                              ;; other functions to call
      "A mode for foo files"            ;; doc string for this mode
      )))

;;; ===========================================================================
;;; Hungry
(when (eload 'hungry-delete (elsub "hungry-delete"))
  (global-hungry-delete-mode 1)
  (progn
    (add-hook 'lisp-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'emacs-lisp-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'octave-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'python-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'scons-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'bjam-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'sh-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'csharp-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'matlab-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'perl-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'scheme-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'html-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'org-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'makefile-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'autoconf-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'tex-mode-hook 'turn-on-hungry-delete-mode 1)
    (add-hook 'latex-mode-hook 'turn-on-hungry-delete-mode 1)
    )
  )

;;; ===========================================================================
;;; Automation in C-like modes
(defun c-enable-auto-modes ()
 (c-toggle-auto-hungry-state 1)
 (c-toggle-auto-newline 1)
 (c-toggle-hungry-state 1))
(add-hook 'c-mode-common-hook 'c-enable-auto-modes t)

;;; ===========================================================================
;;; Markdown

(defun setup-markdown-hook ()
  "Setup Markdown hook."
  (executable-find-auto-install-on-demand "markdown"))
(when (append-to-load-path (elsub "markdown-mode"))
  (autoload 'markdown-mode "markdown-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
  (add-hook 'markdown-mode-hook 'setup-markdown-hook))

;;; ===========================================================================
;;; OCaml
(when (append-to-load-path (elsub "tuareg"))
  (autoload 'tuareg-mode "tuareg-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.ml[ily]?$" . tuareg-mode))
  (add-to-list 'auto-mode-alist '("\\.topml$" . tuareg-mode))
  )

;;; ===========================================================================
;;; Makefile
(setq auto-mode-alist (append '(("\\.mak\\'" . makefile-mode)
                                ("mydefs.bsp\\'" . makefile-mode) ; VxWorks BSP Defines
                                ("/.deps/.*\.Po\\'" . makefile-mode) ; Automake Dependency File
                                ("^[Mm]akefile[.-]" . makefile-mode)
                                ("Makedefs\\'" . makefile-mode)
                                )
                              auto-mode-alist))

;;; ===========================================================================
;;; CMake
(autoload 'cmake-mode "cmake-mode" nil t)
(add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-mode))
(add-to-list 'auto-mode-alist '("CMakeCache\\.txt\\'" . cmake-mode))
(add-to-list 'auto-mode-alist '("\\.cmake\\'" . cmake-mode))

;;; ===========================================================================
;;; Cook. See: http://miller.emu.id.au/pmiller/software/cook/
(autoload 'cook-mode "cook-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.cook\\'" . cook-mode))

;;; ===========================================================================
;;; Jam Build Tools
(autoload 'bjam-mode "bjam-mode" nil t)
(add-to-list 'auto-mode-alist `(,(regexp-opt (list "Jamfile" "Jamfile.v2" "Jamrules" "Jambase" "Jamroot")) . bjam-mode))
(add-to-list 'auto-mode-alist '("\.jam$" . bjam-mode))

;;; ===========================================================================
;; OpenGL Minor Mode:
;; ToDo: Make this work the way hippie-expand wants
;; it to and add it to the list `hippie-expand-try-functions-list'
;; below.
(add-hook 'c-mode-common-hook
 	  '(lambda ()
             (when (memq major-mode '(c-mode c++-mode objc-mode))
               (cond ((string-match "/\\([Oo]pen\\)?[Gg][Ll]/" ;if OpenGL anywhere in directory path
                                    buffer-file-name)
                      (require 'OpenGL)
                      (OpenGL-minor-mode 1))))))
;;(autoload 'OpenGL-minor-mode "OpenGL" "OpenGL editing utilities." t)
(defun try-complete-OpenGL-symbol (old)
  (interactive)
  (insert (ogl--try-completion old)))

;;; ===========================================================================
;;; GLSL (OpenGL Shading Language)
(when (append-to-load-path (elsub "glsl-mode"))
  (autoload 'glsl-mode "glsl-mode" nil t)
  (add-to-list 'auto-mode-alist '("\\.vert\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.frag\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.vp\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.fp\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.vertex[-_]program\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.fragment[-_]program\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.glsl\\'" . glsl-mode))
  (add-to-list 'auto-mode-alist '("\\.hlsl\\'" . glsl-mode)) ;Direct X
  (add-to-list 'auto-mode-alist '("\\.cg\\'" . glsl-mode))   ;Direct X
  ;;(add-to-list 'auto-mode-alist '("\\.glsl.program\\'" . glsl-mode))
  )

;;; ===========================================================================
;;; nVidia CUDA Programming Mode. See: http://www.emacswiki.org/emacs/CudaMode
(autoload 'cuda-mode "cuda-mode" "Toggle `cuda-mode' mode in this buffer." t)
(add-to-list 'auto-mode-alist '("\\.cu\\'" . cuda-mode))

;;; ===========================================================================
;;; RTF
(autoload 'rtf-mode "rtf-mode" "RTF mode" t)
(add-to-list 'auto-mode-alist '("\\.rtf\\'" . rtf-mode))

;;; ===========================================================================
;;; JavaScript source text. See: http://www.nongnu.org/espresso/
;; http://www.nongnu.org/espresso/
(when nil                          ;moved to ~/ware/emacs/lisp/progmodes/js.el
  (autoload 'espresso-mode "espresso" "Start espresso-mode" t)
  (add-to-list 'auto-mode-alist '("\\.js\\'" . espresso-mode))
  (add-to-list 'auto-mode-alist '("\\.json\\'" . espresso-mode)))

;;; ===========================================================================
;;; Identica
(append-to-load-path (elsub "identica-mode"))
(autoload 'identica "identica-mode" "Start Identica" t)

;;; ===========================================================================
;;; http://www.emacswiki.org/cgi-bin/wiki/BefungeMode
(autoload 'befunge "befunge-mode" "Befunge Interpreter/Debugger" t)
(autoload 'befunge-mode "befunge-mode" "Befunge mode"   t)
(add-to-list 'auto-mode-alist '( "\\.be?f\\'" . befunge-mode))

;;; ===========================================================================
;;; SWIG
(autoload 'swig-mode (elsub "ywb-codes/emacs/site-lisp/contrib/swig-mode.elc"))
(when nil
  (dolist (fn '(swig-enable
                swig-disable))
    (autoload fn "swig-mode-ext" nil nil))
  (autoload 'swig-mode "swig-mode-ext" nil nil))

;;; ===========================================================================
;; Perl
(defun pnw-perl-mode-hook ()
  (when (boundp 'perl-indent-level)
    (setq perl-indent-level 4)))
(add-hook 'perl-mode-hook 'pnw-perl-mode-hook t)

;;; ===========================================================================
;; Scheme
(add-to-list 'auto-mode-alist '("\\.ss\\'" . scheme-mode))
;; program invoked by the run-scheme command
(setq scheme-program-name "umb-scheme")
(setq scheme-working-style 'split-window)
(defun pnw-scheme-mode-hook ()
  (when (boundp 'scheme-mode-map)
    (define-key scheme-mode-map [(meta return)] 'scheme-send-last-sexp))
  (save-excursion                       ;function doesn't affect the cursor
    (cond ((equal scheme-working-style 'split-window)
           (progn
             (split-window-vertically)
             (other-window 1)
             (run-scheme scheme-program-name)
             (other-window 1)))
          ((equal scheme-working-style 'more-frames)
           (if window-system            ;alt. not complete
               (progn
                 (make-frame)
                 (other-frame 1)
                 (run-scheme scheme-program-name)
                 (other-frame 1)))))))
(add-hook 'scheme-mode-hook 'pnw-scheme-mode-hook t)

;;; ===========================================================================
;; Lout text.
(when (append-to-load-path (elsub "lout-mode"))
  (add-to-list 'auto-mode-alist '("\\.lt\\'" . lout-mode)))

;;; ===========================================================================
;; Prolog
(add-to-list 'auto-mode-alist '(".*gprolog.*/.*\\.pl\\'" . prolog-mode))
(if (string-match "GNU Prolog" (shell-command-to-string "gprolog")) ;; Use GNU prolog if it exists.
    (defvar prolog-program-name "gprolog"))

;;; ===========================================================================
;;; Julia
(when (file-readable-p (elsub "others/julia-mode.el"))
  (autoload 'julia-mode "julia-mode" "Major mode for editing Julia code." t)
  (add-to-list 'auto-mode-alist '("\\.jl\\'" . julia-mode)))

;;; ===========================================================================
;;; Octave
(add-to-list 'magic-mode-alist '("\\`[[:space:]]*function" . octave-mode))

;;; ===========================================================================
;;; Modelica
(when (append-to-load-path (elsub "modelica-mode"))
  (autoload 'modelica-mode "modelica-mode" "Modelica Editing Mode" t)
  (add-to-list 'auto-mode-alist '("\\.mo$" . modelica-mode))
  ;; Enable Modelica browsing
  (autoload 'mdc-browse "mdc-browse" "Modelica Class Browsing" t)
  (autoload 'br-mdc "br-mdc" "Modelica Class Browsing" t))

;;; ===========================================================================
;;; Wolfram (Mathematic)
;;; See also: https://github.com/kawabata/wolfram-mode
;;; See also: https://github.com/melton1968/math
(when (append-to-load-path (elsub "wolfram-mode"))
  (autoload 'wolfram-mode "wolfram-mode" nil t)
  (autoload 'run-wolfram "wolfram-mode" nil t)
  ;; (setq wolfram-program "/Applications/Mathematica.app/Contents/MacOS/MathKernel")
  (add-to-list 'auto-mode-alist '("\\.wolf$" . wolfram-mode)))

;;; ===========================================================================
;;; Android: http://www.emacswiki.org/emacs-en/GoogleAndroid. CEDET uses it
(when (append-to-load-path (elsub "android-mode"))
  (autoload 'android-mode "android-mode" "Android Project Management mode." t)
  ;;(add-hook 'dired-mode-hook (lambda () (when (file-directory-p (elsub "android-mode")) (android-mode 1))))
  ;;(add-hook 'find-file-hook (lambda () (when (elsub "android-mode") (android-mode 1))))
  )

;;; ===========================================================================
;;; GObject C
(when (append-to-load-path (elsub "gobject-c-mode"))
  (autoload 'gobject-c-mode "gobject-c-mode" "GObject C source code mode." t)
  (when nil
    (add-hook 'c-mode-hook 'gobject-c-mode)
    (add-hook 'c++-mode-hook 'gobject-c-mode)))

;;; ===========================================================================
;;; Ada
(when t;; (append-to-load-path (elsub "ada-mode"))
  (autoload 'ada-mode "ada-mode" "Major mode for editing Ada code." t)
  (add-to-list 'auto-mode-alist '("\\.ad[abs]\\'" . ada-mode))
  (defun ada-mode-charedit ()
    (when (require 'charedit nil t)
      (charedit-local-set-key ?c 'ada-display-comment 'code)
      (charedit-local-set-key ?i 'ada-if 'code)
      (charedit-local-set-key ?e 'ada-else 'code)
      (charedit-local-set-key ?E 'ada-elsif 'code)
      (charedit-local-set-key ?f 'ada-for-loop 'code)
      (charedit-local-set-key ?w 'ada-while-loop 'code)
      (charedit-local-set-key ?s 'ada-package-spec 'code)
      (charedit-local-set-key ?b 'ada-package-body 'code)
      ))
  (add-hook 'ada-mode-hook 'ada-mode-charedit t))

;;; ===========================================================================
;; Objective-C mode
;;(add-to-list 'auto-mode-alist '("\\.mm?$" . objc-mode))
(add-to-list 'magic-mode-alist '("\\(.\\|\n\\)*\n@implementation" . objc-mode))
(add-to-list 'magic-mode-alist '("\\(.\\|\n\\)*\n@interface" . objc-mode))
(add-to-list 'magic-mode-alist '("\\(.\\|\n\\)*\n@protocol" . objc-mode))

;; The default mode for .h files is c-mode. This works reasonably well for C++
;; headers, although it has incomplete syntax highlighting, but it’s much worse
;; for Objective C, where you get things like parameters not lining up properly
;; by their colons. You can handle this by adding a function to
;; magic-mode-alist, like this:
(defun in-objc-header? ()
  (and (string-equal (file-name-extension buffer-file-name) "h")
       (re-search-forward "@\\<interface\\>"
                          magic-mode-regexp-match-limit t)))
(add-to-list 'magic-mode-alist '(in-objc-header? . objc-mode))

;;; ===========================================================================
;; Swift
(when (append-to-load-path (elsub "swift-mode"))
  (autoload 'swift-mode "swift-mode" "Major mode for editing Apple Mac OS X Swift Code." t)
  (add-to-list 'auto-mode-alist '("\\.swift\\'" . swift-mode)))

;;; ===========================================================================

(defun dscanner-faze (str)
  "Colorize Completion Candidate STR."
  (let* ((entry (split-string str " "))
         (name (car entry))
         (type (cadr entry)))
    (cond ((member type '("f" "m"))
           (faze name 'fun))
          (t
           (faze name 'fun)))))

;;; ===========================================================================
;;; Indentation

;; Automatically indent yanked text if in programming-modes
;; See: http://www.emacswiki.org/emacs-en/AutoIndentation
;; Google Groups: "auto-indent yanks"
;; See: http://groups.google.com/group/gnu.emacs.help/browse_frm/thread/2320016f6b51e3ce/4df62e5af03f5ed1?hl=en&lr=&ie=UTF-8&oe=UTF-8&rnum=1#4df62e5af03f5ed1
;; See: http://lists.gnu.org/archive/html/help-gnu-emacs/2002-11/msg00610.html
(when (eload 'auto-indent-mode
             (elsub "auto-indent-mode"))
  ;; (auto-indent-mode -1)
  )

(require 'yank-indent nil t)
(require 'indent-dwim nil t)

(when (require 'gindent nil t)   ;Emacs Interface to external command GNU indent
  (autoload 'gindent-buffer "gindent" nil t)
  (autoload 'gindent-file "gindent" nil t)
  (autoload 'gindent-region "gindent" nil t))

;;(eload 'casi)                    ;C-like Automatic Style Input: See: smart-operator.el and py-smart-operator.el
;;(eload 'pgo-indent)                     ;Indentation

(defun open-line-and-indent (n)
  (interactive "*p")
  (delete-horizontal-space t)
  (open-line n)
  (indent-according-to-mode))

(global-set-key [(control ?o)] 'open-line-and-indent)
(global-set-key [(control m)] 'newline-and-indent) ;; Automatically indent newline in all modes.

;;; ===========================================================================
;;; http://www.emacswiki.org/emacs-en/SmartTabs
;; (require 'smarttab nil t)

;;; ===========================================================================
;;; Fortran
;;; http://www.emacswiki.org/emacs/AutoIndentation
(add-hook 'f90-mode-hook (lambda () (local-set-key (kbd "RET") 'reindent-then-newline-and-indent)))
(add-to-list 'magic-mode-alist
             `(,(rx bol (* space)
                    (| "REAL" "LOGICAL" "INTEGER")
                    (* space)
                    (+ (in digit))) . fortran-mode))

;;; ===========================================================================
;;; D - http://www.prowiki.org/wiki4d/wiki.cgi?EditorSupport/EmacsDMode
;; Only this version works in latest Emacs: http://www.billbaxter.com/etc/d-mode.el

;; (unless
;;     (require 'd-mode nil t)
;;   (ignore-errors (package-install 'd-mode)))
;;(setq load-path (delete "/home/per/.emacs.d/elpa/d-mode-20130807.32" load-path)) ;TODO Fix for Emacs 24.4
(when (append-to-load-path (elsub "d-mode"))
  (autoload 'd-mode "d-mode" "Major mode for editing D code." t)
  (add-to-list 'auto-mode-alist '("\\.d[i]?\\'" . d-mode))
  (add-to-list 'magic-mode-alist `(,(rx buffer-start "#!"
                                        (| (? "/usr") "/bin/env" (* space)
                                           (? "/usr") "/bin/")
                                        "rdmd") . d-mode))
  (add-hook 'd-mode-hook (lambda ()
                           (require 'dmd-query nil t))))
(defun dscanner-complete ()
  "Use Dscanner to complete at point."
  (interactive)
  (inhibit-messages (save-buffer))
  (let* ((result
          (split-string
           (shell-command-to-string
            (mapconcat 'identity
                       (list "dscanner"
                             "-I"
                             (getenv "DMD_D2_INCLUDE")
                             (concat "--"
                                     (cond ((looking-back (eval `(rx (regexp ,ID) (* space) "." (* space)))) "dot")
                                           ((looking-back (eval `(rx (regexp ,ID) (* space) "(" (* space)))) "paren")
                                           (t "paren"))
                                     "Complete")
                             buffer-file-name
                             (number-to-string (position-bytes (point))))
                       " "))
           "\n"))
         (collection (mapcar 'dscanner-faze
                             (cdddr result)) ;skip first three elements
                     ))
    (insert (completing-read "Completion Member: " collection))))

(defun d-lineup-cascaded-calls (langelem)
  "This is a modified variant of `c-lineup-cascaded-calls'
function for the D programming language which accounts for
optional parenthesis and compile-time parameters in function
calls."

  (if (and (eq (c-langelem-sym langelem) 'arglist-cont-nonempty)
           (not (eq (c-langelem-2nd-pos c-syntactic-element)
                    (c-most-enclosing-brace (c-parse-state)))))
      ;; The innermost open paren is not our one, so don't do
      ;; anything.  This can occur for arglist-cont-nonempty with
      ;; nested arglist starts on the same line.
      nil

    (save-excursion
      (back-to-indentation)
      (let ((operator (and (looking-at "->\\|\\.")
                           (regexp-quote (match-string 0))))
            (stmt-start (c-langelem-pos langelem)) col)

        (when (and operator
                   (looking-at operator)
                   (or (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (eq (char-after) ?\()
                        (zerop (c-backward-token-2 2 t stmt-start))
                        (looking-at operator))
                       (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (looking-at operator))
                       (and
                        (zerop (c-backward-token-2 1 t stmt-start))
                        (looking-at operator))
                       )
                   )
          (setq col (current-column))

          (while (or (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (eq (char-after) ?\()
                      (zerop (c-backward-token-2 2 t stmt-start))
                      (looking-at operator))
                     (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (looking-at operator))
                     (and
                      (zerop (c-backward-token-2 1 t stmt-start))
                      (looking-at operator))
                     )
            (setq col (current-column)))

          (vector col))))))

(c-add-style "D"
             '("stroustrup"
               (c-offsets-alist
                (innamespace . -)
                (inline-open . 0)
                (inher-cont . c-lineup-multi-inher)
                (template-args-cont . +)
                (substatement-open . 0)
                (statement-block-intro . +)
                (arglist-cont-nonempty (d-lineup-cascaded-calls
                                        c-lineup-gcc-asm-reg
                                        c-lineup-arglist))
                (statement-cont . d-lineup-cascaded-calls)
                )))
;;; See: https://stackoverflow.com/questions/25797945/adjusting-alignment-rules-for-ucfs-chains-in-d/25843155#25843155
(defun d-turn-on-lineup-cascaded-calls ()
  (add-to-list 'c-offsets-alist '(arglist-cont-nonempty . d-lineup-cascaded-calls))
  (add-to-list 'c-offsets-alist '(statement-cont . d-lineup-cascaded-calls)))
(add-hook 'd-mode-hook 'd-turn-on-lineup-cascaded-calls t)

(defvar ffap-d-path
  (let ((arch (with-temp-buffer
                (when (eq 0 (ignore-errors
                              (call-process "dmd" nil '(t nil) nil
                                            "-print-multiarch")))
                  (goto-char (point-min))
                  (buffer-substring (point) (line-end-position)))))
        (base '("/usr/include" "/usr/local/include")))
    (if (zerop (length arch))
        base
      (append base (list (expand-file-name arch "/usr/include")))))
  "List of directories to search for include files.")

(defun ffap-d-mode (name)
  (ffap-locate-file name t ffap-d-path))

;;; ===========================================================================
;;; DMD C++ Source
(add-to-list 'auto-mode-alist
             '("dmd/src/.*\\.[ch]\\'" . c++-mode))

;;; ===========================================================================

(require 'dmd-compilation-error)
(require 'd-backtrace)

;;; ===========================================================================
;;; Highlight Swedish and C++ template "required from" in non-error.
(when nil                               ;TODO Disturbs?
  (setcdr (assq 'gnu compilation-error-regexp-alist-alist)
          '("^\\(?:[[:alpha:]][-[:alnum:].]+: ?\\|[ 	]+\\(?:in \\|from \\)\\)?\\([0-9]*[^0-9\n]\\(?:[^\n :]\\| [^-/\n]\\|:[^ \n]\\)*?\\): ?\\([0-9]+\\)\\(?:-\\(?4:[0-9]+\\)\\(?:\\.\\(?5:[0-9]+\\)\\)?\\|[.:]\\(?3:[0-9]+\\)\\(?:-\\(?:\\(?4:[0-9]+\\)\\.\\)?\\(?5:[0-9]+\\)\\)?\\)?:\\(?: *\\(\\(?:Future\\|Runtime\\)?[WwVv]arning\\|W:\\)\\| *\\([Ii]nfo\\(?:\\>\\|rmationa?l?\\)\\|I:\\|required from\\|\\|instantiated from\\|[Nn]ote\\|[Aa]nm\\)\\| *[Ee]rror\\|[Ff]el\\|[0-9]?\\(?:[^0-9\n]\\|$\\)\\|[0-9][0-9][0-9]\\)"
            1
            (2 . 4)
            (3 . 5)
            (6 . 7))))

;;; mode line
(when nil        ;TODO Disabled in order for colored flycheck-mode-line to work
  (when (append-to-load-path (elsub "smart-mode-line"))
    (setq sml/theme 'dark)
    (require 'smart-mode-line)
    (sml/setup)
    (add-to-list 'sml/replacer-regexp-list `(,(concat "^/p/avionics-work/develop/users/"
                                                      "\\(" user-login-name "\\)")
                                             ":WS-\\1:"))))

;;; ===========================================================================

;;; This fix prevents group permission problems for byte-compiled files.

(defun copy-file-modes (from-file to-file)
  "Copy `file-modes' from FROM-FILE to TO-FILE."
  (set-file-modes to-file (file-modes from-file)))

(defun adjust-byte-compiled-file-permissions (filename)
  "Adjust file modes of byte-compiled version of FILENAME to
match FILENAME."
  (let ((elc (concat filename "c")))
    (when (file-exists-p elc)
      (copy-file-modes filename elc))))
(defadvice byte-compile-file (after adjust-permissions (filename &optional load))
  (adjust-byte-compiled-file-permissions filename))
(ad-activate 'byte-compile-file)

;;; ===========================================================================
;;; asciidoc
(when (append-to-load-path (elsub "asciidoc-mode"))
  (autoload 'asciidoc-mode "asciidoc-mode" "Major mode for editing D code." t)
  (add-to-list 'auto-mode-alist '("\\.\\(asciidoc\\)\\'" . asciidoc-mode))
  (add-to-list 'auto-mode-alist '("\\.\\(ad\\)\\'" . asciidoc-mode))
  (add-to-list 'auto-mode-alist '("\\.\\(adoc\\)\\'" . asciidoc-mode)))

;;; ===========================================================================
;;; FlyCheck

(defun flycheck-set-repeatable-navigation ()
  (global-set-key [(control f6)] 'flycheck-first-error)
  (global-set-key [(control f7)] 'flycheck-previous-error)
  (global-set-key [(control f8)] 'flycheck-next-error)
  ;; Make navigation repeatable
  (defun flycheck-previous-error-repeatable (&optional n) (interactive) (flycheck-previous-error n))
  (defun flycheck-next-error-repeatable (&optional n) (interactive) (flycheck-next-error n))
  (repeatable-command-advice flycheck-previous-error-repeatable)
  (repeatable-command-advice flycheck-next-error-repeatable)
  (let ((map flycheck-command-map))
    (define-key map "n" 'flycheck-next-error-repeatable)
    (define-key map "p" 'flycheck-previous-error-repeatable)
    map))
(add-hook 'flycheck-mode-hook 'flycheck-set-repeatable-navigation t)

;; Highlight navigation hits
(defadvice flycheck-error-list-previous-error (after ctx-flash-flycheck-previous-error activate)
  (hictx-line (buffer-window flycheck-error-list-source-buffer)
              nil nil hictx-new-window-timeout))
(defadvice flycheck-error-list-next-error (after ctx-flash-flycheck-next-error activate)
  (hictx-line (buffer-window flycheck-error-list-source-buffer)
              nil nil hictx-new-window-timeout))

(defun flycheck-shellcheck-buffer-size-check ()
  (when (> (buffer-size) 100000)
    (add-to-list 'flycheck-disabled-checkers 'sh-shellcheck)))
(add-hook 'flycheck-mode-hook 'flycheck-shellcheck-buffer-size-check t)

(defun flycheck-pylint-configure-messages ()
  "Configure flycheck pylint enabled and disabled messages."
  (when (eq major-mode 'python-mode)
    (setq-default flycheck-pylint-enabled-messages-string nil
                  flycheck-pylint-disabled-messages-string '("C0103" "C0301" "C0302" "C0303" "C0321"
                                                             "R0903" "R0904"
                                                             "R0913" "R0914" "R0915"
                                                             "W0311" "W0511"
                                                             "missing-docstring"
                                                             "invalid-name"
                                                             "unnecessary-semicolon"))))
(add-hook 'flycheck-mode-hook 'flycheck-pylint-configure-messages t)

(defun flycheck-pylint-setup-pythonpath ()
  "Configure flycheck pylint PYTHONPATH."
  (let ((scons-executable (executable-find "scons"))
        (name "PYTHONPATH"))
    (setenv name (concat (uniquify-environment-path-string (getenv name))
                         ":"
                         (expand-file-name
                          "lib/scons"
                          (file-name-directory
                           (directory-file-name
                            (file-name-directory scons-executable))))))))
(add-hook 'flycheck-mode-hook 'flycheck-pylint-setup-pythonpath t)

;;; Note: Disabled for now. Instead put std.cfg in ~/.config/cppcheck
;; (let ((cppcheck (executable-find "cppcheck")))
;;   (setenv "CFGDIR" (expand-file-name "cfg"
;;                                      (file-name-directory
;;                                       (directory-file-name
;;                                        (file-name-directory cppcheck))))))
;; (getenv "CFGDIR")

(defconst flycheck-common-include-path
  (list
   "./public"
   "./include"
   "../public"
   "../include"
   "../../public"
   "../../include")
  "Flycheck include paths common for many languages.")

(defun setup-flycheck-common-stuff ()
  ;; Generic
  (let ((std-path flycheck-common-include-path))
    (setq flycheck-clang-include-path std-path
          flycheck-dmd-include-path (append std-path
                                            '(".."
                                              "../.."
                                              "../../..")) ;DUB examples often import from parents
          flycheck-gcc-include-path std-path
          flycheck-gfortran-include-path std-path
          flycheck-gnat-include-path std-path)

    ;; Set C++ Standard
    (cond ((memq major-mode '(c-mode))
           (setq flycheck-gcc-language-standard "c99"
                 flycheck-clang-language-standard "c99"))
          ((memq major-mode '(c++-mode))
           (setq flycheck-gcc-language-standard "c++11"
                 flycheck-clang-language-standard "c++11"))
          ;; ((memq major-mode '(objc-mode))
          ;;  (setq flycheck-gcc-language-standard "c99"))
          )

    ;; C/C++/Objective-C
    (when (memq major-mode '(c-mode c++-mode objc-mode))
      (when (and buffer-file-name
                 (string-match "/dmd/src/" (file-name-directory
                                            buffer-file-name)))
        (dolist (dir '("root"
                       "tk"
                       "backend"))
          (add-to-list 'flycheck-clang-include-path dir)
          (add-to-list 'flycheck-gcc-include-path dir))
        (when (eq system-type 'gnu/linux)
          ;; TODO Fetch from from "make -B foo.o" when editing foo.c?
          (add-to-list 'flycheck-gcc-definitions "TARGET_LINUX")
          (add-to-list 'flycheck-clang-definitions "TARGET_LINUX"))))

    ;; Ada (GNAT)
    (when (memq major-mode '(ada-mode))
      (let ((cs (trace-file-upwards "." "config_spec.xml")))
        (when cs
          (let* ((top (car cs))
                 (build-root-dir (expand-file-name "build" top))
                 (build-dir (when (and build-root-dir
                                       (file-directory-p build-root-dir))
                              (car (last (directory-files
                                          build-root-dir
                                          t)))))
                 (include-dir (when (and build-dir
                                         (file-directory-p build-dir))
                                (expand-file-name "include" build-dir))))
            (when include-dir
              (setq flycheck-gnat-include-path
                    (append
                     std-path
                     (list (expand-file-name "components" include-dir)
                           (expand-file-name "subsystems" include-dir)))))))))))
(add-hook 'flycheck-before-syntax-check-hook
          'setup-flycheck-common-stuff t)

;; (repeatable-command-advice flycheck-previous-error)
;; (repeatable-command-advice flycheck-next-error)
;; (c-add-style "D" '((c++-indent-level . 4)
;;                    (c-basic-offset . 4)
;;                    (substatement-open . 0)
;;                    (inline-open . 0)))

;;; DCD
(defun launch-dcd-server ()
  "Lauch DCD (D Completion Daemon)."
  (interactive)
  (let ((dmd (executable-find "dmd"))
        (dcd (executable-find "dcd-server")))
    (when (and dmd
               dcd)
      (start-process "DCD" nil dcd
                     (concat "-I" (expand-file-name "~/justd"))
                     (concat "-I" (expand-file-name "src/druntime/import"
                                                    (directory-file-name
                                                     (file-name-directory
                                                      dmd))))
                     (concat "-I" (expand-file-name "src/phobos"
                                                    (directory-file-name
                                                     (file-name-directory
                                                      dmd))))))))
;; (when (executable-find "dcd-client")
;;   (start-process "dcd-set-paths" nil "dcd-client"
;;                  (concat "-I" (expand-file-name "~/justd"))))
;;; https://github.com/atilaneves/ac-dcd
(defun d-mode-setup-dcd ()
  (when (and
         (when (append-to-load-path (elsub "flycheck-dmd-dub"))
           (require 'flycheck-dmd-dub nil t))
         (when (append-to-load-path (elsub "ac-dcd"))
           (require 'ac-dcd nil t)))
    (launch-dcd-server)
    (auto-complete-mode t)
    (yas-minor-mode-on)
    (ac-dcd-maybe-start-server)
    (add-to-list 'ac-sources 'ac-source-dcd)
    (define-key d-mode-map (kbd "C-c ?") 'ac-dcd-show-ddoc-with-buffer)
    (define-key d-mode-map (kbd "C-c .") 'ac-dcd-goto-definition)
    (define-key d-mode-map (kbd "C-c ,") 'ac-dcd-goto-def-pop-marker)
    (when (featurep 'popwin)
      (add-to-list 'popwin:special-display-config
                   `(,ac-dcd-error-buffer-name :noselect t))
      (add-to-list 'popwin:special-display-config
                   `(,ac-dcd-document-buffer-name :position right :width 80)))))
(add-hook 'd-mode-hook 'd-mode-setup-dcd t)

(defun dmd-support-columns (&optional dmd-compiler)
  "Check if installed DMD supports `-vcolumns' flag introduced in
DMD version 2.066."
  (string-match "-vcolumns" (shell-command-to-string "dmd --help")))

(defun d-mode-setup-generic ()
  ;;(add-to-list 'completion-at-point-functions 'dscanner-complete)
  (setq imenu-generic-expression nil)

  (c-set-style "D")
  (c-set-offset 'case-label c-basic-offset) ;fix indentation of switch case labels

  ;; Flycheck D Unittest: https://github.com/tom-tan/flycheck-d-unittest/wiki/Start-D-with-Emacs
  (when (require 'flycheck nil t)
    (flycheck-mode 1))
  (when (dmd-support-columns)
    (flycheck-define-checker d-dmd      ;TODO Integrate this with flycheck.el
      "A D syntax checker using the DMD compiler.

See URL `http://dlang.org/'."
      :command ("dmd" "-vcolumns" "-debug" "-o-"
                "-wi"     ; Compilation will continue even if there are warnings
                (eval (concat "-I" (flycheck-d-base-directory)))
                ;;(option-list "-I" flycheck-dmd-include-path s-prepend)
                (option-list "-I" flycheck-dmd-include-path concat)
                source)
      :error-patterns
      ((error line-start (file-name) "(" line "," column "): Error: " (message) line-end)
       (warning line-start (file-name) "(" line "," column "): "
                (or "Warning"
                    "Deprecation") ": " (message) line-end)
       (info line-start (file-name) "(" line "," column "):        " (message) line-end))
      :modes d-mode))

  ;; (when (and (append-to-load-path (elsub "flycheck-d-unittest"))
  ;;            (require 'flycheck-d-unittest nil t))
  ;;   (setup-flycheck-d-unittest))
  ;; TODO Disabled for now...
  (setq flycheck-checkers
        (delq 'd-dmd-unittest flycheck-checkers))

  (when (require 'ffap nil t)
    (setq ffap-alist
          (append ffap-alist
                  '((d-mode . ffap-d-mode))))))
(add-hook 'd-mode-hook 'd-mode-setup-generic t)

;;; See: http://www.lunaryorn.com/2014/07/30/new-mode-line-support-in-flycheck.html
(setq flycheck-mode-line
      '(:eval
        (pcase flycheck-last-status-change
          (`not-checked nil)
          (`no-checker (propertize " -" 'face 'warning))
          (`running (propertize " ✷" 'face 'success))
          (`errored (propertize " !" 'face 'error))
          (`finished
           (let* ((error-counts (flycheck-count-errors flycheck-current-errors))
                  (no-errors (cdr (assq 'error error-counts)))
                  (no-warnings (cdr (assq 'warning error-counts)))
                  (face (cond (no-errors 'error)
                              (no-warnings 'warning)
                              (t 'success))))
             (propertize (format " %s/%s" (or no-errors 0) (or no-warnings 0))
                         'face face)))
          (`interrupted " -")
          (`suspicious '(propertize " ?" 'face 'warning)))))

;; https://github.com/flycheck/flycheck/issues/302
(when nil                               ;NOTE: Builtin
  (defun flycheck-display-error-messages-unless-error-buffer (errors)
    ;;(message "Here: %s" (get-buffer-window flycheck-error-list-buffer))
    (unless (get-buffer-window flycheck-error-list-buffer)
      (flycheck-display-error-messages errors)))
  (setq flycheck-display-errors-function
        #'flycheck-display-error-messages-unless-error-buffer))
;;(eval-after-load "flycheck" '(add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode))

;; https://github.com/flycheck/flycheck/issues/303
(defun flycheck-error-list-shrink-to-fit ()
  (let ((window (flycheck-get-error-list-window t)))
    (with-selected-window window
      (fit-window-to-buffer window 30))))
(add-hook 'flycheck-error-list-after-refresh-hook 'flycheck-error-list-shrink-to-fit)

(defun fix-flycheck-path ()
  (when (prepend-to-load-path (elsub "flycheck")) ;override flycheck
    (load-file (elsub "flycheck/flycheck.elc"))))
(add-hook 'after-init-hook 'fix-flycheck-path)
(when (require 'flycheck nil t)
  ;; install checkers
  (executable-find-auto-install-on-demand "asciidoc") ;asciidoc-mode-hook
  (executable-find-auto-install-on-demand '("pyflakes" "pylint")) ;python-mode-hook
  (executable-find-auto-install-on-demand '("chktex" "lacheck")) ;LaTeX-mode-hook
  (executable-find-auto-install-on-demand "xmllint" '("libxml2-utils")) ;nxml-mode-hook
  (executable-find-auto-install-on-demand "make")           ;makefile-mode-hook
  (executable-find-auto-install-on-demand "markdown")       ;markdown-mode-hook
  (executable-find-auto-install-on-demand "bash")           ;sh-mode-hook
  (executable-find-auto-install-on-demand '("ghc" "hlint")) ;haskell-mode-hook
  (executable-find-auto-install-on-demand '("clang" "g++")) ;c-mode-hook c++-mode-hook
  (executable-find-auto-install-on-demand "xmlstarlet")     ;latex-mode-hook
  (executable-find-auto-install-on-demand "shellcheck")     ;sh-mode-hook
  ;; (executable-find-auto-install-on-demand "gnat-4.8")       ;ada-mode-hook
  ;; (executable-find-auto-install-on-demand "gnat-4.9")       ;ada-mode-hook

  ;; https://github.com/flycheck/flycheck/issues/303
  (defun display-buffer-window-below-and-shrink (buffer alist)
    (let ((window (or (get-buffer-window buffer)
                      (display-buffer-below-selected buffer alist))))
      (when window
        (message "Here window is %s" window)
        (fit-window-to-buffer window 15)
        ;; (with-selected-window window (enlarge-window (- (frame-height) (window-height))))
        (shrink-window-if-larger-than-buffer window)
        window)))
  ;; (setq display-buffer-alist nil)
  ;; (add-to-list 'display-buffer-alist
  ;;              `(,(rx string-start (eval flycheck-error-list-buffer) string-end)
  ;;                (display-buffer-window-below-and-shrink . ((reusable-frames . t)))))

  (when nil
    (dolist (hook '(c-mode-hook c++-mode-hook objc-mode-hook d-mode-hook
                                ada-mode-hook
                                fortran-mode-hook f90-mode-hook ;; f77-mode-hook
                                asciidoc-mode-hook
                                sh-mode-hook
                                makefile-mode-hook
                                haskell-mode-hook
                                emacs-lisp-mode-hook lisp-mode-hook lisp-interaction-mode-hook
                                TeX-mode-hook LaTeX-mode-hook
                                haskell-mode-hook
                                python-mode-hook
                                maxima-mode-hook
                                ielm-mode-hook
                                nxml-mode-hook))
      (add-hook hook 'flycheck-mode))))

(add-hook 'after-init-hook 'global-flycheck-mode t)

;;; Flycheck Coloring
(when (require 'flycheck-color-mode-line nil t)
  (eval-after-load "flycheck"
    '(add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode)))

;;; Flycheck Flashing
(when (require 'hictx nil t)
  (defadvice flycheck-previous-error (after ctx-flash-flycheck-previous-error activate)
    (hictx-line nil nil hictx-new-window-timeout))
  (ad-activate 'flycheck-previous-error)
  (defadvice flycheck-next-error (after ctx-flash-flycheck-next-error activate)
    (hictx-line nil nil hictx-new-window-timeout))
  (ad-activate 'flycheck-next-error))

;;; ===========================================================================
;;; FlySpell
(when (require 'hictx nil t)
  (defadvice flyspell-goto-next-error (after ctx-flash-flyspell-goto-next-error activate)
    (hictx-line nil nil hictx-new-window-timeout))
  (ad-activate 'flyspell-goto-next-error))

;;; ===========================================================================
;;; C Style
(require 'c-styles nil nil)

;;; ===========================================================================
;;; SASS
(when (append-to-load-path (elsub "scss-mode"))
  (add-to-list 'auto-mode-alist '("\\.scss\\'" . sass-mode)))

;;; ===========================================================================
;;; C#
(when (file-readable-p (elsub "others/csharp-mode.el"))
  (autoload 'csharp-mode "csharp-mode" "Major mode for editing C# (Sharp) code." t)
  (add-to-list 'auto-mode-alist '("\\.cs\\'" . csharp-mode))
  (defun my-csharp-mode-hook ()
    (auto-fill-mode)
    (setq tab-width 4))
  (add-hook 'csharp-mode-hook 'my-csharp-mode-hook t))

;;; ===========================================================================
;;; LLVM
;;(custom-set-variables '(fill-column 80) '(c++-indent-level 2) '(c-basic-offset 2) '(indent-tabs-mode nil))
;; Alternative to setting the global style.  Only files with "llvm" in
;; their names will automatically set to the llvm.org coding style.
(c-add-style "llvm.org" '((fill-column . 80)
                          (c++-indent-level . 2)
                          (c-basic-offset . 2)
                          (indent-tabs-mode . nil)
                          (c-offsets-alist . ((innamespace 0)))))
(defun setup-llvm-c-mode ()
  "Setup LLVM C Settings."
  (when (and buffer-file-name
             (string-match "llvm" buffer-file-name))
    (c-set-style "llvm.org")))
(add-hook 'c-mode-common-hook 'setup-llvm-c-mode)
(autoload 'llvm-mode "llvm-mode" "LLVM Mode" t)
(autoload 'tablegen-mode "tablegen-mode" "Tablegen Mode" t)
(add-to-list 'auto-mode-alist '("\\.ll\\'" . llvm-mode))
(add-to-list 'auto-mode-alist '("\\.td\\'" . tablegen-mode))

;;; Demangle C++ Symbols
(when (append-to-load-path (elsub "demangle-mode"))
  (autoload 'demangle-mode "demangle-mode" nil t)
  (add-hook 'llvm-mode-hook 'demangle-mode))

;;; ===========================================================================
;;; Google Go
(autoload 'go-mode "go-mode" "\
Major mode for editing Go source text.

This provides basic syntax highlighting for keywords, built-ins,
functions, and some types.  It also provides indentation that is
\(almost) identical to gofmt.

\(fn)" t nil)

(add-to-list 'auto-mode-alist (cons "\\.go\\'" (function go-mode)))

;;; ===========================================================================
;;; Clojure: See: http://tapestryjava.blogspot.com/2008/11/getting-started-with-clojure.html
(append-to-load-path (elsub "nrepl"))
(when (append-to-load-path (elsub "clojure-mode"))
  (autoload 'clojure-mode "clojure-mode" "Major mode for editing Clojure code." t)
  (add-to-list 'auto-mode-alist '("\\.clj$" . clojure-mode)))
(when nil
  ;; TODO Make this mode-local only in `clojure-mode'.
  (setq inferior-lisp-program
        (let* ((java-path "java")       ; Path to java implementation
                                        ; Extra command-line options
                                        ; to java.
               (java-options "-Xms100M -Xmx600M")
                                        ; Base directory to Clojure.
                                        ; Change this accordingly.
               (clojure-path "/usr/local/clojure/")
                                        ; The character between
                                        ; elements of your classpath.
               (class-path-delimiter ":")
               (class-path (mapconcat (lambda (s) s)
                                        ; Include all *.jar files in the clojure-path directory
                                      (file-expand-wildcards (concat clojure-path "*.jar"))
                                      class-path-delimiter)))
          (concat java-path
                  " " java-options
                  " -cp " class-path
                  " clojure.lang.Repl"))))

(append-to-load-path (elsub "auto-complete/lib/popup"))
(append-to-load-path (elsub "company"))

;;; auto-complete
(append-to-load-path (elsub "auto-complete"))  ;enough for now
(defun fix-auto-complete-keys ()
  "See also: https://stackoverflow.com/questions/25782419/change-keybinding-for-auto-complete/25783341#25783341"
  ;; (unset-key ac-completing-map [return])
  ;; (when nil (ac-set-trigger-key [(meta return)]))
  (unset-key ac-completing-map (kbd "RET"))
  (unset-key ac-completing-map [return])
  (define-key ac-completing-map [(control return)] 'ac-complete))
(add-hook 'auto-complete-mode-hook 'fix-auto-complete-keys)

(when nil
  (when (eload 'auto-complete (elsub "auto-complete"))
    (eload 'auto-complete-config (elsub "auto-complete-clang"))

    (defun my-ac-config ()
      (setq-default ac-sources '(ac-source-abbrev
                                 ac-source-dictionary
                                 ac-source-words-in-same-mode-buffers))
      (add-hook 'emacs-lisp-mode-hook 'ac-emacs-lisp-mode-setup)
      (add-hook 'ruby-mode-hook 'ac-ruby-mode-setup)
      (add-hook 'css-mode-hook 'ac-css-mode-setup)
      (add-hook 'auto-complete-mode-hook 'ac-common-setup)
      (global-auto-complete-mode 1))
    ;;(my-ac-config)

    (when nil
      (add-to-list 'load-path (concat myoptdir "AC"))
      (add-to-list 'ac-dictionary-directories (concat myoptdir "AC/ac-dict")))

    ;; Auto Complete Clang
    (when nil                         ;NOTE: Disabled because it sucks!
      (when (require 'auto-complete-clang nil t)
        (setq ac-clang-executable clang-command-name
              clang clang-command-name
              ac-auto-start 1
              ac-quick-help-delay 0.5
              clang-completion-suppress-error 't)
        (define-key ac-mode-map [(control return)] 'auto-complete)
        (defun ac-cc-setup ()
          ;; (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources))
          ;; (setq ac-sources (append '(ac-source-semantic ac-source-yasnippet) ac-sources))
          (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources)) (delete-dups ac-sources))
        (add-hook 'c-mode-common-hook 'ac-cc-setup)))
    ))

;;; ===========================================================================
;;; Python
;; Use python-mode.el instead of python.el: https://launchpad.net/python-mode/
;; See: http://www.emacswiki.org/cgi-bin/wiki/PythonMode
;; See: http://www.loveshack.ukfsn.org/emacs/

(defun charedit-add-defs (defs)
  "Add definitions DEFS as list of conses (FUN . CHAR)"
  (dolist (elt defs)
    (let ((fn (car elt))
          (key (cdr elt)))
      (when (fboundp fn)
        (charedit-local-set-key key fn 'code)))))

(when (append-to-load-path (elsub "pdee")))

(defun python-mode-add-charedits ()
  (ignore-errors                        ;TODO Fix this!
    (when (require 'charedit nil t)
      (when nil
        (charedit-add-defs '((py-def . ?d)
                             (py-class . ?c)
                             (py-if . ?i)
                             (py-else . ?e)
                             (py-for . ?f)
                             (py-try/except . ?t)
                             (py-try/finally . ?T)
                             (py-while . ?w)
                             (py-execute-region . ?x))))
      (charedit-add-defs '((python-skeleton-def . ?d)
                           (python-skeleton-define . ?D)
                           (python-skeleton-class . ?c)
                           (python-skeleton--else . ?e)
                           (python-skeleton-try . ?t)
                           (python-skeleton--except . ?x)
                           (python-skeleton--finally . ?F)
                           (python-skeleton-if . ?i)
                           (python-skeleton-for . ?f)
                           (python-skeleton-while . ?w)
                           )))))
;; Use: (python-mode-add-charedits)

;;; https://tkf.github.io/emacs-jedi/latest/
(when nil ;TODO: fails
  (when (require 'jedi nil t)
    (jedi:install-server)
    (add-hook 'python-mode-hook 'jedi:setup)
    ;; (setq jedi:complete-on-dot t)          ; optional
    ))

;;; Pymacs
(when nil                               ;TODO fails
  (when (append-to-load-path (elsub "pymacs"))
    (let ((pymacs-root (elsub "pymacs")))
      (when (append-to-load-path pymacs-root)
        (setq pymacs-load-path `(,pymacs-root))
        (add-to-PATH (expand-file-name pymacs-root) "PYTHONPATH")))
    ;;(progn (eload 'pycomplete) (eload 'pycomplete+))
    (autoload 'pymacs-load "pymacs" nil t)
    (autoload 'pymacs-eval "pymacs" nil t)
    (autoload 'pymacs-apply "pymacs")
    (autoload 'pymacs-call "pymacs")))

(defun pnw-setup-python-mode ()
  (defvar py-mode-map python-mode-map)
  ;;(set-variable 'py-python-command "/usr/bin/python2.5")
  ;;(set-variable 'py-indent-offset 4)
  ;;(set-variable 'py-smart-indentation nil)
  (set-variable 'indent-tabs-mode nil)
  (when (and (append-to-load-path (elsub "pdee/extensions"))
             (require 'highlight-indentation nil t)
             (fboundp' highlight-indentation))
    (highlight-indentation))

  (defun py-next-block ()
    "Go to the next block. Cf. `forward-sexp' for lisp-mode."
    (interactive)
    (when (fboundp 'py-mark-block)
      ;; (py-mark-block nil 't)
      (py-mark-block)
      (back-to-indentation)))
  ;; Pymacs: http://pymacs.progiciels-bpi.ca/

  (when (boundp 'python-mode-map)
    (define-key python-mode-map [(control c) (control x)] 'py-execute-buffer)
    (define-key python-mode-map [(control meta shift ?f)] 'py-next-block)) ;for python-mode.el
  (when (boundp 'python-mode-map)
    (define-key python-mode-map [(control meta shift ?f)] 'py-next-block)) ;for python.el
  (repeatable-command-advice python-indent-shift-right)
  (repeatable-command-advice python-indent-shift-left)
  )
(add-hook 'python-mode-hook 'pnw-setup-python-mode t)

(add-hook 'python-mode-hook 'turn-on-eldoc-mode)

(defun python-mode-setup-keys ()
  (when (and (require 'pymacs nil t)
             (fboundp 'pymacs-eval))
    (define-key python-mode-map "\M-:" 'pymacs-eval))
  ;; In python-mode.el RET is bound to py-newline-and-indent, which
  ;; indents the next line if necessary. In python.el this is bound to
  ;; C-j instead. You can get the previous behavior with this in your
  ;; InitFile:
  (define-key python-mode-map "\C-m" 'newline-and-indent)
  ;;(modify-syntax-entry ?_ "." python-mode-syntax-table)
  (abbrev-mode 1)
  (turn-off-auto-fill))
(add-hook 'python-mode-hook 'python-mode-setup-keys t)

(uniquify-environment-variable "PYTHONPATH")

(when nil
  (append-to-load-path (elsub "python"))
  (defvar py-buffer-name 'nil "Python Buffer name.") ;NOTE: Needed by python-mode.
  (autoload 'python-mode "python-mode" "Python Mode." t)
  (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
  (add-to-list 'interpreter-mode-alist '("python" . python-mode))

  ;; Function
  (defadvice py-beginning-of-def-or-class (after py-beginning-of-def-or-class-ctx-flash activate) (when (called-interactively-p 'any) (hictx-defun-afpt))) (ad-activate 'py-beginning-of-def-or-class)
  (defadvice py-end-of-def-or-class (after py-end-of-def-or-class-ctx-flash activate) (when (called-interactively-p 'any) (hictx-defun-bfpt))) (ad-activate 'py-end-of-def-or-class)
  )

(when nil
  (when (boundp 'python-shell-map)
    (defvar py-shell-map python-shell-map))
  (setf py-shell-map python-shell-map)
  (when (append-to-load-path (elsub "ipython/"))
    (eload 'ipython)
    (eload 'anything-ipython)))

(add-hook 'python-mode-hook 'python-mode-add-charedits t)

;;; ===========================================================================
;;; SCons
(autoload 'scons-mode "scons-mode" "Major mode for SCons SConstruct and SConscript file." t nil)
(add-to-list 'auto-mode-alist `(,(rx (| "SConstruct" "SConscript")) . scons-mode))
(add-to-list 'auto-mode-alist '("\\.scons\\'" . scons-mode))
(when nil       ;TODO Enable in scons-mode
  ;; SCons builds into a 'build' subdir, but we want to find the
  ;; errors in the regular source dir.  So we remove
  ;; build/XXX/YYY/{dbg,final}/ from the filenames.
  (defun process-error-filename (filename)
    (let ((case-fold-search t))
      (let ((f (replace-regexp-in-string
                "[Ss]?[Bb]uild[\\/].*\\(final\\|dbg\\)[^\\/]*[\\/]" "" filename)))
        (cond ((file-exists-p f)
               f)
              (t filename)))))
  ;;(setq compilation-parse-errors-filename-function 'process-error-filename)
  )

;;; ===========================================================================
;;; Tup
(when (file-readable-p (elsub "tup-mode"))
  (autoload 'tup-mode "tup-mode" "Major mode for tup." t nil)
  (add-to-list 'auto-mode-alist '("\\.tup$" . tup-mode))
  (add-to-list 'auto-mode-alist '("Tupfile" . tup-mode))
  (add-to-list 'auto-mode-alist '("tup.config" . tup-mode)))

;;; ===========================================================================
;;; Cobol
(when (file-readable-p (elsub "others/cobol-mode.el"))
  (autoload 'cobol-mode "cobol-mode" "Major mode for Tandem COBOL files." t nil)
  (add-to-list 'auto-mode-alist '("\\.cob\\(?:ol\\)?\\'" . cobol-mode)))

;;; ===========================================================================
;;; Eiffel
(when (file-readable-p (elsub "others/eiffel.el"))
  (autoload 'eiffel-mode "eiffel" "Major mode for Eiffel programs" t)
  (add-to-list 'auto-mode-alist '("\\.e\\'" . eiffel-mode)))

;;; ===========================================================================
;;; Visual Basic
(when (file-readable-p (elsub "others/visual-basic-mode.el"))
  (autoload 'visual-basic-mode "visual-basic-mode" "Visual Basic mode." t) ;Visual Basic Mode
  ;; If you are doing Rhino scripts, add
  (add-to-list 'auto-mode-alist '("\\.\\(frm\\|bas\\|rvb\\|vbs\\)$" . visual-basic-mode))) ;TODO Enable cls (conflicts LaTeX-mode)

;;; ===========================================================================
;;; Lua
(when (append-to-load-path (elsub "lua-mode"))
  (autoload 'lua-mode "lua-mode" "Lua editing mode." t)
  (add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-mode))
  (add-hook 'lua-mode-hook 'hs-minor-mode))

;;; ===========================================================================
;;; Ruby
(defun ruby-interpolate ()
  "In a double quoted string, interpolate."
  (interactive)
  (insert "#")
  (when (and
         (looking-back "\".*")
         (looking-at ".*\""))
    (insert "{}")
    (backward-char 1)))
(when nil
  (add-hook 'ruby-mode-hook
            (lambda ()
              (eload 'rcov-overlay)        ;colorize untested ruby code
              (when (eload 'ruby-electric) ;electric commands editing for ruby files
                (when (fboundp 'ruby-electric-mode)
                  (ruby-electric-mode)))
              (when (eload 'ruby-block) ;highlight matching block
                (when (fboundp 'ruby-block-mode)
                  (ruby-block-mode))
                )
              (when nil ;NOTE: Disabled because it `ruby-block-mode' gets enable everywhere."
                (eload 'ruby-block)
                )
              (when (append-to-load-path (elsub "rvm"))
                (eload 'rvm))           ;an interface to the Eclipse IDE.
              (when (boundp 'ruby-mode-map) (define-key ruby-mode-map (kbd "#") 'ruby-interpolate))
              ;; Ruby Alignment
              (set-alist-slot 'align-rules-list
                              'ruby-hash-string
                              `((regexp . "\\(\\s-*\\)\\(\"[^\"]*\"\\|:[a-zA-Z]*\\)\\(\\s-*\\)=>\\(\\s-*\\)")
                                (group . (1 3 4))
                                (repeat . t)
                                (modes . (ruby-mode)))
                              ))))

;;; ===========================================================================
;;; NXML/XML
;;(eload 'nxml-mode)
;;(when (eload 'xquery-mode))
(progn
  ;;(add-to-list 'auto-mode-alist '("\\.html?\\'" . html-mode)) ;NOTE: Override html-mode
  (add-to-list 'magic-mode-alist
               '("\\`<\\?xml \\(?:.\\|<br/>\\)+?>\\(?:\\|<br/> \\)<!DOCTYPE html " . xml-mode))
  (when nil
    (when (and (eload 'repeatable)
               (require 'rng-valid nil t))
      (when (require 'hictx nil t)
        (defadvice nxml-backward-element (after ctx-flash-nxml-backward-element activate) (when (called-interactively-p 'any) (hictx-c-token-balanced-afpt)))
        (defadvice nxml-forward-element (after ctx-flash-nxml-backward-element activate) (when (called-interactively-p 'any) (hictx-c-token-balanced-bfpt)))
        )
      (repeatable-command-advice rng-previous-error)
      (repeatable-command-advice rng-next-error)
      )))

;;; ===========================================================================
;;; Haskell

(append-to-load-path (elsub "structured-haskell-mode/elisp"))

(prepend-to-load-path (elsub "haskell-mode")) ;;(prepend-to-load-path (elsub "fptools/CONTRIB/haskell-modes/emacs")
(defun haskell-setup-filladapt ()
  "Setup filladapt for Haskell mode."
  (interactive)
  (when (require 'filladapt nil t)
    (when (boundp 'filladapt-token-table)
      (add-to-list 'filladapt-token-table '("-- " haskell-comment)))
    (when (boundp 'filladapt-token-match-table)
      (add-to-list 'filladapt-token-match-table '(haskell-comment haskell-comment)))
    (when (boundp 'filladapt-token-conversion-table)
      (add-to-list 'filladapt-token-conversion-table '(haskell-comment . exact))))
  )
(defun haskell-fix-maps ()
  "Fix keys and menus."
  ;;(define-key-after haskell-mode-map KEY DEFINITION &optional AFTER)
  ;; TODO Add menu-entry for this (inferior-haskell-load-and-run)
  (when (boundp 'haskell-mode-map)
    (let ((map haskell-mode-map))
      (define-key map [?\C-c ?\C-r] 'inferior-haskell-load-and-run)
      (define-key map "\C-ch" 'haskell-hoogle) ;See: http://www.haskell.org/haskellwiki/Hoogle
      (define-key map [(meta ?:)] 'haskell-eval-expression)
      ;;(setq haskell-hoogle-command "hoogle")
      )
    (easy-menu-define haskell-mode-menu haskell-mode-map
      "Menu for the Haskell major mode."
      ;; Suggestions from Pupeno <pupeno@pupeno.com>:
      ;; - choose the underlying interpreter
      ;; - look up docs
      `("Haskell"
        ["Indent line" indent-according-to-mode]
        ["Indent region" indent-region mark-active]
        ["(Un)Comment region" comment-region mark-active]
        "---"
        ["Start interpreter" switch-to-haskell]
        ["Load file" inferior-haskell-load-file]
        ["Load and run file" inferior-haskell-load-and-run]
        "---"
        ["Load tidy core" ghc-core-create-core]
        "---"
        ,(if (default-boundp 'eldoc-documentation-function)
             ["Doc mode" eldoc-mode
              :style toggle :selected (bound-and-true-p eldoc-mode)]
           ["Doc mode" haskell-doc-mode
            :style toggle :selected (and (boundp 'haskell-doc-mode) haskell-doc-mode)])
        ["Customize" (customize-group 'haskell)]
        ))))
(defun haskell-eval-expression (arg)
  "Evaluate Haskell Expression ARG and print value in the echo area."
  (interactive (list
                (let ((def (when (region-active-p)
                             (string-strip (buffer-substring (region-beginning)
                                                             (region-end))))))
                  (read-string (format "Haskell Eval%s: "
                                       (if def (format " (default %s)" def) ""))
                               nil
                               'haskell-eval-expression-history
                               def))))
  (inferior-haskell-send-command (inferior-haskell-process) arg))
(defun pnw-setup-haskell-mode ()
  ;; TODO Add eldoc support for all symbols including operators along with documentation string.a
  ;; Fontify "(i-1,j-1)" in "a!(i-1,j-1)" using font-lock-keywords and sexp-after-point() `subscript' face
  (eldoc-mode 1)
  (when (boundp' haskell-operator-face)
    (setq haskell-operator-face 'font-lock-operator-face))
  ;; Prefer GHC over HUGS.
  (when (boundp' haskell-program-name)
    (setq haskell-program-name (or (when (executable-find "ghci") "ghci")
                                   (when (executable-find "hugs") "hugs \"+.\""))))
  ;; Unicode Overlays
  ;; \see http://haskell.org/ghc/docs/latest/html/users_guide/syntax-extns.html#n-k-partens
  (when (require 'unicode-overlays nil t)
    (add-hook 'haskell-mode-hook 'haskell-unicode))
  (when (boundp' haskell-font-lock-symbols)
    (setq haskell-font-lock-symbols 'unicode))

  (defvar haskell-eval-expression-history nil "HASKELL Expression Evaluation History.")
  (when (require 'desktop nil t)
    (add-to-list 'desktop-globals-to-save 'haskell-eval-expression-history t))

  (require 'inf-haskell nil t)
  (require 'haskell-ghci nil t)
  (require 'haskell-c nil t)
  (when (require 'haskell-doc nil t)
    (turn-on-haskell-doc-mode))
  ;; Indentation
  (when (require 'haskell-indent nil t)
    (turn-on-haskell-indent))
  ;;(turn-on-haskell-simple-indent)
  ;;(turn-on-haskell-simple-indent)
  (haskell-setup-filladapt)
  (haskell-decl-scan-mode 1)
  (when (require 'hs-lint nil t) ;; (hs-lint-mode)
    )
  (when (require 'speedbar nil t)
    (speedbar-add-supported-extension ".hs")
    (speedbar-add-supported-extension ".lhs"))
  (inferior-haskell-send-command (inferior-haskell-process)
                                 ":set -fwarn-incomplete-patterns") ;Warn incomplete patterns.

  ;; (add-hook 'haskell-mode-hook 'haskell-setup-defaults)
  (when nil
    (when (load (elsub "haskell-mode/haskell-site-file")) ;note there
      ;; Editing literate Haskell with LaTeX convention
      (when nil
        (autoload 'haskell-latex-mode "haskell-latex")
        (add-to-list 'auto-mode-alist '("\\.l[gh]s\\'" . haskell-latex-mode))
        )))
  ;; Use `mmm-mode' in literal haskell
  ;; \see http://haskell.org/haskellwiki/Literate_programming#Multi-mode_support_in_Emacs
  (when (require 'mmm-mode nil t)
    (add-hook 'haskell-mode-hook 'my-mmm-mode)
    (mmm-add-classes
     '((literate-haskell-bird
        :submode text-mode
        :front "^[^>]"
        :include-front true
        :back "^>\\|$"
        )
       (literate-haskell-latex
        :submode literate-haskell-mode
        :front "^\\\\begin{code}"
        :front-offset (end-of-line 1)
        :back "^\\\\end{code}"
        :include-back nil
        :back-offset (beginning-of-line -1)
        )))
    (defun my-mmm-mode ()
      ;; go into mmm minor mode when class is given
      (make-local-variable 'mmm-global-mode)
      (when (boundp 'mmm-global-mode)
        (setq mmm-global-mode 'true)))
    (when (boundp 'mmm-submode-decoration-level)
      (setq mmm-submode-decoration-level 0))))
(add-hook 'haskell-mode-hook 'pnw-setup-haskell-mode)
(autoload 'haskell-mode "haskell-mode" "Haskell Mode." t nil)
(autoload 'literate-haskell-mode "haskell-mode" "Haskell Mode." t nil)
(add-to-list 'auto-mode-alist '("\\.\\(?:[gh]s\\|hi\\)\\'" . haskell-mode))
(add-to-list 'auto-mode-alist '("\\.l[gh]s\\'" . literate-haskell-mode))

;;; Disabled
(when nil
  ;; NOTE: This could be useful.
  (when nil
    (add-hook 'python-mode-hook
              (lambda ()
                (set (make-variable-buffer-local
                      'beginning-of-defun-function) ;NOTE: Variable from python-mode.el which is not GNU Emacs standard.
                     'py-beginning-of-def-or-class)
                (setq outline-regexp "def\\|class ")))
    )
  ;; See: http://wiki.python.org/moin/EmacsPythonCompletion
  ;; Several uses are supported:
  ;;   1. hippie-expand support via try-complete-py-complete-symbol, just like the lisp-version, nice for the [S-tab] hungry.
  ;;   2. minibuffer-complete, pressing [M-return] brings up a minibuffer completion of the expression before point, usefull if you want to get an overview of your options.
  ;;   3. pressing [f1] brings up help on a python symbol before point (just what "help(thingy)") gives
  ;;   4. pressing "(" or [f2] tries to parse the preceeding tokens as a funtion or method, and retrieve the signature via the "inspect" module, and messages it to you
  ;;   5. pressing "," shows last signature.
  ;;   6. tries to work for both py-execute-buffer and py-execute-import-or-reload oriented work-styles.
  ;;   TRICK: (4+5) is great for calling functions
  ;;   * string.join
  (when (eload 'py-complete)
    (autoload 'py-complete-init "py-complete")
    ;;(add-hook 'python-mode-hook 'py-complete-init)
    )
  ;; py-indent.el --- Python indentation with annotations
  (when (eload 'py-indent)
    )
  ;; See: http://wiki.github.com/Ignas/pycomplexity
  ;; See: http://en.wikipedia.org/wiki/Cyclomatic_complexity
  (when (eload 'pycomplexity)
    )
  )

;;; gitconfig-mode
(when (append-to-load-path (elsub "gitconfig-mode"))
  (add-to-list 'auto-mode-alist '("\\.gitconfig" . gitconfig-mode)))

;;; Alignment
(autoload 'align-regexp "align" "Align the current region using an ad-hoc rule read from the minibuffer." t)
(autoload 'align-entire "align" "Align the selected region as if it were one alignment section." t)
(global-set-key [(control meta \;)] 'align-regexp)
(global-set-key [(control tab)] 'align-entire)

(when nil
  (autoload 'align-let "align-let" nil t)
  (autoload 'align-let-keybinding "align-let" nil t)
  (add-hook 'lisp-mode-hook 'align-let-keybinding)
  (add-hook 'emacs-lisp-mode-hook 'align-let-keybinding)
  (add-hook 'scheme-mode-hook     'align-let-keybinding)
  ;; Modify C++ Alignment
  (set-alist-slot 'align-rules-list
                  'c-assignment
                  `((regexp . ,(concat "[^-=!^&*+<>/| 	\n]\\(\\s-*[-=!^&*+<>/|]*\\)"
                                       "="
                                       "\\(\\s-*\\)\\([^= 	\n]\\|$\\)"))
                    (group 1 2)
                    (repeat . t)
                    (justify . t)
                    (tab-stop)
                    (modes . align-c++-modes))))

;;; iBuffer: http://www.emacswiki.org/emacs/IbufferMode
;; (add-to-list 'ibuffer-never-show-regexps "^\\*")
;; (when (require 'ibuf-ext nil t)
;;   (add-to-list 'ibuffer-never-show-predicates "^\\*"))
(global-set-key [(control x) (control b)] 'ibuffer)

;;; Regular Expression Builder: http://www.masteringemacs.org/articles/2011/04/12/re-builder-interactive-regexp-builder/
(setq-default reb-re-syntax 'string)
(defun re-builder-choose-syntax ()
  (interactive)
  (setq reb-re-syntax
        (intern (completing-read "Select syntax: "
                                 (mapcar (lambda (el)
                                           (cons (symbol-name el) 1))
                                         '(read string sregex rx))
                                 nil t (symbol-name reb-re-syntax))))
  (message "Press C-c C-q to exit re-builder.")
  (sit-for 2)
  (re-builder))
(global-set-key [(control c) (?r)] 're-builder-choose-syntax)
(defun rx-builder ()
  "Like `re-builder' but for `rx'."
  (interactive)
  (let ((reb-re-syntax 'rx))
    (re-builder)))
;;(when (require 're-builder+ nil t))
(progn (define-key-after menu-bar-tools-menu [re-builder]
         '(menu-item "RE-Builder" re-builder
                     :help "Build and Test Regular Expressions in the current buffer.")
         'spell)
       (define-key-after menu-bar-tools-menu [rx-builder]
         '(menu-item "RX-Builder" rx-builder
                     :help "Build and Test Regular Expressions (in rx format) in the current buffer.")
         're-builder))

;;; Make Customizable
(defcustom completion-ignore-case t "*Non-nil means name completion ignores case." :group 'completion)

;;; Viewer
(defface modeline '((t (:inherit mode-line)))
  "Backwards compatible for old-style face naming needed by viewer."
  :group 'viewer)
(eload 'viewer)

;;; Killing: http://www.emacswiki.org/emacs/BrowseKillRing
;; See: http://www.emacswiki.org/cgi-bin/wiki/AutoIndentation
(defun kill-and-join-forward (&optional arg)
  "If at end of line, join with following; otherwise kill line.
    Deletes whitespace at join."
  (interactive "P")
  (if (and (eolp) (not (bolp)))
      (delete-indentation t)
    (kill-line arg))
  (unless (minibufferp)
    (when (cc-derived-mode-p major-mode)
      (just-one-space))))
;; TODO Disabled because it inserts an annoying extra space when editing
;; (global-set-key [(control k)] 'kill-and-join-forward)
(global-set-key [(control k)] 'kill-line)
(when (fboundp 'icicle-yank-pop-commands)
  (global-set-key [(meta y)] 'icicle-yank-pop-commands))

(when nil
  ;; Interactively insert items from kill-ring:
  ;; M-y and C-y work as usual.  You can also use C-r like in a
  ;; shell. C-v, M-v, C-n and C-p will scroll the view.
  (when (require 'kill-ring-search nil t)
    (global-set-key [(shift meta y)] 'kill-ring-search))
  ;; Interactively insert items from kill-ring
  (when (require 'browse-kill-ring nil t)
    (global-set-key [(control meta shift y)] 'browse-kill-ring) ;easier to use.
    ;;(when (require 'browse-kill-ring+ nil t))
    ;;(browse-kill-ring-default-keybindings)
    )
  ;;(global-set-key [(control c) (y)] (lambda () (interactive) (popup-menu 'yank-menu)))
  (global-set-key [(control c) (y)] 'browse-kill-ring)
  ;; (eload 'anything-show-kill-ring)
  (defun pnw/popup-kill-ring ()
    "Use popup menu to access kill-ring."
    (interactive)
    (popup-menu 'yank-menu))
  ;; TODO Activate this
  ;; (require 'popup-kill-ring nil t)
  )

;;; Evaluate Expressions
(when (and (append-to-load-path (elsub "eval-expr"))
           (eload 'eval-expr))
  (eval-expr-install)
  ;; (eval-expr-uninstall)
  )
;;; Use paredit in Minibuffer
;;; http://stackoverflow.com/questions/2665292/how-can-i-get-paredit-mode-when-doing-eval-expression
(defun conditionally-enable-paredit-mode ()
  "enable paredit-mode during eval-expression"
  (if (memq this-command '(eval-expression
                           pp-eval-expression
                           edebug-eval-expression
                           data-debug-eval-expression
                           icicle-pp-eval-expression))
      (when (fboundp 'paredit-mode)
        (paredit-mode 1)
        (local-set-key [return] 'minibuffer-complete-and-exit) ;override `paredit-newline'
        (local-set-key "<return>" 'minibuffer-complete-and-exit) ;override `paredit-newline'
        )))
(add-hook 'minibuffer-setup-hook 'conditionally-enable-paredit-mode)

;;; Debugging
(add-to-list 'auto-mode-alist '("\\.gdb\\'" . gdb-script-mode))
(setq-default gdb-use-separate-io-buffer t)
(setq-default gdb-many-windows t)
;; BashDB
;; TODO How do I guide bashdb to search the current directory for
;; source files. I thought "-L ." did it, but this is for something
;; else.
(when (require 'bashdb nil t) ;TODO Remove later.
  (setq gud-bashdb-command-name "bashdb ")
  (setq gud-zshdb-command-name "zshdb"))

;;; rocky/emacs-dbgr
(when (append-to-load-path (elsub "emacs-dbgr"))
  ;; TODO Disabled require to speed up startup time: (require 'realgud nil t)
  )

;;; Development Tools
(eload 'file-magic)               ;file/magic code editing commands for Emacs
(ignore-errors (eload 'oprofile-mode))  ;OProfile - http://oprofile.sourceforge.net/  TODO Fix this error
(eload 'gprof-utils)                    ;GProf
(eload 'gprof-mode)                     ;GProf
(eload 'oprofile)                   ;Interface to OProfile
(eload 'strace-mode)                ;Mode (only font-locking) for strace output.
(eload 'valgrind)                   ;Valgrind - http://valgrind.org/

(defun comint-previous-input-dinged (arg)
  (interactive "*p")
  (unless (ignore-errors
            (progn (comint-previous-input arg) t))
    (message "No previous comint history input")
    (ding)))

(defun comint-next-input-dinged (arg)
  (interactive "*p")
  (unless (ignore-errors
            (progn (comint-next-input arg) t))
    (message "No next comint history input")
    (ding)))

(defun comint-fix-previous-next-input ()
  (let ((map comint-mode-map))
    (local-set-key [(meta p)] 'comint-previous-input-dinged)
    (local-set-key [(meta n)] 'comint-next-input-dinged)))

(add-hook 'comint-mode-hook 'comint-fix-previous-next-input) t

;; Display output from the debugged program in a separate buffer.
(defun pnw-gud-setup-hook ()
  ;; Browse history with up and down key.
  (local-set-key [up] 'comint-previous-input)
  (local-set-key [down] 'comint-next-input)
  ;;(gdb-display-threads-buffer) ;automatically display buffer listing all threads of process
  ;; (shrink-window-if-larger-than-buffer
  ;;                 (get-buffer-window (gdb-get-buffer 'gdb-threads-buffer)))

  (progn
    (unless (fboundp 'gud-up-dwim) (defun gud-up-dwim (arg) (interactive "p") (gud-up arg)))
    (unless (fboundp 'gud-down-dwim) (defun gud-down-dwim (arg) (interactive "p") (gud-down arg)))
    (unless (fboundp 'gud-finish-dwim) (defun gud-finish-dwim (arg) (interactive "p") (gud-finish arg)))
    (unless (fboundp 'gud-next-dwim) (defun gud-next-dwim (arg) (interactive "p") (gud-next arg)))
    (unless (fboundp 'gud-step-dwim) (defun gud-step-dwim (arg) (interactive "p") (gud-step arg)))
    (unless (fboundp 'gud-cont-dwim) (defun gud-cont-dwim (arg) (interactive "p") (gud-cont arg)))
    (unless (fboundp 'gud-until-dwim) (defun gud-until-dwim (arg) (interactive "p")
                                             (unless (fboundp 'gud-until)
                                               (gud-until arg))))

    (global-set-key [(meta ?g) (?<)] 'gud-up-dwim)
    (global-set-key [(meta ?g) (?>)] 'gud-down-dwim)
    (global-set-key [(meta ?g) (up)] 'gud-up-dwim)
    (global-set-key [(meta ?g) (down)] 'gud-down-dwim)
    (global-set-key [(meta ?g) (right)] 'gud-next-dwim)
    (global-set-key [(meta ?g) (?f)] 'gud-finish-dwim)
    (global-set-key [(control ?x) (control ?a) (control ?f)] 'gud-finish-dwim)
    (global-set-key [(meta ?g) (?u)] 'gud-until-dwim)
    (global-set-key [(meta ?g) (meta ?<)] 'gud-up-dwim)
    (global-set-key [(meta ?g) (meta ?>)] 'gud-down-dwim)
    (global-set-key [(meta ?g) (meta up)] 'gud-up-dwim)
    (global-set-key [(meta ?g) (meta down)] 'gud-down-dwim)
    (global-set-key [(meta ?g) (meta right)] 'gud-next-dwim)
    (global-set-key [(meta ?g) (meta ?f)] 'gud-finish-dwim)
    (global-set-key [(meta ?g) (meta ?u)] 'gud-until-dwim)

    ;;(gdb-get-buffer 'gdb-stack-buffer)
    ;;(gdb-get-buffer 'gdb-partial-output-buffer)
    (when (require 'hictx nil t)
      (defun hictx-line-gdb-source ()
        (hictx-line (when (boundp 'gdb-source-window) gdb-source-window)))
      (defun hictx-line-gdb-stack-buffer ()
        (when (fboundp 'gdb-get-buffer)
          (let ((stack-buffer (gdb-get-buffer 'gdb-stack-buffer)))
            (when stack-buffer
              (let ((win (get-buffer-window stack-buffer)))
                (when win
                  (hictx-line win)))))))
      (defadvice gdb-frame-handler (after gdb-frame-handler-ctx-flash activate) (hictx-line-gdb-source)) (ad-activate 'gdb-frame-handler)
      (defadvice gdb-goto-breakpoint (after gdb-goto-breakpoint-ctx-flash activate) (hictx-line-gdb-source)) (ad-activate 'gdb-goto-breakpoint)
      (defadvice gud-up (after gud-up-ctx-flash activate) (hictx-line-gdb-stack-buffer)) (ad-activate 'gud-up)
      (defadvice gud-down (after gud-down-ctx-flash activate) (hictx-line-gdb-stack-buffer)) (ad-activate 'gud-down)
      (defadvice gud-up-dwim (after gud-up-dwim-ctx-flash activate) (hictx-line-gdb-stack-buffer)) (ad-activate 'gud-up-dwim)
      (defadvice gud-down-dwim (after gud-down-dwim-ctx-flash activate) (hictx-line-gdb-stack-buffer)) (ad-activate 'gud-down-dwim)
      (defadvice gdb-display-source-buffer (after gdb-display-source-buffer-ctx-flash activate) (hictx-line ad-return-value)) (ad-activate 'gdb-display-source-buffer)
      )
    (when nil                           ;Note: Disabled. Cannot use repeatable on these bindings
      (when (eload 'repeatable)
        (repeatable-command-advice gud-up-dwim)
        (repeatable-command-advice gud-down-dwim)
        (repeatable-command-advice gud-finish-dwim)
        (repeatable-command-advice gud-next-dwim)
        (repeatable-command-advice gud-step-dwim)
        (repeatable-command-advice gud-cont-dwim)
        )))
  (define-key global-map [(control x) (control a) (control return )] 'gdb-restore-windows)
  (define-key global-map [(meta g) (meta return )] 'gdb-restore-windows)
  (define-key global-map [(meta g) (return )] 'gdb-restore-windows)
  )
(add-hook 'gud-mode-hook 'pnw-gud-setup-hook)

;;; Comments
(defun c-adjust-comments ()
  (setq comment-start "/*"
        comment-end "*/"))
(add-hook 'c-mode-hook 'c-adjust-comments)
(add-hook 'c++-mode-hook 'c-adjust-comments)
(add-hook 'd-mode-hook 'c-adjust-comments)
(add-hook 'flex-mode-hook 'c-adjust-comments)
;;(eload 'c-comment-edit)             ;Edit C comments
(eload 'comment-dwim nil "comment-dwim.el")
(global-set-key [(control c) (\;)] 'comment-region)
(global-set-key [(control c) (meta \;)] 'uncomment-region)
(add-hook 'lisp-mode-hook (lambda () (local-set-key [(control c) (\;)] 'comment-region)))
(add-hook 'emacs-lisp-mode-hook (lambda () (local-set-key [(control c) (meta \;)] 'comment-region)))
(add-hook 'sh-mode-hook (lambda ()
                          ;; override shell mode case statement template insertion
                          (local-set-key [(control c) (\;)] 'comment-region)
                          (local-set-key [(control c) (meta \;)] 'uncomment-region)
                          ))

;;; YASnippet
(when (eload 'yasnippet (elsub "yasnippet"))
  (yas-global-mode -1)                  ;disable for now because steals completion key
  )
;; (eload 'pgo-yasnippet)

;;; Process Management
;;(eload 'etop)                ;run "top" to display information about processes
;;(eload 'top-mode)            ;run "top" from emacs
;;(autoload 'vkill "vkill" "view and kill Unix processes from within Emacs" t)
;;(autoload 'list-unix-processes "vkill" "view and kill Unix processes from within Emacs" t)
;;(global-set-key [(control c) (k)] 'vkill)
;; operate on system processes like dired
(defun proced-dwim (&optional arg)
  (interactive "P")
  (let (split-height-threshold)
    (proced arg)))
(global-set-key [(control c) (p)] 'proced-dwim)
(defalias 'process-editor 'proced-dwim)
(defalias 'ps 'proced-dwim)

;;; Character Edit Do What I Mean (DWIM)
(when (eload 'charedit (elsub "mine"))
  (charedit-setup-map)
  (charedit-add-hooks))

;;; IEdit
(eload 'iedit-dwim)

;;; Multiple Cursors
(when (append-to-load-path (elsub "multiple-cursors"))
  (eload 'multiple-cursors)
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
  )

;;; Changelogs
(add-to-list 'auto-mode-alist '("$changelog\..*\..gz\\'" . change-log-mode))
(add-to-list 'auto-mode-alist '("$changelog[0-9]*" . change-log-mode))

;;; crontab
(autoload 'crontab-mode "crontab-mode" "Mode for editing crontab files." t)
(add-to-list 'auto-mode-alist '("\\.cron\\(tab\\)?\\'" . crontab-mode))
(add-to-list 'auto-mode-alist '("$cron\\(tab\\)?" . crontab-mode))

;;; Mode for editing TVA SP PARDEF configuration files
(autoload 'pardef-mode "pardef-mode" "Mode for editing pardef files." t)
(add-to-list 'auto-mode-alist '("\\.SA\\'" . pardef-mode))

;;; C
(add-to-list 'auto-mode-alist '("\\.S[ch]\\'" . c-mode)) ;C Mode for SWARC code
(add-to-list 'auto-mode-alist '("$config.h.in\\'" . c-mode)) ;C Mode for config.h.in

;;; Rust
(autoload 'rust-mode "rust-mode" "Major mode for Rust code." t)
(add-to-list 'auto-mode-alist '("\\.rs$" . rust-mode))

;;; Auto-(De)Compression
(when (require 'jka-compr nil t)      ;Handle compressed files transparently
  (auto-compression-mode 1))

;; arc-lzh-exe.el --- archive-mode support for LHa self-extracting .exe's.
;; See: http://user42.tuxfamily.org/arc-lzh-exe/index.html
(when (autoload 'archive-lzh-exe-mode-maybe "arc-lzh-exe" nil t)
  (add-to-list 'auto-mode-alist '("\\.exe\\'" . archive-lzh-exe-mode-maybe))
  (modify-coding-system-alist 'file "\\.exe\\'" 'no-conversion)
  )

;;; Expand
(eload 'pgo-hippie-expand)

;;; Repetition Detection
;; (when (eload 'keyolution)
;;   ;; (turn-off-keyolution)
;;   ;; (turn-on-keyolution))
;;(when (eload 'loops))        ;detect loops in lists
(when (eload 'repdet)               ;Detects Repetition in user activity
  ;; (turn-on-repdet)
  ;; (turn-off-repdet)
  (global-set-key [(meta shift f10)]
                  (lambda () (interactive)
                    (message "%d" (length repdet-input-event-list))))
  (global-set-key [(meta shift f11)] 'repdet-use-as-macro)
  (global-set-key [(meta shift f12)] 'call-last-kbd-macro)
  (global-set-key [(meta shift f5)] 'turn-on-repdet)
  (global-set-key [(meta shift f6)] 'turn-off-repdet)
  )

;;; EMMS: Emacs Multimedia System
(when (append-to-load-path (elsub "emms/lisp"))
  (when (eload 'emms-setup)
    (ignore-errors (emms-all)) ;standard stable featuresd
    ;;(emms-standard)                       ;standard
    (emms-default-players)
    (emms-default-players)
    (eload 'emms-mode-line-icon)
    (setq emms-source-file-default-directory "~/Music/")
    (setq emms-player-mpg321-parameters '("-o" "alsa"))
    ;; Music Player Daemon (MPD)
    (when (require 'emms-player-mpd nil t)
      (setq emms-player-mpd-server-name "localhost")
      (setq emms-player-mpd-server-port "6600")
      (add-to-list 'emms-info-functions 'emms-info-mpd)
      (add-to-list 'emms-player-list 'emms-player-mpd)
      )
    (load-file-if-exist (elsub "emms-get-lyrics.elc"))
    ;; Add music file to playlist on '!', --lgfang
    (when (boundp 'dired-guess-shell-alist-user)
      (add-to-list 'dired-guess-shell-alist-user
                   (list "\\.\\(flac\\|mp3\\|ogg\\|wav\\)\\'"
                         '(if (y-or-n-p "Add to emms playlist? ")
                              (progn (emms-add-file (dired-get-filename))
                                     (keyboard-quit))
                            "mplayer"))))
    (global-set-key [(XF86AudioNext)] 'emms-next)
    (global-set-key [(XF86AudioPrev)] 'emms-previous)
    (global-set-key [(XF86AudioStop)] 'emms-playlist-mode-go)
    (global-set-key [(control XF86AudioStop)] 'emms-smart-browse)
    (global-set-key [(XF86AudioPause)] 'emms-pause)
    ))
;; TODO WARNING: WARNING: This crashes my Emacs a lot!
(when nil
  (eload 'mode-line-frame))         ;Create information frame like mode-line^

;;; Version Control
(when (append-to-load-path (elsub "git-gutter"))
  (eload 'git-gutter)
  ;; (when (string-equal (system-name) "lappis")
  ;;   (global-git-gutter-mode 1)
  ;;   )
  )

;;; Git/Magit
(when (append-to-load-path (elsub "magit"))
  (autoload 'magit-status "magit" "Magit Status.")
  (autoload 'magit-push "magit")
  (defalias 'vc-push 'magit-push)
  (global-set-key [(control x) (G)] 'magit-push))
(when (append-to-load-path (elsub "git-modes")))
(when (append-to-load-path (elsub "magit-log-edit")))
(when (append-to-load-path (elsub "org-magit")))
(when (append-to-load-path (elsub "pcache")))
(when (append-to-load-path (elsub "logito")))
(when (append-to-load-path (elsub "sigma-gh")))
(when (append-to-load-path (elsub "magit-gh-pulls")))
(when (append-to-load-path (elsub "magit-filenotify"))
  (add-hook 'magit-mode 'magit-filenotify-mode))
;; (when (append-to-load-path (elsub "magit-tramp"));; NOTE: Disabled because it replaces magit.el
;;   )

(require 'esh-util)                     ;to get `eshell-host-names'
(defun my-shell-mode-hook ()
  (local-set-key [(tab)] 'completion-at-point)
  (ansi-color-for-comint-mode-on))
(add-hook 'shell-mode-hook 'my-shell-mode-hook)

;;; Minimap
(when (append-to-load-path (elsub "minimap"))
  (autoload 'minimap-mode "minimap"
    "Minimap sidebar a la Sublime Text. http://www.emacswiki.org/emacs-en/MiniMap" t))

;;; TeX, LaTeX AUCTeX
(defun my-TeX-mode-hook ()
  ;; (local-set-key [f8] 'TeX-next-error)
  ;; (local-set-key [f9] 'TeX-command-master)
  ;; (local-set-key [f10] 'TeX-view)
  ;; (local-set-key [f9] 'tex-buffer)
  ;; (local-set-key [f10] 'tex-view)
  (TeX-PDF-mode 1)
  (when (boundp 'LaTeX-mode-map)
    (define-key LaTeX-mode-map "\C-c\C-t\C-x" 'TeX-toggle-shell-escape))
  )
(add-hook 'TeX-mode-hook 'my-TeX-mode-hook t)
(add-hook 'LaTeX-mode-hook 'auto-fill-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(add-hook 'LaTeX-mode-hook 'my-TeX-mode-hook t)
(when (append-to-load-path (elsub "cdlatex"))
  (autoload 'cdlatex-mode "cdlatex" "CDLaTeX Mode" t)
  (autoload 'turn-on-cdlatex "cdlatex" "CDLaTeX Mode" nil)
  (add-hook 'LaTeX-mode-hook 'turn-on-cdlatex) ; with AUCTeX LaTeX mode
  (add-hook 'latex-mode-hook 'turn-on-cdlatex))

(when nil                               ;TODO Disabled. Do we really need this?
  (when (require 'goto-chg nil t)
    (defadvice goto-last-change (after ctx-flash-highlight-symbol-prev activate) (hictx-line)) (ad-activate 'goto-last-change)
    (global-set-key [(control .)] 'goto-last-change)))

(defadvice LaTeX-env-item (around LaTeX-env-item-region activate)
  "When there is an active region, wrap the environment around it.
Insert \\item macros at the beginning of every non empty line of the region.
See: https://tex.stackexchange.com/questions/161717/all-lines-itemized-when-mark-is-active"
  (let ((beg (min (point) (mark))))
    (if (< (point) (mark))
        (exchange-point-and-mark))
    (save-excursion
      (while (re-search-backward "^\\(.+\\)$" beg t)
        (replace-match "\\\\item \\1" t nil)
        (beginning-of-line 1))))
  ad-do-it
  ;; Remove the extra \item.
  (re-search-forward "\\\\item " (save-excursion (end-of-line)) t)
  (replace-match ""))

(when (and (append-to-load-path (elsub "auctex")))
  (when (append-to-load-path (elsub "auctex/preview"))
    (eload 'preview)) ;now included in AUCTex. Previously named preview-latex.el.

  (eload 'texlabel)          ;auto insertion of equation labels in TeX
  (eload 'latex-units)       ;add a Units sub-menu to auctex's math-mode's menu.

  (add-to-list 'auto-mode-alist '("\\.tikz\\'" . latex-mode))
  (add-to-list 'auto-mode-alist '("\\.pgf\\'" . latex-mode))

  ;; To edit LaTeX documents, you will probably want this
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  (setq-default TeX-save-query nil) ;;autosave before compiling

  ;; LaTeX Shell Escaping. See: http://old.nabble.com/shell-escape-td1076639.html
  ;; LaTeX package `minted' requires external shell calls to syntax highlighter
  ;; python-fragments.
  (setq LaTeX-command "latex -shell-escape")
  (defun TeX-toggle-shell-escape ()
    (interactive)
    (setq LaTeX-command (when (and (boundp 'LaTeX-command)
                                   (string-equal LaTeX-command "latex"))
                          "latex -shell-escape" "latex")))
  )

;;; Put this to override `icicle-yank-maybe-completing'
(eload 'slick-edit)          ;Quick Single-Line Kill and Yank used in SlickEdit.

;;; emacsclient -e "(show-frame)"
(defun show-frame (&optional frame)
  "Show the current Emacs frame or the FRAME given as argument.
And make sure that it really shows up!"
  (raise-frame)
  ; yes, you have to call this twice. Don’t ask me why…
  ; select-frame-set-input-focus calls x-focus-frame and does a bit of
  ; additional magic.
  (select-frame-set-input-focus (selected-frame))
  (select-frame-set-input-focus (selected-frame)))

;;; Webjump
(when (require 'webjump nil t)
  (global-set-key [(control c) (j)] 'webjump)
  (global-set-key [(control x) (w)] 'webjump)
  (setq webjump-sites
        (delete-dups
         (append '(
                   ("Reddit Search" .
                    [simple-query "www.reddit.com" "http://www.reddit.com/search?q=" ""])
                   ("Google Image Search" .
                    [simple-query "images.google.com" "images.google.com/images?hl=en&q=" ""])
                   ("Flickr Search" .
                    [simple-query "www.flickr.com" "flickr.com/search/?q=" ""])
                   ("Astar algorithm" .
                    "http://www.heyes-jones.com/astar")
                   ("stackoverflow" .
                    [simple-query "stackoverflow.com" "http://stackoverflow.com/search?q=" ""])
                   ("eHow" .
                    [simple-query "ehow.com" "http://ehow.com/search.html?q=" ""])
                   ("Personal Packages Archives (PPAs)" .
                    [simple-query "launchpad.net" "https://launchpad.net/ubuntu/+ppas?name_filter=" ""])
                   ("Wikibooks" .
                    [simple-query "en.wikibooks.org" "http://en.wikibooks.org/w/index.php?search=" ""])
                   ("Videolectures" .
                    [simple-query "videolectures.net" "http://videolectures.net/site/search/?q=" ""])
                   ("Ask Ubuntu" .
                    [simple-query "askubuntu.com" "http://askubuntu.com/search?q=" ""])
                   ("Mathematics" .
                    [simple-query "math.stackexchange.com/" "http://math.stackexchange.com/search?q=" ""])
                   ("Facebook" .
                    [simple-query "facebook.com" "http://www.facebook.com/search.php?q=" ""])
                   ("Super User" .
                    [simple-query "superuser.com" "http://superuser.com/search?q=" ""])
                   ("TeX - LaTeX" .
                    [simple-query "tex.stackexchange.com" "http://tex.stackexchange.com/search?q=" ""])
                   )
                 webjump-sample-sites))))

;;; Saving
(when (require 'saveplace nil t) (setq-default save-place nil save-place-file "~/.emacs.d/places")) ;TODO Disabled in favor of `desktop'.
(when nil (when (require 'session nil t) (add-hook 'after-init-hook 'session-initialize))) ;NOTE: Disabled in favour of `desktop'.
;;; Desktop
(when t
  ;; session.el may have changed this
  (desktop-save-mode 1) ;; save the desktop file automatically if it already exists

  (when (require 'frame-restore) ;save/restore frame size & position at shutdown/startup
    )

  (when (require 'desktop-frame)        ;save window configuration within frame
    )

  ;; See: http://www.emacswiki.org/emacs/DeskTop#toc2
  (progn
    (add-to-list 'desktop-modes-not-to-save 'dired-mode)
    (add-to-list 'desktop-modes-not-to-save 'Info-mode)
    (add-to-list 'desktop-modes-not-to-save 'info-lookup-mode)
    (add-to-list 'desktop-modes-not-to-save 'fundamental-mode)
    (add-to-list 'desktop-modes-not-to-save 'magit-mode))
  (setq desktop-buffers-not-to-save
        (concat "\\("
                "\\`\\*vc-dir\\*\\|"
                "\\` \\|"               ;starting with space
                "\\`/p/avionics-\\|" ;slow NFS
                "^nn\\.a[0-9]+\\|\\.log\\|(ftp)\\|^tags\\|^TAGS"
                "\\|\\.emacs.*\\|\\.diary\\|\\.newsrc-dribble\\|\\.bbdb"
	        "\\)$"))

  ;; See: http://www.emacswiki.org/emacs/DeskTop#toc4
  ;; TODO This doesn't work as expected.
  (defun emacs-process-p (pid)
    "If pid is the process ID of an emacs process, return t, else nil.
Also returns nil if pid is nil."
    (when pid
      (let ((attributes (process-attributes pid)) (cmd))
        (dolist (attr attributes)
          (if (string= "comm" (car attr))
              (setq cmd (cdr attr))))
        (if (and cmd (or (string= "emacs" cmd) (string= "emacs.exe" cmd))) t))))
  (defadvice desktop-owner (after pry-from-cold-dead-hands activate)
    "Don't allow dead emacsen to own the desktop file."
    (when (not (emacs-process-p ad-return-value))
      (setq ad-return-value nil)))

  (setq desktop-save 'ask               ;always ask before saving desktop
        desktop-dirname (expand-file-name "~/.emacs.d/")
        desktop-base-file-name "desktop"
        desktop-base-lock-name "desktop.lock")
  (setq desktop-globals-to-save
        (add-list-members
            (delete-list-members desktop-globals-to-save
              'regexp-search-ring
              'regexp-history
              'search-ring
              'file-name-history
              'buffer-name-history)

          '(buffer-name-history . 200)
          '(file-name-history . 500)

          'setenv-history
          'vc-git-history

          'coding-system-history

          'find-args-history
          'grep-history 'grep-regexp-history
          'locate-history-list

          ;; tag histories
          'bookmarkp-tag-history
          'find-tag-history
          'gtags-history-list
          'org-ctags-find-tag-history
          'org-tags-history

          '(kill-ring . 50)
          '(compile-history . 200)
          '(minibuffer-history . 200)
          '(regexp-history . 200)
          '(read-expression-history  . 200)
          '(search-ring . 200)
          '(regexp-search-ring . 200)
          '(query-replace-history . 200)
          '(regexp-history . 200)
          'kmacro-ring             ;macros are often time-consuming => unlimited
          'register-alist

          'Info-search-history

          '(command-history . 500)
          'extended-command-history
          'shell-command-history
          'dired-shell-command-history ;; TODO join with shell-command-history

          'tags-table-list
          'tags-file-name
          'desktop-missing-file-warning
          'eshell-host-names

          ;; NOTE: Windows are not printables so no need to remember
          ;; `winner-ring-alist'. We could refer to windows by the
          ;; buffers the display but this has not been implemented yet.
          ;; (winner-ring-alist . 100)

          '(mark-ring . 200)
          '(global-mark-ring . 200)
          ;;(senator-tag-ring . 200) ;TODO This fails

          '(semantic-bookmark-ring . 200)

          ;; NOTE: Skip `semantic-mru-bookmark-ring' because it takes an awful lot of space.
          ;; (semantic-mru-bookmark-ring . 200)
          ))

  (when nil
    ;; Add proper semantic/ecb support for their minor modes
    (when (boundp 'desktop-minor-mode-table)
      (setq desktop-minor-mode-table
            (append desktop-minor-mode-table
                    '((ecb-minor-mode nil)
                      (semantic-show-unmatched-syntax-mode nil)
                      (semantic-stickyfunc-mode nil)
                      (senator-minor-mode nil)
                      (semantic-idle-scheduler-mode nil)))))
    ))

(progn (setq custom-file (elsub "~/.emacs.d/custom.el"))
       (load custom-file 'noerror))
(eload 'pgo-keys)			;Lastly Override Key Bindings
(set-frame-font "6x13")

;;; ===========================================================================
;;; Pretty save message
(defun d-file-logical-lines-count (&optional filename)
  "Return number of logical lines in D file FILENAME."
  (let ((filename (or filename
                      (buffer-file-name))))
    (string-to-number
     (second (split-string
              (first (split-string (shell-command-to-string
                                    (concat "dscanner " "-l " filename))
                                   "\n")))))))
(d-file-logical-lines-count)

(defun message-pretty-save ()
  "Advanced message() function.
See https://stackoverflow.com/questions/24115904/extending-minibuffer-message-for-save-buffer/24116386#24116386"
  (let ((filename buffer-file-name))
    (message "Wrote %s [%s%s]"
             filename
             (format "%d lines"
                     (count-lines (point-min)
                                  (point-max)))
             (if (and (eq major-mode 'd-mode)
                      (executable-find "dscanner"))
                 (format ", %d logical lines"
                         (d-file-logical-lines-count filename))
               ""))))
(add-hook 'after-save-hook
          'message-pretty-save t)

(uniquify-environment-variable "PATH")

;;; ===========================================================================
;;; Start Emacs Server
;;; C-x # runs the command `server-edit' to complete an emacsclient edit.

(defun server-start-dwim ()
  (when (require 'server nil t)
    ;; (let ((tmpfile "/tmp/emacs1000"))
    ;;  (when (file-exists-p tmpfile)
    ;;    (shell-command (concat "chmod 700 " tmpfile))))                                        ;https://groups.google.com/forum/?fromgroups=#!topic/gnu.emacs.bug/5Ge23R7WSMQ
    (setq server-host (getenv "HOSTNAME")
          server-use-tcp t)    ;make it possible to reach Emacs from other hosts
    ;; (server-force-delete)
    (server-start)
    (when (and (functionp 'server-edit)
               (fboundp 'repeatable-command-advice))
      (repeatable-command-advice server-edit))))
(add-hook 'after-init-hook 'server-start-dwim t)

;; If you are already running an instance of Emacs in --daemon mode then you can
;; wrap the code in something like:
(when (and (daemonp)
	   (eload 'edit-server))
  (when (fboundp 'edit-server-start)
    (edit-server-start)))

;;; ===========================================================================

;; =========================================== Inactives =====================================
;; =========================================== Inactives =====================================
;; =========================================== Inactives =====================================
;; =========================================== Inactives =====================================

(when nil

  ;; WARNING: To SLOW in cc-modes!!!
  ;; See: http://www.emacswiki.org/emacs-en/RainbowDelimiters
  (when nil
    (when (require 'rainbow-delimiters nil t)
      (add-hook 'c-mode-common-hook 'rainbow-delimiters-mode 1)
      (add-hook 'ada-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'python-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'lisp-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'emacs-lisp-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'sh-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'octave-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'makefile-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'outline-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'org-mode-hook 'rainbow-delimiters-mode 1)
      (add-hook 'clojure-mode-hook 'rainbow-delimiters-mode 1)
      ))

  ;;(eload 'pgo-ecb)             ;Emacs Code Browser (ECB)
  (require 'shell-macro nil t)

  ;; =============== Defaults ================================

  (defun change-major-mode-syntax ()
    (modify-syntax-entry ?_ "_"))
  (add-hook 'change-major-mode-hook 'change-major-mode-syntax)

  ;; Use: xxXdfdf

;;; TRAMP
;;; http://superuser.com/questions/203196/how-can-i-make-emacs-tramp-offer-completions-from-my-ssh-config?rq=1
  (when (require 'tramp nil t)
    (setq tramp-default-method "pscp"
          tramp-copy-size-limit 1e6
          tramp-verbose 0)
    (when (require 'tramp-sh nil t)
      (add-to-list 'tramp-remote-process-environment "PATH=$PATH:/usr/openwin/bin"))
    (setq my-tramp-ssh-completions
          '((tramp-parse-sconfig "~/.ssh/config")
            (tramp-parse-shosts "~/.ssh/known_hosts")))
    (when nil
      (mapc (lambda (method)
              (tramp-set-completion-function method my-tramp-ssh-completions))
            '("fcp" "rsync" "scp" "scpc" "scpx" "sftp" "ssh"))
      )
    (when (eload 'tramp-auto)
      ;; see: http://www.reddit.com/r/emacs/comments/chtwd/emacs_and_tramp_remote_su_to_root_please_help/
      ;; This will allow you to issue /sudo:anymachine.anydomain/ and become root
      ;; through sudo. Unfortunately /sudo:username@anymachine.anydomain/ does not
      ;; seem to work.
      (add-to-list 'tramp-default-proxies-alist '("\\." "\\`root\\'" "/ssh:%h:"))
      ))

  ;; Roland Walker's Stuff
  (require 'anaphora nil t)
  (require 'alert nil t)
  (require 'browse-url-dwim nil t)
  (require 'buffer-utils nil t)
  (require 'string-utils nil t)
  (require 'vector-utils nil t)
  (require 'nav-flash nil t)
  (require 'dynamic-fonts nil t)
  (require 'button-lock nil t)
  (require 'font-utils nil t)
  (require 'macro-utils nil t)
  (require 'ucs-utils nil t)
  (require 'syntactic-sugar nil t)
  (require 'double-type nil t)
  (require 'smooth-scroll nil t)
  (require 'linear-undo nil t)
  (when (require 'persistent-soft nil t)
    (require 'wiki-nav nil t))
  (require 'header2 nil t)

  ;; Better feedback when loading.
  (when nil
    (defadvice load (before debug-log (file)) (message "### Now loading: %s" file))
    )

  (when nil (eload 'bookmark+)          ;Extensions to `bookmark.el'.
        (eload 'bookmark+-1)            ;Extensions to `bookmark.el'.
        (eload 'bookmark+-bmu)          ;Extensions to `bookmark.el'.
        (eload 'bookmark+-lit)          ;Bookmark highlighting for Bookmark+.
        (eload 'one-key-bmkp)           ;one-key menus for bookmarks
        )

  (when nil
    (when (eload 'find-things-fast (elsub "find-things-fast")) ;Find things fast, leveraging the power of git
      ;; (global-set-key (kbd [f1]) 'ftf-find-file)
      ;; (global-set-key (kbd [f2]) 'ftf-grepsource)
      ;; (global-set-key (kbd [f4]) 'ftf-gdb)
      ;; (global-set-key (kbd [f5]) 'ftf-compile)
      )
    (eload 'fastnav (elsub "fastnav"))  ;Fast navigation and editing routines.
    )

  ;; http://www.emacswiki.org/emacs-en/OneKey
  (eload 'one-key)
  (eload 'one-key-default)

  ;; (eload 'closure)
  ;; (eload 'closure2)

  (when (require 'dove-ext nil t)
    (delete-list-members hippie-expand-try-functions-list 'try-expand-dabbrev-path)
    )

  (eload 'smart-tabs-mode (elsub "smart-tabs/")) ;Intelligently indent with tabs, align with spaces!

  ;; idle-require.el --- load elisp libraries while Emacs is idle
  ;; See: http://nschum.de/src/emacs/idle-require/
  (when (eload 'idle-require)
    ;; (setq idle-require-symbols '(cedet nxml-mode)) ;; <- Specify packages here.
    ;; (idle-require 'cedet) ;; <- Or like this.
    ;; (idle-require-mode 1) ;; starts loading
    )

  ;; =============== Selection ================================

  ;; I use this instead of pc-selection-mode() to get highlighting of
  ;; both Emacs-style and pc-selection-style selections/marks.
  (unless pnw-me? (cua-selection-mode 1)) ;CUA Selection
  ;;(delete-selection-mode 1)) ;Mark Behavior emulates Motif, MAC or MS-Windows cut and paste style.

  ;; =============== Defaults ================================

  ;; Prevent changes to window configuration.
  ;; NOTE: Disabled because otherwise Icicles opens other frame during completion help C-up/down.
  ;; TODO Gives disturbing behaviour in Emacs 24.1 so disabled.
  ;; (setq pop-up-windows nil)

  (defun revert-retain-undo ()
    "Retain the Undo List after reverting a buffer from file.
http://stackoverflow.com/questions/4924389/is-there-a-way-to-retain-the-undo-list-in-emacs-after-reverting-a-buffer-from-fi"
    (when (y-or-n-p "Make revert undoable?")
      (kill-ring-save (point-min) (point-max))))
  (add-hook 'before-revert-hook 'revert-retain-undo)

  ;; =============== Buffer local faces ================================
  ;; http://www.emacswiki.org/emacs/FacesPerBuffer

  ;; (require 'face-remap nil t)
  (when t
    (defun my-buffer-face-mode-variable ()
      "Set font to a variable width (proportional) fonts in current buffer"
      (interactive)
      (when (boundp 'buffer-face-mode-face)
        (setq buffer-face-mode-face '(:family "DejaVu Sans" :height 100 :width semi-condensed)))
      (buffer-face-mode))
    (defun my-buffer-face-mode-fixed ()
      "Sets a fixed width (monospace) font in current buffer"
      (interactive)
      (when (boundp 'buffer-face-mode-face)
        (setq buffer-face-mode-face '(:family "Consolas" :height 100)))
      (buffer-face-mode))
    (add-hook 'erc-mode-hook 'my-buffer-face-mode-variable)
    (add-hook 'Info-mode-hook 'my-buffer-face-mode-variable)

    (when nil
      (when (and (require 'info nil t)
                 (require 'hictx nil t))
        (defadvice Info-prev-reference (after Info-prev-reference-ctx-flash activate) (hictx-line)) (ad-activate 'Info-prev-reference)
        (defadvice Info-next-reference (after Info-next-reference-ctx-flash activate) (hictx-line)) (ad-activate 'Info-next-reference)
        (defadvice Info-follow-nearest-node (after Info-follow-nearest-node-ctx-flash activate) (hictx-line)) (ad-activate 'Info-follow-nearest-node)
        (defadvice Info-follow-nearest-node-new-window (after Info-follow-nearest-node-new-window-ctx-flash activate) (hictx-line)) (ad-activate 'Info-follow-nearest-node-new-window)
        (defadvice backward-button (after backward-button-ctx-flash activate) (hictx-button)) (ad-activate 'backward-button)
        (defadvice forward-button (after forward-button-ctx-flash activate) (hictx-button)) (ad-activate 'forward-button)
        ))

    (add-hook 'Man-mode-hook 'my-buffer-face-mode-variable)
    )

  ;; =============== Imenu and `which-function-mode' ================================

  (eval-after-load "imenu" '(progn (eload 'imenu+))) ;Extensions to `imenu.el'

  (when nil
    (add-hook 'c-mode-common-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'go-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'ada-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'python-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'lisp-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'emacs-lisp-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'sh-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'octave-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'makefile-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'outline-mode-hook (lambda () (imenu-add-menubar-index)))
    (add-hook 'org-mode-hook (lambda () (imenu-add-menubar-index)))
    )

  ;; Do M-x imenu-tree to view IMenu items as a tree.
  (when nil
    (eload 'imenu-tree)
    (autoload 'imenu-tree "imenu-tree" "Imenu tree" t))

  ;; http://www.emacswiki.org/emacs-en/BisonMode
  (when (require 'bison-mode nil t)
    (add-hook 'bison-mode-hook
              (setq imenu-create-index-function
                    (lambda ()
                      (let ((end))
                        (goto-char (point-min))
                        (re-search-forward "^%%")
                        (forward-line 1)
                        (setq end (save-excursion (re-search-forward "^%%") (point)))
                        (loop while (re-search-forward "^\\([a-z].*?\\)\\s-*\n?\\s-*:" end t)
                              collect (cons (match-string 1) (point))))))
              ))

  ;; =============== Alarm, Bell and Ding ================================

  (when nil
    (ignore-errors                     ;ignore error about revering .zsh_history
      (shell-command "xset b on b 50 1000 100"))) ;Turn off XBell globally
  ;; http://www.emacswiki.org/emacs/AlarmBell
  ;;(eload 'mode-line-bell)
  ;;(eload 'echo-area-bell)
  ;;(setq ring-bell-function 'echo-area-bell)
  (defun describe-last-function()
    "Describe `last-command' executed."
    (interactive)
    (describe-function last-command))
  (define-key help-map [(control meta l)] 'describe-last-function)

  ;; =============== Cursor ================================

  ;; Change cursor color according to mode; inspired by
  ;; http://www.emacswiki.org/emacs/ChangingCursorDynamically

  ;; TODO This solution should not change `cursor-type' and call
  ;; `set-cursor-color' unless cursor has changed.
  (progn
    ;; valid values are t, nil, box, hollow, bar, (bar . WIDTH), hbar,
    ;; (hbar. HEIGHT); see the docs for set-cursor-type
    (setq djcb-read-only-cursor-type 'box)
    (setq djcb-overwrite-cursor-type 'hollow)
    (setq djcb-normal-cursor-type    'box)

    (setq djcb-read-only-color       "green")
    (setq djcb-overwrite-color       "red")
    (setq djcb-normal-color          "orange")
    (defun djcb-set-cursor-according-to-mode ()
      "Change cursor color and type according to some minor modes."
      (cond
       (buffer-read-only
        (set-cursor-color djcb-read-only-color)
        (setq cursor-type djcb-read-only-cursor-type))
       (overwrite-mode
        (set-cursor-color djcb-overwrite-color)
        (setq cursor-type djcb-overwrite-cursor-type))
       (t
        (set-cursor-color djcb-normal-color)
        (setq cursor-type djcb-normal-cursor-type))))
    ;;(add-hook 'post-command-hook 'djcb-set-cursor-according-to-mode)
    )

  ;; =============== CClookup ================================
  ;; http://taesoo.org/Opensource/CClookup
  ;; git clone git@github.com:tsgates/cclookup.git

  ;; add cclookup to your loadpath, ex) "~/.lisp/addons/cclookup"
  (setq cclookup-dir "[PATH]")
  (add-to-list 'load-path cclookup-dir)
  ;; load cclookup when compile time
  ;; (eval-when-compile (eload 'cclookup (elsub "cclookup"))

  ;; set executable file and db file
  (setq cclookup-program (concat cclookup-dir "/cclookup.py"))
  (setq cclookup-db-file (concat cclookup-dir "/cclookup.db"))

  ;; to speedup, just load it on demand
  (autoload 'cclookup-lookup "cclookup"
    "Lookup SEARCH-TERM in the C++ Reference indexes." t)
  (autoload 'cclookup-update "cclookup"
    "Run cclookup-update and create the database at `cclookup-db-file'." t)

  (add-hook 'c-mode-common-hook
            (lambda () (local-set-key "\C-cH" 'cclookup-lookup)))

  ;; cd ~/.lisp/addons/cclookup
  ;; ./cclookup.py -u ./www.cppreference.com/wiki
  ;; ./cclookup.py -l print
  ;; fprintf	./www.cppreference.com/wiki/c/io/fprintf	c/io	print formatted...a

  ;; =============== Clang Settings ================================
  (eload 'cc-clang)

  ;; =============== Complete ================================

  (when nil
    (defun clang-completion-load-hook ()
      (load-library "clang-completion-mode"))
    (add-hook 'c-mode-common-hook 'clang-completion-load-hook))



  (eload 'matlab-octave-harmony)

  (global-set-key [(control x) (control delete)] 'save-buffers-kill-terminal)

  ;; =============== Listings ================================

  (eload 'operators-mode)               ;C/C++ Operators
  (eload 'list-colors-display)          ;List Colors
  (eload 'listings)                     ;Listings of various kinds.
  (eload 'ascii)                        ;Character Code (ASCII) display.
  (eload 'time-ext)                     ;more function for time/date

  (eload 'info-look) ;major-mode-sensitive Info index lookup facility. See: http://www.emacswiki.org/emacs-en/InfoLook
  (eload 'info-xref) ;check external references in an Info document

;;; I-Search
  (eload 'search-in)             ;Contextual String and Regexp Search.

  (eload 'pgo-isearch)                  ;Isearch Setups
  (eload 'isearch-extension)            ;Extension for isearch.

  (eload 'sparse)                       ;Interface to Semantic Parse (Sparse)
  (eload 'regexp-utils)                 ;Regexp Utilities
  (eload 'renumber)                     ;Renumber Utilities
  (eload 'search-utils)                 ;Search Utils
  (eload 'chain-predicates)             ;Chained Predicates

  (eload 'copyedit) ;tweak editing commands for handling prose. See: http://www.emacswiki.org/emacs-en/CopyeditMode

  (eload 'eaauto nil "eaauto.el")

  (eload 'thingatpt-pnw)

  (when (require 'pcache nil t)
    (require 'persistent-soft nil t))

;;; win-switch.el --- fast, dynamic bindings for window-switching/resizing
  (when (require 'win-switch nil t)
    (global-set-key "\C-xo" 'win-switch-dispatch))

  ;; Protect Buffers from being killed.
  ;; (eload 'protbuf)
  ;; (eload 'protbuf-by-name)

  ;; =============== Frame Layout and Fitting ================================

  (eload 'fit-frame)
  (when nil
    (eload 'autofit-frame)              ;WARNING: Disabled because it fails
    )

  ;; =============== Auto-Deletion of Trailing Stuff ================================

  (defun delete-trailing-control-M ()
    "Remove ^M at end of line in the whole buffer."
    (interactive)
    (save-match-data
      (save-excursion
        (goto-char (point-min))
        (when (and (re-search-forward "$" (point-max) t)
                   (y-or-n-p "Delete trailing ^M at end of line in the whole buffer? "))
          (let ((remove-count 0))
            (backward-char)             ;move before first hit
            (while (re-search-forward "$" (point-max) t)
              (setq remove-count (+ remove-count 1))
              (replace-match "" nil nil))
            (message (format "%d ^M removed from buffer." remove-count)))))))
  ;;(add-hook 'before-save-hook 'delete-trailing-control-M)
  (setq-default show-trailing-whitespace nil) ;Show the bastards

  ;;TODO Gives error:
  ;;(setq-mode-local completion-list-mode show-trailing-whitespace t)         ;NOTE: Makes no sense having this in read-only buffers.
  (defun delete-trailing-whitespace-and-indent ()
    "Delete trailing whitespace and then indent."
    (let ((retab (and (not
                       ;; skip tabs in makefiles
                       (memq major-mode '(makefile-mode
                                          makefile-gmake-mode)))
                      (looking-back "^[ \t\n]+") ;only whitespace before
                      (looking-at "[ \t\n]*$")   ;only whitespace after
                      )))
      (delete-trailing-whitespace)
      (when retab
        (indent-for-tab-command)))      ;restore indentation at cursor
    )
  ;; WARNING: TODO This is simply too slow for large c++ files such as hispui.cpp.
  ;;(remove-hook 'before-save-hook 'delete-trailing-whitespace-and-indent)

  ;; =============== Visualization and Highlighting ================================

  (require 'highlight nil t)            ;Highlighting commands.

  ;; Minor mode to visualise blanks (SPACE, HARD SPACE and TAB). NOTE: Previously named blank-mode.el
  (when (require 'whitespace nil t)
    (define-key menu-bar-options-menu [whitespace-mode]
      `(menu-item "Highlight Blanks" whitespace-mode
                  :help "Highlight All Blanks/Whitespace (Black-Mode))"
                  :button  (:toggle . whitespace-mode)
                  :visible t)
      ))

  ;; Highlight Line
  (when (require 'hl-line+ nil t)       ;Extensions to hl-line.el.
    ;;(hl-line-toggle-when-idle -1)         ;Turn it off
    (hl-line-when-idle-interval 0.5)    ;NOTE: I find 0.5 s optimal.
    )

  ;; =============== Abbreviation and Expansion ================================

  (require 'expand-alias nil t)

  ;; Dynamic abbreviation expansion in the middle of a word
  (when (eload 'mdabbrev)
    ;;(global-set-key [(meta /)] 'mdabbrev-expand)
    )

  ;; exec-abbrev-cmd.el --- Execute commands by giving an abbreviation
  (when (eload 'exec-abbrev-cmd)
    ;;(global-set-key [(control c) (x)] 'exec-abbrev-cmd)
    )

  ;; predictive.el --- Predictive abbreviation expansion
  (when nil
    (when (eload 'predictive)
      ;; If you want to enable support for specific major-modes
      (eload 'predictive-latex)
      (eload 'predictive-html)
      (eload 'predictive-texinfo)
      ))

;;; pabbrev.el --- Predictive abbreviation expansion
  (when nil                             ;TODO Fix and enable
    (when (require 'pabbrev nil t)
      ;; (global-pabbrev-mode)
      ;; (setq pabbrev-read-only-error nil)

      ;; One annoying thing about the default behaviour is that if there
      ;; are multiple suggestions for expansion, it will open for you to
      ;; choose one. I prefer to just expand to the displayed expansion,
      ;; always, without opening any additional buffers. To get this
      ;; behaviour, redefine the following function
      (defun pabbrev-expand-maybe-no-buffer()
        "Expand abbreviation, or run previous command.
If there is no expansion the command returned by
`pabbrev-get-previous-binding' will be run instead."
        (interactive)
        (if pabbrev-expansion
            (pabbrev-expand)
          (let ((prev-binding
                 (pabbrev-get-previous-binding)))
            (if (and (fboundp prev-binding)
                     (not (eq prev-binding 'pabbrev-expand-maybe)))
                (funcall prev-binding)))))
      )

    ;; ac-dabbrev.el --- auto-complete.el source for dabbrev
    (when (require 'ac-dabbrev nil t))
    (require 'smart-dabbrev nil t)      ;Smarter dabbrev-expand
    )

  ;; =============== GNUS and Mail ================================

  (setq user-full-name "Per Nordlöw"
        user-mail-address "per.nordlow@gmail.com")
  ;;(setq mail-host-address nil)

  (defvar google-smtp-port 587 "Google Mails SMTP Port.")

  ;; GnusGmail: http://www.emacswiki.org/cgi-bin/wiki/GnusGmail
  (when (require 'gnus nil t)
    ;; (setq gnus-select-method '(nntp "foo.bar.com"))
    ;; Use Gmail’s IMAP as a (secondary):
    (add-to-list 'gnus-secondary-select-methods '(nnimap "gmail"
                                                         (nnimap-address "imap.gmail.com")
                                                         (nnimap-server-port 993)
                                                         (nnimap-stream ssl)))
    ;; (add-to-list 'gnus-secondary-select-methods '(nntp "localhost"))
    ;; (add-to-list 'gnus-secondary-select-methods '(nntp "news.gnus.org"))
    ;; (add-to-list 'gnus-secondary-select-methods '(nnml ""))

    ;; Use Gmail’s SMTP server:
    (when (require 'sendmail nil t)
      (setq send-mail-function 'smtpmail-send-it
            message-send-mail-function 'smtpmail-send-it
            ))
    (when (require 'smtpmail nil t)
      (setq smtpmail-starttls-credentials '(("smtp.gmail.com" google-smtp-port nil nil))
            smtpmail-auth-credentials '(("smtp.gmail.com" google-smtp-port "per.nordlow@gmail.com" nil))
            smtpmail-default-smtp-server "smtp.gmail.com"
            smtpmail-smtp-server "smtp.gmail.com"
            smtpmail-smtp-service google-smtp-port
            smtpmail-local-domain "foi.se" ;"prinsen.skg"
            )
      ;; (setq smtpmail-debug-info t)
      ;; (setq mail-self-blind t)
      ;; (setq smtpmail-code-conv-from nil)
      )

    ;; Add the following to ~/.authinfo
    ;; machine imap.gmail.com login per.nordlow@gmail.com password secret port 993
    ;; machine smtp.gmail.com login per.nordlow@gmail.com password secret port 587

    (when nil
      (setq mail-sources '((pop :server "pop.provider.org"
                                :user "you"
                                :password "secret")))
      (when (require 'imapua nil t)))
    )

  ;; GNUS extension
  (when (require 'gnus-extension nil t))

  ;; store and recall recently used email addresses
  (when (require 'recent-addresses nil t)
    (recent-addresses-mode 1))

  ;; Add quotes to signature according to recipients (Gnus/RMAIL/MH-E/vm)
  (when nil (require 'sig-quote nil t))

  ;; Quote text with a semi-box
  (when nil (require 'boxquote nil t))

  ;; warn-mail.el --- warn for mails incoming
  (when (and nil (require 'warn-mail nil t))
    ;; (load "warn-mail.el")
    ;; (setq mail-list-to-watch (list
    ;;                         "/home/you/incoming/default"
    ;;                           "/home/you/incoming/friends"))
    ;; (tv-launch-warn-without-fetch)
    ;; (global-set-key (kbd "C-c f m") 'tv-launch-mail-system)
    ;; you can set also everythings from customize.
    ;; NOTE: if you launch warn-mail on start of emacs that mine
    ;; fetchmail is already started and you don't need to set a keybinding
    ;; for (tv-launch-mail-system).
    )

  ;; I needed a small uptime program for some Web servers.
  ;; I wondered: "how much Emacs Lisp would it take?".
  ;; The answer? About 12 lines and 10 minutes
  ;; (mostly spent reading gnus and w3m code):
  (when (and nil (require 'gnus nil t) (require 'w3m nil t))
    (defun mailme-mail-via-gnus (to subject stuff)
      (message-mail to subject)
      (insert stuff)
      (message-send-and-exit))
    (defun mailme-search-url (url crib to subject stuff)
      (with-temp-buffer
        (let ((w3m-process-timeout 10))
          (w3m-retrieve url t t))
        (goto-char (point-min))
        (if (re-search-forward crib (point-max) t)
            (message "found")
          (mailme-mail-via-gnus to subject stuff))))
    )

  (when nil
    (defadvice message-send-mail (around gmail-message-send-mail protect activate)
      "Set up SMTP settings to use Gmail's server when mail is from a gmail.com address."
      (interactive "P")
      (if (save-restriction
            (message-narrow-to-headers)
            (string-suffix-p "gmail.com"
                             (message-fetch-field "from"))) ;if from an adress ending with gmail.com
          (let ((message-send-mail-function 'smtpmail-send-it)
                ;; gmail says use port 465 or 587, but 25 works and those don't, go figure
                (smtpmail-starttls-credentials '(("smtp.gmail.com" 25 nil nil)))
                (smtpmail-auth-credentials '(("smtp.gmail.com" 25 "per.nordlow@gmail.com" nil)))
                (smtpmail-default-smtp-server "smtp.gmail.com")
                (smtpmail-smtp-server "smtp.gmail.com")
                (smtpmail-smtp-service 25))
            ad-do-it)
        ad-do-it))
    (ad-activate 'message-send-mail)
    )

  ;; http://julien.danjou.info/google-contacts.el.html
  (when nil                             ;TODO Fix by getting oauth2 via ELPA
    (when (require 'google-contacts nil t)
      ;; You can integrate directly Google Maps into Gnus;
      (when (require 'org-contacts-gnus nil t)
        )
      ;; You can integrate directly Google Maps into message-mode;
      (when (require 'org-contacts-message nil t)
        )
      ))

  ;; =============== Glade ================================

  (when nil
    (when (eload 'glade-mode)
      (add-to-list 'magic-mode-alist
                   '("\\`<\\?xml[ \t\r\n]+[^>]*>[ \t\r\n]*<!DOCTYPE glade-interface"
                     . glade-mode))
      (add-to-list 'auto-mode-alist '("\\.glade\\'" . glade-mode))
      ))
  (add-to-list 'auto-mode-alist '("\.glade\\'" . xml-mode))

  ;; =============== Objective-C ================================
  ;; http://www.emacswiki.org/emacs-en/CcMode


  (defadvice ff-get-file-name (around ff-get-file-name-framework
                                      (search-dirs
                                       fname-stub
                                       &optional suffix-list))
    "Search for Mac framework headers as well as POSIX headers."
    (or
     (if (string-match "\\(.*?\\)/\\(.*\\)" fname-stub)
         (let* ((framework (match-string 1 fname-stub))
                (header (match-string 2 fname-stub))
                (fname-stub (concat framework ".framework/Headers/" header)))
           ad-do-it))
     ad-do-it))
  (ad-enable-advice 'ff-get-file-name 'around 'ff-get-file-name-framework)
  (ad-activate 'ff-get-file-name)

  ;; =============== Doxymacs: Doxygen ================================
  (when (load-file-if-exist (elsub "mine/doxymacs.elc"))
    (setq doxymacs-doxygen-style "JavaDoc") ;use either JavaDoc, Qt and C++
    ;; To use the external XML parser
    ;; (setq doxymacs-use-external-xml-parser t)
    (add-hook 'c-mode-common-hook 'doxymacs-mode)
    (add-hook 'python-mode-hook 'doxymacs-mode)
    (add-hook 'fortran-mode-hook 'doxymacs-mode)
    (add-hook 'vhdl-mode-hook 'doxymacs-mode)
    (add-hook 'php-mode-hook 'doxymacs-mode)
    (add-hook 'idl-mode-hook 'doxymacs-mode)
    (add-hook 'sh-mode-hook 'doxymacs-mode)

    ;; Doxygen keywords fontified
    (when nil
      (defun my-doxymacs-font-lock-hook ()
        (if (memq major-mode '(c-mode c++-mode objc-mode java-mode csharp-mode d-mode
                                      python-mode fortran-mode vhdl-mode php-mode idl-mode sh-mode))
            (doxymacs-font-lock)))
      (add-hook 'font-lock-mode-hook 'my-doxymacs-font-lock-hook))
    )

  ;; =============== Slime ================================
  ;; http://github.com/nablaone/slime
  (when nil
    (when (eload 'slime nil nil nil "git://github.com/nablaone/slime.git")
      (setq inferior-lisp-program "clisp") ; your Lisp system
      (slime-setup)))

  ;; =============== Scala ================================

  ;; =============== ENSIME - ENhanced Scala Interaction Mode for Emacs ================================

  ;; TODO Look in directory ../ensime

  ;; =============== Shell Mode ================================

  (add-to-list 'auto-mode-alist '("/etc/init.d/" . sh-mode))
  (add-to-list 'auto-mode-alist '("/etc/bash_completion.d/" . sh-mode))
  (add-to-list 'auto-mode-alist '("profile.env\\'" . sh-mode))

  (defun sh-mode-charedit ()
    (when (require 'charedit nil t)
      (charedit-local-set-key ?t 'sh-tmp-file 'code)
      (charedit-local-set-key ?l 'sh-indexed-loop 'code)
      (charedit-local-set-key ?\( 'sh-function 'code)

      (charedit-local-set-key ?i 'sh-if 'code)
      (charedit-local-set-key ?f 'sh-for 'code)
      (charedit-local-set-key ?c 'sh-case 'code)

      (charedit-local-set-key ?r 'sh-repeat 'code)
      (charedit-local-set-key ?s 'sh-select 'code)
      (charedit-local-set-key ?u 'sh-until 'code)
      (charedit-local-set-key ?w 'sh-while 'code)
      (charedit-local-set-key ?o 'sh-while-getopts 'code)
      (charedit-local-set-key ?\\ 'sh-backslash-region 'code)
      (charedit-local-set-key ?x 'sh-execute-region 'code))
    )
  (add-hook 'sh-mode-hook 'sh-mode-charedit)

;;; TODO Fix error about .zsh_history and activate.
  ;;(eload 'shell-history)                  ;integration with shell history



  ;; =============== Autoconf/M4 ================================
  (eload 'pgo-autoconf)

  ;; =============== waf ================================
  (add-to-list 'auto-mode-alist '("wscript\\'" . python-mode))

  ;; =============== Make ================================

  (when (require 'make-mode nil t)

    (defconst makefile-nmake-statements
      `("!IF" "!ELSEIF" "!ELSE" "!ENDIF" "!MESSAGE" "!ERROR" "!INCLUDE" ,@makefile-statements)
      "List of keywords understood by nmake.")

    (defconst makefile-nmake-font-lock-keywords
      (makefile-make-font-lock-keywords
       makefile-var-use-regex
       makefile-nmake-statements
       t))

    (define-derived-mode makefile-nmake-mode makefile-mode "nMakefile"
      "An adapted `makefile-mode' that knows about nmake."
      (setq font-lock-defaults
            `(makefile-nmake-font-lock-keywords ,@(cdr font-lock-defaults))))

    (add-to-list 'auto-mode-alist '("\\.mak\\'" . makefile-nmake-mode))

    ;; filling indented makefile comments
    (when (require 'make-mode-fillindent nil t)
      )

    (when (require 'hictx nil t)
      (defadvice makefile-previous-dependency (after makefile-previous-dependency-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'makefile-previous-dependency)
      (defadvice makefile-next-dependency (after makefile-next-dependency-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'makefile-next-dependency)
      (repeatable-command-advice makefile-previous-dependency)
      (repeatable-command-advice makefile-next-dependency)
      )
    )

  ;; =============== DOS ESRI batch files (.bat .cmd) ================================

  ;; See: http://www.emacswiki.org/emacs-en/DosScripts
  (when nil
    (when (eload 'batch-mode))
    (when (eload 'cmd-mode)))
  (when (eload 'dos) ;The recommended way. more features than `batch-mode' and `cmd-mode'.
    (add-to-list 'auto-mode-alist '("\\.\\(cmd\\|bat\\)\\'" . dos-mode))
    (add-to-list 'auto-mode-alist '("/CONFIG\\." . dos-mode))
    (add-to-list 'auto-mode-alist '("/AUTOEXEC\\." . dos-mode))
    (eload 'dos-indent)
    )

  ;; =============== NASM (Netwide Assembler) code. ================================

  (autoload 'nasm-mode "nasm-mode" "Toggle `nasm-mode' mode in this buffer." t)
  (add-to-list 'auto-mode-alist '("\\.nasm" . nasm-mode))

  ;; =============== Google Coding Style ================================

  (when (require 'google-c-style nil t)
    (add-hook 'c-mode-common-hook 'google-set-c-style)
    (add-hook 'c-mode-common-hook 'google-make-newline-indent)
    )

  (when nil
    (append-to-load-path (elsub "google-maps")))

  ;; =============== Refactor ================================

  (when (eload 'erefactor)
    (add-hook 'emacs-lisp-mode-hook
              (lambda ()
                (define-key emacs-lisp-mode-map [(control c) (control v)] erefactor-map))))

  ;; =============== Counts ================================
  (eload 'wc-mode)

  ;; =============== Integration for gist.github.com ================================

  (eload 'gist nil nil nil "git://github.com/defunkt/gist.el.git")

  ;; =============== Maths Characters Menu ================================

  (let ((system-configuration-options (concat system-configuration-options " --with-gtk")))
    (when (eload 'maths-menu)           ;insert maths characters from a menu
      (add-hook 'find-file-hook 'maths-menu-mode))) ;for all buffers having a file

  ;; a mode to input math chars
  (autoload 'xmsi-mode "xmsi-math-symbols-input" "Load xmsi minor mode for inputting math (Unicode) symbols." t)
  ;; (xmsi-mode 1) ; activate the mode.

  ;; =============== Elisp Dependency Handling ================================

  (eload 'lib-requires)       ;Commands to list Emacs Lisp library dependencies.
  (eload 'elisp-depend)       ;Parse depend libraries of elisp file.

  ;; =============== Tools ================================

;;; Elisp Dependency Handling
  (eload 'lib-requires)       ;Commands to list Emacs Lisp library dependencies.
  (eload 'elisp-depend)       ;Parse depend libraries of elisp file.

  (when (require 'midnight)) ;run something every midnight, e.g., kill old buffers

  (eload 'pos-tip)                      ;Show tooltip at point
  (eload 'popup)                        ;Display things in pop-up frames
  (eload 'popup-pos-tip nil nil "http://www.greenend.org.uk/rjk/2002/03/popup.el") ;pos-tip.el wrapper library for programs using popup.el

  (eload 'read-char-spec)               ;Generalized `y-or-n-p'.
  (defun y-or-n-p-with-help (prompt)
    "Copy of `y-or-n-p', as an example use of `read-char-spec'.
PROMPT is as for `y-or-n-p'."
    (read-char-spec prompt '((?y t "Answer in the affirmative")
                             (?n nil "Answer in the negative"))))
  ;; Use: (y-or-n-p-with-help "Open it?")

  (when nil
    (eload 'eol-conversion))      ;set end-of-line conversion for current buffer

  ;; Gentoo Syntax for ebuild
  (append-to-load-path (elsub "gentoo-syntax"))
  (eload 'gentoo-syntax)
  ;; Gentoo Portage Package Configuration
  (setq auto-mode-alist
        (append '(("/etc/portage/package\.keywords\\'" . conf-mode)
                  ("/etc/portage/package\.unmask\\'" . conf-mode)
                  ("/etc/portage/package\.use\\'" . conf-mode)
                  )
                auto-mode-alist))

  (eload 'fink)                         ;fink Packages Management
  (eload 'finkinfo-mode)                ;major mode for editing fink info files

  (when (eload 'doi)           ;Do Or Insert. http://www.emacswiki.org/emacs/Doi
    (when (eload 'doi-extension)
      ))

  (when (eload 'typopunct)            ;Automatic typographical punctuation marks
    ;; To insert a typographical ellipsis sign (…) on three consecutive dots, use the following code:
    (defconst typopunct-ellipsis (decode-char 'ucs #x2026))
    (defun typopunct-insert-typographical-ellipsis (arg)
      "Change three consecutive dots to a typographical ellipsis mark."
      (interactive "p")
      (cond ((and (= 1 arg)
                  (looking-back "\\.\\.")
                  (eq this-command last-command))
             (replace-match "")
             (insert typopunct-ellipsis))
            (t
             (insert (make-string arg ?.)))))
    (define-key typopunct-map "." 'typopunct-insert-typographical-ellipsis)
    ;; To actually insert three dots (...), you may type C-3 . or break the chain of dot insertions.
    )

  ;; =============== Pretty Printing ================================

  ;; htmlize.el -- Convert buffer text and decorations to HTML.
  ;; See: http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el
  ;; See: http://marmalade-repo.org/packages/htmlize
  (when (eload 'htmlize nil nil "http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el.cgi")
;;; (global-set-key [print] 'htmlize-buffer)
    (defun htmlize-outline ()
      "Convert outline buffer to HTML."
      (interactive)
      (let ((str (buffer-string))
            (out-buf (concat buffer-file-name ".html")))
        (replace-regexp-in-string
         (concat "\\(" "^\\*" "\\)" "[\t ]")
         "<h1> "
         str)
        ;; ToDo: Replace empty rows with <p>
        (switch-to-buffer out-buf)
        (html-mode)
        (insert str)
        ))
    )
  (defun browse-htmlized-file (file &optional target)
    "Htmlize FILE and then open it in Web Browser."
    (interactive (list (read-file-name
                        "HTML-ize file: "
                        nil nil nil (and buffer-file-name
                                         (file-name-nondirectory
                                          buffer-file-name)))))
    (let ((target (or target
                      (concat (file-name-sans-extension file) ".html"))))
      (when (or (not (file-exists-p target))
                (y-or-n-p-with-help (format "Overwrite %s" target)))
        (htmlize-file file target)
        (browse-url target))))

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/HtmlFontify
  ;; See: http://rtfm.etla.org/emacs/htmlfontify/
  ;;(when (eload 'htmlfontify))

  (when (fboundp 'icicle-pp-eval-expression)
    (global-set-key [(control meta ?:)] 'icicle-pp-eval-expression))
  (substitute-key-definition 'pp-eval-expression 'icicle-pp-eval-expression global-map)

  (eload 'unicode-overlays)

  (when nil
    (when (eload 'pp+)                  ;Extensions to `pp.el'.
      (substitute-key-definition 'eval-last-sexp 'pp-eval-last-sexp global-map)
      (substitute-key-definition 'eval-expression 'pp-eval-expression global-map)
      )
    (defun eval-last-sexp-and-replace ()
      "Replace the preceding sexp with its value."
      (interactive)
      (backward-kill-sexp)
      (condition-case nil
          (prin1 (eval (read (current-kill 0)))
                 (current-buffer))
        (error (message "Invalid sexp")
               (insert (current-kill 0)))))
    (global-set-key [(control shift meta return)] 'eval-last-sexp-and-replace)
    ;;Test it on the following sentence: Today I spent (+ 2 3 4 5) dollars.

    (when (eload 'eval-sexp-fu)
      (turn-on-eval-sexp-fu-flash-mode))
    )


  ;; =============== Smart Tabs. See: http://www.emacswiki.org/emacs/SmartTabs ================================

  (when nil
    (append-to-load-path (elsub "smart-tabs"))
    ;;(eload 'smarttabs)
    (setq-default tab-width 4)          ; or any other preferred value
    (setq cua-auto-tabify-rectangles nil)

    (smart-tabs-advice js2-indent-line js2-basic-offset) ;JavaScript, Js2Mode
    (smart-tabs-advice cperl-indent-line cperl-indent-level) ;Perl, CPerlMode
    (smart-tabs-advice python-indent-line-1 python-indent)   ;Python, python.el
    (add-hook 'python-mode-hook
              (lambda ()
                (setq indent-tabs-mode 1)
                (setq tab-width (default-value 'tab-width))))
    ;; Smart tabs are, of course, fully Python compliant, as the interpreter
    ;; ignores the leading whitespace of continuation lines. However, in
    ;; accordance with PEP 8, you should probably use tabs only when maintaining
    ;; old code.
    (smart-tabs-advice ruby-indent-line ruby-indent-level) ;Ruby
    (setq ruby-indent-tabs-mode 1)
    (smart-tabs-advice vhdl-indent-line vhdl-basic-offset) ;VHDL
    (setq vhdl-indent-tabs-mode 1)

    ;; What you probably want to do: Disable tabs globally (spaces only) and
    ;; reactivate them for modes with smart tabs handling. For CC Mode:
    (setq-default indent-tabs-mode nil)
    (add-hook 'c-mode-common-hook (lambda () (setq indent-tabs-mode 1)))
    )

  ;; =============== Calendar ================================

;;; Swedish calendar for Emacs
  (when (require 'sv-kalender nil t)
    )


  ;; =============== Buffers ================================

  (when nil ;TODO Fix error regarding `menu-bar-update-buffers-maxbuf' and activate
    (eload 'fix-buffers-list))

;;; http://www.emacswiki.org/emacs-en/Locales
  (when (eload 'locales)           ;a minor mode for frame-relative buffer lists
    ;; (locales-mode 1)
    )

  (when nil
    (defadvice switch-to-buffer (before save-buffer-now activate) (when buffer-file-name (save-buffer))) (ad-activate 'switch-to-buffer)
    (defadvice other-window (before other-window-now activate) (when buffer-file-name (save-buffer))) (ad-activate 'other-window)
    (defadvice other-frame (before other-frame-now activate) (when buffer-file-name (save-buffer))) (ad-activate 'other-frame)
    )

  ;; =============== Sudo ================================

  ;; Sudo wrappers and other tools
  ;; See: http://stackoverflow.com/questions/95631/open-a-file-with-su-sudo-inside-emacs
  ;; See: http://stackoverflow.com/questions/2472273/how-do-i-run-a-sudo-command-in-emacs
  ;; TODO Don't add command to shell history.
  (when nil                             ;TODO Disabled in favor of sudo-ext.el
    (defun sudo-shell-command (command &optional prompt output-buffer error-buffer)
      "Execute COMMAND and as root.
Use PROMPT when querying the password."
      (shell-command (concat "echo " (read-passwd (or prompt (format "Root Password (to execute %s): " command))) " | sudo -S " command)
                     output-buffer error-buffer)))
  ;; Use: (sudo-shell-command "ls -a /root/" nil "*sudo-shell-command-output*" "*sudo-shell-command-error*")
  ;; Use: (sudo-shell-command "ls -a /root/" "Root Password: " "*sudo-shell-command-output*" "*sudo-shell-command-error*")

  ;; (load-file (elsub "nakkaya/int/sudo.elc") ;No good
  ;; (load-file (elsub "sudo.elc")             ;No good
  (eload 'sudo-ext)                     ;sudo support

  ;; =============== Terminal Emulators ================================

  ;; NTerm --- New TERMinal emulator
  (autoload 'nterm "nterm" nil t)

  ;; Managing multiple terminal buffers in Emacs
  (autoload 'multi-term "multi-term" nil t)
  (autoload 'multi-term-next "multi-term" nil t)
  ;; (setq multi-term-program "/bin/zsh") ;; or use zsh...
  (add-hook 'term-mode-hook (lambda () (setq autopair-dont-activate t))) ;autopair fix
  ;; (global-set-key (kbd "C-c t") 'multi-term-next)
  ;; (global-set-key (kbd "C-c T") 'multi-term) ;; create a new one

  ;; =============== Diff ================================

  (when nil                    ;Note: Disabled until compatible with Emacs 23.2.
    (require 'diff+ nil t))    ;Note: Enhancements to Ediff



;;; diff-save-buffer.el --- default filename when saving a diff.
  ;; Homepage: http://www.geocities.com/user42_kevin/diff-save-buffer/diff-save-buffer.el.txt
  ;; diff-save-buffer is a variant of save-buffer for use in an M-x diff or
  ;; M-x vc-diff buffer.  It offers an initial filename in the save prompt
  ;; based on the parent file being diffed.
  (autoload 'diff-save-buffer "diff-save-buffer" nil t)
  ;; The intention is to bind it to C-x C-s in diff buffers, with for instance
  ;;     (autoload 'diff-save-buffer-keybinding "diff-save-buffer")
  ;;     (add-hook 'diff-mode-hook 'diff-save-buffer-keybinding)

;;; ediff-url.el --- Diffing buffer against downloaded url
  (require 'ediff-url nil t)

;;; ediff-trees.el --- Recursively ediff two directory trees
  (when (require 'ediff-trees nil t)
    (global-set-key [(control f7)] 'ediff-trees-examine-previous)
    (global-set-key [(control f8)] 'ediff-trees-examine-next)
    (global-set-key [(shift control f7)] 'ediff-trees-examine-next-regexp)
    (global-set-key [(shift control f8)] 'ediff-trees-examine-previous-regexp)
    )

  ;; =============== Debugging with GUD and GDB ================================

  ;; See: http://users.snap.net.nz/~nickrob/
  (when (require 'gud nil t)
    ;; NOTE: -nx means that we skip ~/.gdbinit. Required for gdba to work.
    ;; NOTE: Use -i=mi for Machine Interpreter
    ;; NOTE: The flag -f doesn't work for me. 2010-02-23
    (defconst gdb-common-flags " --annotate=3 -i=mi "
      "Flags that we should use the GDB/MI from within Emacs.")

    ;; Nice to automatically have toolbar when debugging.
    (defun gud-auto-tool-bar ()
      "Automatically show tool-bar when switching to a debugger buffer."
      (if (eq major-mode 'gud-mode)
          (tool-bar-mode 1)
        (tool-bar-mode -1)))
    ;; WARNING: Creates very disturbing flash!
    ;;(remove-hook 'after-change-major-mode-hook 'gud-auto-tool-bar)
    ;;(add-hook 'gud-mode-hook (lambda () (tool-bar-mode 1)))

    (setq gdb-executable (or (executable-find "gdb-7.3")
                             "gdb")
          gud-gdb-command-name (concat gdb-executable gdb-common-flags)
          gud-gud-gdb-command-name gud-gdb-command-name
          gud-gdba-command-name gud-gdb-command-name)



    ;; The graphical interface described above can currently only be
    ;; used to debug a single program at a time. Here are two files,
    ;; multi-gud.el, multi-gdb-ui.el, that should allow multiple debug
    ;; sessions within one invocation of Emacs. They still require Emacs
    ;; 22 and need to be evaluated *instead* of gud.el and
    ;; gdb-ui.el. For example you could put them in your load-path and
    ;; have
    ;; (load-library "multi-gud.el")
    ;; NOTE: WARNING: Now merged into Emacs CVS.
    ;; (load-library "multi-gdb-ui.el")
    )


;;; gdb-shell.el --- minor mode to add gdb features to shell
  ;;(require 'gdb-shell nil t)

  ;; =============== Killing  ================================

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/BackwardKillLine
  ;; define the function to kill the characters from the cursor
  ;; to the beginning of the current line
  (defun backward-kill-line (arg)
    "Kill chars backward until encountering the end of a line."
    (interactive "p")
    (kill-line 0))
  (global-set-key [(control shift meta k)] 'backward-kill-line)

  (eload 'pgo-kill)

  (append-to-load-path (elsub "delim-kill"))
  (eload 'delim-kill)

  (when (eload 'keep-buffers)
    (keep-buffers-protect-buffer "*scratch*")
    (keep-buffers-protect-buffer "*Messages*")
    (keep-buffers-protect-buffer "*Backtrace*")
    (keep-buffers-erase-on-kill t)
    )
  ;;(eload 'archive-region)
  ;;(eload 'tellicopy)

  ;; =============== Apply Function/Operation on Multiple Regions/Selections ================================
  ;; See: http://www.emacswiki.org/emacs/ApplyFunctionOnMultipleRegions

  ;; second-sel.el --- Secondary selection commands
  ;; WARNING: Note: Disabled for now because of error message I can't
  ;; yet trace: (error "No `SECONDARY' selection")
  (when nil                          ;NOTE: Disabled in favor of Icicles variant
    (when (require 'second-sel nil t)
      (global-set-key [(control meta y)] 'secondary-dwim)
      (define-key esc-map "y" 'yank-pop-commands)
      ))

  ;; Provides multiple noncontiguous selections. Based on `multi-region.el'.
  ;; TODO 3-Click should select current symbol.
  ;; TODO 4-Click should select current expression (in C).
  ;; TODO 5-Click should select current statement (in C).

  ;; TODO Enable and fix override behaviour for M-w that disturbs slick-yank.
  ;; (autoload 'multi-select-mode "multi-select" nil t)
  ;; (multi-select-mode 1)

  (when nil
    (when (require 'multi-region nil t)
      (setq multi-region-map
            (let ((map (make-sparse-keymap)))
              (define-key map "m" 'multi-region-mark-region)
              (define-key map "u" 'multi-region-unmark-region)
              (define-key map "U" 'multi-region-unmark-regions)
              (define-key map "x" 'multi-region-execute-command)
              map))
      (define-key global-map (kbd "C-M-m") multi-region-map)
      (defvar menu-bar-multi-region-menu
        (let ((m (make-sparse-keymap "Multi-Region")))
          (define-key m [mark]
            '(menu-item "Multi-Region Mark" multi-region-mark-region
                        :help "Multi-Region Mark"))
          (define-key m [unmark]
            '(menu-item "Multi-Region Unmark" multi-region-unmark-region
                        :help "Multi-Region Unmark"))
          (define-key m [unmark-all]
            '(menu-item "Multi-Region Unmark All" multi-region-unmark-regions
			:help "Multi-Region Unmark all"))
	  (define-key m [execute]
	    '(menu-item "Multi-Region Execute Command" multi-region-execute-command
			:help "Multi-Region Execute Command"))
	  (fset 'menu-bar-multi-region-menu m)))
      ;; Add it to the "Tools" on the Emacs top menu bar.
      (define-key-after menu-bar-edit-menu [multi-region]
	'(menu-item "Multi-Region" menu-bar-multi-region-menu) 'mark-whole-buffer)
      ))

  ;; =============== Editing ================================

  (when nil
    (require 'multiple-line-edit nil t))

  ;; =============== (Un)Fill ================================

  ;; We want this in code comments in most programming modes.
  (when nil
    (add-hook 'lisp-mode-hook 'turn-on-auto-fill)
    (add-hook 'emacs-lisp-mode-hook 'turn-on-auto-fill)
    (add-hook 'c-mode-common-hook 'turn-on-auto-fill)
    (add-hook 'ada-mode-hook 'turn-on-auto-fill)
    (add-hook 'octave-mode-hook 'turn-on-auto-fill)
    (add-hook 'python-mode-hook 'turn-on-auto-fill)
    (add-hook 'scons-mode-hook 'turn-on-auto-fill)
    (add-hook 'sh-mode-hook 'turn-on-auto-fill)
    (add-hook 'autoconf-mode-hook 'turn-on-auto-fill)
    )
  (global-set-key [(control c) (q)] 'auto-fill-mode)

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/AutoFillMode
  ;; Automatic filling of paragraph lines: auto-fill-mode or refill-mode

  ;; To automatically fill comments but not code in ProgrammingModes,
  ;; something like this can be used.
  (when nil
    (add-hook 'c-mode-common-hook
	      (lambda ()
		(auto-fill-mode 1)
		(set (make-local-variable 'fill-nobreak-predicate)
		     (lambda ()
		       (not (eq (get-text-property (point) 'face)
				'font-lock-comment-face)))))))

  ;; See: EmacsWiki: Fillcode: http://www.emacswiki.org/cgi-bin/wiki?action=browse;id=Fillcode
  ;; See: http://snarfed.org/space/fillcode
  ;; NOTE: Disabled because of this error:
  ;; Debugger entered--Lisp error: (wrong-number-of-arguments called-interactively-p 1)
  ;; called-interactively-p(any)
  ;; ad-Orig-fillcode-mode(nil)
  ;; fillcode-mode()
  ;; run-hooks(c-mode-common-hook c-mode-hook)
  ;; apply(run-hooks (c-mode-common-hook c-mode-hook))
  ;; run-mode-hooks(c-mode-common-hook c-mode-hook)
  ;; c-mode()
  ;; set-auto-mode-0(c-mode nil)
  ;; set-auto-mode()
  ;; normal-mode(t)
  ;; after-find-file(nil t)
  ;; find-file-noselect-1(#<buffer vec2f.h> "~/justcxx/vec2f.h" nil nil "~/justcxx/vec2f.h" (165228 2054))
  ;; find-file-noselect("~/justcxx/vec2f.h" nil nil nil)
  ;; find-file("~/justcxx/vec2f.h")
  ;; find-file-at-point()
  ;; call-interactively(find-file-at-point nil nil)
  (when (and nil (require 'fillcode nil t))
    (add-hook 'c-mode-common-hook 'fillcode-mode)
    (add-hook 'perl-mode-hook 'fillcode-mode)
    (add-hook 'python-mode-hook 'fillcode-mode)
    (add-hook 'scons-mode-hook 'fillcode-mode)
    (add-hook 'sh-mode-hook 'fillcode-mode)
    (add-hook 'sql-mode-hook 'fillcode-mode)
    )


  ;; See: EmacsWiki: FillAdapt: http://www.emacswiki.org/cgi-bin/wiki/FillAdapt
  ;; See: http://cc-mode.sourceforge.net/filladapt.php
  (when (require 'filladapt nil t)
    (make-local-variable 'filladapt-token-table)
    ;; Fill <li> as bullet points
    ;; The setup below gets FillAdapt to treat <li> as a bullet point,
    ;; like for instance
    ;; <li> Eighty megabytes and
    ;; constantly swapping.
    ;; You can do the same with <p>, if you write <p> paragraphs that way too.
    (add-hook 'html-mode-hook
	      (lambda ()
		(require 'filladapt)
		(set (make-local-variable 'filladapt-token-table)
		     (append filladapt-token-table
			     '(("<li>[ \t]" bullet))))))
    (add-hook 'text-mode-hook 'turn-on-filladapt-mode)

    ;;(add-hook 'c-mode-common-hook 'turn-on-filladapt-mode)
    (defun filladapt-c-mode-common-hook ()
      (c-setup-filladapt)
      (filladapt-mode 1))
    (add-hook 'c-mode-common-hook 'filladapt-c-mode-common-hook)

    ;; Support C/C++/Java comments and Javadoc/Doxygen
    (when nil                             ;WARNING: this really ruins things!
      (add-to-list 'filladapt-token-table '("///*" c++-comment))
      ;;(delete '("///*" c++-comment) filladapt-token-table) ;remove the old
      ;; (add-to-list 'filladapt-token-table `(,(concat "^[ \t]*"
      ;;                                                "\\(//\\|\\*\\)"
      ;;                                                "[^ \t]*")
      ;;                                       c++-comment))
      ))

  ;; =============== (Natural) Language Tools ================================

  ;; Automatically capitalize (or upcase) words
  (autoload 'auto-capitalize-mode "auto-capitalize"
    "Toggle `auto-capitalize' minor mode in this buffer." t)
  (autoload 'turn-on-auto-capitalize-mode "auto-capitalize"
    "Turn on `auto-capitalize' minor mode in this buffer." t)
  (autoload 'enable-auto-capitalize-mode "auto-capitalize"
    "Enable `auto-capitalize' minor mode in this buffer." t)

  ;; Look up synonyms for a word or phrase in a thesaurus.
  ;; See: ftp://ibiblio.org/pub/docs/books/gutenberg/etext02/mthes10.zip
  (when (eload 'synonyms)
    (when (and (eload 'mthesaur)
	       (boundp 'mthesaur-file))
      (setq mthesaur-file "~/mthes10/mthesaur.txt"
	    synonyms-file mthesaur-file)
      )
    (setq synonyms-cache-file (concat synonyms-file ".cache"))
    ;;    (autoload 'mthesaur-search "mthesaur"
    ;;      "Thesaurus lookup of a word or phrase." t)
    ;;    (autoload 'mthesaur-search-append "mthesaur"
    ;;      "Thesaurus lookup of a word or phrase, append results." t)
    )

  (when (eload 'plural))                 ;Pluralize english nouns.

  ;; =============== Language Analysis: Spell Checking and Dictionary (Guessing) ================================

  ;; Grammar check utility using LanguageTool
  (append-to-load-path (elsub "langtool"))
  (when (eload 'langtool)
    (global-set-key "\C-x4w" 'langtool-check-buffer)
    (global-set-key "\C-x4W" 'langtool-check-done)
    (global-set-key "\C-x4n" 'langtool-goto-next-error)
    (global-set-key "\C-x4p" 'langtool-goto-previous-error)
    (global-set-key "\C-x44" 'langtool-show-message-at-point)
    )

  (when (require 'flyspell-lazy nil t)
    ;;(flyspell-lazy-mode 1)
    )

  ;; \see http://www.emacswiki.org/emacs/FlySpell
  (autoload 'flyspell-mode "flyspell" "On-the-fly ispell." t)
  (eval-after-load "flyspell-guess" '(flyspell-insinuate-guess-indicator))
  (add-hook 'TeX-mode-hook 'flyspell-mode)
  (add-hook 'LaTeX-mode-hook 'flyspell-mode)
  (add-hook 'outline-mode-hook 'flyspell-mode)
  (add-hook 'org-mode-hook 'flyspell-mode)
  ;;(add-hook 'matlab-mode-hook 'flyspell-mode)
  ;; Programming Mode
  ;;(add-hook 'prog-mode-hook 'flyspell-prog-mode)
  (when (require 'flyspell nil t)
    (setq flyspell-prog-text-faces (remove 'font-lock-string-face flyspell-prog-text-faces))) ;don't spell check strings

  ;; \see http://stackoverflow.com/questions/8122038/user-interaction-improvements-to-flyspell-correct-word
  (defvar flyspell-last-replacements nil)
  (defun flyspell-insert-and-replace-all (word)
    (let ((pos (point)))
      (unless (eq flyspell-auto-correct-pos pos) ; same check as done in flyspell-auto-correct-word
	(setq flyspell-last-replacements nil)))
    (save-excursion
      (dolist (word-markers flyspell-last-replacements)
	(delete-region (car word-markers) (cdr word-markers))
	(goto-char (car word-markers))
	(insert word)))
    (insert word)
    (save-excursion
      (let ((do-replacement (not flyspell-last-replacements)))
	(while (re-search-forward (concat "\\<" flyspell-auto-correct-word "\\>") nil t)
	  (replace-match word)
	  ;; and, when doing first search/replace, record all the positions
	  (when do-replacement
	    (let ((end-marker (point-marker))
		  (begin-marker (make-marker)))
	      (set-marker begin-marker (- (point) (length word)))
	      (set-marker-insertion-type end-marker t)
	      (set-marker-insertion-type begin-marker nil)
	      (add-to-list 'flyspell-last-replacements (cons begin-marker end-marker))))))))
  (setq flyspell-insert-function 'flyspell-insert-and-replace-all)

  (autoload 'auto-dictionary-mode "auto-dictionary" "Automatic dictionary switcher for flyspell." t)
  (add-hook 'flyspell-mode-hook (lambda () (auto-dictionary-mode 1)))

  ;; =============== Compile/Make/Build ================================

  (require 'compile+ nil t)

;;; Extra Compilation Font Locking
  (defun compilation-font-lock-extras ()
    )
  (add-hook 'compilation-mode-hook 'compilation-font-lock-extras)

  (when (require 'flymake nil t)
    ;; http://www.emacswiki.org/emacs-en/FlymakeCursor
    (eload 'flymake-cursor)               ;displays flymake error msg in minibuffer after delay
    (defun flymake-goto-prev-error-and-show-err-menu () (interactive) (flymake-goto-prev-error) (flymake-display-err-menu-for-current-line))
    (defun flymake-goto-next-error-and-show-err-menu () (interactive) (flymake-goto-next-error) (flymake-display-err-menu-for-current-line))
    (global-set-key [(shift f7)] 'flymake-goto-prev-error) ;TODO Support "At first hit"
    (global-set-key [(shift f8)] 'flymake-goto-next-error) ;TODO Support "At last hit"
    (global-set-key (kbd "C-c C-d") 'flymake-display-err-menu-for-current-line)
    ;; (global-set-key (kbd "C-c C-n") 'flymake-goto-next-error)
    ;; (global-set-key (kbd "C-c C-p") 'flymake-goto-prev-error)
    (when (require 'power-utils nil t)
      (setq flymake-max-parallel-syntax-checks compilation-jobs-count))
    )

  (when (and nil (eload 'flymake))
    ;; You may want to invoke flymake-shell when sh-mode loads.
    (when (eload 'flymake-shell)
      (add-hook 'sh-mode-hook 'flymake-shell-load))
    ;; See: http://www.netfort.gr.jp/~dancer/diary/daily/2008-Oct-14.html.en#2008-Oct-14-21:17:38
    (defun flymake-find-file-hook ()
      (when (and (not (local-variable-p 'flymake-mode (current-buffer)))
		 (flymake-can-syntax-check-file buffer-file-name)
		 (not buffer-read-only))
	(flymake-mode)
	(flymake-log 3 "automatically turned ON flymake mode")))
    ;; (add-hook 'find-file-hook 'flymake-find-file-hook)
    (when (and (eload 'flymake)
	       (eload 'fringe-helper))
      (defvar flymake-fringe-overlays nil)
      (make-variable-buffer-local 'flymake-fringe-overlays)

      (defadvice flymake-make-overlay (after add-to-fringe first
					     (beg end tooltip-text face mouse-face)
					     activate compile)
	(push (fringe-helper-insert-region
	       beg end
	       (fringe-lib-load (if (eq face 'flymake-errline)
				    fringe-lib-exclamation-mark
				  fringe-lib-question-mark))
	       'left-fringe 'font-lock-warning-face)
	      flymake-fringe-overlays))
      (ad-activate 'flymake-make-overlay)

      (defadvice flymake-delete-own-overlays (after remove-from-fringe activate
						    compile)
	(mapc 'fringe-helper-remove flymake-fringe-overlays)
	(setq flymake-fringe-overlays nil))
      (ad-activate 'flymake-delete-own-overlays)

      )
    (eload 'flymake-extension)   ;Some extension for flymake
    (eload 'flymake-for-csharp)  ;See: http://www.emacswiki.org/emacs-en/FlymakeCsharp
    )

  (when (ignore-errors (load "auctex.el" nil t t)) ;AUCTex

    ;;; reftex
    (when t
      (setq reftex-plug-into-AUCTeX t)
      (autoload 'reftex-mode "reftex" "RefTeX Minor Mode" t)
      (autoload 'turn-on-reftex "reftex" "RefTeX Minor Mode" nil)
      (autoload 'reftex-citation "reftex-cite" "Make citation" nil)
      (autoload 'reftex-index-phrase-mode "reftex-index" "Phrase Mode" t)
      ;; (add-hook 'reftex-load-hook 'imenu-add-menubar-index)
      )
    (setq cdlatex-paired-parens "$([{")
    (TeX-global-PDF-mode 1) ;export to PDF instead of DVI
    ;;(setq ispell-personal-dictionary "my-personal-dict")

    (when (require 'paredit nil t)
      (defun cdlatex-close-gt ()
	"End a pair of parens, brackets or braces."
	(interactive)
	(search-forward (char-to-string last-command-event)))
      (when (eload 'charedit)
	;; TODO Also bind ")" to `cdlatex-pbb-pnw' or some analog function.
	(defun cdlatex-pbb-pnw ()
	  "Insert a pair of parens, brackets or braces."
	  (interactive)
	  (let ((paren (char-to-string last-command-event))
		(wrap (use-region-p))     ;if mark is activate we want to wrap
		)
	    (if (and (stringp cdlatex-paired-parens)
		     (string-match (regexp-quote paren) cdlatex-paired-parens)
		     (not
		      (and (fboundp 'cdlatex-number-of-backslashes-is-odd)
			   (cdlatex-number-of-backslashes-is-odd)))) ;override
		(if wrap
		    (char-wrap-region last-command-event)
		  (insert paren)
		  (when (boundp 'cdlatex-parens-pairs)
		    (insert (cdr (assoc paren cdlatex-parens-pairs))))
		  (forward-char -1))
	      (insert paren))))
	(add-hook 'LaTeX-mode-hook
		  (lambda ()
		    (when (boundp 'cdlatex-mode-map)
		      (define-key cdlatex-mode-map  "("         'cdlatex-pbb-pnw)
		      (define-key cdlatex-mode-map  "{"         'cdlatex-pbb-pnw)
		      (define-key cdlatex-mode-map  "["         'cdlatex-pbb-pnw)
		      (define-key cdlatex-mode-map  "|"         'cdlatex-pbb-pnw)
		      (define-key cdlatex-mode-map  "<"         'cdlatex-pbb-pnw)
		      ;;(define-paredit-pair ?$ ?$ "dollar")
		      (define-key cdlatex-mode-map  ")"         'paredit-close-parenthesis)
		      (define-key cdlatex-mode-map  "}"         'paredit-close-curly)
		      (define-key cdlatex-mode-map  "]"         'paredit-close-square)
		      (define-key cdlatex-mode-map  "$"         'cdlatex-dollar)
		      ;;(define-key cdlatex-mode-map  ">"         'cdlatex-close-gt)
		      )                 ) t
					  )))

    (when nil
      ;; latex-math-preview.el --- preview LaTeX mathematical expressions.
      ;; (load "latex-math-preview.el" nil t t)
      (autoload 'latex-math-preview-expression "latex-math-preview" nil t)
      (autoload 'latex-math-preview-insert-symbol "latex-math-preview" nil t)
      (autoload 'latex-math-preview-save-image-file "latex-math-preview" nil t)
      ;; For YaTeX mode, in addition to above settings,
      (add-hook 'yatex-mode-hook
		(lambda ()
		  (YaTeX-define-key "p" 'latex-math-preview-expression)
		  (YaTeX-define-key "j" 'latex-math-preview-insert-symbol)))
      ;; (setq latex-math-preview-in-math-mode-p-func 'YaTeX-in-math-mode-p)
      ;; See: http://www.emacswiki.org/cgi-bin/wiki/TexMathPreview
      ;; See: http://www.geocities.com/user42_kevin/tex-math-preview/index.html
      (when (eload 'texmathp)
	(autoload 'tex-math-preview "tex-math-preview" nil t)
	)
      )

    (defun TeX-command-master-skip-confirm ()
      "Run command on the current document.
If a prefix argument OVERRIDE-CONFIRM is given, confirmation will
depend on it being positive instead of the entry in `TeX-command-list'."
      (interactive)
      (if (fboundp 'TeX-command-query)
	  (TeX-command
	   (TeX-command-query (TeX-master-file))
	   'TeX-master-file -1)
	(message "warning: No function `TeX-command-query' defined!")))
    (when nil (add-hook 'TeX-mode-hook
			(lambda ()
			  (define-key TeX-mode-map [(control c) (control c)] 'TeX-command-master-skip-confirm))
			t))               ;NOTE: append to override

    ;; \see http://www.emacswiki.org/emacs/AUCTeX#toc18
    (defun guess-TeX-master (&optional filename)
      "Guess the master file for FILENAME from currently open .tex files.
FILENAME defaults to `buffer-file-name'."
      (let ((candidate nil)
	    (filename (file-name-nondirectory (or filename
						  buffer-file-name))))
	(save-excursion
	  (dolist (buffer (buffer-list))
	    (with-current-buffer buffer
	      (let ((name (buffer-name))
		    (file buffer-file-name))
		(if (and file (string-match "\\.tex$" file))
		    (progn
		      (goto-char (point-min))
		      (if (re-search-forward (concat "\\\\input{" filename "}") nil t)
			  (setq candidate file))
		      (if (re-search-forward (concat "\\\\include{" (file-name-sans-extension filename) "}") nil t)
			  (setq candidate file))))))))
	(if candidate
	    (message "TeX master document: %s" (file-name-nondirectory candidate)))
	candidate))
    (add-hook 'LaTeX-mode-hook 'guess-TeX-master)

    ;; Use Evince
    (setq TeX-view-program-list '(("Evince" "evince %o")))
    ;; This doesn't work:
    ;; (setq TeX-view-program-list '(("Evince" "evince --page-index=%(outpage) %o")))
    (setq TeX-view-program-selection '((output-pdf "Evince")))
    (add-hook 'LaTeX-mode-hook 'TeX-source-correlate-mode)
    (setq TeX-source-correlate-start-server t)
    ;; \see http://www.emacswiki.org/emacs/AUCTeX#toc19
    (when (require 'dbus nil t)
      (defun th-evince-sync (file linecol)
	"Synchronize Evince page with its LaTeX source page."
	(let ((buf (get-buffer file))
	      (line (car linecol))
	      (col (cadr linecol)))
	  (if (null buf)
	      (message "Sorry, %s is not opened..." file)
	    (switch-to-buffer buf)
	    (goto-char (point-min)) (forward-line (1- (car linecol)))
	    (unless (= col -1)
	      (move-to-column col)))))
      (when (and (eq window-system 'x)
		 (fboundp 'dbus-register-signal))
	(dbus-register-signal
	 :session nil "/org/gnome/evince/Window/0"
	 "org.gnome.evince.Window" "SyncSource"
	 'th-evince-sync)))
    )

  ;; =============== Org ================================

  (when (eload 'org)
    (add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

    ;;(global-set-key [(control c) (l)] 'org-store-link)
    (global-set-key [(control c) (a)] 'org-agenda)
    (global-set-key [(control c) (r)] 'org-remember)
    ;;(global-set-key [(control c) (l)] 'org-store-link)
    ;;(global-set-key [(control c) (b)] 'org-iswitchb)
    ;; (define-key org-mode-map "\C-a" 'move-beginning-of-line)
    ;; (define-key org-mode-map "\C-e" 'move-end-of-line)
    ;; (define-key org-mode-map "<S-M-tab>" 'org-shifttab)
    ;; (define-key org-mode-map [shift meta \t] 'org-shifttab)

    (when (file-exists-p "~/Notes")
      (setq org-agenda-files
	    (concatenate 'list
			 (directory-files "~/Notes" t "\\.org$")
			 (directory-files "~/Notes" t "\\.txt$")
			 (directory-files (elsub "mine") t "TODO")
			 (directory-files "~/justcxx/dvis" t "TODO")
			 (directory-files "~/justcxx/semnet/doc" t "TODO")
			 ))
      (setq org-default-notes-file "~/Notes/DIARY.org")
      )

    (when (and (eload 'repeatable) (require 'org nil t))
      (repeatable-command-advice org-todo)
      (repeatable-command-advice outline-next-heading)
      (repeatable-command-advice outline-previous-heading)
      (repeatable-command-advice outline-next-visible-heading)
      (repeatable-command-advice outline-previous-visible-heading)
      (repeatable-command-advice outline-up-heading)
      )

    (setq org-todo-keywords
	  '((sequence "TODO" "IN-PROGRESS" "WAITING"
		      "|" "DONE" "CANCELLED")))
    (setq org-export-with-sub-superscripts '{}) ;M_{star} will still be a subscript, but M_star not.

    ;; extra link types
    (when t
      ;; With these settings, you could link to a specific bug with
      ;; `[[bugzilla:129]]', search the web with `[[google:OrgMode]]' and find out
      ;; what the Org author is doing besides Emacs hacking with
      ;; `[[ads:Dominik,C]]'.
      (setq org-link-abbrev-alist
	    '(("bugzilla" . "http://10.1.2.9/bugzilla/show_bug.cgi?id=")
	      ("google"   . "http://www.google.com/search?q=")
	      ("ads"      . "http://adsabs.harvard.edu/cgi-bin/nph-abs_connect?author=%s&db_key=AST")))

      ;; org-elisp-symbol.el --- Org links to emacs-lisp symbols
      (when (eload 'org-elisp-symbol)
	))

    ;; See: http://www.emacswiki.org/emacs-en/OrgOutlook
    (when (fboundp 'w32-short-file-name)
      (eload 'org-outlook)
      )

    ;; org-bibtex.el --- Org links to BibTeX entries
    (when (eload 'org-bibtex)
      )

    ;; See:
    ;; org-babel.el
    ;; http://orgmode.org/worg/org-contrib/babel/
    ;; http://eschulte.github.com/babel-dev/
    ;; TODO Make work by adding path
    (when (require 'org-babel-init nil t)
      (require 'org-babel-octave)
      (require 'org-babel-matlab)
      (byte-recompile-directory (elsub "babel-dev/") 0 t))

    (when (require 'org-contacts nil t)   ;See: http://julien.danjou.info/org-contacts.html
      )

    ;; See: http://www.gnu.org/software/emacs/manual/html_node/org/CDLaTeX-mode.html
    (when nil (add-hook 'org-mode-hook 'turn-on-org-cdlatex))

    ;; Fast note taking in Org-mode
    ;; See: http://members.optusnet.com.au/~charles57/GTD/remember.html
    (when (eload 'org-remember)
      (org-remember-insinuate)
      (progn
	(setq remember-annotation-functions '(org-remember-annotation))
	(setq remember-handler-functions '(org-remember-handler))
	(add-hook 'remember-mode-hook 'org-remember-apply-template)
	)
      (setq org-remember-templates
	    '(
	      ("Computer-Tip" ?c "* TODO %? %^g\n %i\n " "~/Notes/TIPS.org" "Computer Tips")
	      ("Life-ToDo" ?l "* TODO %? %^g\n %i\n " "~/Notes/TODO.org" "Life ToDO")
	      ("DVis-ToDo" ?a "* TODO %? %^g\n %i\n " "~/justcxx/dvis/TODO.org" "Uncategorized")
	      ("Emacs-ToDo" ?e "* TODO %? %^g\n %i\n " (elsub "mine/Emacs-TODO.txt") "Emacs ToDo")
	      ("Idea-ToDo" ?i "* TODO %? %^g\n %i\n " "~/Notes/Ideas.org" "General Ideas")
	      ("DVis-Bug" ?i "* TODO %? %^g\n %i\n " "~/justcxx/dvis/TODO.org" "Bug")

	      ("Soft-Book-Read" ?b "\n* %^{Book Title} %t :READING: \n%[~/elisp/remember-templates/book.txt]\n" "~/Notes/Great_Media.txt" "Soft Books")
	      ("Tech-Book-Read" ?b "\n* %^{Book Title} %t :READING: \n%[~/elisp/remember-templates/book.txt]\n" "~/Notes/Great_Media.txt" "Technical Books")
	      ("Film-Seen" ?f "\n* %^{Film Title} %t :WATCHING: \n%[~/elisp/remember-templates/film.txt]\n" "~/Notes/Great_Media.txt" "Great-Movies/Filmer/Videos")
	      ("Site" ?f "\n* %^{Site Title} %t :SURFING: \n%[~/elisp/remember-templates/site.txt]\n" "~/Notes/Great_Media.txt")

	      ("Contact" ?c "\n* %^{Name} :CONTACT:\n%[~/elisp/remember-templates/contact.txt]\n" "~/Notes/Contacts.txt")
	      ("Journal" ?j "\n* %^{topic} %T \n%i%?\n" "~/Notes/DIARY.org" "Journal")
	      ))
      )

    (when (eload 'hideshow-org)
      (global-set-key "\C-ch" 'hs-org/minor-mode)
      )

    )

  ;; =============== Track Command Frequencies ================================

  ;; See: http://xahlee.org/emacs/command-frequency.html
  (when (eload 'command-frequency)
    (custom-set-variables
     '(command-frequency-autosave-timeout 60)
     '(command-frequency-buffer "*command-frequencies*")
     '(command-frequency-table-file "~/.emacs.d/command-frequencies") ;needed for load to pick correct file
     )
    ;;(command-frequency-table-load nil t)
    (when (ignore-errors ;TODO Errors in `called-interactively-p' on Emacs 23 but not on 24.
	    (command-frequency-mode 1))
      (command-frequency-autosave-mode 1)
      (defalias 'list-command-frequencies 'command-frequency))
    )

  ;; =============== Completion ================================

  (defun minibuffer-complete-substring ()
    "Complete the minibuffer contents as far as possible using
substring completion."
    (interactive)
    (sit-for 1)
    (let ((completion-styles '(substring)))
      (minibuffer-complete)))
  (let ((map minibuffer-local-completion-map))
    ;;(define-key map [backtab] 'minibuffer-complete-substring)
    (define-key map "?" nil ;NOTE: Remove binding to `minibuffer-completion-help'.
      )
    )

  (eload 'completion-styles-cycle)        ;Cycle Completion Styles.

  ;; =============== Other ================================

  (when nil
    (eload 'simple-call-tree)
    (eload 'simple-call-tree+)) ;analyze source code based on font-lock text-properties

  ;; =============== Anything ================================

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/Anything
  (append-to-load-path (elsub "anything-config"))
  (append-to-load-path (elsub "anything-config/extensions"))
  (append-to-load-path (elsub "anything-config/developer-tools"))
  (when t
    (and (eload 'anything-startup)
	 (eload 'anything-make)
	 (eload 'anything-dabbrev-expand)
	 ;;(eload 'anything-gtags)
	 (eload 'anything-auto-install)
	 )
    (when t
      ;;(eload 'anything-rcodetools)
      ;;(eload 'anything-grep)
      ;;(eload 'anything-menu)
      ;;(eload 'anything-migemo)
      ;;(eload 'anything-eproject)
      ;;(eload 'anything-mercurial)
      ;;(eload 'anything-delicious)
      ;;(eload 'anything-complete)
      ;;(eload 'anything-match-plugin)
      ;;(eload 'anything-include)
      ;;(eload 'anything-adaptive) ;See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/2e9e0abc5309c70e#
      ;;(eload 'anything-show-completion)
      ;;(eload 'anything-c-info)
      ;;(eload 'anything-c-javadoc)

      ;;(setq anything-input-idle-delay 0.3)

      (when (eload 'anything-dired-history) ;Show dired history with anything.el support.
	(setq anything-dired-history-cache-file "~/.emacs.d/dired-history")
	(define-key dired-mode-map "," 'anything-dired-history-view)
	)

      ;; TODO Merge these into anything-config.el
      (when t
	(setq anything-c-source-file-name-history
	      '((name . "File Name History")
		(candidates . (lambda ()
				(mapcar (lambda (a)
					  (propertize a
						      'face
						      (cond ((file-directory-p a)
							     'font-lock-directory-name-face)
							    (t
							     'font-lock-file-name-face))
						      ))
					file-name-history)))
		(match anything-c-match-on-file-name
		       anything-c-match-on-directory-name)
		(type . file)))

	(setq anything-c-source-emacs-commands
	      '((name . "Emacs Commands")
		(candidates . (lambda ()
				(let (commands)
				  (mapatoms (lambda (a)
					      (when (commandp a)
						(push (propertize (symbol-name a)
								  'face 'font-lock-command-name-face)
						      commands))))
				  (sort commands 'string-lessp))))
		(type . command)
		(requires-pattern . 2)))

	(setq anything-c-source-emacs-functions
	      '((name . "Emacs Functions")
		(candidates . (lambda ()
				(let (commands)
				  (mapatoms (lambda (a)
					      (when (functionp a)
						(push (propertize (symbol-name a)
								  'face 'font-lock-function-name-face) commands))))
				  (sort commands 'string-lessp))))
		(type . function)
		(requires-pattern . 2)))

	(setq anything-c-source-emacs-variables
	      '((name . "Emacs Variables")
		(candidates . (lambda ()
				(let (commands)
				  (mapatoms (lambda (a)
					      (when (and (boundp a) ;bound
							 (not (fboundp a))) ;but not a function
						(push (propertize (symbol-name a)
								  'face 'font-lock-variable-name-face)
						      commands))))
				  (sort commands 'string-lessp))))
		(type . variable)
		(requires-pattern . 2))
	      )

	(setq anything-c-source-emacs-symbols
	      '((name . "Emacs Symbols")
		(candidates . (lambda ()
				(let (commands)
				  (mapatoms (lambda (a)
					      (when (boundp a) ;is a symbol
						(push (propertize (symbol-name a)
								  'face (symbol-def-face a)) commands))))
				  (sort commands 'string-lessp))))
		(type . variable)
		(requires-pattern . 2))
	      ))

      ;; Anything Lacarte
      (when (and (require 'anything-config nil t)
		 (require 'lacarte nil t))
	(setq LaTeX-math-menu-unicode t)
	(when (boundp 'LaTeX-mode-map)
	  (define-key LaTeX-mode-map [?\M-`] 'anything-math-symbols))
	(defvar anything-c-source-lacarte-math
	  '((name . "Math Symbols")
	    (init . (lambda()
		      (setq anything-c-lacarte-major-mode major-mode)))
	    (candidates
	     . (lambda () (when (eq anything-c-lacarte-major-mode 'latex-mode)
			    (delete '(nil) (lacarte-get-a-menu-item-alist LaTeX-math-mode-map)))))
	    (action . (("Open" . (lambda (candidate)
				   (call-interactively candidate)))))))
	(defun anything-math-symbols ()
	  "Anything for searching math menus"
	  (interactive)
	  (anything '(anything-c-source-lacarte-math)
		    (thing-at-point 'symbol) "Symbol: "
		    nil nil "*anything math symbols*")))

      ;; Redefine locate to fewer matches
      (setq anything-c-source-locate
	    '((name . "Locate")
	      (candidates . anything-c-locate-init)
	      (type . file)
	      (properties-action . anything-ff-properties)
	      (requires-pattern . 3)
	      (candidate-number-limit . 50)
	      (mode-line . anything-generic-file-mode-line-string)
	      (delayed)))

      (defun pnw-anything ()
	"Per Nordlöw's Anything."
	(interactive)
	(let ((buffer-name " *pnw-anything")
	      split-height-threshold)     ;we want much height in anything
	  (anything-at-point
	   '(anything-c-source-create
	     anything-c-source-buffers
	     anything-c-source-emacs-process
	     ;;anything-c-source-buffers-list

	     anything-c-source-file-name-history
	     ;;anything-c-source-dired-history
	     anything-c-source-ffap-guesser

	     ;; @TODO Replace with my own version in `makefile-targets' and
	     ;;`compilation-read-build-target'.
	     ;; anything-c-source-make-targets

	     ;; anything-c-source-eproject-files
	     ;; anything-c-source-eproject-projects
	     ;; anything-c-source-gtags-select

	     anything-c-source-extended-command-history
	     anything-c-source-complex-command-history

	     anything-c-source-calculation-result

	     anything-c-source-man-pages
	     ;;anything-c-source-man-apropos

	     ;; anything-c-source-emacs-commands
	     ;; anything-c-source-emacs-functions
	     ;; anything-c-source-emacs-variables
	     anything-c-source-emacs-symbols

	     anything-c-source-advice

	     anything-c-source-lacarte-math

	     anything-c-source-customize-face

	     ;;anything-c-source-imenu
	     anything-c-source-bookmarks
	     anything-c-source-bookmark-set

	     ;; anything-c-source-apropos-emacs-commands
	     ;; anything-c-source-apropos-emacs-faces
	     ;; anything-c-source-apropos-emacs-functions
	     ;; anything-c-source-apropos-emacs-variables

	     ;; TODO Improve performance of `anything-c-source-apt' by only
	     ;; displaying when have typed at leasy, say two characters,
	     ;; similar to behaviour of `anything-c-source-locate'.
	     anything-c-source-apt

	     ;; TODO Add `anything-c-source-apt-file-search'
	     ;; that does "apt-file search /tidy.h" using my tools in auto-deb.el.

	     anything-c-source-info-pages
	     anything-c-source-info-emacs
	     anything-c-source-info-elisp
	     ;;anything-c-source-info-menu-items
	     ;;anything-c-source-info-apropos

	     anything-c-source-locate
	     ;;anything-c-source-tracker-search

	     anything-c-source-google-suggest
	     ;;anything-c-source-semantic

	     anything-c-source-kill-ring

	     ;;anything-c-source-auto-install-from-emacswiki
	     ;;anything-c-source-auto-install-from-gist
	     ;;anything-c-source-auto-install-from-library
	     )
	   (when (region-active-p)
	     (symbol-name-at-point))
	   nil nil nil (get-buffer-create buffer-name))
	  ;; kill instead of `bury-buffer' because we don't want`winner' and alikes
	  ;; to know about this buffer
	  (kill-buffer buffer-name)
	  ))
      (global-set-key (kbd "M-X") 'pnw-anything)
      )
    ;;(if (functionp 'icicle-anything) (global-set-key (kbd "M-X") 'icicle-anything) (global-set-key (kbd "M-X") 'anything))
    )

  ;; =============== Diff/EDiff/Compare/Merge ================================

;;; XML-RPC
;;; \see http://www.emacswiki.org/emacs/XmlRpc

;;; JIRA
;;; \see http://emacswiki.org/emacs/JiraMode
  (when (require 'jira nil t)             ;XML-RPC
    )

;;; JIRA-REST
;;; \see https://github.com/mattdeboard/jira-rest
;;; \see https://developer.atlassian.com/display/JIRADEV/JIRA+REST+APIs#JIRARESTAPIs-GettingStartedwithREST
  (when (require 'jira-rest nil t)        ;REST
    )

  (when nil                               ;NOTE: Disabled for now because I don't want a bright background
    (when (eload 'diff-mode-)
      (add-to-list 'special-display-buffer-names
		   '("*Diff*" (background-color . "LightSteelBlue")))
      (add-to-list 'special-display-buffer-names
		   '("*vc-diff*" (background-color . "LightSteelBlue")))))

  ;;(setq-default ediff-highlight-all-diffs 'nil);; only hilight current diff:
  (autoload 'unidiff-mode "unidiff" "Editing unified format patches." t)
  (add-to-list 'auto-mode-alist '("\\.diff\\'" . unidiff-mode))

  (eload 'tfs)                            ;MS Team Foundation Server commands for Emacs. See: http://www.emacswiki.org/emacs-en/MSTFS

  ;; Emerge. NOTE: Slow, Ugly and Stupid
  ;; See: http://www.emacswiki.org/emacs-en/EmergeDiff
  ;; (when (require 'emerge nil t))
  (setq emerge-diff-options "--ignore-all-space")

  ;; =============== Chat ================================

  ;; Emacs Internet Relay Chat (IRC) Client
  (when (require 'erc)
    ;;(eload 'erc-extension)
    (defun irc-pnw ()
      "Run IRC with my favorite settings. "
      (interactive)
      ;; Servers: irc.freenode.net, lindbohm.freenode.net
      (erc :server "lindbohm.freenode.net" :nick "per" :full-name "Per Nordlöw"))
    )

  ;; =============== Constants ================================

  ;; enter definition of constants into source code
  ;;(eload 'constants)
  (autoload 'constants-insert "constants" "Insert constants into source." t)
  (autoload 'constants-get "constants" "Get the value of a constant." t)
  (autoload 'constants-replace "constants" "Replace name of a constant." t)
  (setq constants-unit-system 'SI)   ;  this is the default
  ;;   (define-key global-map "\C-cci" 'constants-insert)
  ;;   (define-key global-map "\C-ccg" 'constants-get)
  ;;   (define-key global-map "\C-ccr" 'constants-replace)

  ;; =============== Windows (Win32) ================================

  ;; See: http://www.emacswiki.org/emacs-en/MsShellExecute
  (when (eq system-type 'windows-nt)
    ;; Assure that Alt is mapped to Meta on Windows. We do not need to
    ;; use Alt to access the menubar.
    (defvar w32-alt-is-meta t)
    (setq w32-alt-is-meta t)
    (when (eload 'cygwin-mount)           ;Teach EMACS about cygwin styles and mount points.
      (when (fboundp 'cygwin-mount-activate)
	(cygwin-mount-activate)))
    (eload 'w32-symlinks)
    (eload 'setup-cygwin)
    (setq grep-command "findstr /n /s /i /p ") ;grep on window
    (eload nil (elsub "others") "w32-browser.el")
    (eload nil (elsub "others") "w32browser-dlgopen.el")
    )

  (eload 'w32-browser)
  (eload 'w32browser-dlgopen)
  (eload 'w32-shell-execute)
  (eload 'powershell)

  ;; =============== Windows (Win32) Windows Handling ================================

  ;; (setq initial-frame-alist
  ;;       `((left . 0) (top . 0)
  ;;         (width . 237) (height . 65)))

  ;; This sets the parameters for creating the initial X Windows
  ;; frame. It positions the emacs frame in the top left corner of the
  ;; display [0, 0] (measured in pixels) and then resizes the frame to
  ;; 237 columns by 65 rows. Unfortunately, the number of columns and
  ;; rows vary depending on font-size, scroll bar visibility, etc. The
  ;; dimensions of. Just happen to work for my font, scroll-bars off, etc.

  ;; Here is another (hard-coded) alternative. This is especially good
  ;; if you need to resize the frame after startup.

  ;; 1
  ;; 2

  ;; (set-frame-position (selected-frame) 0 0)
  ;; (set-frame-size (selected-frame) 237 65)

  ;; If you don't necessarily want to maximize your window, but instead
  ;; want a window with specific dimensions at a specific location, you
  ;; can skip Option 3 because Option 2 is your best bet2.  Option 3

  ;; We will describe Option 3 in part 2 of the series. There, we will
  ;; use the display-pixel-width and display-pixel-height functions to
  ;; automatically determine the proper size of the emacs frame.

  (defun w32-restore-frame ()
    "Restore a minimized frame"
    (interactive)
    (when (fboundp 'w32-send-sys-command)
      (w32-send-sys-command 61728)))

  (defun w32-maximize-frame ()
    "Maximize the current frame"
    (interactive)
    (when (fboundp 'w32-send-sys-command)
      (w32-send-sys-command 61488)))
  ;; (add-hook 'after-init-hook 'w32-maximize-frame t)

  ;; =============== Run/Call/Execute Programs ================================

  (eload 'lively)                         ;interactively updating text

  ;; =============== APT ================================

  (autoload 'apt-sources-mode "apt-sources" "Toggle `apt-sources' mode in this buffer." t)
  (add-to-list 'auto-mode-alist '("sources.list\\'" . apt-sources-mode))
  ;;(eload 'apt-utils)
  (autoload 'apt-utils-search "apt-utils" "Debian Advanced Package Management Tool (APT)" t)
  (autoload 'apt-utils-show-package "apt-utils" "Debian Advanced Package Management Tool (APT)" t)
  (when (eload 'auto-deb)
    (auto-deb-setup-keybindings))

  ;; =============== Unit Test ================================

  (eload 'pgo-unit-test) ;Unit Test Framework Integration

  ;; =============== Uncategorized ================================

  ;;(eload 'zeitgeist)                      ;Zeitgeist logging.
  (eload 'wide-n)                         ;cycle among buffer restrictions

  ;; =============== Customize ================================

  (require 'browse-url)

  ;; Make marks visible.
  (when (eload 'visible-mark)
    (global-visible-mark-mode -1))
  ;; Mark automatically
  (when (eload 'auto-mark))
  ;; Highlight marks in buffer.
  (when (eload 'himarks-mode))

  (when nil
    (autoload 'completing-help-mode "completing-help"
      "Toggle a facility to display information on completions."
      t nil)
    (autoload 'turn-on-completing-help-mode "completing-help"
      "Turn on a facility to display information on completions."
      t nil)
    (autoload 'turn-off-completing-help-mode "completing-help"
      "Turn off a facility to display information of completions."
      t nil)
    (turn-on-completing-help-mode))

  (eload 'relangs) ;Relations, Associations between Different Languages and their APIs

  (autoload 'say-minor-mode "festival" "Menu for using Festival." t)
  ;;(say-minor-mode 1)
  ;;(eload 'festival-extension)   ;Simple festival extension for festival.el

  ;; =============== Append Font After Lastly ================================

  ;; =============== Backups ================================

  ;; TODO Wait until more mature!
  ;; C-c v Save Specific Version
  ;; C-c b List Backups
  ;; C-c k Kill Buffer Prompt
  ;; C-c w Walk Backups
  (when nil        ;NOTE: Disabled for now because it activates auto-save which is very annoying!
    (setq emacs-directory "~/.emacs.d/")
    (append-to-load-path (elsub "backups-mode"))
    (when (require 'backups-mode nil t)
      (defvar backup-directory ".backups")
      (defvar tramp-backup-directory ".tramp-backups")
      ;;(backups-mode-start)
      (setq delete-old-versions 1)         ;keep all versions forever
      (require 'backup-walker nil t)
      (repeatable-command-advice kill-buffer-prompt)
      ))

  ;; =============== Recent Files ================================

  (when nil
    (when (require 'recentf nil t)
      (recentf-mode -1)
      (global-set-key [(control x) (control r)] 'recentf-open-files)
      ;;(global-set-key [(control x) (meta f)] 'icicle-recent-file)
      (when nil
	(when (eload 'recentf-buffer)
	  (global-set-key [(control c) (?r) (?f)] 'recentf-open-files-in-simply-buffer)
	  (eload 'recentf-ext)
	  ;;(recentf-open-files-in-simply-buffer)
	  ))))

  ;; =============== Setup (Desktop) Configuration Save & Restoration, Sessions ==========

  ;; Clean up Other Windows
  (dired "~/")
  (delete-other-windows)

  ;; A very simple alternative to more involved SessionManagement solutions.
  (when (and nil
	     (require 'savehist nil t))
    ;;(savehist-mode 1)             ;save history to ~/.emacs.d/history
    ;; (savehist-additional-variables
    ;;    'search-ring 'regexp-search-ring)
    ;; By default, Savehist mode saves only your minibuffer histories,
    ;; but you can optionally save other histories as well (see option
    ;; `savehist-additional-variables'). You can, for instance save
    ;; your search strings by setting `savehist-additional-variables'
    ;; to (search-ring regexp-search-ring).
    ;; You can also fine-tune Savehist to save only specific histories,
    ;; not all minibuffer histories see the doc string of option
    ;; `savehist-save-minibuffer-history'.
    )
  ;; Revive.el saves current editing status including the window
  ;; splitting configuration, which can't be recovered by `desktop.el'
  ;; nor by `saveconf.el', into a file and reconstructs that status
  ;; correctly.
  (when nil
    (when (require 'revive nil t)))

  ;; TODO Prevent Disturbing Frame Popup Behaviour
  (ignore-errors (ad-remove-advice 'other-window 'around 'sr-advice-other-window))

  ;;; Unused stuff
  (eload 'bookmark-search)              ;Provide a search command for emacs
                                        ;bookmarks ala anything.
  (eload 'pgo-scroll)             ;Scrolling Behaviour (mainly for Mouse Wheel).
  (eload 'pgo-elisp-tools)              ;Emacs Lisp Development Tools
  (eload 'pgo-tempo)                    ;Tempo
  (eload 'pgo-chord)                    ;Key Chords
  (eload 'pgo-man)                      ;Man Integration.
  (eload 'pgo-grep)                     ;Grep
  (eload 'reference-sheet-help-utils)   ;
  (eload 'pgo-project)                  ;Project Management
  (eload 'pgo-term)                     ;Serial Port Terminal
  (eload 'nterm) ;New TERMinal emulator. Warning: Superslow. See: http://www.emacswiki.org/emacs-en/NewTerminal
  (eload 'pgo-outline)               ;Outline
  (eload 'pgo-highlight)             ;Highlighting of current Line, Column, etc.
  (eload 'pgo-multiple-modes)        ;Multiple Modes in Same Buffer.
  (eload 'pgo-build-tools)           ;Software Build Tools
  (eload 'pgo-po-mode)               ;Setup major mode for GNU gettext PO files
  (eload 'pgo-gprof)                 ;Setup major mode for GNU gettext PO files
  (eload 'pgo-replace)               ;Replacements
  (eload 'pgo-google)
  (eload 'pgo-comint)
  (eload 'pgo-vhdl)
  (eload 'pgo-compression)              ;Setup Compression Interfaces.
  (eload 'pgo-color-theme)
  (eload 'gob)                          ;A code generator for GObject
  (eload 'color-occur nil nil "http://www.bookshelf.jp/elc/color-occur.el") ;colored occur mode
  (eload 'color-moccur nil nil "http://www.bookshelf.jp/elc/color-moccur.el") ;colored multi-buffer occur mode
  (eload nil (elsub "others") "moccur-edit.el")
  (eload nil (elsub "others") "occur-schroeder.el")

  (eload 'tooltip-help)                 ;Show help as tooltip.
  ;;(eload 'redspace-mode) ;highlighting empty space at end of lines
  (eload 'ga)                           ;Package Management
  (eload 'autoinsert) ;Auto-Insert File Header. See: http://www.emacswiki.org/cgi-bin/wiki/AutoInsertMode
  (eload 'regex-tool) ;A regular expression evaluation tool for programmers
  (eload 'eperiodic)  ;Periodic Table
  ;;(eload 'test-primes)

  ;; gtk-look.el --- lookup Gtk and Gnome documentation.
  (autoload 'gtk-lookup-symbol "gtk-look" nil t)
  ;; This makes M-x gtk-lookup-symbol available, but you'll probably want to
  ;; bind it to a key.  C-h C-j is one possibility, being close to C-h C-i for
  ;; `info-lookup-symbol'.  For instance to do that globally,
  (global-set-key [(control h) (control j)] 'gtk-lookup-symbol)

  (when (eload 'dabbrev-expand-multiple) ;dabbrev-expand for multiple
    ;;(global-set-key "\M-/" 'dabbrev-expand-multiple)
    )

  ;; Expansion Handling Keys
  ;; Use "Anjuta IDE" style keybindings for code completion
  ;;(global-set-key [(control return)] 'dabbrev-expand) ;find completions from buffers
  ;;(global-set-key [(control return)] 'expand-abbrev) ;expands almost anything using completion buffer

  ;; Wrap Region is a minor mode for Emacs that wraps a region with
  ;; punctuations. For tagged markup modes, such as HTML and XML, it
  ;; wraps with tags.
  (append-to-load-path (elsub "wrap-region"))
  (when (and nil (eload 'wrap-region))
    (dolist (hook '(c-mode-common-hook
                    haskell-mode-hook
                    emacs-lisp-mode-hook
                    lisp-mode-hook
                    lisp-interaction-mode-hook
                    maxima-mode-hook
                    ielm-mode-hook))
      (add-hook hook (lambda () (wrap-region-mode 1))))
    (add-hook 'emacs-lisp-mode-hook
              (lambda()
                (wrap-region-set-mode-punctuations '("\"" "\[" "(" "{"))
                (wrap-region-mode 1)
                ))
    )

  ;; header2.el --- Support for creation and update of file headers.
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/AutomaticFileHeaders
  (when (eload 'header2)
    (add-hook 'lisp-mode-hook 'auto-make-header)
    (add-hook 'emacs-lisp-mode-hook 'auto-make-header)
    ;;(add-hook 'c-mode-common-hook 'auto-make-header)
    (add-hook 'write-file-hooks 'auto-update-file-header)
    ;; Variable `comment-end-p' is free here.  It is bound in `make-header'.
    (defsubst header-code ()
      "Insert \"Code: \" line."
      (insert (concat (section-comment-start) "Code:" (and comment-end-p comment-end)
                      "\n\n\n\n" "(provide '" (file-name-sans-extension (buffer-name)) ")\n\n")))
    )

  ;; template-simple.el --- Simple template functions and utils
  (when (eload 'template-simple)
    (setq template-directory (elsub "templates"))
    )

  (eload 'ediprolog)                    ;Emacs does Interactive Prolog

  (when (eload 'pp-c-l)            ;Display Control-l characters in a pretty way
    (pretty-control-l-mode -1)     ; Turn on pretty display of `^L'.
    )

  (if (fboundp 'icicle-find-first-tag)
      (global-set-key "\M-." 'icicle-find-first-tag))

  ;; Wikipedia Mode
  ;; See: http://en.wikipedia.org/wiki/Wikipedia:Wikipedia-mode.el
  (when nil                  ;TODO Disabled because it changes my key-bindings.
    (autoload 'wikipedia-mode "wigkipedia-mode.el"
      "Major mode for editing documents in Wikipedia markup." t)
    (add-to-list 'auto-mode-alist '("\\.wiki\\'" . wikipedia-mode)))

  ;; File System Tree Traversals/Operation
  (eload 'pnw-findr)                    ;modified version of pnw-findr.el

  (when nil ;NOTE: Warning: Disabled because it defines its own file-compressed-p()
    (when (eload 'traverselisp) ;elisp implementations of rgrep, grep-find, grep, etc...
      ;; Use: (traverse-deep-rfind "/etc" "tab")
      (delete ".svg" traverse-ignore-files) ;NOTE: We may want to edit SVG-files...
      ))

  (when (eload 'sregex) ;Symbolic Regular Expressions - Humaner specification of regular expressions.
    ;; Use: (sregexq (opt (or "Per" "Bengt" "Anna-Karin")))
    )

  (eload 'escreen)                      ;emacs window session manager

  ;; See: http://journal.dedasys.com/articles/2008/06/06/indent-region-as
  ;; TODO I'd use ``make-indirect-buffer'' for this; that way, you
  ;; can have all the bells and whistles of the programming language
  ;; in question (syntax highlighting, etc) while the text ends up in
  ;; the HTML buffer.
  (defun indent-region-as (other-mode)
    "Indent selected region as some other mode.  Used in order to
indent source code contained within HTML."
    (interactive "aMode to use: ")
    (save-excursion
      (let ((old-mode major-mode))
        (narrow-to-region (region-beginning) (region-end))
        (funcall other-mode)
        (indent-region (region-beginning) (region-end) nil)
        (funcall old-mode)))
    (widen))

  (eload 'buffer-bg) ;Changing background color of windows. See: http://www.emacswiki.org/cgi-bin/wiki/BufferBackgroundColor
  (eload 'abc-mode)  ;Major mode for editing abc music files

  ;; remote login interface
  (when (eload 'ftelnet)
    (global-set-key [(control c) (T)] 'ftelnet)
    )

  (when (eload 'wordnet)
    (global-set-key [(control c) (w)] 'wordnet-search)
    )

  ;; NOTE: Disabled for now because it slows down font-locking.
  ;; (eval-after-load "font-lock" '(eload 'font-lock+)) ;Enhancements to standard library `font-lock.el'.

  ;; file-journal.el --- revisit files by date
  ;; TODO Add this logic into session.el by adding read/write timestamps (already in file permissions).
  (when (and nil (eload 'file-journal))
    (setq fj-journal-file (elsub "file-journal"))
    (setq fj-journal-size 365)
    (setq fj-save-timer-interval 60)
    )

  (eload 'indirect-region)           ;Edit the current region in another buffer.

  ;; tie-mode.el --- Tie code editing commands for GNU Emacs
  (add-to-list 'auto-mode-alist '("\\.tie\\'" . tie-mode))

  ;; Extensions to standard library tool-bar.el
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/ToolBar
  (when (eload 'tool-bar+ (elsub "others") "tool-bar+.el")
    (tool-bar-pop-up-mode 1))

  ;; Show menubar only when the mouse is at the top of the frame.
  (when (eload 'active-menu (elsub "others") "active-menu.el"
               "http://www.skamphausen.de/cgi-bin/ska/active-menu.el")
    (active-menu 1))

  (eload 'codepad (elsub "emacs-codepad/") "codepad.el" nil "git://github.com/ruediger/emacs-codepad.git") ;Emacs integration for codepad.org

  (eload 'notify (elsub "others") "notify.el")
  (eload 'notify-app (elsub "emacs-codepad/") "notify-app.el")

  ;; Fringe Stuff
  (when (eload 'rfringe) ;display the relative location of the region, in the fringe. See: http://www.emacswiki.org/emacs-en/RFringe
    )
  (when (eload 'fringe-helper) ;helper functions for fringe bitmaps. See: http://nschum.de/src/emacs/fringe-helper/
    )
  (when nil
    (when (eload 'hideshow-fringe))
    ;; hideshowvis.el --- Add markers to the fringe for regions foldable by hideshow.el
    (when (load-file-if-exist (elsub "hideshowvis.elc"))
      (autoload 'hideshowvis-enable "hideshowvis" "Highlight foldable regions")
      (when nil
        (dolist (hook (list 'lisp-mode-hook
                            'emacs-lisp-mode-hook
                            'c-mode-common-hook
                            'python-mode-hook
                            ))
          (add-hook hook 'hideshowvis-enable))
        )
      )
    (when (eload 'fringe-mark))
    )

  (when (eload 'df-mode)            ;show space left on devices in the mode line
    (df-mode 1))

  (eload 'mwe-color-box (elsub "others") "mwe-color-box.el")

  (when (eload 'pmdb-mode)
    (add-to-list 'auto-mode-alist '("\\.PMDB\\'" . pmdb-mode)))

  ;; TODO Support case when `mark-active' is non-nil.
  (defun count-all-buffer (&optional buffer)
    "Count number of characters and words in BUFFER."
    (interactive)
    (save-excursion                     ;function doesn't affect the cursor
      (let ((wc 0)                      ;word count
            (cc (- (point-max) (point-min)))) ;char count
        (goto-char (point-min))
        (while (< (point) (point-max))
          (forward-word 1)
          (setq wc (1+ wc)))
        (message "Buffer contains %d chars and %d words."
                 (if (> cc 0) cc "no")
                 (if (> wc 0) wc "no")
                 ))))
  ;; Use: (count-all-buffer)
  (if (file-exists-p (elsub "wcount-mode.el"))
      (progn
        (autoload 'wcount-mode "wcount-mode.el"
          "Keep a running count of words in a buffer." t)
        (wcount-mode 10)))

  (eload 'incr (elsub "others") "incr.el")          ;Increase everything as you want

  (eload 'fuzzy-match)                  ;fuzzy matching

  (eload nil (elsub "others") "auto-async-byte-compile.el")
  (eload nil (elsub "others") "auto-install.el")
  (eload nil (elsub "others") "auto-install-batch-list.el")
  ;;(eload nil (elsub "others") "auto-install-extensions.el")

  (eload 'hexview-mode)                 ;A simple & fast hexadecimal file viewer

  ;; Yodl
  (when (eload 'yodl)
    (add-to-list 'auto-mode-alist '("\\.yo\\'" . yodl-mode))
    (add-to-list 'auto-mode-alist '("\\.yodl\\'" . yodl-mode))
    )

  ;; ===========================================================================================

  (eload 'register-list)              ;Interactively list/edit registers
  (when (eload 'ell))                 ;Emacs Lisp List
  (when (eload 'w3))                  ;Emacs/W3
  (when (eload 'find-func-extension)) ;Some extension functions for `find-func.el'.

  ;; babel.el --- interface to web translation services such as Babelfish
  ;;  * the Babelfish service at babelfish.yahoo.com
  ;;  * the Google service at translate.google.com
  ;;  * the Transparent Language motor at FreeTranslation.com
  (when (eload 'babel)
    ;; Use: (babel-as-string "Define a project root")
    )

  (when (eload 'find-cmd)               ;NOTE: For earlier Emacses
    ;; Define a project root and take actions based upon it.
    (when (eload 'project-root))
    )

  ;; ===========================================================================================
  ;; Printing

  (setq lpr-command "lpr")              ;print command
  (setq lpr-switches '("-Plp"))         ;print options

  ;; Pretty print buffer to other buffer *Postscript*
  ;; 1. M-x ps-spool-buffer-with-faces
  ;; 2. Save the buffer *Postscript* to disk fand view with a postscript
  ;;    interpreter program like gv.
  (when (eload 'ps-print)               ;print buffer as postscript
    (defun pnw-print ()
      (interactive)
      (setq ps-landscape-mode 1)        ;landscape mode
      (setq ps-number-of-columns 2)     ;two columns
      (ps-spool-buffer-with-faces)
      (switch-to-buffer "*PostScript*")
      (ps-mode)
      )
    )

  ;; ===========================================================================================
  ;; X selection manipulation

  (defun x-own-selection (s)
    (x-set-selection `PRIMARY s))

  ;; openpaste.el -- Emacs interface to OpenPastebin
  ;; Depends on xml-rpc  (http://www.emacswiki.org/cgi-bin/wiki/XmlRpc)
  (when (and (eload 'xml-rpc)
             (eload 'openpaste))
    (autoload 'openpaste-region "openpaste")
    (define-key global-map (kbd "C-x p") 'openpaste-region)
    )

  ;; xml-gen.el --- A DSL for generating XML.
  (when (eload 'xmlgen)
    )

  ;; prove.el --- A DSL for generating XML.
  (when (eload 'prove)
    )

  ;; amixer.el --- Control AMixer from Emacs
  (when (eload 'amixer)
    )

  (put 'upcase-region 'disabled nil) ;Change to Motif, MAC or MS-Windows Cut and Paste Style.

  ;; ===========================================================================================
  ;; See: http-post-simple.el --- HTTP POST requests using the url library

  ;; Provides ways to use the url library to perform HTTP POST requests.
  ;; See the documentation to `http-post-simple' and `http-post-multipart'
  ;; for more information.

  (eload 'http-post-simple)

  ;; ===========================================================================================
  ;; control-lock.el --- Like caps-lock, but for your control key.  Give you pinky a rest!
  (eload 'control-lock)

  ;; ===========================================================================================
  ;; Coding Systems

  ;; Use the following for i18n to get swedish characters:

  ;; This sets the coding system priority and the default input method
  ;; and sometimes other things.  LANGUAGE-NAME should be a string
  ;; which is the name of a language environment.  For example, "Latin-1"
  ;; specifies the character set for the major languages of Western Europe.
  ;; (set-language-environment "Latin-1")

  ;; When this mode is enabled, characters in the range of 160 to 255
  ;; display not as octal escapes, but as accented characters.  Codes 146
  ;; and 160 display as apostrophe and space, even though they are not the
  ;; ASCII codes for apostrophe and space.
  ;; NOTE: Enable this?:
  ;; (set-language-environment "Latin-1")

  ;; Add coding-system at the front of the priority list for automatic detection.
  ;; (prefer-coding-system 'mule-utf-8-unix)

  ;; Coding system to be used for encoding the buffer contents on saving.
  ;; This makes the *compilation* buffer interpret locale gcc messages as
  ;; unicode which is good.
  ;; (setq buffer-file-coding-system 'mule-utf-8)

  ;; Set input method.
  ;;(set-input-method 'mule-utf-8)

  ;; > How do I make compilation-mode read and respect this locale when I
  ;; > compile from within emacs, inside compilation-mode? My installation
  ;; > (latest CVS version of Emacs) interprets it iso-latin-1.

  ;; NOTE: This make GCC output be correctly interpreted displayed in the buffer *compilation*
  ;; (set-default-coding-systems 'mule-utf-8-unix)

  ;; if you want to use utf-8 only for compiling, but I doubt it...
  ;; This fails for me so comment it away.
  ;; (remove-hook 'compilation-mode-hook
  ;;         (lambda () (set-process-coding-system 'utf-8)))

  ;; > I guess we should use the result of (getenv "LANG") to somehow setup
  ;; > the buffer-file-coding system.

  ;; That could help, but the situations are oftem more complex, you may
  ;; want to use different coding systems with different files or
  ;; processes...

  ;; I added this line to ~/.emacs and i got dead-keys worrking again:
  ;; NOTE: Not need anymore.. 2008-09-01
  ;;(load-library "iso-transl")

  ;; ===========================================================================================
  ;;

  (eload 'gutenberg-coding)         ;coding system for Project Gutenberg EBooks.
  (GNUEmacs-21 (eload 'html-coding)) ;coding system from meta in html files (for Emacs 21)

  ;; ===========================================================================================
  ;; Load Gentoo things (if present).

  (GNUEmacs-21
   (load-file-if-exist "/usr/share/emacs/site-lisp/site-gentoo.el"))

  ;; ===========================================================================================
  ;; Spell Checking

  ;; Use aspell instead of ispell
  ;; The easiest way to use Aspell with Emacs or Xemacs is to add this line
  (setq-default ispell-program-name "aspell")

  ;; For some reason version 3.0 of ispell.el (the lisp program that (x)emacs
  ;; uses) want to reverse the suggestion list. To fix this add this line:
  (setq-default ispell-extra-args '("--reverse"))

  ;; speck.el --- minor mode for spell checking
  (when (eload 'speck)
    )

  ;; ===========================================================================================
  ;; flydoc.el --- on-the-fly documentation

  (when (eload 'flydoc)
    (flydoc-default-setup)
    ;; (global-flydoc-mode 1)
    ;; (global-set-key "\C-ce" 'flydoc-explain)
    )

  ;; ===========================================================================================
  ;; auto-dictionary
  ;; See: http://nschum.de/src/emacs/auto-dictionary/

  ;; What's this for?  dictionary-switcher-mode tries to guess the
  ;; buffer's text language and adjusts ispell/flyspell automatically.
  ;; Currently English, German, French, Spanish and Swedish are somewhat
  ;; supported, but extensions should be pretty straightforward.
  ;; (Please contact me, if you'd like to contribute.)

  ;; Usage Just type. When you stop for a few moments
  ;; dictionary-switcher-mode will evaluate the content.  If you're
  ;; unhappy with the results, call adict-change-dictionary to change
  ;; it.  Use switch-language-hook to hook into these changes.

  (when nil
    (when (eload 'auto-dictionary)
      (add-hook 'flyspell-mode-hook (lambda () (auto-dictionary-mode 1)))))

  ;; ===========================================================================================

  (when (eload 'auto-diff)
    )

  ;; ===========================================================================================
  ;; completing-help.el --- an enhancement to `display-completion-list'

  (when (eload 'completing-help)
    )

  ;; ===========================================================================================
  ;; See: http://www.emacswiki.org/cgi-bin/emacs-en/CompanyMode
  ;; company-mode: http://nschum.de/src/emacs/company-mode/

  (when (eload 'company-mode)
    (company-mode 1)
    ;; ToDo: Replace default keybinding (TAB) for company
    ;; completion/expand with M-tab.
    )

  ;; ===========================================================================================
  ;; fork of company-mode.el, with code from auto-complete.el and completion
  ;; http://github.com/jeffdameth/ca2/tree/master

  (when nil                             ;NOTE: Disabled because it overrides TAB
    (when (eload 'ca2+)
      ;; either enable ca-mode per buffer via (ca-mode 1) or (global-ca-mode 1)
      ;; to enable it in all buffer that match 'ca-modes'

      (when (eload 'ca2+sources)
        )

      (when (eload 'ca2+config)
        )
      )
    )

  ;; ===========================================================================================

  ;; pair-mode.el --- insertion of paired characters
  ;; NOTE: Why is not insert-parentheses() enough?

  (defcustom pnw/use-pair-mode t
    "Flags whether or not to load pair-mode upon startup." :type 'boolean :group 'pnw-options)

  (when (and pnw/use-pair-mode
             (eload 'pair-mode))
    ;;(global-pair-mode nil)                ;NOTE: Disable for now because we only want this in certain cases
    )

  ;; ;; insert-pair()
  ;; (if nil
  ;;     (progn
  ;;       (add-to-list 'insert-pair-alist '(?“ ?”))
  ;;       (add-to-list 'insert-pair-alist '(?‘ ?’))
  ;;       (add-to-list 'insert-pair-alist '(?+ ?+))
  ;;       (define-key osx-key-mode-map "\M-'" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\M-\"" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\M-\‘" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\M-[" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\M-+" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\C-c`" 'insert-pair)
  ;;       (define-key osx-key-mode-map "\C-cp" 'delete-pair)
  ;;       )
  ;;   )

  ;; ===========================================================================================
  ;; time-stamp
  ;; (add-hook 'before-save-hook 'time-stamp)
  ;; copyright
  ;; (add-hook 'before-save-hook 'copyright-update)

  ;; ===========================================================================================
  ;; misc-fns.el

  ;; This toggles on/off the menu and tool bars for more editing area.
  (defvar stark-frame () )
  (defun stark-frame () "Toggle toobar & menu bar on/off."
    (interactive)
    (setq stark-frame (not stark-frame))
    (tool-bar-mode (if stark-frame 0 1))
    (menu-bar-mode (if stark-frame 0 1))
    (if stark-frame
        (set-frame-size (selected-frame)(frame-width)(+ (frame-height) 1))
      (set-frame-size (selected-frame)(frame-width)(- (frame-height) 1))))

  (global-set-key (kbd "<S-f10>") 'stark-frame)

  ;; This is really annoying!
  (auto-raise-mode -1)

  ;; NOTE: this is the original version defined in frame.el
  (if nil
      (defun special-display-popup-frame (buffer &optional args)
        "Display BUFFER in its own frame, reusing an existing window if any.
Return the window chosen.
Currently we do not insist on selecting the window within its frame.
If ARGS is an alist, use it as a list of frame parameter specs.
If ARGS is a list whose car is a symbol,
use (car ARGS) as a function to do the work.
Pass it BUFFER as first arg, and (cdr ARGS) gives the rest of the args."
        (if (and args (symbolp (car args)))
            (apply (car args) buffer (cdr args))
          (let ((window (get-buffer-window buffer 0)))
            (or
             ;; If we have a window already, make it visible.
             (when window
               (let ((frame (window-frame window)))
                 (make-frame-visible frame)
                 (raise-frame frame)
                 window))
             ;; Reuse the current window if the user requested it.
             (when (cdr (assq 'same-window args))
               (condition-case nil
                   (progn (switch-to-buffer buffer) (selected-window))
                 (error nil)))
             ;; Stay on the same frame if requested.
             (when (or (cdr (assq 'same-frame args)) (cdr (assq 'same-window args)))
               (let* ((pop-up-frames nil) (pop-up-windows t)
                      special-display-regexps special-display-buffer-names
                      (window (display-buffer buffer)))
                 ;; Only do it if this is a new window:
                 ;; (set-window-dedicated-p window t)
                 window))
             ;; If no window yet, make one in a new frame.
             (let ((frame
                    (with-current-buffer buffer
                      (make-frame (append args special-display-frame-alist)))))
               (set-window-buffer (frame-selected-window frame) buffer)
               (set-window-dedicated-p (frame-selected-window frame) t)
               (frame-selected-window frame))))))
    )

  ;; ===========================================================================================
  ;; frame-restore.el

  ;; ToDo: Test and then activate as default.
  (when nil
    (eload 'frame-restore)
    )

  ;; ===========================================================================================
  ;; centered-cursor-mode.el --- cursor stays vertically centered

  (when (eload 'centered-cursor-mode)
    ;; To activate do:
    ;;   M-x ccm
    ;; or
    ;;   M-x centered-cursor-mode
    )

  ;; ===========================================================================================
  ;; rcirc-color.el -- color nicks

  (when window-system
    (when (eload 'rcirc-color)
      )
    (when (eload 'rcirc-controls)
      )
    )

  ;; ===========================================================================================
  ;; subedit.el --- edit part of a buffer in a new buffer

  (when (eload 'subedit)
    )

  ;; ===========================================================================================
  ;; mthesaur.el --- Thesaurus look-up of a word or phrase.
  ;; See: ftp://ibiblio.org/pub/docs/books/gutenberg/etext02/mthes10.zip

  (setq mthesaur-file
        (expand-file-name (substitute-in-file-name "~/mthes10/mthesaur.txt")))

  (when (eload 'mthesaur)
    (global-set-key "\C-ct" 'mthesaur-search)
    ;; (global-set-key "\C-c\C-t" 'mthesaur-search-append)

    ;; NOTE: Added the line (shrink-window-if-larger-than-buffer (get-buffer-window results-buf)):
    (when (eload 'mthesaur-util)
      ))

  ;; ===========================================================================================
  ;; sh-beg-end.el --- Something for C-M-a,

  (when (eload 'sh-beg-end)
    )

  ;; ===========================================================================================
  ;; doc-view.el --- View PDF/PostScript/DVI files in Emacs

  (when (eload 'doc-view)
    )

  ;; ===========================================================================================
  ;; defstruct+.el --- extensions to Common Lisp structs

  ;; WARNING: This ruins font-locking for several modes such as emacs-lisp-mode.
  ;; So I disable it!. NOTE: This bug is now fixed so I enable it again!
  (when (eload 'defstruct+)
    )

  ;; ===========================================================================================

  (defcustom pnw/use-iswitchb nil
    "Flags whether or not to load and use iswitchb." :type 'boolean :group 'pnw-options)

  (defcustom pnw/use-ido nil
    "Flags whether or not to load ido upon startup." :type 'boolean :group 'pnw-options)

  (defcustom pnw/use-mcomplete nil
    "Flags whether or not to load mcomplete upon startup. Features may
  conflict with Icicles minibuffer completion and history search."
    :type 'boolean :group 'pnw-options)

  (defcustom pnw/use-icomplete nil
    "Flags whether or not to load icomplete upon startup." :type 'boolean :group 'pnw-options)

  (when (and pnw/use-ido
             (eload 'ido))
    ;; To avoid bug: Recursive load of tramp. Use this instead of (ido-mode 1)
    (add-hook 'term-setup-hook 'ido-mode)
    ;; (ido-mode 1)
    (setq ido-enable-flex-matching t)      ;expand/complete acronymus
    (setq ido-confirm-unique-completion t) ;consistent with standard behaviour
    (setq ido-show-dot-for-dired t)        ;consistent with standard behaviour
    (ido-everywhere t)     ;use ido everywhere file and directory names are read
    ;;(ido-toggle-regexp) ;use ido everywhere file and directory names are read
    )
  ;;(ido-completing-read "ido-completing-read test: " '("alpha" "beta" "gamma"))

  ;; iswitchb - IswitchBuffer
  (when (and pnw/use-iswitchb
             (eload 'iswitchb))


    )

  (setq iswitchb-default-method 'samewindow) ;stay in current frame
  (setq iswitchb-max-to-show nil)            ;no limit

  ;; For more about iswitch-buffer, see UseIswitchBuffer.
  (when (eload 'iswitchb-pnw-highlight))

  ;; iswitchb ignores
  (when nil
    (add-to-list 'iswitchb-buffer-ignore "^\\*") ;starting with a star
    (add-to-list 'iswitchb-buffer-ignore "^ ")
    (add-to-list 'iswitchb-buffer-ignore "*Messages*")
    (add-to-list 'iswitchb-buffer-ignore "*ECB")
    (add-to-list 'iswitchb-buffer-ignore "*Buffer")
    (add-to-list 'iswitchb-buffer-ignore "*Completions")
    (add-to-list 'iswitchb-buffer-ignore "*ftp ")
    (add-to-list 'iswitchb-buffer-ignore "*bsh")
    (add-to-list 'iswitchb-buffer-ignore "*jde-log")
    (add-to-list 'iswitchb-buffer-ignore "^[tT][aA][gG][sS]$")
    )

  ;; iswitchb-fc
  ;;============================================================
  (when (eload 'filecache)
    ;; (load "iswitchb-fc")
    )

  (if pnw/use-mcomplete
      (if (eload 'mcomplete)
          (progn
            (autoload 'mcomplete-mode "mcomplete"
              "Toggle minibuffer completion with prefix and substring matching."
              t nil)
            (autoload 'turn-on-mcomplete-mode "mcomplete"
              "Turn on minibuffer completion with prefix and substring matching."
              t nil)
            (autoload 'turn-off-mcomplete-mode "mcomplete"
              "Turn off minibuffer completion with prefix and substring matching."
              t nil)

            ;; If you want to activate this package as you start Emacs do
            (turn-on-mcomplete-mode)

            (setq mcomplete-default-method-set
                  '(mcomplete-prefix-method mcomplete-substr-method))

            (load "mcomplete-history")
            )))

  (if pnw/use-icomplete
      (eval-after-load "icomplete" '(progn (eload 'icomplete+)))
    (when (require 'pcomplete nil t)
      (icomplete-mode 1)
      )
    )

  ;; ===========================================================================================
  ;; see: http://www.emacswiki.org/emacs-en/AutoComplete
  ;; see: http://emacs-fu.blogspot.com/2010/10/auto-complete-mode.html
  ;; auto-complete.el --- Auto completion with popup menu

  (when (eload 'auto-complete)
    ;; (global-auto-complete-mode 1)
    )
  (when (eload 'auto-complete+)
    )
  ;; auto-complete-etags.el ---
  (when (eload 'auto-complete-etags)
    )
  ;; auto-complete-verilog.el ---
  (when (eload 'auto-complete-verilog)
    )
  ;; auto-complete-octave.el ---
  (when (eload 'auto-complete-octave)
    )

  ;; ===========================================================================================

  ;; A similar result more in the spirit of Emacs would just extend
  ;; Isearchôòùs facilities to yank items from the cursor position in the
  ;; buffer. For instance, Isearch has a binding for yanking
  ;; s-expressions from the buffer. However, an s-expression is a
  ;; broader definition than the symbol of a common imperative
  ;; programming language. The yank needs to be only generic enough for
  ;; identifiers (ôòüsymbolsôòý). ôòøC-M-wôòù is an obvious binding in
  ;; Isearch for this ôòüsymbol yankôòý.

  (when (eload 'etags)
    (if (not (boundp 'tags-complete-tag))
        ;; NOTE: For later Emacses that renames tags-complete-tag() to
        ;; tags-complete-tags-table-file();
        (defalias 'tags-complete-tag 'tags-complete-tags-table-file)
      )

    (defun etags-verify-tags-table-alt ()
      "Return non-nil if the current buffer is a valid etags TAGS file."
      ;; Use eq instead of = in case char-after returns nil.
      (or (eq (char-after (point-min)) ?\f))
      )
    ;; NOTE: Override to accept ECtags tables aswell.
    (setq verify-tags-table-function 'etags-verify-tags-table-alt)
    )

  ;; etags-extension.el --- A collect extensions for etags.
  (when (eload 'etags-extension)
    )

  ;; etags-stack.el --- Navigate the tags stack
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/EtagsStack
  (when (eload 'etags-stack)
    )

  ;; etags-select.el --- Select from multiple tags
  (defcustom pnw/use-etags-select nil
    "Flags whether or not to use etags-select upon startup." :type 'boolean :group 'pnw-options)
  (if pnw/use-etags-select
      (when (eload 'etags-select)
        (global-set-key "\M-?" 'etags-select-find-tag-at-point))
    )

  ;; The command ôòøC-s C-M-w C-sôòù defined here will search for the
  ;; entire symbol at the current point. This shorter implementation
  ;; than the one above of ôòøisearch-yank-symbolôòù always uses ôòüword
  ;; searches and does not alternatively offer ôòüpartialôòý searches. A
  ;; generally useful feature for Isearchôòùs extensibility would allow
  ;; one to search by yanking the entire thing at a point (see
  ;; ThingAtPoint) and not only something starting at point.

  (defun my-tags-search (arg regexp &optional file-list-form)
    "Search through all files listed in tags table for match for REGEXP.
Stops when a match is found.
To continue searching for next match, use command
\\[tags-loop-continue].

See documentation of variable `tags-file-name'.
With prefix arg, force case-sensitivity"
    (interactive "P\nsTags search (regexp): ")
    (let ((search-function (if arg 're-search-forward-sensitive
                             're-search-forward)))
      (if (and (equal regexp "")
               (eq (car tags-loop-scan) search-function)
               (null tags-loop-operate))
          ;; Continue last tags-search as if by M-,.
          (tags-loop-continue nil)
        (setq tags-loop-scan
              (list search-function (list 'quote regexp) nil t)
              tags-loop-operate nil)
        (tags-loop-continue (or file-list-form t)))))

  (eload 'xgtags)

  ;; ===========================================================================================

  (when (eload 'idutils)
    (global-set-key [(control c) (i)] 'gid)
    )

  ;; ===========================================================================================
  ;; buffer-move.el ---
  (when (eload 'buffer-move)
    ;; (global-set-key (kbd "<C-S-up>")     'buf-move-up)
    ;; (global-set-key (kbd "<C-S-down>")   'buf-move-down)
    ;; (global-set-key (kbd "<C-S-left>")   'buf-move-left)
    ;; (global-set-key (kbd "<C-S-right>")  'buf-move-right)
    )

  ;; ===========================================================================================
  ;; Buffer Navigation

  (defun switch-to-other-buffer ()
    (interactive)
    (switch-to-buffer (other-buffer)))

  ;; Shortcuts for Buffer Navigation
  (global-set-key [(control shift f6)] 'list-buffers)
  ;;(global-set-key [(control f6)] 'switch-to-other-buffer)
  (global-set-key [(control f6)] 'other-window)
  (global-set-key [(f6)] 'switch-to-buffer)

  ;; Buffer Cyclic Navigation

  (defalias 'switch-to-next-buffer 'bury-buffer)

  (defun toggle-switch-to-previous-buffer ()
    (interactive)
    (switch-to-buffer (other-buffer)))

  ;; Buffer Navigation (Borland Pascal Style)
  (defun toggle-two-buffers ()
    (interactive)
    (switch-to-buffer (elt (buffer-list) 1)))

  (defun switch-to-previous-buffer ()
    "Switch to previous buffer."
    (interactive)
    (switch-to-buffer (elt (buffer-list) (- (length (buffer-list)) 1)))
    )

  (global-set-key [(control x) (control left)] 'switch-to-previous-buffer)
  (global-set-key [(control x) (control right)] 'switch-to-next-buffer)

  ;;(global-set-key [(control shift iso-lefttab)] 'switch-to-previous-buffer)
  ;;(global-set-key [-backtab] 'switch-to-previous-buffer)
  ;;(global-set-key [(control tab)] 'switch-to-next-buffer)
  ;;(global-set-key [\C-tab] 'next-buffer)
  ;;(global-set-key [\C-\S-tab] 'previous-buffer)

  (defun switch-buffers-between-frames ()
    "switch-buffers-between-frames switches the buffers between the two last frames"
    (interactive)
    (let ((this-frame-buffer nil)
          (other-frame-buffer nil))
      (setq this-frame-buffer (car (frame-parameter nil 'buffer-list)))
      (other-frame 1)
      (setq other-frame-buffer (car (frame-parameter nil 'buffer-list)))
      (switch-to-buffer this-frame-buffer)
      (other-frame 1)
      (switch-to-buffer other-frame-buffer)))

  ;; Electric Buffers makes it a loss less painful to change buffers:
  ;; your cursor immediately goes to the correct window when you go C-x
  ;; C-b.

  ;; Use the "electric-buffer-list" instead of "buffer-list"
  ;; so that the cursor automatically switches to the other window
  ;; (global-set-key "\C-x\C-b" 'electric-buffer-list)

  (minibuffer-electric-default-mode 1)

  ;; ===========================================================================================

  ;; Some of these things can be done already via file groups, etc. but
  ;; here are some easy things to use:
  (defun search-buffers (str)
    (interactive "sregex:")
    (let
        ((pt) (buf))
      (foreachbuffer
       (goto-char 0)
       (let ((dosearch (lambda  () (if (re-search-forward str nil t)
                                       (progn (setq pt (point))
                                              (setq buf i)
                                              (case (read-char "(c)ontinue (q)uit (n)ext buffer:")
                                                (?n nil)
                                                (?q (error "done."))
                                                (t (funcall dosearch)))))))
             )
         (funcall dosearch))))
    (if pt
        (progn
          (switch-to-buffer buf)
          (goto-char pt))
      ))


  ;; ===========================================================================================
  ;; Conversions

  ;; Wrap all lines.
  (defun wrap-all-lines ()
    "Enable line wrapping"
    (interactive)                       ;this makes the function a command too
    (set-default 'truncate-lines nil))

  ;; ===========================================================================================

  ;; visible-lines.el
  (when (eload 'visible-lines)
    (defun move-end-of-visible-line (&optional line)
      "Move to the end of current visible line."
      (interactive "p")
      (beginning-of-visible-line line)
      (let ((point (point-at-eol)))
        (vertical-motion 1)
        (unless (= point (point-max))
          (backward-char))))
    ;;   (defun end-of-visible-line (&optional line)
    ;;     "..."
    ;;     (move-end-of-visible-line (or line 1)))
    )

  ;; ===========================================================================================

  ;; jpeg-mode.el
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/JpegMode
  (when (eload 'jpeg-mode)
    )

  ;; ===========================================================================================
  ;; smart-dnd.el --- user-configurable drag-n-drop feature

  (when (eload 'smart-dnd)
    ;; (smart-dnd-setup
    ;;  '(
    ;;    ("\\.png\\'" . "image file: %f\n")
    ;;    ("\\.jpg\\'" . "image file: %f\n")
    ;;    (".exe\\'"   . (message (concat "executable: " f)))
    ;;    (".*"        . "any filename: %f\n")
    ;;    ))
    )

  ;; ===========================================================================================

  ;; help-dwim.el --- Show help information
  (when (eload 'help-dwim))

  ;; help-dwim-perldoc.el
  (when (eload 'help-dwim-perldoc))

  ;; motion-and-kill-dwim.el --- Motion and kill DWIM commands
  (when (eload 'motion-and-kill-dwim))

  ;; ===========================================================================================

  ;; This tiny piece of code does something that I keep finding myself
  ;; wanting. Given a list of regular expressions, search-list returns a list
  ;; containing the matches with their beginning and ending positions in the
  ;; buffer.

  ;; I would very much like to know if something like this already exists. If
  ;; so, my apologies.

  (if nil
      (progn
        (GNUEmacs-21-4
         (setq meta-search-list
               '(defun search-list (l)
                  (flet ((search-list-make-res (beg end str)
                                               (list (cons beg end) str)))
                    (let (res)
                      (mapcar
                       (lambda (l)
                         (save-excursion ;function doesn't affect the cursor
                           (goto-char (point-min))
                           (while (re-search-forward l (point-max) t)
                             (push (search-list-make-res (match-beginning 0)
                                                         (match-end 0)
                                                         (match-string-no-properties 0))
                                   res))))
                       l)
                      res)))))

        (GNUEmacs-21-4 (eval meta-search-list))

        ;; Example usage
        (GNUEmacs-21-4 (search-list '("Yoni")))
        ))

  ;; "Cut your own wood and it will warm you twice"
  ;; Regards, Yoni Rabkin Katzenell

  ;; ===========================================================================================
  ;; Line Functions

  (defun sort-words-in-lines (start end)
    (interactive "r")
    (goto-char start)
    (beginning-of-line)
    (while (< (setq start (point)) end)
      (let ((words (sort (split-string (buffer-substring start (line-end-position)))
                         (function string-lessp))))
        (delete-region start (line-end-position))
        (dolist (word words ) (insert word " ")))
      (beginning-of-line) (forward-line 1)))
  ;; alpha gamma beta delta

  (defun mark-line-and-copy ()
    "Copy the current line into the kill ring."
    (interactive)
    (let ((k
           (if (>= (buffer-size) (line-end-position))
               1
             0)))
      (kill-ring-save (line-beginning-position)
                      (+ k (line-end-position)))
      (message "Line copied")))

  (defun duplicate-line ()
    "Copy this line under it; put point on copy in current column." ;
    (interactive)
    (let ((start-column (current-column)))
      (save-excursion
        (mark-line-and-copy)            ;save-excursion restores mark
        (move-to-column 0)
        (yank))
      (move-to-column start-column))
    (message "Line duplicated"))

  (when nil
    (global-unset-key (kbd "C-l"))
    (global-set-key (kbd "C-l C-l")  'duplicate-line)
    ;; (global-set-key (kbd "C-l C-d")  'kill-line) ; write this one
    (global-set-key (kbd "C-l C-c")  'mark-line-and-copy)
    )

  (eload 'calc-util)

  ;; ===========================================================================================

  ;; shell-completion.el --- provides tab completion for shell commands
  (when
      (eload 'shell-completion)
    ;;(defvar my-lftp-sites (shell-completion-get-file-column "~/.lftp/bookmarks" 0 "[ \t]+"))
    (defvar my-lftp-sites "")
    (add-to-list 'shell-completion-options-alist
                 '("lftp" my-lftp-sites))
    (add-to-list 'shell-completion-prog-cmdopt-alist
                 '("lftp" ("help" "open" "get" "mirror") ("open" my-lftp-sites)))
    )

  ;; ===========================================================================================
  ;; Firefox-like zooming of fonts.

  (when nil
    (setq default-font-zoom-index 2)
    (setq font-zoom-index default-font-zoom-index)

    (setq font-zoom-list
          (list "-*-fixed-*-*-*-*-6-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-10-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-13-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-17-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-18-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-24-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-36-*-*-*-*-*-*-*"
                "-*-fixed-*-*-*-*-48-*-*-*-*-*-*-*"))

    (defun font-zoom-increase-font-size ()
      (interactive)
      (progn
        (setq font-zoom-index (min (- (length font-zoom-list) 1)
                                   (+ font-zoom-index 1)))
        (set-frame-font (nth font-zoom-index font-zoom-list))))

    (defun font-zoom-decrease-font-size ()
      (interactive)
      (progn
        (setq font-zoom-index (max 0
                                   (- font-zoom-index 1)))
        (set-frame-font (nth font-zoom-index font-zoom-list))))

    (defun font-zoom-reset-font-size ()
      (interactive)
      (progn
        (setq font-zoom-index default-font-zoom-index)
        (set-frame-font (nth font-zoom-index font-zoom-list))))

    ;; (define-key global-map (read-kbd-macro "C--") 'font-zoom-decrease-font-size)
    ;; (define-key global-map (read-kbd-macro "C-=") 'font-zoom-increase-font-size)
    ;; (define-key global-map (read-kbd-macro "C-0") 'font-zoom-reset-font-size)

    ;; (set-frame-font (nth font-zoom-index font-zoom-list))
    )

  ;; ===========================================================================================

  ;; Mac OS X specifics.

  (if darwin-p
      (progn
        ;; set a smaller font. maybe too small for some...
        (when nil
          (set-default-font
           "-apple-monaco-medium-r-normal--10-100-75-75-m-100-mac-roman"))

        ;; we probably don't want this in any case, cause it makes it impossible
        ;; to write swedish characters
        ;;(setq mac-command-key-is-meta nil)

        (when nil                       ;if non-nil active mac keybinding
          (global-set-key [(alt a)] 'mark-whole-buffer)
          (global-set-key [(alt v)] 'yank)
          (global-set-key [(alt c)] 'kill-ring-save)
          (global-set-key [(alt x)] 'kill-region)
          (global-set-key [(alt s)] 'save-buffer)
          (global-set-key [(alt l)] 'goto-line)
          (global-set-key [(alt o)] 'find-file)
          (global-set-key [(alt f)] 'isearch-forward)
          (global-set-key [(alt g)] 'isearch-repeat-forward)
          (global-set-key [(alt w)]
                          (lambda ()
                            (interactive)
                            (kill-buffer (current-buffer))))
          )

        ;; use spotlight as a stand-in for locate on osx:
        (defun spotlight ()
          (interactive)
          (let ((locate-command "mdfind"))
            (call-interactively 'locate nil)))

        (eload 'mdfind)
        ))

  ;; ===========================================================================================
  ;; font locking adjustments

  ;; new in 21.4: set font-lock-maximum-decoration correctly.

  ;; setting specific fonts.
  ;;(setq veramono "fixed")
  ;;(add-to-list 'default-frame-alist (cons 'font veramono))

  ;; *Maximum size of a buffer for buffer fontification.
  (setq font-lock-maximum-size 512000)

  ;; by default turn on colorization (syntax highlightning)
  (if (fboundp 'global-font-lock-mode)
      (global-font-lock-mode 1))

  ;; font-menus.el --- additional font menus for GNU Emacs
  (eload 'font-menus)

  ;; fast-lock.el --- automagic text properties caching for fast Font Lock mode
  (when nil
    (when (eload 'fast-lock)
      (setq font-lock-support-mode 'fast-lock-mode ; lazy-lock-mode
            fast-lock-cache-directories '((elsub "fast-lock-cache")))
      ))

  ;;(setq font-lock-support-mode 'jit-lock-mode)

  ;; ===========================================================================================
  ;; Colors

  ;; All font's color settings use set-foreground-color, set-background-color

  (when (eload 'font-lock)
    (setq font-lock-use-default-fonts nil)
    (setq font-lock-use-default-colors nil)

    ;; Disabled this cause performance with cc-mode-5.30.9 sucks for big files.
    (setq font-lock-mode-maximum-decoration nil)
    )

  (load-file-if-exist (elsub "font-lock-color-test.elc"))

  (progn
    (set-background-color "#181818")
    ;;(set-background-color "#21381E")

    (set-foreground-color "wheat")

    (set-mouse-color "green")
    (set-cursor-color "green")
    (set-border-color "#152030")

    ;;(set-face-background 'default "black")
    ;; (set-face-foreground 'default "wheat")
    ;; (set-face-background 'region "blue")
    ;; (set-face-foreground 'region "gray60")
    )

  (when nil
    ;; OS X and speed coloring
    (when (or (string-equal (getenv "OSTYPE") "darwin7.0")
              (string-equal (getenv "HOSTNAME") "speed.tva.mil"))
      (set-background-color "#202020")
      ;;(set-background-color "#21381E")
      (set-foreground-color "wheat")
      (set-mouse-color "green")
      (set-cursor-color "green")
      (set-border-color "#152030"))

    ;; apollo coloring
    (when (string-equal (getenv "HOST") "apollo")
      (set-background-color "#2D294C")
      (set-foreground-color "wheat")
      (set-mouse-color "green")
      (set-cursor-color "green")
      (set-border-color "#152030"))

    ;; Choose warning red background for root user.
    (when (string-equal (getenv "USER") "root")
      (set-background-color "#400000")
      (set-foreground-color "wheat")
      )
    )

  ;; For more information see info file (Control-h i)

  ;; Buffer sensitive coloring.

  ;;(setq special-display-buffer-names
  ;;      (cons '("*compilation*"
  ;;            (background-color . "white")
  ;;            (foreground-color . "black"))
  ;;          special-display-buffer-names))

  ;; ===========================================================================================
  ;; sunrise-commander.el --- Two-pane file manager for Emacs based on Dired and

  (append-to-load-path (elsub "sunrise-commander"))
  (when (eload 'sunrise-commander)
    (add-to-list 'auto-mode-alist '("\\.srvm\\'" . sr-virtual-mode))
    )

  ;; lusty-explorer.el --- Dynamic filesystem explorer and buffer switcher
  (when (eload 'lusty-explorer)
    )

  ;; easy-todo.el --- Manage your todos in an extremely easy way!
  (when (eload 'easy-todo)
    )

  ;; policy-switch.el -- Window configuration navigation utility.
  (when (eload 'policy-switch)
    ;; To achieve persistence across sessions.
    (add-hook 'desktop-save-hook 'policy-switch-remove-unprintable-entities)
    ;; Suggested Keybinding
    (progn
      (global-set-key (kbd "C-c G n") 'policy-switch-policy-next)
      (global-set-key (kbd "C-c G a") 'policy-switch-policy-add)
      (global-set-key (kbd "C-c G g") 'policy-switch-policy-goto)
      (global-set-key (kbd "C-c G p") 'policy-switch-policy-prev)
      (global-set-key (kbd "C-c G r") 'policy-switch-policy-remove)
      (global-set-key (kbd "C-c G N") 'policy-switch-config-next)
      (global-set-key (kbd "C-c G P") 'policy-switch-config-prev)
      (global-set-key (kbd "C-c G G") 'policy-switch-config-goto)
      (global-set-key (kbd "C-c G A") 'policy-switch-config-add)
      (global-set-key (kbd "C-c G R") 'policy-switch-config-remove)
      (global-set-key (kbd "C-c G u") 'policy-switch-config-restore)
      (global-set-key (kbd "C-c G m") 'policy-switch-toggle-mode-line)
      )
    )

  (eval-after-load "faces" '(progn (eload 'faces+)))

  (eload 'face-remap+)


  (when (eload 'thumb-frm))

  ;; doremi.el
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/DoReMi
  ;;    `doremi-frm.el' - Incrementally adjust frame properties.
  ;;    `doremi-cmd.el' - Other Do Re Mi commands.
  ;;    `doremi-mac.el' - Macro to define Do Re Mi commands and
  ;;                      automatically add them to Do Re Mi menu.
  (defcustom pnw/use-doremi nil
    "Flags whether or not to load Emacs DoReMi." :type 'boolean :group 'pnw-options)
  (when pnw/use-doremi
    (when (eload 'doremi))
    (when (eload 'doremi-frm)
      )
    (when (eload 'doremi-cmd)
      )
    (when (eload 'doremi-mac)
      )
    )

  (when (eload 'wordfreq))
  (when (eload 'otp))

  ;; ===========================================================================================

  (defun clone-buffer-and-write-file (filename)
    "Clone the current buffer and write it into FILENAME."
    (interactive "FClone to file: ")
    (let ((buffer-file-name nil))
      (kill-buffer (with-current-buffer (clone-buffer)
                     (write-file filename (called-interactively-p 'any))
                     (current-buffer)))))
  (defalias 'clone-file 'clone-buffer-and-write-file)

  ;; ===========================================================================================
  ;; URL Package

  ;; The URL package contains code to parse and handle URLs. It was
  ;; originally part of w3, the web browser written entirely in
  ;; EmacsLisp. Now it is a separate library available in EmacsFromCVS.

  ;; You can use URL to download web pages - it works in the background
  ;; dealing with all the HTTP codes, authorization, cookies,
  ;; etc. Useful functions are url-retrieve-synchronously which returns
  ;; the buffer containing the servers response and url-retrieve which
  ;; lets you run a callback function after the page has been retrieved.

  ;; With its file name handlers enabled (see
  ;; url-setup-file-name-handlers or url-handler-mode if youre using the
  ;; URL in EmacsFromCVS) you can use functions like find-file and
  ;; file-exists-p on URLs.

  (setq url-using-proxy "http://www-gw.foi.se:8080/")

  ;; ===========================================================================================
  ;; Text Mode Settings

  ;; By default we starting in text mode.

  (setq initial-major-mode
        (lambda ()
          (text-mode)
          (font-lock-mode 1)))

  (defvar pnw-text-mode-hook
    (lambda ()
      ;; Used by center-line (M-s), center-paragraph and center-region.
      (setq fill-column 79)
      (abbrev-mode 1)

      ;;(flyspell-mode 1)

      ;; load my own regexp's
      (when nil
        (set (make-local-variable 'font-lock-defaults)
             '(pnw-font-lock-extra t nil nil
                                   backward-paragraph)))
      ))

  ;;(remove-hook 'text-mode-hook pnw-text-mode-hook)
  (add-hook 'text-mode-hook pnw-text-mode-hook)

  ;; Always switch to text mode for filenames that
  (add-to-list 'auto-mode-alist '("^README\\..*\\'" . text-mode))
  (add-to-list 'auto-mode-alist '("^INSTALL\\..*\\'" . text-mode))

  ;; ===========================================================================================

  ;; See: http://www.emacswiki.org/emacs-en/AutoSizeShellMode
  (defun jinzougen-shell ()
    "Show the last output of the shell buffer."
    (interactive)
    (let ((win (selected-window)))
      (switch-to-buffer-other-window "*shell*")
      (set-window-text-height
       nil (1+ (save-excursion
                 (goto-char comint-last-output-start)
                 (count-matches "\n"))))
      (recenter -1)
      (select-window win)))
  ;; (global-set-key (kbd "C-c s") 'jinzougen-shell)

  ;; ===========================================================================================
  ;; EmacsMuse
  ;; Documentation: http://mwolson.org/static/doc/muse.html
  ;; Tutorial: http://mwolson.org/projects/MuseQuickStart.html
  ;; See: http://www.emacswiki.org/cgi-bin/wiki?action=browse;oldid=MuseMode;id=EmacsMuse

  (defcustom pnw/use-muse t
    "Flags whether or not to load Emacs Muse." :type 'boolean :group 'pnw-options)

  (when pnw/use-muse
    (add-to-list 'load-path (elsub "muse/lisp") t)

    (when (eload 'muse-mode)            ; load authoring mode

      ;; load publishing styles I use
      (eload 'muse-html)                ;HTML
      (eload 'muse-latex)               ;LaTeX
      (eload 'muse-texinfo)             ;TexInfo
      (eload 'muse-docbook)             ;DocBook

      (eload 'muse-project)             ; publish files in projects

      (setq muse-project-alist
            '(("website" ("~/Pages" :default "index")
               (:base "html" :path "~/public_html")
               (:base "pdf" :path "~/public_html/pdf"))))
      )
    )
  ;; ===========================================================================================
  ;; Man Mode

  (defvar pnw-man-mode-hook
    (lambda ()
      (set-background-color "white")
      (set-foreground-color "black")
      (set-mouse-color "black")
      (set-cursor-color "black")
      (set-border-color "black")
      ))

  ;; Man pages are colored white with black text.
  ;;(add-hook 'Man-mode-hook pnw-man-mode-hook)

  ;; ===========================================================================================
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/timer+.el

  (when nil
    (eval-after-load "timer" '(progn (eload 'timer+)))
    )

  ;; buffer-action.el --- Perform actions(compile, etc) in buffer based on mode/filename
  ;;
  ;; This is a mostly rewritten based on ideas from Seiji Zenitani
  ;; <zenitani@mac.com>'s `smart-compile.el'. Besides compile action, i've
  ;; add a run action, and maybe more in the future.
  (when (eload 'buffer-action)
    ;;       (autoload 'buffer-action-compile "buffer-action")
    ;;       (autoload 'buffer-action-run "buffer-action")
    )

  ;; cdb-gud.el --- Grand Unified Debugger mode for running Microsoft's CDB
  ;; NOTE: Skipped because it generates error!
  ;;(load "cdb-gud")

  ;; ===========================================================================================

  ;; Boxed comments for C mode.
  ;;     (setq c-mode-hook
  ;;           (lambda ()
  ;;              (define-key c-mode-map "\M-q" 'reindent-c-comment)))
  ;;     (autoload 'rebox-c-comment "c-boxes" nil t)
  ;;     (autoload 'reindent-c-comment "c-boxes" nil t)

  ;; line-comment-banner.el --- Comment a line in a banner style.
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/LineCommentBanner
  (when (eload 'line-comment-banner)
    ;;(global-set-key (kbd "C-;") 'line-comment-banner)
    )

  ;; mo-mode.el --- view and edit gettext .mo message files
  ;; WARNING: Seems buggy I disable it for now.
  (when nil
    (when (eload 'mo-mode)
      (modify-coding-system-alist 'file "\\.g?mo\\'" 'raw-text-unix)
      (add-to-list 'auto-mode-alist '("\\.g?mo\\'" . mo-mode))
      )
    )

  ;; nXhtml - Emacs Utilities for XHTML
  ;; See: http://ourcomments.org/Emacs/nXhtml/doc/nxhtml.html
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/NxhtmlMode
  ;; xquery-mode.el --- A simple mode for editing xquery programs
  (when nil
    (append-to-load-path (elsub "nxhtml"))
    (append-to-load-path (elsub "nxhtml/nxhtml")) ;MuMaMo
    (append-to-load-path (elsub "nxhtml/util"))
    (append-to-load-path (elsub "nxhtml/related"))
    (when t (when (load "../nxhtml/autostart.el"))))

  (eload 'hide-lines)
  (eload 'hide-region)

  ;; hidesearch.el --- Incremental search while hiding non-matching lines.
  (when (eload 'hidesearch)
    (global-set-key (kbd "C-c C-s") 'hidesearch)
    (global-set-key (kbd "C-c C-a") 'show-all-invisible)
    )

  ;; tail.el --- Tail files within Emacs
  ;;  Primary URL for tail.el is http://inferno.cs.univ-paris8.fr/~drieu/emacs/
  (when (eload 'tail)
    )

  ;; quick-yes.el --- M-y to answer "yes" to `yes-or-no-p'.
  ;; Homepage: http://www.geocities.com/user42_kevin/quick-yes/index.html
  (when (eload 'quick-yes))

  ;; rst.el --- ReStructuredText Support for Emacs
  (when (eload 'rst)
    ;; Don't really what rst does. Skipping keybindings for now.
    ;; (add-hook 'text-mode-hook 'rst-text-mode-bindings)
    )

  ;; edi-mode.el --- edit raw EDI files
  (when (eload 'edi-mode)
    (add-to-list 'auto-mode-alist '("\\.edi" . edi-mode))
    (add-to-list 'magic-mode-alist '("\\`ISA" . edi-mode))
    )

  ;; gas-mode.el --- mode for editing assembler code
  (when (eload 'gas-mode)
    (add-to-list 'auto-mode-alist '("\\.S\\'" . gas-mode))
    )

  (load-file-if-exist (elsub "unparen.elc"))

  (when nil            ;Warning: Cripples output when editing. Disabled for now.
    (when (eload 'vnesting)
      (add-hook 'lisp-mode-hook 'vnest-mode)
      (add-hook 'emacs-lisp-mode-hook 'vnest-mode)
      )
    )

  ;; ===========================================================================================
  ;; Pretty Overlays for symbols and operators.

  ;; Original Google Groups thread: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/364ac52b45c28847/#
  ;;
  ;; We humans are very good at recognizing content based on images and
  ;; shapes, often more efficiently than we recognize words, at least
  ;; when the words are long. For this reason a text written in chinese
  ;; and/or japanese can more efficiently ("with a higher bandwidth")
  ;; explain a concept to to the reader than is possible with (western)
  ;; alphabets.
  ;;
  ;; When reading source code, especially C code, we are often
  ;; confronted by quite long function names, especially in C
  ;; environments such as GNOME. These function names are however built
  ;; up of smaller words or acronyms often separated by underline or
  ;; capitalization. After having seen the clever Emacs extensions
  ;; pretty-lamda and pretty-greek (given below) I have gotten a feeling
  ;; that this concept of "visual abbreviations" could be applied also
  ;; to these contexts of long C identifiers. I believe this would make
  ;; reading such C source code easier and more visually
  ;; attractive. Wanting to try out my idea I thought I could start
  ;; simple by overlay/change all the gtk_ prefix with a miniturized
  ;; version of the GTK's main icon seen www.gtk.org
  ;; (http://www.gtk.org/images/gtk-logo-rgb.gif). Is this possible to
  ;; do easily in Emacs or do I have to change the internals (C code) of
  ;; Emacs?
  (defun pretty-gtk ()
    "Highlight symbols starting with gtk_ using the GIMP Tool Kit (GTK) Icon."
    (add-to-list 'char-property-alias-alist '(display pretty))
    (add-to-list 'font-lock-extra-managed-props 'pretty)
    (font-lock-add-keywords
     nil
     `(("\\_<\\(gtk\\)_"
        (1 '(face nil pretty ,(create-image "~/pnw/images/gtk-logo-rgb-cropped-10x13.png"))))))
    ;; Image overlays using font-lock-add-keywords() and create-image() for more compact code view
    ;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/a4c8fef9485648be/f6b5c48e7417e58c#f6b5c48e7417e58c
    )
  (add-hook 'c-mode-common-hook 'pretty-gtk)

  ;; ---------------------------------------------------------------------------

  (defcustom pnw/use-pretty-mode t
    "Flags whether or not to load and pretty-mode." :type 'boolean :group 'pnw-options)
  (when pnw/use-pretty-mode
    (append-to-load-path (elsub "pretty-mode"))
    (when (eload 'pnw-pretty-mode)
      ;; (global-pretty-mode 1)
      ;; or
      ;; (add-hook 'my-pretty-language-hook 'turn-on-pretty-mode)
      )
    )

  (defcustom pnw/use-pretty-greek nil
    "Flags whether or not to load and pretty-greek." :type 'boolean :group 'pnw-options)
  (when pnw/use-pretty-greek
    (eload 'pnw-pretty-greek)
    )

  ;; emoticons.el --- Replace text with emoticons
  (when (eload 'emotions)
    (setq emotions-icon-dir (elsub "icons")
          emotions-theme "adium")

    ;; To use it with ERC:
    ;;    (add-to-list 'erc-replace-alist
    ;;                 '(emoticons-regexp . emoticons-replace))
    )

  ;; ===========================================================================================
  ;; unicad.el
  ;; an elisp port of Mozilla Universal Charset Auto Detector (UNICAD)
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/Unicad

  (defcustom pnw/use-unicad nil
    "Flags whether or not to load unicad upon startup." :type 'boolean :group 'pnw-options)

  (if pnw/use-unicad
      (when (eload 'unicad)
        ;; WARNING: WARNING: WARNING: WARNING: This code slows down Emacs extremely!
        ;; (unicad-enable)
        (unicad-disable)
        ))

  ;; ===========================================================================================
  ;; Java

  (add-hook 'conf-javaprop-mode-hook
            (lambda () (conf-quote-normal nil)))

  ;; ===========================================================================================
  ;; Folding Mode

  (defcustom pnw/use-folding nil
    "Flags whether or not to load folding upon startup." :type 'boolean :group 'pnw-options)

  (if pnw/use-folding
      (progn
        ;; 1) If you wish to explicitly load folding mode when you need it
        ;; (using M-x folding-mode):
        (autoload 'folding-mode          "folding" "Folding mode" t)
        (autoload 'turn-off-folding-mode "folding" "Folding mode" t)
        (autoload 'turn-on-folding-mode  "folding" "Folding mode" t)
        ;; 2) Or you can have it automatically load when it finds folding
        ;; marks (I prefer it this way):
        (if (load "folding" 'nomessage 'noerror)
            (folding-mode-add-find-file-hook))
        ))

  ;; ===========================================================================================
  ;; Toggle hideshow minor mode.

  (defcustom pnw/use-hs-minor-mode t
    "Flags whether or not to load hs-minor-mode upon startup." :type 'boolean :group 'pnw-options)

  (if pnw/use-hs-minor-mode
      (progn
        ;; turn on hs-minor-mode in programming modes
        (remove-hook 'c-mode-common-hook (lambda () (hs-minor-mode 1) ))
        (remove-hook 'ada-mode-hook (lambda () (hs-minor-mode 1) ))
        (remove-hook 'octave-mode-hook (lambda () (hs-minor-mode 1) ))
        (remove-hook 'lisp-mode-hook (lambda () (hs-minor-mode 1) ))
        (remove-hook 'emacs-lisp-mode-hook (lambda () (hs-minor-mode 1) ))
        (remove-hook 'python-mode-hook (lambda () (hs-minor-mode 1) ))

        ;;       (global-set-key [(control +)] 'hs-show-block)
        ;;       (global-set-key [(control -)] 'hs-hide-block)
        ;;       (global-set-key [(control *)] 'hs-show-all)
        ;;       (global-set-key [(control /)] 'hs-hide-all)

        (global-set-key [(control kp-add)] 'hs-show-block)
        (global-set-key [(control kp-subtract)] 'hs-hide-block)
        (global-set-key [(control kp-multiply)] 'hs-show-all)
        (global-set-key [(control kp-divide)] 'hs-hide-all)
        ))

  ;; ===========================================================================================
  ;; Lex/FLex

  ;; ToDo: Move this to (elsub "pnw-flex-mode.el")
  (when (eload 'derived)

    (defvar flex-font-lock-keywords
      `((,(concat "\\<"
                  (regexp-opt '("abls" "axis" "bar" "bmat" "bm3d" "bond" "boun" "calc"
                                "circ" "data" "drlx" "echo" "exam" "exec" "extr" "ffld" "func" "gcon" "geom"
                                "glue" "grav" "grid" "grph" "heat" "intr" "isln" "job" "ldef" "line" "linr"
                                "magn" "mass" "matr" "mbrn" "mem" "membrane" "mgr" "modl" "mods" "mp" "old"
                                "outp" "piez" "plod" "pnbl" "pout" "pplt" "prcs" "prnt" "regrid" "rest"
                                "riera" "rigd" "set" "shap" "shel" "show" "site" "stop" "term" "time" "titl"
                                "trns" "user" "watr" "wndo" "xfil" "zone") t)
                  "\\>") (0 font-lock-keyword-face))
        (,(concat "\\<"
                  (regexp-opt '("prop" "sect" "elem" "gcon" "del" "out1" "node" "plot"
                                "eye" "vert" "clos" "end" "type" "rate" "hist" "xcrd" "ycrd" "zcrd" "regn"
                                "grup" "optn" "erod" "gend" "tinc" "vpnt" "bc" "fix" "skew" "defn" "rnod"
                                "csec" "pdef" "sdef" "vctr") t)
                  "\\>") (0 font-lock-function-name-face))
        (,(concat "\\<"
                  (regexp-opt '("symb") t)
                  "\\>") (0 font-lock-string-face))
        "Keyword highlighting specification for `flex-mode'."))

    (define-derived-mode flex-mode c-mode "flex"
      "A major mode for editing .flex files."

      ;; try to set the indentation correctly
      (setq-default c-basic-offset 4)
      (make-variable-buffer-local 'c-basic-offset)

      (c-set-offset 'knr-argdecl-intro 0)
      (make-variable-buffer-local 'c-offsets-alist)

      (use-local-map flex-mode-map)

      ;; get rid of that damn electric-brace which is not useful with flex
      (define-key flex-mode-map "{"       'self-insert-command)
      (define-key flex-mode-map "}"       'self-insert-command)

      (define-key flex-mode-map [tab] 'flex-indent-command)


      ;;(set (make-local-variable 'font-lock-defaults) '(flex-font-lock-keywords))
      ;;   (let ((table (make-syntax-table)))
      ;;     (modify-syntax-entry ?* ". 23b" table)
      ;;     (modify-syntax-entry ?/ ". 14" table)
      ;;     (modify-syntax-entry ?C "<" table)
      ;;     (modify-syntax-entry ?\n ">" table)
      ;;     (set-syntax-table table))

      (run-hooks 'flex-mode-hook)
      )

    (provide 'flex-mode)

    (add-to-list 'auto-mode-alist '("\\.l\\'" . flex-mode))
    )

  ;; ===========================================================================================

  (defun lookup-debug-context (function)
    "Go to FUNCTION (a symbol), narrow to region."
    (interactive
     (let ((fn (save-excursion
                 (beginning-of-defun)
                 (forward-word 2)
                 (if (featurep 'xemacs)
                     (function-at-point)
                   (function-called-at-point))))
           val)
       (list (intern-soft (completing-read (if fn
                                               (format "Describe function (default \"%s\"): " fn)
                                             "Describe function: ")
                                           obarray 'fboundp t nil nil (symbol-name fn))))))
    (if (file-readable-p
         ;; No effect, why?
         (condition-case nil
             (symbol-file function)
           (error "No sourcedata found")))
        (let* ((datei (symbol-file function)))
          (cond
           ((file-exists-p (concat (file-name-sans-extension datei) ".el"))
            (find-file (concat (file-name-sans-extension datei) ".el")))
           ((file-exists-p (concat (file-name-sans-extension datei) ".el.gz"))
            (find-file (concat (file-name-sans-extension datei) ".el.gz")))
           ((file-exists-p (concat datei ".gz"))
            (find-file (concat datei ".gz")))
           (t (error (concat "No sources ... (vorhanden)"))))
          ;; 2007-06-03 a.roeh...@web.de changed section end
          (widen)
          (goto-char (point-min))
          (cond
           ((search-forward (concat "(defun " (symbol-name function)" ") nil t) ;;
            Leerzeichen, um "-" in Funktionsnamen auszuschlieÂÃÂen
            (progn
              (narrow-to-region (progn (beginning-of-defun) (point))(progn
                                                                      (end-of-defun) (point)))
              (delete-other-windows)))
           ((progn (goto-char (point-min))
                   (re-search-forward (concat "(defalias '" (symbol-name
                                                             function) " '\\([^)]+\\)") nil t 1))
            (progn
              (message " %s" (match-string-no-properties 1))
              (goto-char (point-min))
              (search-forward (match-string-no-properties 1))))
           ((progn (goto-char (point-min))
                   (re-search-forward (concat "\(define-.+" (symbol-name function) " *$") nil
                                      t 1))
            (message " %s" (match-string-no-properties 0)))
           (t (goto-char (point-min)))))
      (message "%s" "No file assigned, self-made function?")))

  ;; ===========================================================================================
  ;; Flawfinder wrapper

  (defun flawfind-buffer-file ()
    "Run flawfinder on file associated with current buffer."
    (interactive)
    (let ((file (read-file-name "Find flaws in file: " nil buffer-file-name)))
      (if (executable-find "flawfinder")
          (progn
            (compile (concat "flawfinder " file))
            )
        (message "Program flawfinder not found")))
    )
  (global-set-key [(control c) (F)] 'flawfind-buffer-file)

  ;; ===========================================================================================
  ;; Splint wrapper

  (defun splint-buffer-file ()
    "Run splint on file associated with current buffer."
    (interactive)
    (let ((file (read-file-name "Apply splint on file: " nil buffer-file-name)))
      (if (executable-find "splint")
          (progn
            (compile (concat "splint " file))
            )
        (message "Program splint not found")))
    )
  (global-set-key [(control c) (S)] 'splint-buffer-file)

  ;; ===========================================================================================
  ;; Cyclomatic Complexity Measure
  ;; pmccabe - calculate McCabe cyclomatic complexity or non-commented line counts for C and C++ programs

  (defun pmccabe-buffer-file ()
    "Run pmccabe on file associated with current buffer."
    (interactive)
    (let ((file (read-file-name "Apply pmccabe on file: " nil buffer-file-name)))
      (if (executable-find "pmccabe")
          (progn
            (compile (concat "pmccabe " file))
            )
        (message "Program pmccabe not found")))
    )
  (defalias 'cyclomatic-complexity-buffer-file 'pmccabe-buffer-file)
  (global-set-key [(control c) (shift p)] 'pmccabe-buffer-file)

  ;; ===========================================================================================
  ;; W3

  ;;(if (file-exists-p "~/gnu/share/emacs/site-lisp/w3.el")
  ;;    (eload 'w3))

  ;;(if (file-exists-p (elsub "merriam.el")
  ;;    (eload 'merriam))

  ;; ===========================================================================================
  ;; CDI

  ;; oggel
  (add-hook 'cdi-mode-hook
            (lambda ()
              (eload 'oggel)))

  ;; ===========================================================================================
  ;; calc.el --- the GNU Emacs calculator
  (when (eload 'calc)
    (when (eload 'calc-ext)
      (defvar calc-command-flags)
      ))

  ;; ===========================================================================================
  ;; Calc mode, using H-P style postfix notation."
  (when (eload 'calc-mode))

  ;; ===========================================================================================
  ;; echo-pick.el --- filter for echo area status messages

  (when (eload 'echo-pick)
    (setq echo-pick-limit 3)
    ;;(echo-pick-mode 1)
    )

  ;; ===========================================================================================
  ;; CSS - Cascading Style Sheets

  (when (eload 'css-mode)
    (add-to-list 'auto-mode-alist '("\\.css\\'" . css-mode))
    )

  (autoload 'gpl-mode "gpl")
  (add-to-list 'auto-mode-alist
               '("\\.gpl\\'" . gpl-mode))

  ;; css-color.el --- Highlight and edit CSS colors
  (when (eload 'css-color)
    ;; (autoload 'css-color-mode "css-color" "" t)
    (add-hook 'css-mode-hook
              (lambda ()
                (css-color-mode 1)))
    )

  (when (eload 'css-palette)
    ;; (autoload 'css-palette-minor-mode "css-palette" "" t)
    (add-hook 'css-mode-hook
              (lambda ()
                (css-palette-minor-mode 1)))
    )

  ;; ===========================================================================================
  ;; nav.el --- Emacs mode for IDE-like navigation of directories
  ;; See: http://code.google.com/p/emacs-nav/
  ;; Nav is a lightweight solution for Emacs users who want something
  ;; like TextMate's file browser, or the Eclipse project view. Unlike
  ;; these two, Nav only shows the contents of a single directory at a
  ;; time, but it allows recursive searching for filenames using the
  ;; 'f' key-binding, and recursive grepping of file contents with the
  ;; 'g' key-binding. Nav can be run painlessly in terminals, where
  ;; Speedbar either fails on its attempt to make a new frame or is
  ;; hidden. Nav's terminal-friendliness comes from running in the
  ;; frame where it was started, keeping window management simple. The
  ;; Nav key bindings are simple, as well -- each key command is a
  ;; single keystroke long.

  (append-to-load-path (elsub "nav"))         ;emacs-nav
  (when (eload 'nav)
    )

  ;; ===========================================================================================
  ;; Treebar

  ;; treebar.el -- tree based navigation for speedbar
  (append-to-load-path (elsub "treebar"))
  (when (eload 'treebar)
    )

  ;; ===========================================================================================
  ;; Speedbar


  ;;required by speedbar bug in Emacs CVS
  (defvar dframe-xemacsp nil)

  (eload 'dframe)

  (when (eload 'speedbar)
    ;; Add speedbar to "Tools" Menu
    (define-key-after (lookup-key global-map [menu-bar tools])
      [speedbar] '("Speedbar" . speedbar-frame-mode) [calendar])

    (defun pnw-speedbar-vc-check-dir-p (directory)
      "Return t if we should bother checking DIRECTORY for version control files.
This can be overloaded to add new types of version control systems."
      (or
       ;; Local CVS available in Emacs 21
       (and (fboundp 'vc-state)
            (or
             (file-exists-p (concat directory "CVS/"))
             (file-exists-p (concat directory ".svn/"))
             (file-exists-p (concat directory ".bzr/"))
             (file-exists-p (concat directory ".git/"))
             ))
       ;; Local RCS
       (file-exists-p (concat directory "RCS/"))
       ;; Local SCCS
       (file-exists-p (concat directory "SCCS/"))
       ;; Remote SCCS project
       (let ((proj-dir (getenv "PROJECTDIR")))
         (when proj-dir
           (file-exists-p (concat proj-dir "/SCCS"))))
       ;; User extension
       (run-hook-with-args-until-success 'speedbar-vc-directory-enable-hook
                                         directory)
       ))

    (add-hook 'speedbar-vc-directory-enable-hook 'pnw-speedbar-vc-check-dir-p)

    (setq speedbar-verbosity-level 3)
    )

  ;; sr-speedbar.el --- Same frame speedbar
  (when (eload 'sr-speedbar)
    ;;  (global-set-key [(super ?s)] 'sr-speedbar-toggle)
    )

  ;; ---------------------------------------------------------------------------

  ;; Above function requires elscreen.el and below function. If you
  ;; don’t use below function and elscreen.el, please rename
  ;; ‘elscreen-switch-or-create’ to ‘switch-to-buffer’ on above
  ;; function.
  (defun elscreen-switch-or-create (buf)
    (defun create-new-buf (buf)
      (if (equal elscreen-default-buffer-name (buffer-name (window-buffer)))
          (switch-to-buffer buf)
        (elscreen-create)
        (switch-to-buffer buf)))
    (defun switch-to-elscreen-create-inner (screen-list buf)
      (cond ((null (elscreen-get-window-configuration (car screen-list)))
             nil)
            ((equal (car screen-list) (elscreen-find-screen-by-buffer (buffer-name buf)))
             (elscreen-goto (car screen-list)))
            (t
             (switch-to-elscreen-create-inner (cdr screen-list) buf))))
    (if (null (switch-to-elscreen-create-inner (elscreen-get-screen-list) buf))
        (create-new-buf buf)
      t))

  ;; ===========================================================================================
  ;; mwe-log-commands.el --- log keyboard commands to buffer

  ;; mwe-log-commands by MichaelWeber can be used to demo Emacs to an
  ;; audience. When activated, keystrokes get logged into a designated
  ;; buffer, along with the command bound to them.

  (eload 'mwe-log-commands)

  ;; ===========================================================================================
  ;; echoline mode - a minor mode for Octave/Matlab which highlights "echoing"

  (when (load-file-if-exist (elsub "echoline.elc"))
    (add-hook 'octave-mode-hook 'echoline-mode)
    (add-hook 'matlab-mode-hook 'echoline-mode)
    )

  ;; ===========================================================================================
  ;; Project-Centric Functionality

  ;; The concept of projects and solutions in Visual Studio is central
  ;; to it's operation. Emacs is not an IDE, but it does play one on
  ;; TV. I can make Emacs do enough to satisfy my requirements. There is
  ;; a session management tool for Emacs out there, but I don't really
  ;; need that. I take a more simple route, of setting a few states
  ;; within Emacs whenever I approach working on a project. Observe the
  ;; following code which opens a source file in one of the projects,
  ;; fires up the speedbar, starts a tags table definition and sets up
  ;; the environment for compiling a single file in the project:

  (defun project-foo (dir)
    (interactive "DProject Directory: ")
    (save-excursion
      (cd dir)
      (find-file "bar.cpp")
      (find-file "bar.h")
      (add-to-list 'tags-table-list "tags")
      (setq compile-command "perl compile.pl")
      (setq c++-compile-current-file "cl.exe /Od ")
      (setenv "INCLUDE" (concat dir "/include;")
              (speedbar)
              )))

  ;; ===========================================================================================
  ;; iss-mode.el --- Mode for InnoSetup install scripts

  (progn
    (autoload 'iss-mode "iss-mode" "Innosetup Script Mode" t)
    (setq auto-mode-alist (append '(("\\.iss$"  . iss-mode)) auto-mode-alist))
    (setq iss-compiler-path "c:/Programme/Inno Setup 5/")
    (add-hook 'iss-mode-hook 'xsteve/iss-mode-init)
    (defun xsteve/iss-mode-init ()
      (interactive)
      ;;     (define-key iss-mode-map [f6] 'iss-compile)
      ;;     (define-key iss-mode-map [(meta f6)] 'iss-run-installer)))
      )
    )

  ;; dar.el --- disk archiver (DAR) interface for emacs
  ;; dar.el provides an Emacs interface for DAR from:
  ;; See: http://dar.linux.free.fr/
  (when (eload 'dar))

  ;; mouse-embrace.el
  (when (eload 'mouse-embrace))

  ;; Set way for mouse cursor to avoid text cursor.
  ;; I like 'animate the best.
  (mouse-avoidance-mode 'none) ;NOTE: Disturbs behaviour of tooltip shown by th-show-help()

  ;; Added xte.el, an emacs interface to xautomation.
  ;; It allows to send keystrokes in X Window environments.
  (when (eload 'xte))

  ;; MultiSelect
  ;; Homepage: http://www.skamphausen.de/cgi-bin/ska/multiselect
  (when (eload 'multiselect)
    (multiselect-install-default-keybindings)
    )

  (eload 'incr)                         ;Increase

  ;; ===========================================================================================

  ;; traverse-dir.el -- replace grep-find. Replaced by traverselisp
  ;;(when (eload 'traverse-dir))

  ;; find.el --- Build a valid find(1) command with sexps
  (eload 'find)

  ;; ===========================================================================================

  (when (eload 'sgml-mode)
    (when (require 'hl-tags-mode)       ;Highlight the current SGML tag context
      (add-hook 'sgml-mode-hook (lambda () (hl-tags-mode 1)))
      (add-hook 'nxml-mode-hook (lambda () (hl-tags-mode 1))))

    ;; Automatically indent after inserts of SGML tags.
    (defadvice sgml-tag (after indent-region activate)
      (indent-region (region-beginning) (region-end) nil))

    (add-to-list 'auto-mode-alist '("\\.xsl\\'" . sgml-mode))
    )
                                        ;htmlize a buffer/source tree with optional hyperlinks

  ;; ===========================================================================================
  ;; Show Images Automatically

  (when (require 'iimage)
    (autoload 'iimage-mode "iimage" "Support Inline image minor mode." t)

    ;; ToDo: Deactivated because iimage-recenter is slow!
    ;; (add-hook 'info-mode-hook 'turn-on-iimage-mode)
    ;;   (add-hook 'wiki-mode-hook 'turn-on-iimage-mode)
    ;;   (add-hook 'org-mode-hook 'turn-on-iimage-mode)
    ;;   (add-hook 'outline-mode-hook 'turn-on-iimage-mode)
    ;;(add-hook 'text-mode-hook 'turn-on-iimage-mode)
    ;; ToDo: This should work!
    (global-set-key [(control l)] 'recenter)
    )

  ;; eiv.el --- emacs image viewer
  (when (eload 'eiv)
    )

  ;; drill-instructor.el ---  Enforce key-bind of Emacs.
  (when (eload 'drill-instructor)
    )

  ;; ===========================================================================================
  ;; imagetext.el --- show text parts of image files

  ;;WARNING: Disabled because this results in an error upon startup.
  (when nil
    (when (eload 'imagetext)
      (autoload 'imagetext-show "imagetext")
      (add-hook 'image-mode-hook 'imagetext-show)
      )
    )

  ;; ===========================================================================================
  ;; Scrolling Adjustments

  ;; By default in Emacs, when you scroll, you are given what amounts to
  ;; half a page down when your cursor reaches the end of the screen. If
  ;; you prefer the smooth scrolling of Visual Studio, you can get it:

  (if t
      (progn
        ;; Emacs-style scrolling
        (setq scroll-step 0)
        (setq scroll-conservatively 0)
        )
    (progn
      ;; Other IDE-style scrolling
      (setq scroll-step 1)
      (setq scroll-conservatively 50)
      ))


  ;; ===========================================================================================
  ;; Enable direct scrolling with the mouse

  (if t (when (eload 'track-scroll)))

  ;; ===========================================================================================
  ;; screen-lines

  ;;(eload 'screen-lines)
  ;;(screen-lines-mode 1)
  ;;(global-set-key [(control \?)] 'screen-lines-mode)

  ;; ===========================================================================================
  ;; Interactive replacement for locate-library with completion

  (when (eload 'ilocate-library)
    (global-set-key [(control c) (B)] 'ilocate-library)
    )

  ;; ===========================================================================================

  ;; Today I looked at my ~/.emacs file and I saw that I defined a lot
  ;; of aliases for commands I frequently use. Most of the time the
  ;; aliases are words that are built by taking each first char of a
  ;; word in the command, e.g. nsn for newsticker-show-news, eb for
  ;; emms-browser or omm for outline-minor-mode. But what should I do
  ;; when I want to create an alias for ediff-buffers since eb is
  ;; already used?

  ;; My solution was to write a function that calls a command by its
  ;; abbreviation.

  ;; UPDATE: Alex Schröder pointed me to the builtin
  ;; partial-completion-mode which allows nearly the same. It requires
  ;; that you type the separator (- or _), too, so you need a few
  ;; keystrokes more when you know the commands name. On the other hand
  ;; it completes not only function names, but also files, e.g. f_b.c
  ;; will expand to foo_bar.c.

  ;; UPDATE2:
  ;; The version above uses ido-completing-read when ido-mode is enabled.

  (defun th-execute-abbreviated-command (prefixarg)
    "Queries for a command abbreviation like \"mbm\" and calculates
a list of all commands of the form \"m[^-]*-b[^-]*-m[^-]*$\". If
this list has only one item, this command will be called
interactively. If there a more choices, the user will be queried
which one to call.

The PREFIXARG is passed on to the invoked command."
    (interactive "P")
    (let* ((abbrev (read-from-minibuffer "Command Abbrev: "))
           (regexp (let ((char-list (append abbrev nil)) ;; string => list of chars
                         (str "^"))
                     (dolist (c char-list)
                       (setq str (concat str (list c) "[^-]*-")))
                     (concat (substring str 0 (1- (length str))) "$")))
           (commands (remove-if-not (lambda (string) (string-match regexp string))
                                    (let (c)
                                      (mapatoms (lambda (a)
                                                  (if (commandp a)
                                                      (push (symbol-name a) c))))
                                      c))))
      (cond ((> (length commands) 1)
             (call-interactively (intern (completing-read "Command: " commands))
                                 t))
            ((= (length commands) 1)
             (call-interactively (intern (car commands)) t))
            (t (message "No such command.")))))

  ;; To make it quickly accessible Iôòùve bound it to C-x x.

  ;; (global-set-key (kbd "C-x x") 'th-execute-abbreviated-command)

  ;; SHELLFM
  (eload 'pgo-shellfm)

  ;; Open some dictionaries for use with try-expand-dabbrev-all-buffers.
  (progn
    (find-file-noselect-if-exist "/usr/share/dict/american-english")
    (find-file-noselect-if-exist "/usr/share/dict/swedish")
    (find-file-noselect-if-exist "/usr/share/dict/italian"))

  ;; ===========================================================================================
  ;; Completion Hovering

  (when (eload 'dabbrev-hover))
  ;; Don't activate dh-fancy-doing-mode since it changes tab-bevaiour

  ;; ===========================================================================================
  ;; Emacs interface to the Google API

  ;; ToDo: Activate because it needs "soap"
  ;;(when (eload 'google))

  ;; ===========================================================================================
  ;; Google Code Search
  ;; codesearch.el --- search for free software source code on the

  (when (eload 'codesearch)
    (defalias 'google-code-search 'codesearch)
    )

  ;; ===========================================================================================
  ;; Advanced highlighting of matching parentheses

  (when nil
    (when (eload 'mic-paren)
      (paren-activate)
      (add-hook 'c-mode-common-hook
                (function (lambda ()
                            (paren-toggle-open-paren-context 1))))
      ))

  ;; ===========================================================================================

  ;; Manage bookmarks in HTML

  ;;(load-file-if-exist (elsub "hbmk.elc")

  ;; bm.el  -- Visible bookmarks in buffer.
  ;; See: http://www.nongnu.org/bm/
  (when (eload 'bm)
    ;; An extension for bm.el that adds a function that lists all
    ;; bookmarks in all buffers.
    (when (eload 'bm-ext)
      )
    (progn
      ;;     (global-set-key (kbd "<S-f6>") 'bm-toggle)
      ;;     (global-set-key (kbd "<S-f8>") 'bm-show)
      (global-set-key [(control c) (b) (t)] 'bm-toggle)
      (global-set-key [(control c) (b) (s)] 'bm-show)
      (global-set-key [(control c) (b) (S)] 'bm-show-all)
      (global-set-key [(control c) (b) (p)] 'bm-previous)
      (global-set-key [(control c) (b) (n)] 'bm-next)
      )
    )

  ;; ===========================================================================================
  ;; Interface to (s)locate

  (defcustom pnw/use-gse-locate nil
    "Flags whether or not to load gse-locate upon startup." :type 'boolean :group 'pnw-options)

  (if pnw/use-gse-locate                ;replaced by locate.el
      (when (eload 'gse-locate)
        (global-set-key [(control c) (l)] 'gse-locate)
        ))

  ;; ===========================================================================================

  ;; Search and install Gentoo packages

  (defcustom pnw/use-portage nil
    "Flags whether or not to load Portage Mode upon startup." :type 'boolean :group 'pnw-options)

  (if pnw/use-portage
      (progn
        (when (eload 'semantic-el)
          (when (eload 'portage)
            )
          )))

  ;; ===========================================================================================
  ;; See: EmacsWiki: ToggleOption

  ;; Hereôòùs a command that toggles binary options. You can use
  ;; completion to choose an option to toggle.

  ;; By default, completion candidates are user options that have Custom
  ;; type ôòøbooleanôòù. However, with a prefix argument, the set of
  ;; candidates is extended to either all user options or all variables:

  ;; * No prefix arg ôòó ôòøbooleanôòù user option
  ;; * Prefix arg >= 0 ôòó any user option
  ;; * Prefix arg < 0 ôòó any variable

  ;; The prefix arg is useful because there are many options that have a
  ;; ôòønilôòù or non-ôòønilôòù value, but the latter is not necessarily
  ;; ôòøtôòù. ôòó DrewAdams

  ;; A similar definition is used in Icicles as a multi-command. That
  ;; is, in Icicles, you can toggle more than one option per command
  ;; invocation.

  (defun dradams/toggle-value (opt)
    "Toggle option's value.  This makes sense for binary (toggle) options.
By default, completion candidates are limited to user options that
have `boolean' custom types.  However, there are many \"binary\" options
that allow other non-nil values than t.

You can use a prefix argument to change the set of completion
candidates, as follows:

 - With a non-negative prefix arg, all user options are candidates.
 - With a negative prefix arg, all variables are candidates."
    (interactive
     (list (completing-read
            "Toggle value of option: " obarray
            (cond ((and current-prefix-arg
                        (wholenump (prefix-numeric-value current-prefix-arg)))
                   'user-variable-p)
                  (current-prefix-arg 'boundp)
                  (t (lambda (sym) (eq (get sym 'custom-type) 'boolean))))
            t nil 'variable-name-history)))
    (let ((sym (intern opt)))
      (set sym (not (eval sym))) (message "`%s' is now %s" opt (eval sym))))


  ;; ===========================================================================================

  ;; A [not so] simple calculator for Emacs

  (if (file-exists-p (elsub "calculator.elc"))
      (progn
        (autoload 'calculator "calculator" "Run the Emacs calculator." t)
        (global-set-key [(control c) (u)] 'calculator)
        ))

  ;; ===========================================================================================

  ;; IMDB
  ;; (when (file-exists-p (elsub "imdb.elc")
  ;; Comment because it causes a problem.
  ;;(eload 'imdb)
  ;;(setq imdb-proxy (getenv "PROXY_HOST"))
  ;;(setq imdb-proxyport (getenv "PROXY_PORT"))
  ;; )

  ;; Editing Maple code and interacting with Maple and Mint
  (defcustom pnw/use-maple t
    "Flags whether or not to load Maple Mode upon startup." :type 'boolean :group 'pnw-options)
  (if pnw/use-maple
      (if (file-exists-p (elsub "maple-mode.elc"))
          (progn
            (autoload 'maple-mode "maple"
              "Editing Maple code and interacting with Maple and Mint."
              t nil))))

  ;; Enable Partial Completion mode.
  (partial-completion-mode nil)

  ;; default to lisp-mode for
  (setq auto-mode-alist
        (append '(
                  (".abbrev_defs\\'" . emacs-lisp-mode)
                  (".emacs.desktop\\'" . emacs-lisp-mode) ;desktop save file
                  (".emacs.bmk\\'" . emacs-lisp-mode)     ;bookmark file
                  (".session\\'" . emacs-lisp-mode)       ;bookmark file
                  (".ido.last\\'" . emacs-lisp-mode)
                  ;;                  ("semantic.cache\\'" . emacs-lisp-mode)
                  )
                auto-mode-alist))

  ;; ===========================================================================================
  ;; Grep Stuff

  (defalias 'grep-occur 'occur)

  (global-set-key [(control c) (f)] 'grep-find)
  ;;(global-set-key [(control c) (h)] 'grep-approximate)

  ;; ===========================================================================================
  ;; make C-. repeat last command
  ;;(global-set-key (kbd "C-.") 'repeat)

  ;; ===========================================================================================
  ;; PageUp and PageDown as in usual Windows Apps

  (defun sfp-page-down ()
    (interactive)
    (setq this-command 'next-line)
    (next-line
     (- (window-text-height)
        next-screen-context-lines)))

  (defun sfp-page-up ()
    (interactive)
    (setq this-command 'previous-line)
    (previous-line
     (- (window-text-height)
        next-screen-context-lines)))

  ;; ===========================================================================================
  ;; Occur

  ;; icicle-occur

  ;; occur
  (eload 'color-occur)

  ;; moccur-edit provides to edit moccur buffer and to apply the changes to
  ;; the file.
  (eload 'moccur-edit)

  ;;(eload 'occur-schroeder)

  (when (eload 'golisp))                ;GoLisp

  ;; Color Browser
  ;; This cannot be loaded
  ;; (eload 'color-browser)

  ;; facemenu+.el
  ;; If you load library facemenu+.el after you load library
  ;; highlight.el, then the commands in library highlight.el will also
  ;; be available on a Highlight submenu in the Text Properties
  ;; menus. See FaceMenuPlus for more about library facemenu+.el.
  ;; ToDo: I get the error: Debugger entered--Lisp error: (void-function easy-menu-do-add-item)
  ;; so I uncomment this for now
  ;; (eload 'facemenu+)

  ;; cursor-chg.el --- Change cursor dynamically, depending on the context.
  ;; Warning: NOTE: Library Lisp:oneonone.el (see OneOnOneEmacs) provides the
  ;; same functionality as library cursor-chg.el, and more. If you use
  ;; library oneonone.el, then do not also use library cursor-chg.el.
  (when (eload 'cursor-chg)
    (toggle-cursor-type-when-idle 1)    ;cursor change when Emacs is idle
    (change-cursor-mode 1)      ;Change for overwrite, read-only, and input mode
    )

  ;; hsv2rgb.el --- Transformation from HSV to RGB
  (when (eload 'hsv2rgb))

  ;; palette.el --- Color palette useful with RGB, HSV, and color names
  (when (and nil (eload 'palette)))

  ;; ===========================================================================================
  ;; ebrowse

  ;;(if (file-exists-p "~/pnw")
  ;;    (progn
  ;;      (shell-command "cd ~/pnw ; make ebrowse & cd ~")
  ;;      (add-to-list 'auto-mode-alist '("BROWSE" . ebrowse-tree-mode))
  ;;      (find-file "~/pnw/BROWSE")))

  ;; ===========================================================================================
  ;; Emacs-lisp mode for ebrowse database file BROWSE

  (add-to-list 'auto-mode-alist '("^BROWSE\\'" . emacs-lisp-mode))

  ;; makeinfo-info.el --- use Info-mode with makeinfo-buffer.
  (when nil
    (eval-after-load "makeinfo" '(eload 'makeinfo-info))
    )

  ;; Read passwords from user, possibly using a password cache.
  ;; May be superseeded by tramp.el
  (when (eload 'password)
    )

  ;; pwsafe.el --- emacs interface to pwsafe
  (when (eload 'pwsafe))

  ;; wimpy-del.el --- Require confirmation for large region deletion.
  (when (eload 'wimpy-del))

  ;; ModeLineConfiguration
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/ModeLineConfiguration

  ;; ModeLineDirtrack
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/ModeLineDirtrack

  ;; Show the current directory in the mode-line:
  (add-hook 'shell-mode-hook
            (lambda ()
              (setq mode-line-format
                    '("%e"
                      #("-" 0 1
                        (help-echo "mouse-1: select (drag to resize), mouse-2 = C-x 1, mouse-3 = C-x 0" auto-composed t))
                      mode-line-mule-info
                      " " (:propertize default-directory face dired-directory) " "
                      mode-line-buffer-identification
                      #("  " 0 2
                        (help-echo "mouse-1: select (drag to resize), mouse-2 = C-x 1, mouse-3 = C-x 0"
                                   auto-composed t))
                      mode-line-modes
                      (which-func-mode ("" which-func-format #("--" 0 2 (help-echo "mouse-1: select (drag to resize), mouse-2 = C-x 1, mouse-3 = C-x 0"))))
                      (global-mode-string (#("--" 0 2 (help-echo "mouse-1: select (drag to resize), mouse-2 = C-x 1, mouse-3 = C-x 0")) global-mode-string))
                      #("-%-" 0 3 (help-echo "mouse-1: select (drag to resize), mouse-2 = C-x 1, mouse-3 = C-x 0" auto-composed t))))))

  ;; ===========================================================================================

  ;;From: Joe Fineman <jcf@TheWorld.com>
  (defun xsteve/transpose-appropriate-chars (char)
    "Transpose the last 2 chars, or the 1 after CHAR with CHAR."
    (interactive "cFirst character of pair:  ")
    (let ((origin (point)))
      (if (< char ? )
          (forward-char -2)
        (search-backward (char-to-string char)))
      (forward-char 2)
      (insert (char-after (- (point) 2)))
      (delete-region (- (point) 3) (- (point) 2))
      (goto-char origin)))

  ;;From: Henrik Enberg
  (defun query-remove-doubled-words (&optional force)
    "Find all doubled words and ask to remove them.
With optional arg FORCE remove them without asking."
    (interactive "P")
    (let ((case-fold-search t)
          (del-counter 0))
      (while (re-search-forward
              "\\(\\<\\w\\{3,\\}\\>\\)[ \t\n]*\\(\\1\\)" nil t)
        (replace-highlight (match-beginning 2) (match-end 2))
        (unwind-protect
            (when (or force (y-or-n-p "Remove this doubled word? "))
              (delete-region (match-beginning 2) (match-end 2))
              (canonically-space-region (match-beginning 0) (match-end 0))
              (setq del-counter (1+ del-counter)))
          (replace-dehighlight)))
      (if (> del-counter 0)
          (message "Removed %d doubled %s." del-counter
                   (if (< del-counter 1) "words" "word"))
        (message "No doubled words found or removed."))))

  ;; filter filter
  ;; alpha alpha

  ;;From: Joe Fineman <jcf@TheWorld.com>
  (defun xsteve/replace-char (char1 char2)
    "Remove the most recent instance of CHAR1; replace it with CHAR2 if not the same."
    (interactive "cCharacter to remove:  \ncReplace it with:  ")
    (save-excursion
      (search-backward (char-to-string char1))
      (delete-char 1)
      (unless (= char2 char1)
        (insert char2))))

  ;;From: Joe Fineman <jcf@TheWorld.com>
  (defun xsteve/insert-missing-char (predecessor insertion)
    "After the most recent PREDECESSOR, insert INSERTION."
    (interactive "cAfter:  \ncInsert:  ")
    (save-excursion
      (search-backward (char-to-string predecessor))
      (forward-char 1)
      (insert insertion)))

  (defun increment-number-at-point (amount)
    "Increment number at point by given AMOUNT."
    (interactive "NIncrement by: ")
    (let ((bounds (bounds-of-thing-at-point 'symbol))
          (old-num (number-at-point)))
      (unless old-num
        (error "No number at point"))
      (delete-region (car bounds) (cdr bounds))
      (insert (format "%d" (+ old-num amount)))))

  ;; ===========================================================================================
  ;; macro-math.el --- in-buffer mathematical operations
  ;; Perform math operations directly in the buffer.  Great for macros.

  ;; For example, use it to increase all numbers in a buffer by one.
  ;; Call `kmacro-start-macro', move the point behind the next number,
  ;; type "+ 1", mark the number and + 1, call
  ;; `macro-math-eval-region'.  Finish the macro with
  ;; `kmacro-end-macro', then call it repeatedly.

  (when (eload 'macro-math)
    (autoload 'macro-math-eval-and-round-region "macro-math" t nil)
    (autoload 'macro-math-eval-region "macro-math" t nil)

    (global-set-key "\C-x~" 'macro-math-eval-and-round-region)
    (global-set-key "\C-x=" 'macro-math-eval-region)
    )

  ;; ===========================================================================================
  ;; keyboard-macro-timer.el --- Run last keyboard macro with a timer

  (autoload 'keyboard-macro-timer-start "keyboard-macro-timer"
    "Execute last keyboard macro with a timer." t)

  ;; ===========================================================================================
  ;; split-root.el --- root window splitter
  ;; Use `split-root-window' to split the root window.  This creates a pair of
  ;; windows, a new one, and one containing your previous window configuration
  ;; (as long as it fits).
  ;; Create a new top-level window in GNU Emacs while keeping your
  ;; current window configuration.  For example, pop up an Eclipse-style
  ;; compilation window.

  (when (eload 'split-root)

    ;; to pop up compilation buffers at the bottom (OPTIONAL)
    (eload 'compile)
    (defvar compilation-window nil
      "The window opened for displaying a compilation buffer.")

    ;;(setq compilation-window-height 14)

    (when nil
      (defun my-display-buffer (buffer &optional not-this-window)
        (if (or (compilation-buffer-p buffer)
                (equal (buffer-name buffer) "*Shell Command Output*"))
            (unless (and compilation-window (window-live-p compilation-window))
              (setq compilation-window (split-root-window compilation-window-height))
              (set-window-buffer compilation-window buffer))
          (let ((display-buffer-function nil))
            (display-buffer buffer not-this-window))))

      (setq display-buffer-function 'my-display-buffer)

      ;; on success, delete compilation window right away!
      (add-hook 'compilation-finish-functions
                (lambda(buf res)
                  (unless (or (eq last-command 'grep)
                              (eq last-command 'grep-find))
                    (when (equal res "finished\n")
                      (when compilation-window
                        (delete-window compilation-window)
                        (setq compilation-window nil))
                      (message "compilation successful")))))
      )
    )

  ;; ===========================================================================================
  ;; Use `pick-backup-and-ediff', `pick-backup-and-diff',
  ;; `pick-backup-and-revert', and `pick-backup-and-view'.
  ;; Use `pick-backup-file' in your own code.
  (eload 'pick-backup) ;Easy access to versioned backup files. See: http://nschum.de/src/emacs/pick-backup/ WARNING: Buggy!

  ;; ===========================================================================================
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/BackupDirectory#toc2

  (when (eload 'backup-dir)
    ;; localize it for safety.
    (make-variable-buffer-local 'backup-inhibited)
    ;; (push '("." . "~/.emacs-backups") backup-directory-alist)
    ;; The following make-backup-file-name will store your files in
    ;; dated directories (for example,
    ;; ~/.backups/emacs/07/04/07/filename):
    ;;   (defun make-backup-file-name (FILE)
    ;;     (let ((dirname (concat "~/.backups/emacs/"
    ;;                            (format-time-string "%y/%m/%d/"))))
    ;;       (if (not (file-exists-p dirname))
    ;;           (make-directory dirname t))
    ;;       (concat dirname (file-name-nondirectory FILE))))
    )

  ;; ===========================================================================================
  ;; Misc Emacs Functions from Stefan ReichÂÃ¶r, stefan@xsteve.at

  (defun xsteve/show-message-buffer (arg)
    "Show the *message* buffer.
When called with a prefix argument, show the *trace-output* buffer."
    (interactive "P")
    (let ((buffer (current-buffer)))
      (pop-to-buffer (if arg "*trace-output*" "*Messages*"))
      (goto-char (point-max))
      (recenter -12)
      (pop-to-buffer buffer)))

  ;; Can emacs be made to right Messages buffer to disc?
  ;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/ef42f9d5b74e838f/582c98a8cdbc32c3#582c98a8cdbc32c3
  (when nil
    (setq message-log-max t)            ; Emacs Lisp!!!
    (with-current-buffer (get-buffer "*Messages*")
      (setq buffer-file-name "~/.emacs_messages")
      (setq buffer-offer-save t))       ; just in case
    (defun save-messages-buffer ()
      (with-current-buffer (get-buffer "*Messages*")
        ;; (save-buffer 0) or even just (basic-save-buffer) is too noisy, so
        ;; we lose their functionality (including basic-save-buffer-1 and
        ;; basic-save-buffer-2):
        (when (and buffer-file-name
                   (buffer-modified-p))
          (write-region (point-min) (point-max) buffer-file-name
                        nil 'quiet))))  ;NOTE: Silence!
    ;; ToDo: Do this less often (using a time interval).
    ;;(remove-hook 'pre-command-hook 'save-messages-buffer)
    ;;(remove-hook 'post-command-hook 'save-messages-buffer)
    )

  (defun xsteve/exchange-slash-and-backslash ()
    "Exchanges / with \ and in the current line or in the region when a region-mark is active."
    (interactive)
    (save-match-data
      (save-excursion
        (let ((replace-count 0)
              (eol-pos (if (use-region-p) (region-end) (progn (end-of-line) (point))))
              (bol-pos (if (use-region-p) (region-beginning) (progn (beginning-of-line) (point)))))
          (goto-char bol-pos)
          (while (re-search-forward "/\\|\\\\" eol-pos t)
            (setq replace-count (+ replace-count 1))
            (cond ((string-equal (match-string 0) "/") (replace-match "\\\\" nil nil))
                  ((string-equal (match-string 0) "\\") (replace-match "/" nil nil)))
            (message (format "%d changes made." replace-count)))))))

  ;; NOTE: This function does not work reliably, it works now for 2005
  (defun xsteve/calendar-week-number (date)
    "Return the week number for DATE.
The week starts on MONDAY."
    (let* ((year (extract-calendar-year date))
           (day-number (calendar-day-number date))
           (day-of-week-first-day (calendar-day-of-week (list 1 1 year)))
           (adjust))
      (when (eq 0 day-of-week-first-day)
        (setq day-of-week-first-day 7))
      (setq adjust (% (- 9 day-of-week-first-day) 8))
      (if (< day-number adjust)
          (calendar-week-number (list 12 31 (- year 1)))
        (+ 1 (/ (- day-number adjust) 7)))))
  ;;(calendar-week-number '(12 31 2004))
  ;;(calendar-week-number '(1 1 2005))
  ;;(calendar-week-number '(2 1 2005))
  ;;(calendar-week-number '(3 1 2005))

  ;; ===========================================================================================
  ;; Calendar

  ;; Fix foolish calendar-mode scrolling.
  (add-hook 'calendar-load-hook
            (lambda ()
              (setq mark-holidays-in-calendar t)
              (define-key calendar-mode-map ">" 'scroll-calendar-left)
              (define-key calendar-mode-map "<" 'scroll-calendar-right)
              (define-key calendar-mode-map "\C-x>" 'scroll-calendar-left)
              (define-key calendar-mode-map "\C-x<" 'scroll-calendar-right)))

  ;; ===========================================================================================
  ;; Evaluation of Emacs Lisp Expressions

  ;; nroff-mode (Manual Pages are written in that)
  (setq auto-mode-alist
        (append '(
                  ("man/.*\\.[1-9][[:lower:]]\\'" . nroff-mode)
                  )
                auto-mode-alist))
  ;; nroff-filladapt.el --- nroff comment prefixes for filladapt
  (when (eload 'nroff-filladapt)
    (add-hook 'nroff-mode-hook 'nroff-filladapt-setups)
    )

  (global-set-key [(meta s)] 'center-line) ;NOTE: Override anything's key-binding.

  ;; openwith.el --- Open files with external programs
  ;;ToDo: Disabled because this openwith annoys me in org-mode trying to
  ;;run eog externally first time I open it and when I do C-l.
  (when nil
    (when (eload 'openwith)
      ;;WARNING: Deactivated because it conflicts with dired-insert-file-icons()
      (openwith-mode nil)
      )
    )

  ;; tagger.el --- Tagged information handler
  (eload 'tagger)

  ;; singlebind.el --- Bind commands to single characters
  (eload 'singlebind)

  ;; timid.el --- timid completion
  (eload 'timid)

  ;; ===========================================================================================

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/TreeMode
  (when (eload 'tree-mode)

    ;; add some nice icons
    (eval-after-load "tree-widget"
      '(if (boundp 'tree-widget-themes-load-path)
           (add-to-list 'tree-widget-themes-load-path (elsub "others") t)))
    )

  ;; Do M-x tags-tree to view content of a TAGS file as a tree.
  (eload 'tags-tree)
  (autoload 'tags-tree "tags-tree" "TAGS tree" t)

  ;; ===========================================================================================

  (defcustom pnw/use-lispdoc nil
    "Flags whether or not to load lispdoc upon startup." :type 'boolean :group 'pnw-options)

  (when pnw/use-lispdoc
    (defun lispdoc (arg)
      "Searches lispdoc.com for SYMBOL, which is by default the symbol
currently under the cursor."
      (interactive "P")
      (let* ((word-at-point (word-at-point))
             (symbol-at-point (symbol-at-point))
             (default (symbol-name symbol-at-point))
             (inp (read-from-minibuffer
                   (if (or word-at-point symbol-at-point)
                       (concat "Symbol (default \"" default "\"): ")
                     "Symbol (no default): "))))
        (if (and (string-equal inp "") (not word-at-point) (not symbol-at-point))
            (message "You didn't enter a symbol!")
          (let ((search-type (if arg "full+text+search" "basic+search"))
                (target-symbol (if (string-equal inp "") default inp)))
            (browse-url (concat "http://lispdoc.com?q=" target-symbol
                                "&search=" search-type))))))

    (define-key help-map (kbd "l") 'lispdoc) ; was view-lossage
    (define-key help-map (kbd "M-l") 'view-lossage)
    ;;(define-key lisp-mode-map (kbd "C-c l") 'lispdoc)
    )

  ;; ===========================================================================================

  ;; A function to go to the definition of a function bound to a key.

  (defun find-key-function-definition (key &optional untranslated up-event)
    "Find the definition of a key."
    (interactive "kKey Sequence: \np\nU")
    (if (numberp untranslated)
        (setq untranslated (this-single-command-raw-keys)))
    (save-excursion
      (let ((modifiers (event-modifiers (aref key 0)))
            window position)
        ;; For a mouse button event, go to the button it applies to
        ;; to get the right key bindings.  And go to the right place
        ;; in case the keymap depends on where you clicked.
        (if (or (memq 'click modifiers) (memq 'down modifiers)
                (memq 'drag modifiers))
            (setq window (posn-window (event-start (aref key 0)))
                  position (posn-point (event-start (aref key 0)))))
        (when (windowp window)
          (set-buffer (window-buffer window))
          (goto-char position))
        (let ((defn (key-binding key)))
          (if (or (null defn) (integerp defn) (equal defn 'undefined))
              (message "%s is undefined" (help-key-description key untranslated))
            (find-function defn))))))

  ;;(global-set-key [(control h) (control k)] 'find-key-function-definition)

  ;; ===========================================================================================

  (eload 'visual-studio-emulation)      ;Visual Studio Emulation

  ;; ===========================================================================================

  ;; gnuserv site-lisp configuration

  ;; gnuserv is know enable by default in Emacs
  ;;(eload 'gnuserv)

  ;; necessary for FSF GNU Emacs only
  (autoload 'gnuserv-start "gnuserv-compat"
    "Allow this Emacs process to be a server for client processes." t)

  ;; By default, gnuserv will load files into new frames. If you would
  ;; rather have gnuserv load files into an existing frame, then
  ;; evaluate the following in the chosen frame:

  ;; Placing the below code in your startup file, for example, will have
  ;; gnuserv load files into the original Emacs frame. NOTE: one
  ;; drawback of this approach is that if the frame associated with
  ;; gnuserv is ever closed, gnuserv won't have a frame in which to
  ;; place buffers.
  (setq gnuserv-frame (selected-frame))

  ;; ===========================================================================================
  ;; Constants - enter constant definitions into source code


  ;; Global Find File
  (when nil                       ;NOTE: Disabled because this gives load error!
    (when (eload 'globalff)
      (global-set-key [(control x) (control g)] 'globalff)

      ;; to harmonize with isearch keybindings
      (define-key globalff-map (kbd "M-r") 'globalff-toggle-regexp-search)
      )
    )

  ;; flash matching parenthesis a la Zmacs
  (when (eload 'flash-paren)
    ;; NOTE: Deactivating this for now as I suspect that it turns on
    ;; blinking upon cursor movement which is really annoying.
    ;; (flash-paren-mode 1)
    )

  ;; linkify.el --- Create clickable links to lines in files.
  (defcustom pnw/use-linkify nil
    "Flags whether or not to load linkify upon startup." :type 'boolean :group 'pnw-options)
  (if pnw/use-linkify
      (when (eload 'linkify)
        ))

  ;; rlogin
  ;;(when (file-exists-p (elsub "rlogin.elc")
  ;;Uncommented because already in Emacs
  ;;(eload 'rlogin)
  ;;)

  ;; xterm-frobs
  ;; Deactivated because it does not work for me /Per NordlÂÃ¶w 2006-02-05
  (when nil
    (when (eload 'xterm-frobs)
      ))

  ;; english-menu.el --- mule-menu template
  (eload 'english-menu)

  ;; clibpc.el --- partial complete functions for c libraries
  (when (eload 'clibpc)
    (when nil
      (add-hook 'c-mode-hook
                (lambda ()
                  (define-key c-mode-map "\t" 'clibpc-complete-function)
                  (eldoc-mode 1)
                  (set (make-local-variable 'eldoc-documentation-function)
                       'clibpc-eldoc-function)))))

  ;; fff
  ;; install some keybindings for fff
  ;;(eval-after-load "fff" '(fff-install-map))
  (when (eload 'fff))
  (when (eload 'fff-elisp))
  (when (eload 'fff-rfc))

  ;; rfc-util.el --- RFC-util interface for emacs.
  (when (eload 'rfc-util))

  ;; doh
  (defcustom pnw/use-doh nil
    "Flags whether or not to load doh upon startup." :type 'boolean :group 'pnw-options)
  (if pnw/use-doh
      (when (eload 'doh)
        (setq doh-file-name (elsub "doh.au"))
        ))
  ;;(ad-remove-advice ding 'before run-doh-hook)

  ;; suggbind
  (when (eload 'suggbind))

  ;; eval-expr
  (when (eload 'eval-expr))
  ;; I really dislike it when GNU/Emacs abbreviates a sexp and takes
  ;; over RET. Accordions have their place, but not in any buffer I'm
  ;; editing.
  (setq eval-expression-print-level 10  ; default 4
        eval-expression-print-length 50) ; default 12

  ;; pager
  (when (eload 'pager)
    (global-set-key [(prior)] 'pager-page-up)
    (global-set-key [(next)] 'pager-page-down)
    (global-set-key [(scroll-up-nomark)] 'pager-page-up)
    (global-set-key [(scroll-down-nomark)] 'pager-page-down)
    (global-set-key [(scroll-up)] 'pager-page-up)
    (global-set-key [(scroll-down)] 'pager-page-down)
    )

  ;; ===========================================================================================
  ;; "Wajig is an interface to many Debian administrative tasks. Written
  ;; in Python, wajig uses traditional Debian administration and user
  ;; tools including apt-get, dpkg, apt-cache, wget, and others. It is
  ;; intended to unify and simplify common administrative tasks." See
  ;; See: http://www.togaware.com/wajig/ for more infomation.

  ;; I write this package as a wrapper of wajig for Emacs. I love living
  ;; within Emacs. :-)

  ;; Put this file into your load-path and the following into your ~/.emacs:

  ;;    (autoload 'wajig "wajig"
  ;;             "Create a *wajig* buffer." t)

  ;; Then, simply run `M-x wajig'.

  ;; Burn CDs and DVDs with external tools
  (when nil (eload 'cdvdmacs))

  ;; linum - Warning: Kind of crappy and slow!
  (defcustom pnw/use-linum nil
    "Flags whether or not to load linum upon startup." :type 'boolean :group 'pnw-options)
  (if pnw/use-linum
      (when (require 'linum nil t)
        (eload 'linum+)
        ))

  ;; Frame Title
  ;; See the variable "mode-line-format" for documentation on syntax
  (setq frame-title-format
        '(("" invocation-name "@" system-name)
          ":%b (%m) file:%f size:%I"))
  ;; File names in title bars with a twist: Replace HOME with ~ while
  ;; still working with Emacs' / and HOME's \. And it works for
  ;; Windows-style HOMEs.
  (when nil
    (setq frame-title-format
          '(:eval
            (if buffer-file-name
                (replace-regexp-in-string
                 "\\\\" "/"
                 (replace-regexp-in-string (regexp-quote (getenv "HOME")) "~"
                                           (convert-standard-filename buffer-file-name)))
              (buffer-name)))))

  (when (eload 'saveplace)
    (setq-default save-place t)
    )

  ;; Translate ANSI escape sequences into faces
  ;; (GNUEmacs->=22
  ;;  (when (eload 'ansi-color)
  ;;    (ansi-color-for-comint-mode-on)
  ;;    (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
  ;;    ))

  ;; pdb.el --- Editing Protein Databank files  -*-coding: iso-2022-7bit;-*-
  ;;(eload 'pdb)

  ;; Highlight crosstool settings files as shell syntax (sh-mode)
  (setq auto-mode-alist
        (append '(
                  ("crosstool-[0-9]\\.[0-9]+/.*\\.dat.*\\'" . sh-mode)
                  ("crosstool-[0-9]\\.[0-9]+/buildlogs/.*\\.dat.*\\'" . sh-mode)
                  )
                auto-mode-alist))

  ;; Create a flashcard-type file for the multiplication table until 15
  (defun mult-table-15()
    (interactive)
    (message
     (mapconcat
      'identity
      (shuffle-vector
       (apply
        'vector
        (apply
         'append
         (let ((list '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))
           (mapcar
            (lambda (a)
              (mapcar
               (lambda (b)
                 (format "%d x %d = : %d" a b (* a b)))
               list))
            list)))))
      "\n")))

  (eload 'pgo-skeleton) ;Lisp language extension for writing statement skeletons

  ;; file-template.el --- File templates
  (eload 'file-template)

  ;; 123-menu.el --- Simple menuing system, reminiscent of Lotus 123 in DOS
  (eload '123-menu)

  ;; listbuf.el --- build buffer menu for use in Buff-menu-mode
  (autoload 'listbuf "listbuf" nil t)

  ;; ===========================================================================================
  ;; Frame State Saving and Loading

  (defun my-save-frame-info ()
    "Save information about current Emacs frames"
    (interactive)
    (let ((cbuf (current-buffer)))
      (switch-to-buffer "*scratch*")
      (goto-char (point-max))

      (insert "(defun my-make-frames ()\n  \"\"\n")
      (insert "  (interactive)\n\n")
      (insert "  ; delete all current frames except 1\n") ;
      (insert "  (while (> (length (frame-list)) 1)\n")
      (insert "    (delete-frame (nth 0 (frame-list))))\n\n")
      (insert "  ; size and position the remaining frame\n")

      (let ((frm (car (frame-list))))
        (insert "  (let ((frm (car (frame-list))))\n")
        (insert (format "    (set-frame-position frm %d %d)\n"
                        (frame-parameter frm 'left)
                        (frame-parameter frm 'top)))
        (insert (format "    (set-frame-size     frm %d %d))\n\n"
                        (frame-width frm)
                        (frame-height frm))))

      (insert "  ; make additional frames and position them\n")

      (dolist (frm (cdr (frame-list)))
        (insert "  (let ((frm (make-frame)))\n")
        (insert (format "    (set-frame-position frm %d %d)\n"
                        (frame-parameter frm 'left)
                        (frame-parameter frm 'top)))
        (insert (format "    (set-frame-size     frm %d %d))\n"
                        (frame-width frm)
                        (frame-height frm))))
      (insert ")\n")
      (switch-to-buffer cbuf)
      (message "Look at the end of the *scratch* buffer..."))
    )

  ;; Use the above in desktop hooks
  (when nil
    (add-hook 'desktop-save-hook
              (lambda ()
                (frame-configuration-to-register ?f)))
    (add-hook 'desktop-after-read-hook
              (lambda ()
                (jump-to-register ?f)))
    )

  ;; ===========================================================================================
  ;; Xrefactory: http://www.xref-tech.com/xrefactory/main.html

  ;; Xrefactory configuration part ;;
  ;; some Xrefactory defaults can be set here
  (when nil
    (if (file-exists-p (elsub "xref"))
        (progn
          (defvar xref-current-project nil) ;; can be also "my_project_name"
          (defvar xref-key-binding 'global) ;; can be also 'local or 'none
          (add-to-list 'load-path (elsub "xref/emacs") t)
          (add-to-list 'load-path (elsub "xref") t)
          (load "xrefactory")
          ;; end of Xrefactory configuration part ;;
          (message "xrefactory loaded")
          ))
    )

  ;; ===========================================================================================
  ;; wiki.el --- hypertext authoring the WikiWay

  (when (eload 'wiki)
    )

  ;; ===========================================================================================
  ;; simple-wiki.el --- edit local raw wiki pages
  ;; SimpleWikiMode: http://www.emacswiki.org/cgi-bin/wiki/SimpleWikiMode

  (when (eload 'simple-wiki)
    (add-to-list 'auto-mode-alist '("w3mtmp" . simple-wiki-mode))
    (autoload 'sgml-tag "sgml-mode" t)
    (define-key simple-wiki-mode-map (kbd "C-c C-t") 'sgml-tag)
    (add-hook 'simple-wiki-mode-hook 'turn-on-auto-fill)
    )

  ;; SimpleWikiEditMode
  (when (eload 'simple-wiki-edit)
    )

  (when (eload 'simple-wiki-completion)
    )

  ;; ===========================================================================================
  ;; full-ack.el --- a front-end for ack

  (when nil
    (add-to-list 'load-path "/path/to/full-ack")
    (autoload 'ack-same "full-ack" nil t)
    (autoload 'ack "full-ack" nil t)
    (autoload 'ack-find-same-file "full-ack" nil t)
    (autoload 'ack-find-file "full-ack" nil t)
    )

  ;; ===========================================================================================

  ;; file-props.el --- Add file properties to your files
  (when nil (when (eload 'file-props)))

  ;; ===========================================================================================

  ;; sqlplus.el --- User friendly interface to SQL*Plus and support for PL/SQL compilation
  (if nil
      (when (eload 'sqlplus)
        (add-to-list 'auto-mode-alist '("\\.sqp\\'" . sqlplus-mode))))

  ;; mysql.el --- mysql front-end
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/mysql
  (when (eload 'mysql)
    (when (eload 'sql-completion)
      ;; sql-completion.el
      (add-hook 'sql-interactive-mode-hook
                (lambda ()
                  (define-key sql-interactive-mode-map "\t" 'comint-dynamic-complete)
                  (sql-mysql-completion-init)))))

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/Bibus
  (eload 'bibus)

  (eload 'scroll-mode-line-mode)        ;Warning: I don't really get it...


  ;; heap.el --- heap (a.k.a. priority queue) data structure package
  (when (eload 'heap))

  ;; tstree.el --- ternary search tree package
  (when (eload 'tstree))

  ;; dict-tree.el --- dictionary data structure package
  (when (eload 'dict-tree))

  ;; ac-anything.el --- Auto Complete with Anything
  (when (eload 'ac-anything))

  ;; trie.el --- trie package
  (when (eload 'trie))

  (eload 'pgo-completion-ui)

  ;; Word documents
  (when (eload 'no-word)
    (add-to-list 'auto-mode-alist '("\\.doc\\'" . no-word)))

  ;; HTML Helper Mode (overrides default HTML-mode)
  (defcustom pnw/use-html-helper-mode nil
    "Flags whether or not to load and use html-helper-mode upon
  startup." :type 'boolean :group 'pnw-options)
  (when pnw/use-html-helper-mode
    (autoload 'html-helper-mode "html-helper-mode" "Yay HTML" t)
    (if (functionp 'html-helper-mode)
        (setq auto-mode-alist
              (append '(
                        ("\\.htm[l]?\\'" . html-helper-mode) ; HTML files
                        ("\\.asp\\'" . html-helper-mode)     ; ASP files
                        ("\\.phtml\\'" . html-helper-mode)   ; HTMLP files
                        )
                      auto-mode-alist))))

  (eload 'pgo-multiple-modes)

  ;; jump-or-exec.el -------- Jump to a buffer or create it.
  (load-file-if-exist (elsub "jump-or-exec.elc"))

  (eload 'edit-variable)

  (eload 'hmac-sha1)

  ;; Clever little snippet. Use M-r to run replace-recent-character.
  (eload 'rrc)

  ;; ipa.el --- In-place annotations
  (eload 'ipa)

  ;; multiverse.el --- manage multiple versions of buffers in an Emacs session
  (eload 'multiverse)

  ;; sawfish.el --- Sawfish mode.
  (when (eload 'sawfish))

  ;; Sudo Wrappers
  ;; Use `write-file-hooks' and `after-save-hook' to run "sudo chown ... " before
  ;; AND after file save.  This allows the Emacs process to grant ownership to the
  ;; user and then restore ownership just after save.
  ;; See: http://www.emacswiki.org/emacs/SudoSave
  (eload 'sudo-save)

  ;; extraedit.el --- Extra useful edit functions and macros
  (when (eload 'extraedit)
    (defalias 'comment-line 'line-comment)
    (defalias 'uncomment-line 'line-uncomment)
    )

  (eload 'cus-edit+)                    ;Enhancements to `cus-edit.el'.

  ;; bencode.el handles serialization of integers, strings, lists, and hash-tables
  ;; Warning: KIND OF CRAPPY!
  (when (load "bencode" nil t)
    ;; Bencoding is a way to encode integers, strings, lists, and
    ;; hash-tables as strings (serialization), and bdecoding does the
    ;; reverse operation. It is part of the BitTorrent metafile
    ;; specification.
    ;; Missing: The specification says ôòüKeys must be strings and appear
    ;; in sorted order (sorted as raw strings, not alphanumerics).
    ;; What does that mean, exactly? Sorting on the raw bytes?
    ;; Hereôòùs an application for the code: TorrentView lets you view
    ;; the files in a torrent:
    (defun bittorrent-view (&optional file)
      "View the current buffer or FILE as a bencoded torrent metainfo file."
      (interactive "fTorrent file: ")
      (with-temp-buffer
        (insert-file-literally file)
        (goto-char (point-min))
        (let* ((data (bdecode-buffer))
               (info (cdr (assoc "info" data)))
               (files (cdr (assoc "files" info))))
          (set-buffer (get-buffer-create file))
          (erase-buffer)
          (dolist (path (mapcar (lambda (f) (cdr (assoc "path" f))) files))
            (insert (mapconcat 'identity path path-separator))
            (newline))
          (goto-char (point-min))
          (view-buffer (current-buffer)))))
    (defalias 'torrent-view 'bittorrent-view)
    )

  ;; Reverse behaviour of MouseRight and Control+MouseRight.
  (global-set-key [(mouse-3)] 'mouse-popup-menubar-stuff)
  (global-set-key [(control mouse-3)] 'mouse-save-then-kill)

  ;; Interactive replacement for locate-library with completion
  ;; WARNING: This really messes up EVERYTHING! Do not use!
  (if nil
      (when (eload 'abbrev-complete)
        ;;      (setq abbrev-complete-use-hippie t)
        ;;      (setq hippie-expand-try-functions-list
        ;;            '(try-complete-file-name-partially
        ;;              try-complete-file-name
        ;;              try-expand-list
        ;;              try-expand-line
        ;;              try-complete
        ;;              try-complete-lisp-symbol-partially
        ;;              try-complete-lisp-symbol))
        ))

  ;; pcmpl-ssh.el --- functions for completing SSH hostnames
  (eload 'pcmpl-ssh)

  ;; msf-abbrev.el --- maintain abbrevs in a directory tree
  ;; See: http://www.bloomington.in.us/~brutt/msf-abbrev.html
  (defcustom pnw/use-msf-abbrev nil
    "Flags whether or not to load msf-abbrev." :type 'boolean :group 'pnw-options)
  (when pnw/use-msf-abbrev
    ;; ensure abbrev mode is always on
    (setq-default abbrev-mode 1)
    (setq save-abbrevs nil) ;; do not bug me about saving my abbreviations
    ;; load up modes I use
    (eload 'cc-mode)
    (eload 'perl-mode)
    (eload 'cperl-mode)
    (eload 'sh-script)
    (eload 'shell)
    ;;(eload 'tex-site) ;; I use AUCTeX
    ;;(eload 'latex)    ;; needed to define LaTeX-mode-hook under AUCTeX
    ;;(eload 'tex)      ;; needed to define TeX-mode-hook under AUCTeX
    ;; (eload 'python)   ;; I use python.el from Emacs CVS, uncomment if you do also
    ;; load up abbrevs for these modes
    (when (eload 'msf-abbrev)
      (setq msf-abbrev-verbose t) ;; optional
      (setq msf-abbrev-root (elsub "mode-abbrevs"))
      ;;   (global-set-key (kbd "C-c l") 'msf-abbrev-goto-root)
      ;;   (global-set-key (kbd "C-c a") 'msf-abbrev-define-new-abbrev-this-mode)
      (msf-abbrev-load)
      )
    )

  ;; ===========================================================================================
  ;; HOC and NMODL Emacs modes for NEURON - for empirically-based
  ;; simulations of neurons and networks of neurons
  ;; See: http://homepages.inf.ed.ac.uk/sterratt/progs/neuron

  (defcustom pnw/use-neuron nil
    "Flags whether or not to load nrnhoc and nmodl." :type 'boolean :group 'pnw-options)

  (when pnw/use-neuron
    (autoload 'nrnhoc-mode "nrnhoc" "Enter NRNHOC mode." t)
    (setq auto-mode-alist (cons '("\\.hoc\\'" . nrnhoc-mode) auto-mode-alist))
    (add-hook 'nrnhoc-mode-hook 'turn-on-font-lock)

    (autoload 'nmodl-mode "nmodl" "Enter NMODL mode." t)
    (setq auto-mode-alist (cons '("\\.mod\\'" . nmodl-mode) auto-mode-alist))
    )

  ;; ===========================================================================================
  ;; Log the time it took to start Emacs.

  (when (and nil (eload 'time-date))
    (message "### Emacs startup time: %d seconds."
             (time-to-seconds (time-since emacs-load-start-time)))
    )

  ;; ===========================================================================================
  ;; TOTD - Tip Of The Day

  (defcustom pnw/use-totd nil
    "Flags whether or not to Display Tip Of The Day (TOTD)." :type 'boolean :group 'pnw-options)

  (when pnw/use-totd
    (defun totd ()
      "Display Tip Of The Day (TOTD)."
      (interactive)
      (with-output-to-temp-buffer "*Tip of the day*"
        (let* ((commands (loop for s being the symbols
                               when (commandp s) collect s))
               (command (nth (random (length commands)) commands)))
          (princ
           (concat "Your tip for the day is:\n"
                   "========================\n\n"
                   (describe-function command)
                   "\n\n\Invoke with:\n\n"
                   (with-temp-buffer
                     (where-is command t)
                     (buffer-string)))))))
    (defalias 'tip-of-the-day 'totd)

    (defvar totd-timer (run-at-time "12:00am" (* 3600 24) 'totd))
    (defun totd-cancel ()
      "Cancel use of Tip Of The Day (TOTD)."
      (interactive)
      (cancel-timer totd-timer))
    )

  ;; ===========================================================================================
  ;; paint.el --- Makes a Emacs to the Paint Tool

  (when (eload 'paint)
    )

  ;; ===========================================================================================
  ;; eimp.el --- Emacs Image Manipulation Package

  ;; (autoload 'eimp-mode "eimp" "Emacs Image Manipulation Package." t)

  (defcustom pnw/use-eimp nil
    "Flags whether or not to use EIMP." :type 'boolean :group 'pnw-options)

  (when pnw/use-eimp
    (if (executable-find "mogrify")
        (when (eload 'eimp)
          ;; (add-hook 'image-mode-hook 'eimp-mode)
          )
      ))

  ;; ===========================================================================================
  ;; dropdown-list.el --- Drop-down menu interface

  (when (eload 'dropdown-list)
    ;; Use: (dropdown-list '("alpha" "beta" "gamma"))
    )

  ;; ===========================================================================================
  ;; tabkey2.el --- Use second tab key pressed for what you want

  (when (eload 'tabkey2)
    )

  ;; ===========================================================================================
  ;; rgrep-traverse.el -- utilise l'interface rgrep pour traverse

  (when (eload 'rgrep-traverse)
    )

  ;; ===========================================================================================
  ;; autoinfo.el --- show automatic information for the current selection

  (eload 'autoinfo)

  ;; ===========================================================================================
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/ProjectLocalVariables
  ;; See: http://www.emacswiki.org/cgi-bin/wiki/FindFileInProject

  ;; find-file-in-project.el --- Find files in a project quickly.
  ;; project-local-variables.el --- Set project-local variables from a file.

  (when nil
    (eload 'find-file-in-project)
    (eload 'project-local-variables)
    )

  ;; ===========================================================================================
  ;; el-get

  (when (require 'el-get nil t))


  ;; ===========================================================================================
  ;; Selections and Kill Ring Enhancements

  ;; I needed to unique lines in a buffer’s content—the same
  ;; functionality that shell command uniq provides—but could not find
  ;; the proper Elisp equivalent for it, though. Even EmacsWiki suggests
  ;; using the shell command to delete duplicate lines. Here goes my
  ;; implementation for Lisp programs, it may come in useful.

  (defun unique-lines (beg end)
    "Unique lines in region.
Called from a program, there are two arguments:
BEG and END (region to sort)."
    (interactive "r")
    (save-excursion
      (save-restriction
        (narrow-to-region beg end)
        (goto-char (point-min))
        (while (not (eobp))
          (kill-line 1)
          (yank)
          (let ((next-line (point)))
            (while
                (re-search-forward
                 (format "^%s" (regexp-quote (car kill-ring))) nil t)
              (replace-match "" nil nil))
            (goto-char next-line))))))

  (defalias 'uniq-lines 'unique-lines)

  ;; ===========================================================================================
  ;; a-menu.el --- create a menu from a specified directory

  (when (eload 'a-menu)
    )

  ;; ===========================================================================================
  ;; contentswitch.el --- switch to buffer/file by content

  (when (eload 'contentswitch)
    )

  ;; ===========================================================================================
  ;; typopunct.el --- Automatic typographical punctuation marks
  ;;
  ;; When typopunct-mode is on, hitting - two times will insert an
  ;; en-dash (–); hitting - once more will change that to an em-dash
  ;; (—). Also, hitting " and ' will insert typographical quotation
  ;; marks (AKA “smart quotes”) depending on context and depending on
  ;; various national typographical conventions. By default, the
  ;; following quotation styles are supported:
  ;;
  ;; * deutsch – for German „quotation marks“ and ‚single quotation marks‘ (default)
  ;; * francais – for French «double quotation marks» and ‹single quotation marks›
  ;; * deutsch-2 – for an alternative style of German »double« and ›single quotation marks‹
  ;; * english – for English “double” and ‘single quotation marks’
  ;;
  ;; See: http://www.emacswiki.org/emacs-en/TypographicalPunctuationMarks

  (add-hook 'org-mode-hook 'org-typopunct-init)
  (defun org-typopunct-init ()
    (eload 'typopunct)
    (typopunct-change-language 'english)
    (typopunct-mode 1)

    ;; We may use skeletons to wrap any selected text in quotes when we
    ;; hit " . This also makes the " key “move over” any existing
    ;; quotation marks.
    (defadvice typopunct-insert-quotation-mark (around wrap-region activate)
      (let* ((lang (or (get-text-property (point) 'typopunct-language)
                       typopunct-buffer-language))
             (omark (if single
                        (typopunct-opening-single-quotation-mark lang)
                      (typopunct-opening-quotation-mark lang)))
             (qmark (if single
                        (typopunct-closing-single-quotation-mark lang)
                      (typopunct-closing-quotation-mark lang))))
        (cond
         (mark-active
          (let ((skeleton-end-newline nil))
            (skeleton-insert (list nil omark '_ qmark) -1)))
         ((looking-at (regexp-opt (list (string omark) (string qmark))))
          (forward-char 1))
         (t
          ad-do-it))))

    )

  (when nil (eload 'messenger-en))      ;MSN Messenger on Emacs

  ;; ===========================================================================================
  ;; strptime.el -- partial implementation of POSIX date and time parsing

  (when (eload 'strptime)
    )

  ;; ===========================================================================================
  ;; celssc-mode.el --- Major mode for editing celestia script files

  ;;     Major mode for editing celestia catalog files.
  ;;     This minor mode is based on
  ;;     tutorial that can be found here:
  ;;     http://two-wugs.net/emacs/mode-tutorial.html

  ;;     If celssc-mode is not part of your distribution, put this file into your
  ;;     load-path and the following into your ~/.emacs:

  (when t
    (autoload 'celssc-mode "celssc-mode"
      "Major mode for editing Celestia's solar system catalog files" t)
    (setq auto-mode-alist (cons '("\\.ssc" . celssc-mode)
                                auto-mode-alist))
    (autoload 'celssc-mode "celssc-mode"
      "Major mode for editing celesita's star catalog files" t)
    (setq auto-mode-alist (cons '("\\.stc" . celssc-mode)
                                auto-mode-alist))
    (autoload 'celssc-mode "celssc-mode"
      "Major mode for edit celestia's deep sky objects files" t)
    (setq auto-mode-alist (cons '("\\.dso" . celssc-mode)
                                auto-mode-alist))
    )

  ;; ===========================================================================================
  ;; apl.el --- APL input method for Emacs
  ;; See: http://stud4.tuwien.ac.at/~e0225855/unicapl/unicapl.html
  ;; See: GNU Unifont: http://unifoundry.com/unifont.html

  (when (eload 'apl)

    ;; Enable the APL input method with
    ;; M-x set-input-method RET apl-ascii RET

    ;; NOTE: Emacs is getting increasingly better at handling Unicode,
    ;; and more recent versions may choose the right glyphs for all
    ;; characters automatically, sometimes drawing from various
    ;; fonts. You therefore may not need "apl-set-font" at all. However,
    ;; you may still find it useful to enforce a uniform font for all
    ;; APL characters.
    ;; (apl-set-font "-gnu-unifont-*-r-*--*-*-*-*-*-*-ISO10646-1")
    ;; With Emacs 22 and later, you can use the shorter form:

    ;; NOTE: Disable cause it does not work for my Emacs 23.
    ;;(apl-set-font '("gnu-unifont" . "ISO10646-1"))
    )

  ;; ===========================================================================================
  ;; bhl.el --- From (P)lain text to (H)tml and (L)aTeX.

  (when (eload 'bhl)
    )

  ;; ===========================================================================================
  ;; blorg.el --- export a blog from an org file

  ;; TODO Errors:
  ;; debugger-setup-buffer: Symbol's function definition is void: :blog-title
  (when nil
    (when (eload 'blorg)
      )
    )

  ;; ===========================================================================================
  ;; flickr.el --- An flickr API client for Emacs

  (when (eload 'flickr)
    ;; You first need to get an API key from flickr:
    ;; http://www.flickr.com/services/api/keys/apply/
    ;;
    ;; Once you've got your key, set these variables:
    ;;
    ;; `flickr-username' : your username (e.g. "baztien")
    ;; `flickr-api-key'  : the key (32 bits)
    ;; `flickr-secret'   : the shared secret (16 bits)
    )

  ;; flickr-group.el --- Get more data about flickr groups
  (when (and (eload 'w3m)
             ;;(eload 'flickr-group)
             )
    )

  ;; ===========================================================================================
  ;; weblogger.el - Weblog maintenance via XML-RPC APIs

  (when (eload 'weblogger)
    )

  ;; ===========================================================================================
  ;; Twit.el --- interface with twitter.com

  (when (eload 'twit)
    )

  ;; ===========================================================================================
  ;; irfc.el --- Interface for IETF RFC document.

  (when (eload 'irfc)
    )

  ;; ===========================================================================================
  ;; mm2mw.el --- A MoinMoin 1.2.x -> MediaWiki 1.7.x converter

  (when (eload 'mm2mw)
    )

  ;; ===========================================================================================
  ;; multi-scratch.el --- Multiple scratches manager

  (when (eload 'multi-scratch)
    )

  ;; ===========================================================================================
  ;; chm-view.el --- View CHM file.

  (when (eload 'chm-view)
    )

  ;; ===========================================================================================
  ;; pushy.el --- pushy completion

  (when (eload 'pushy)
    )

  ;; ===========================================================================================
  ;; wireless --- Display wireless status information

  (defcustom pnw/use-wireless nil
    "Flags whether or not to load wireless." :type 'boolean :group 'pnw-options)
  (if pnw/use-wireless
      (when (eload 'wireless)
        ;;(display-wireless-mode 1)
        ))

  (eload 'basic-edit-toolkit)           ;Basic edit toolkit.

  (eload 'buffer-extension)      ;Some enhanced functions for buffer manipulate.
  (eload 'lazy-set-key)          ;Lazy set keystroke.
  (eload 'fullscreen)            ;Full screen

  ;; ===========================================================================================
  ;; sequential-command.el --- Many commands into one command
  (when (eload 'sequential-command)
    (when (eload 'sequential-command-config)
      )
    )

  ;; ===========================================================================================
  ;; Jump: http://www.emacswiki.org/emacs-en/Jump

  (when (eload 'jump)
    ;;(global-set-key [f4] 'jump-symbol-at-point)
    ;;(global-set-key [(shift f4)] 'jump-back)
    )

  ;; ===========================================================================================
  ;; unibasic.el -- Copyright (C) 1998 Pat Thoyts <pat@zsplat.freeserve.co.uk>

  (when (eload 'unibasic)
    )

  ;; ===========================================================================================
  ;; smallurl.el --- Tinify URLs
  ;; http://www.shellarchive.co.uk/2009-03-08-lessen-a-url-with-smallurl-el.html

  ;; There are two interactive functions... with which you might want to
  ;; interact:
  ;;
  ;; smallurl-replace-at-point - replace the url at point with a tiny one.
  ;; smallurl                  - print and put into the kill ring the tiny
  ;;                             version of the url prompted for.

  (when (eload 'smallurl)
    )

  ;; ===========================================================================================
  ;; ergo-movement-mode.el


  (autoload 'ergo-movement-mode "ergo-movement-mode"
    "Ergonomic keybindings for cursor movement" 'interactive)

  ;; ===========================================================================================
  ;; keychain-environment.el --- Loads keychain environment variables into emacs

  ;; Designed for use with Keychain, see:
  ;; (http://www.gentoo.org/proj/en/keychain/) a tool for loading the
  ;; SSH Agent and keeping it running and accessible on a machine for
  ;; longer than a single login seession.
  ;;
  ;; This library loads the file "$HOME/.keychain/$HOSTNAME-sh" and parses
  ;; it for the SSH_AUTH_SOCK and SSH_AUTH_PID variables, placing these into the
  ;; environment of Emacs.
  ;;
  ;; This is useful for situations where you are running Emacs under X, not
  ;; directly from a terminal, and its inheriting its environment from the
  ;; window manager, which doesn't have these variables as you started keychain
  ;; after you logged in (say as part of your .bashrc)
  ;;
  ;; The function (refresh-keychain-environment) can also be run at any time
  ;; these variables change.


(when (eload 'keychain-environment)
  (eval-after-load "keychain-environment" '(refresh-keychain-environment))
  )

  ;; ===========================================================================================

  ;; Prepare Emacs desktop after loading Emacs

(if nil
    (add-hook 'after-init-hook
              (lambda ()
                ;; Show home directory on left pane, and last visited file on right
                (split-window-horizontally)
                (dired (my-home ?h)))
              ;; Note that 3-rd argument of this `add-hook' should be `t'
              ;; to append the call of the `dired' after other hooked functions,
              ;; most importantly after `desktop-read'.
              t)
  )
  )

;;; dotemacs.el ends here
