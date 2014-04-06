;;; complete-dwim.el --- Unified Interface to Completion, where Indentation and Alignment are actually Whitspace Completion.
;; Author: Per Nordlöw

;;; See: EmacsWiki: TabCompletion:
;;; See: http://www.emacswiki.org/cgi-bin/wiki/TabCompletion
;; TODO: Merge with `completion-at-point' and set `completion-at-point-functions' in Emacs 24.1 otherwise `complete-symbol'.
;; TODO: Merge with `completion-at-point-functions' and `completion-in-region'.
;; TODO: Reuse sym-comp.el functions?

(require 'hippie-exp)
(require 'semantic nil t)
;;(require 'pgo-hippie-expand)
;; (require 'thingatpt+)
;; (require 'thingatpt-util)

(defun unicomplete-hippie-expand (arg &optional no-repeat)
  (let* ((repeat-key (and (null no-repeat)
                          (= (length (this-single-command-keys)) 1)
                          last-input-event))
         (repeat-key-str (format-kbd-macro (vector repeat-key) nil)))
    (hippie-expand nil)                 ;first call
    (while repeat-key
      (message "(Type %s for next candidate)" (faze repeat-key-str 'keycomb))
      (if (equal repeat-key (read-event))
          (progn
            (clear-this-command-keys t)
            (hippie-expand nil)         ;yet another call
            (setq last-input-event nil))
        (setq repeat-key nil)))
    (when last-input-event
      (clear-this-command-keys t)
      (setq unread-command-events (list last-input-event)))
    ))

(defun complete-symbol-dwim ()
  "Complete symbol Do What I Mean (DWIM)."
  (when (fboundp 'completion-at-point)
    (completion-at-point)             ;only in Emacs 24.1
    ))

(defvar complete-dwim-repeats 0
  "Repeat counter for `complete-dwim'.")

;;; See: http://www.emacsblog.org/2007/03/12/tab-completion-everywhere/
(defun complete-dwim (arg &optional no-repeat)
  "A unification of completion, next navigation, indentation and
alignment which is minibuffer compliant: it acts as usual in the
minibuffer. Else, if mark is active, indents region. Else if
point is at the end of a symbol, expands it. Else indents the
current line. A prefix argument means to select completion
using a menu, which default to `completing-read."
  (interactive "p")
  (setq complete-dwim-repeats (if (eq last-command
                                      this-command)
                                  (1+ complete-dwim-repeats)
                                0))
  (cond ((minibufferp)                  ;in minibuffer
         (minibuffer-complete)
         ;; (unless (inhibit-messages (minibuffer-complete)) ;TODO: Make this skip printing messages
         ;;   (if buffer-read-only
         ;;       (progn
         ;;        (message "Can't complete, buffer is read-only!")
         ;;        (sit-for 3)  ;make the original content show after a short while
         ;;        )
         ;;     (ndabbrev-expand)
         ;;     ))
         )
        ((and (boundp 'edebug-active)
              edebug-active)
         (beginning-of-line-text 0))

        ((or (eq major-mode 'help-mode)
             (string-equal (buffer-name) "*Help*"))
         (forward-button 1 t))

        (buffer-read-only               ;read-only buffer
         (cond ((eq major-mode 'Info-mode)
                (Info-next-reference)
                )
               ((eq major-mode 'help-mode)
                (if (next-button 1)
                    (forward-button 1 t)
                  (message "Buffer is read only and no next button") (ding))
                )
               (t                       ;default to
                (if (next-button 1)     ;navigate buttons
                    (forward-button 1 t)
                  (message "Buffer is read only and no next button") (ding)))))

        ((memq major-mode '(gud-mode               ;GUD/GDB
                            inferior-octave-mode)) ;Octave
         (completion-at-point))                    ;Complete using comint

        ((use-region-p)                        ;mark is active
         (indent-region (region-beginning)
                        (region-end))
         (message "Region indented"))
        ((looking-back "^[[:blank:]]*") ;standing after beginning of line plus whitespace
         (if (fboundp 'indent-dwim)
             (indent-dwim arg)
           (indent-for-tab-command arg)))
        ((and (at-syntax-code-p)        ;in code (not in comment nor string)
              (unless (or (and (cc-derived-mode-p)
                               (c-try-expand-stub-bfpt)))
                (or
                 (and (fboundp 'semantic-active-p)
                      (semantic-active-p)
                      (fboundp 'semantic-ia-completing-read-symbol-and-maybe-show-summary)
                      (progn
                        (ignore-errors
                          (semantic-ia-completing-read-symbol-and-maybe-show-summary))
                        ;;(semantic-complete-analyze-inline) ;and if any complete them
                        )
                      ;; (fboundp 'semantic-mode) ;if Semantic online
                      ;; (fboundp 'semantic-analyze-possible-completions) ;if Semantic online
                      ;; (semantic-analyze-possible-completions (point)) ;analyze completions
                      )
                 (cond ((eq major-mode 'emacs-lisp-mode)
                        (complete-symbol-dwim))
                       ((eq major-mode 'python-mode)
                        (if (fboundp 'py-shell-complete)
                            (py-shell-complete) ;python-mode
                          (python-shell-completion-complete-at-point)))
                       (t
                        (call-interactively 'hippie-expand))
                       )))))
        (nil                            ;inserting a YASnippet
         (yas/next-field-group))
        ;; ((semantic-completion-inline-active-p)
        ;;  (semantic-complete-inline-TAB))
        (t
         (unicomplete-hippie-expand nil))
        ))
(global-set-key [(tab)] 'complete-dwim)
(add-hook 'python-mode-hook (lambda () (local-set-key [(tab)] 'complete-dwim)) t)

;; TODO: Only make this repeatable if `complete-dwim' key-binding is a multi-key.
;;(when (eload 'repeatable) (repeatable-command-advice complete-dwim))

;; TODO: Copy `kmacro-call-macro' structure
(when nil
  (defun ndabbrev-expand ()
    "Middle or Standard Dynamic Abbreviation Expansion.
First tries `mdabbrev-expand' and then standard
`dabbrev-expand'."
    (if (require 'mdabbrev nil t)
        (mdabbrev-expand) ;Note: `complete-symbol-dwim' cannot be used here (yet)!
      (dabbrev-expand 0)))

  (global-unset-key [(tab)])
  (define-prefix-command 'unicomplete-map nil
    "Complete:  Do-[<tab>,i,w f,F, t,y,l,L, a, c, d,D f, k, m, o, p, s,S, w]  Nav-[<left>,<right>]  -[<return>]")
  (progn
    (define-key unicomplete-map [(tab)] 'complete-dwim) ;Note: Easiest to press: My Unified version.
    (define-key unicomplete-map [(?i)] 'indent-for-tab-command) ;Indent
    (define-key unicomplete-map [(?w)] 'fixup-whitespace) ;in-Code Indentation

    ;; Dynamic Abbreviation (try-expand-dabbrev)
    (define-key unicomplete-map [(?d)] (make-hippie-expand-function '(try-expand-dabbrev-visible
                                                                      try-expand-dabbrev
                                                                      try-expand-dabbrev-all-buffers)))
    ;;(define-key unicomplete-map [(?D)] 'dabbrev-expand-string) ;Dynamic Abbreviation String. ToDo: Ask gnu.emacs.help.
    ;;(define-key unicomplete-map [(?D)] 'dabbrev-expand-partial) ;Dynamic Abbreviation Expand Partial (try-expand-dabbrev)
    (define-key unicomplete-map [(?D)] 'mdabbrev-expand) ;Mid Dabbrev Expand
    ;;(define-key unicomplete-map [(?n)] 'dabbrev-expand-number)   ;Expand Number

    (when (require 'pabbrev nil t)
      (define-key unicomplete-map [(?p)] 'pabbrev-expand-maybe)
      )

    (define-key unicomplete-map [(?f)] 'try-expand-complete-file-name)
    (define-key unicomplete-map [(?F)] 'try-expand-complete-file-name-partially)

    (define-key unicomplete-map [(?t)] (make-hippie-expand-function '(try-expand-tag))) ;tag
    (define-key unicomplete-map [(?y)] (make-hippie-expand-function '(yas/hippie-try-expand))) ;YASnippet
    (define-key unicomplete-map [(?l)] (make-hippie-expand-function '(try-expand-list))) ;List
    (define-key unicomplete-map [(?L)] (make-hippie-expand-function '(try-expand-list-all-buffers))) ;List all Buffers

    (define-key unicomplete-map [(? )] (make-hippie-expand-function '(try-expand-semantic-complete))) ;Semantic Complete

    ;; ToDo: Add these conditionally
    (define-key unicomplete-map [(?s)] 'complete-symbol-dwim) ;Symbol
    (define-key unicomplete-map [(?S)] (make-hippie-expand-function '(try-complete-lisp-symbol-partially))) ;Lisp Symbol
    ;;(define-key unicomplete-map [(?p)] (make-hippie-expand-function '(py-complete-try-complete-symbol))) ;Python Symbol

    (define-key unicomplete-map [(?k)] (make-hippie-expand-function '(try-expand-dabbrev-from-kill try-expand-whole-kill))) ;Kill Ring
    (define-key unicomplete-map [(?c)] (make-hippie-expand-function '(try-complete-with-calc-result))) ;Calculator Result

    (define-key unicomplete-map [(?a)] 'align-entire) ;Align (Complete Whitespace) (if transient-mark-mode is active)
    (define-key unicomplete-map [(?m)] 'apply-macro-to-region-lines) ;Apply macro (if transient mark mode is active)

    ;; TODO: Merge this into local complete-symbol table
    ;;(define-key unicomplete-map [(?o)] 'try-complete-OpenGL-symbol) ;OpenGL Symbol

    (define-key unicomplete-map [(left)] 'yas/prev-field-group)
    (define-key unicomplete-map [(right)] 'yas/next-field-group)

    ;; See: http://www.emacswiki.org/cgi-bin/wiki/HippieExpand#toc5
    (define-key unicomplete-map [(return)] 'hippie-expand)

    (define-key unicomplete-map [(? )] 'outline-cycle)
    )
  )

;;(global-set-key [(tab)] unicomplete-map)
;; ToDo: Define only for minibuffer-local-map to prevent rebinding of tab in info-mode.

(when nil
  (dolist (mode '(c-mode c++-mode objc-mode-hook java-mode-hook csharp-mode-hook
                         text-mode
                         lisp-mode emacs-lisp-mode
                         sh-mode shell-mode org-mode html-mode log-edit-mode
                         octave-mode matlab-mode
                         help-mode info-mode
                         makefile-mode autoconf-mode scons-mode
                         python-mode ruby-mode))
    (let* ((mode-name (symbol-name mode))
           (hook (intern (concat mode-name "-hook")))
           (map (intern (concat mode-name "-map")))
           (func `(lambda () (define-key ,map [(tab)] 'unicomplete-map))))
      (add-hook hook func)))

  (progn
    (add-hook 'makefile-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'autoconf-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))

    (add-hook 'lisp-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'emacs-lisp-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))

    (add-hook 'c-mode-common-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'fortran-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))

    (add-hook 'ada-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'octave-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'matlab-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))

    (add-hook 'python-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'scons-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'ruby-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))

    (add-hook 'sh-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'shell-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'org-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'html-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    (add-hook 'log-edit-mode-hook (lambda () (local-set-key [(tab)] 'unicomplete-map)))
    ))

(provide 'complete-dwim)
