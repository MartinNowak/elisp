;;; pgo-cedet.el --- setup CEDET Collection of Emacs Development Tools: Semantic, SemanticDB, EDE, stuff.
;; Author: Per Nordlöw

;;; http://alexott.net/en/writings/emacs-devenv/EmacsCedet.html

(defcustom cedet-dev nil "Flags that we should use CEDET trunk version instead of Emacs's own CEDET." :group 'cedet)
(defvar cedet-root-path (elsub "cedet") "CEDET Root Directory.")
(when cedet-dev
  (load-file (concat cedet-root-path "cedet-devel-load.el")))

(defun pnw-setup-cedet ()
  "Setup my CEDET Stuff."

  (let* ((lp 'load-path)
         (lispdir (expand-file-name "lisp" cedet-root-path))
         (append (not cedet-dev)))
    (when cedet-dev
      (load-file (expand-file-name "cedet-devel-load.el" cedet-root-path))
      (add-to-list 'load-path (expand-file-name "contrib/" cedet-root-path))
      (add-to-list  'Info-directory-list (expand-file-name "doc/info" cedet-root-path)))
    ;; (load-file-if-exist (expand-file-name "eieio/linemark.elc" lispdir)) ;needed by mlint
    )

  ;; NOTE: Must be set before Semantic/Senator load. TODO: Can we do this more elegantly?
  (setq-default senator-prefix-key [(control ?,)])
  (setq senator-prefix-key [(control ?,)])

  (semantic-mode 1)

  ;; Activate CEDET/Semantic Modes
  (when (fboundp 'global-semantic-idle-local-symbol-highlight-mode) (global-semantic-idle-local-symbol-highlight-mode 1))
  ;;(when (fboundp 'global-auto-highlight-symbol-mode) (global-auto-highlight-symbol-mode -1))

  ;; (when (fboundp 'global-semantic-show-parser-state-mode) (global-semantic-show-parser-state-mode 1))
  ;; ;; Errors as: with recursive load: (when (fboundp 'global-semantic-mru-bookmark-mode) (global-semantic-mru-bookmark-mode 1))
  (when (fboundp 'global-semantic-idle-scheduler-mode) (global-semantic-idle-scheduler-mode 1))
  (when (fboundp 'global-semantic-idle-summary-mode) (global-semantic-idle-summary-mode 1))
  (when (fboundp 'global-semantic-stickyfunc-mode) (global-semantic-stickyfunc-mode 1))
  (when (fboundp 'global-semantic-idle-completions-mode) (global-semantic-idle-completions-mode -1))
  (when (fboundp 'global-semantic-decoration-mode) (global-semantic-decoration-mode 1))
  (when (fboundp 'global-semantic-highlight-func-mode) (global-semantic-highlight-func-mode 1))
  (when (fboundp 'global-semantic-show-unmatched-syntax-mode) (global-semantic-show-unmatched-syntax-mode 1))
  (when (fboundp 'global-semantic-idle-breadcrumbs-mode) (global-semantic-idle-breadcrumbs-mode -1))
  (when (fboundp 'global-cedet-m3-minor-mode) (global-cedet-m3-minor-mode 1))
  (when (fboundp 'global-semantic-tag-folding-mode) (global-semantic-tag-folding-mode -1))

  ;;  (require 'semantic/bovine/c)
  (require 'semantic/ia)
  (require 'semantic/decorate/include)
  (require 'semantic/lex-spp)
  (require 'eassist nil t)

  ;; customisation of modes
  (defun alexott/cedet-hook ()
    ;; (local-set-key [(control return)] 'semantic-ia-complete-symbol-menu)
    ;; (global-set-key "\C-x\C-m" 'semantic-ia-complete-symbol-menu)
    ;; (local-set-key "\C-c?" 'semantic-ia-complete-symbol)
    ;; (local-set-key "\C-c>" 'semantic-complete-analyze-inline)
    ;; (local-set-key "\C-c=" 'semantic-decoration-include-visit)
    ;; (local-set-key "\C-cj" 'semantic-ia-fast-jump)
    ;; (local-set-key "\C-cq" 'semantic-ia-show-doc)
    ;; (local-set-key "\C-cs" 'semantic-ia-show-summary)
    ;; (local-set-key "\C-cp" 'semantic-analyze-proto-impl-toggle)
    (when (require 'semantic-tag-folding nil t)
      (local-set-key (kbd "C-c <left>") 'semantic-tag-folding-fold-block)
      (local-set-key (kbd "C-c <right>") 'semantic-tag-folding-show-block))
    ;;(add-to-list 'ac-sources 'ac-source-semantic)
    )
  ;; (add-hook 'semantic-init-hooks 'alexott/cedet-hook)
  (progn
    (add-hook 'c-mode-common-hook 'alexott/cedet-hook)
    (add-hook 'lisp-mode-hook 'alexott/cedet-hook)
    (add-hook 'scheme-mode-hook 'alexott/cedet-hook)
    (add-hook 'emacs-lisp-mode-hook 'alexott/cedet-hook)
    (add-hook 'erlang-mode-hook 'alexott/cedet-hook))

  (when nil
    (defun alexott/c-mode-cedet-hook ()
      (local-set-key "." 'semantic-complete-self-insert)
      (local-set-key ">" 'semantic-complete-self-insert)
      (local-set-key "\C-ce" 'eassist-list-methods)
      (local-set-key "\C-c\C-r" 'semantic-symref)
      (add-to-list 'ac-sources 'ac-source-etags)
      (add-to-list 'ac-sources 'ac-source-gtags)
      (setq ac-sources '(ac-source-semantic-raw))
      )
    (add-hook 'c-mode-common-hook 'alexott/c-mode-cedet-hook)
    )

  ;; SemanticDb
  (when (require 'semantic/db nil t)
    (require 'semantic/db-typecache nil t)
    (add-to-list 'semanticdb-project-roots "~/cognia")
    (add-to-list 'semanticdb-project-roots "~/FOI/HISP")
    (when (boundp 'semanticdb-default-save-directory)
      (setq semanticdb-default-save-directory "~/.emacs.d/semanticdb")
      (when (and semanticdb-default-save-directory
                 (file-directory-p semanticdb-default-save-directory))
        (make-directory semanticdb-default-save-directory t) ;; assure it exist (yet).
        (when (boundp 'semanticdb-default-file-name)
          (setq semanticdb-default-file-name ".semantic.cache")) ;Make it hidden.
        ))
    (global-semanticdb-minor-mode 1)
    (when nil
      ;; Force the search to find and read and tag files not yet in memory.
      (setq-mode-local c-mode semanticdb-find-default-throttle '(project unloaded system recursive))
      (setq-mode-local c++-mode semanticdb-find-default-throttle '(project unloaded system recursive))
      (setq-mode-local java-mode semanticdb-find-default-throttle '(project unloaded system recursive))
      (when (if cedet-dev (require 'semanticdb-global nil t) (require 'semantic/db-global nil t)) ;GNU GLOBAL Backend for SemanticDB
        (semanticdb-enable-gnu-global-databases 'c-mode)
        (semanticdb-enable-gnu-global-databases 'c++-mode)
        (semanticdb-enable-gnu-global-databases 'objc-mode)
        (semanticdb-enable-gnu-global-databases 'python-mode)
        )
      (when (require 'cedet-cscope nil t)
        (defalias 'cedet-cscope-expand-file-name 'cedet-cscope-expand-filename))
      ))
  ;; Clang
  (when (require 'semantic/bovine/clang nil t)
    ;; Use 'Clang' version 2.9 or later C/C++ completions
    ;; (when (boundp 'semantic-clang-binary)
    ;;   (setq semantic-clang-binary clang-command-name))
    (semantic-clang-activate)
    ;;(semantic-clang-deactivate)
    )
  ;; GCC. Test with (semantic-c-describe-environment)
  ;; If you want to direct the gcc setup system to use a different
  ;; version of gcc besides "gcc", you can do this in your .emacs
  ;; file: and it will initialize things so that the regular GCC
  ;; isn't used.
  (when (require 'semantic/bovine/gcc nil t)
    (semantic-gcc-setup))
  ;; Exuberant Ctags
  (when nil
    (when (and (fboundp 'cedet-ectag-version-check)
               (cedet-ectag-version-check t))
      (semantic-load-enable-primary-ectags-support)))
  ;; Java
  (require 'cedet-java nil t)
  (require 'semantic/db-javap nil t)
  ;; CPP Macro Preprocessor
  (when (require 'semantic/bovine/c nil t)
    (when (boundp 'semantic-c-takeover-hideif)
      (setq semantic-c-takeover-hideif t))) ;Let Semantic take over hideif. instead of (require 'pgo-hideif)
  ;; SRecode
  (when t
    (global-unset-key [(control ?/)])   ;remove globally
    (when (boundp 'undo-tree-map)
      (define-key undo-tree-map (kbd "C-/") nil)) ;remove locally
    (when (boundp 'srecode-prefix-key)
      (setq srecode-prefix-key [(control ?/)]))
    (when (require 'srecode nil t)
      (when (fboundp 'global-srecode-minor-mode) (global-srecode-minor-mode 1))
      (require 'srecode/mode nil t)
      ))
  ;; EDE
  (global-ede-mode -1)
  ;;(ede-enable-generic-projects)

  ;; NOTE: This used to not work, but does now!
  (progn
    (defun semantic-format-tag-prototype-colorized (tag &optional parent color)
      (semantic-format-tag-prototype tag parent t))
    (setq semantic-format-tag-custom-list
          (append '(radio)
                  (mapcar (lambda (f) (list 'const f))
                          semantic-format-tag-functions)
                  '(function)))
    (add-to-list 'semantic-format-tag-functions
                 'semantic-format-tag-prototype-colorized)
    (when (boundp 'semantic-ia-completion-format-tag-function)
      (setq semantic-ia-completion-format-tag-function 'semantic-format-tag-prototype-colorized)))
  )
(when nil
  (pnw-setup-cedet))

;; =============== Semantic Extensions ================================

(defun semantic-ia-show-summary-and-doc (&optional point)
  "Display a summary and code-level documentation for the symbol under POINT."
  (interactive "P")
  (let* ((ctxt (semantic-analyze-current-context point))
         (pf (when ctxt
               ;; The CTXT is an EIEIO object.  The below
               ;; method will attempt to pick the most interesting
               ;; tag associated with the current context.
               (semantic-analyze-interesting-tag ctxt)))
         (pf1 (reverse (oref ctxt prefix)))
         (c1 (car pf1))
         (doc
          ;; If pf1, the prefix is non-nil, then the last element is either
          ;; a string (incomplete type), or a semantic TAG.  If it is a TAG
          ;; then we should be able to find DOC for it.
          (cond
           ((stringp c1)
            ;; (message "Incomplete symbol name.")
            )
           ((semantic-tag-p c1)
            ;; The `semantic-documentation-for-tag' fcn is language
            ;; specific.  If it doesn't return what you expect, you may
            ;; need to implement something for your language.
            ;;
            ;; The default tries to find a comment in front of the tag
            ;; and then strings off comment prefixes.
            (semantic-documentation-for-tag c1)
            )
           (t
            (message "Unknown tag."))))
         )
    (if pf
        (message "%s%s"
                 (semantic-format-tag-summarize pf nil t)
                 (if (and doc
                          (not (string= doc "")))
                     (let ((pdoc (propertize doc 'face 'font-lock-comment-face)))
                       (if (string-match "\n" pdoc) ;if multi-line comment
                           (concat "\n" pdoc)
                         (concat " : " pdoc)))
                   ""))
      (message "No summary info availalble"))))

;; Complete and Show Summary
(defun semantic-ia-completing-read-symbol (point)
  "Complete the current symbol via `completing-read'.
Completion options are calculated with `semantic-analyze-possible-completions'."
  (interactive "d")
  (require 'imenu)
  (let* ((a (semantic-analyze-current-context point))
         (syms (semantic-analyze-possible-completions a))
         )
    ;; Complete this symbol.
    (if (not syms)
        (progn
          (message "No smart completions found.  Trying Senator.")
          (when (semantic-analyze-context-p a)
            ;; This is a quick way of getting a nice completion list
            ;; in the menu if the regular context mechanism fails.
            (senator-completion-menu-popup)))
      (let* ((menu
              (when (boundp 'semantic-ia-completion-menu-format-tag-function)
                (mapcar
                 (lambda (tag)
                   (cons
                    (funcall semantic-ia-completion-menu-format-tag-function tag)
                    (vector tag)))
                 syms)))
             (ans
              (if (= (length menu) 1)
                  (car menu)
                (assoc (completing-read "Complete symbol: " menu) menu))))
        (when ans
          (if (not (semantic-tag-p ans))
              (setq ans (aref (cdr ans) 0)))
          (delete-region (car (oref a bounds)) (cdr (oref a bounds)))
          (semantic-ia-insert-tag ans)

          ;; If tag is a function that takes no arguments move beyond function arguments.
          (when (and (semantic-tag-of-class-p ans 'function)
                     (null (semantic-tag-function-arguments ans)))
            ;; TODO: Do something!
            )
          ans)))))

(defun semantic-maybe-show-summary ()
  "Show summary of context if possible."
  (when (looking-back (concat "(" L*))
    (insert ")")
    (backward-sexp)
    (semantic-ia-show-summary (point))
    (down-list)))

(defun semantic-ia-complete-symbol-and-maybe-show-summary (&optional pos)
  "Complete and show summary."
  (interactive "d")
  (prog1 (semantic-ia-complete-symbol pos)
    (semantic-maybe-show-summary)))

(defun semantic-ia-completing-read-symbol-and-maybe-show-summary (&optional pos)
  "Complete and show summary."
  (interactive "d")
  (prog1 (semantic-ia-completing-read-symbol pos)
    (semantic-maybe-show-summary)))

;;; Semantic Library Paths
;;; http://www.emacswiki.org/emacs/SemanticLibraryParsing
(when nil
  (require 'semantic-fftw nil t)                          ;FFTW
  (require 'semantic-boost nil t)                         ;Boost C++
  (require 'semantic-wxwidgets nil t)                     ;wxWidgets
  (require 'semantic-glib-gtk nil t)                      ;Glib/GTK
  (require 'semantic-opencv nil t)                        ;OpenCV 1/2
  (require 'semantic-qt4 nil t)                           ;Qt4
  (when (and nil (file-directory-p "/usr/include/qt4")) ;Qt
    (add-to-list 'auto-mode-alist '("/usr/include/qt4" . c++-mode))
    (semantic-add-system-include "/usr/include/qt4" 'c++-mode)
    (when (boundp 'semantic-lex-c-preprocessor-symbol-file)
      (add-to-list 'semantic-lex-c-preprocessor-symbol-file "/usr/include/qt4/Qt/qconfig.h")
      (add-to-list 'semantic-lex-c-preprocessor-symbol-file "/usr/include/qt4/Qt/qconfig.h")
      ;; Qt is using some preprocessor symbols in its class definitions. You need to set them manually via
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("Q_GUI_EXPORT" . ""))
      (add-to-list 'semantic-lex-c-preprocessor-symbol-map '("Q_CORE_EXPORT" . ""))
      )))

(when nil
  (when (y-or-n-p-with-timeout "Load CEDET Extra?" 1 nil)

    ;; ================= Semantic IMenu =================
    (when nil
      (when (if cedet-dev (require 'semantic-imenu nil t) (require 'semantic/imenu nil t))
        ;;(defun pnw/semantic-hook () (imenu-add-to-menubar "TAGS"))
        (setq semantic-imenu-auto-rebuild-directory-indexes nil)
        (add-hook 'semantic-init-hook 'pnw/semantic-hook)
        ;; Make semantic default back to imenu's create function.
        ;;(defalias 'semantic-create-imenu-index 'imenu-default-create-index-function)
        ))

    ;; ================= EDE =================
    (when (require 'ede nil t)
      (when nil
        (global-ede-mode 1)
        (when (fboundp 'ede-enable-generic-projects)
          (ede-enable-generic-projects))
        (add-hook 'dired-mode-hook 'ede-dired-minor-mode)) ;Activate "Project" menu in dired-mode
      (defun ede-choose-configuration ()
        "Choose configuration for current project."
        (interactive)
        (let ((obj (when (boundp 'ede-object-root-project)
                     ede-object-root-project)))
          (if (null obj)
              (message "No current project.")
            (oset obj configuration-default
                  (completing-read (format "Configuration (current: '%s'): "
                                           (oref obj configuration-default))
                                   (oref obj configurations) nil t)))))
      )


    ;; CEDET Changelog Auto Creation from CVS Log
    ;; NOTE: Used to Generate Error: (error "Failed to find version for newly installed cogre")
    (when nil (require 'cedet-update-changelog nil t))

    ;; ================= EmacsAssist =================
    ;; C/C++/Java/Python method/function navigator.  Contains some useful
    ;; functions features for C/C++ developers similar to those from VisualAssist.
    ;; Remember that convenient M-o, M-g and M-m?
    (when (require 'eassist nil t)
      ;;(define-key c-mode-base-map [(control x) (t)] 'eassist-switch-h-cpp) ;override toggle-source()
      ;;(define-key c-mode-base-map (kbd "M-m") 'eassist-list-methods))
      ;; I've put a new analyzer library together to try and solve this
      ;; problem. I added a very simple user interface to with the
      ;; command `semantic-analyze-proto-impl-toggle'.  Bind this to a
      ;; key, and press it to jump between a prototype and its
      ;; implementation.
      ;;
      ;; It works ok in my test directories, but I haven't had much
      ;; opportunity to test it beyond that.  If it doesn't work the
      ;; first time, you may need to try
      ;; `semanticdb-dump-all-table-summary' and make sure the right
      ;; directories and tables had been loaded.  The idle work tasks
      ;; should automatically pick up all the files needed, but it
      ;; depends on the breadth of your project.
      (defalias 'semantic-analyze-interface-impl-toggle 'semantic-analyze-proto-impl-toggle)
      (defalias 'semantic-analyze-header-source-toggle 'semantic-analyze-proto-impl-toggle)
      ;; TODO: http://groups.google.se/group/gnu.emacs.help/browse_thread/thread/3ac6b30e2cea24a5#
      )

    ))
(when nil
  (when (if cedet-dev (require 'senator nil t) (require 'semantic/senator nil t))
    (progn
      (add-hook 'isearch-mode-hook     'senator-isearch-mode-hook)
      (add-hook 'isearch-mode-end-hook 'senator-isearch-mode-hook)
      (define-key isearch-mode-map [(control ?,)] 'senator-isearch-toggle-semantic-mode))

    (defun senator-tweaks ()
      (when (boundp 'senator-minor-mode-name)
        (setq senator-minor-mode-name "SN")) ;More Compact mode-line
      (when (boundp 'senator-prefix-map)
        (when (require 'repeatable nil t)
          (repeatable-substitute-binding 'senator-complete-symbol senator-prefix-map)) ;TODO: This doesn't work because TAB is already bound?
        (progn                          ;harmonizes with M-.
          (define-key senator-prefix-map "." 'semantic-ia-fast-jump)
          (define-key c-mode-map [(control ?.)] 'semantic-ia-fast-jump)
          (define-key c++-mode-map [(control ?.)] 'semantic-ia-fast-jump)
          (define-key prog-mode-map [(control ?.)] 'semantic-ia-fast-jump)
          (define-key emacs-lisp-mode-map [(control ?.)] 'semantic-ia-fast-jump)
          (add-hook 'python-mode-hook (lambda () (local-set-key [(control ?.)] 'semantic-ia-fast-jump)))
          (add-hook 'ruby-mode-hook (lambda () (local-set-key [(control ?.)] 'semantic-ia-fast-jump)))
          (add-hook 'haskell-mode-hook (lambda () (local-set-key [(control ?.)] 'semantic-ia-fast-jump)))
          )
        (define-key senator-prefix-map "s" (if (fboundp 'semantic-ia-show-summary-and-doc)
                                               'semantic-ia-show-summary-and-doc
                                             'semantic-ia-show-summary))
        (define-key senator-prefix-map "d" 'semantic-ia-show-doc)
        (when (fboundp 'semantic-ia-show-help)
          (define-key senator-prefix-map "h" 'semantic-ia-show-help))
        (define-key senator-prefix-map "c" 'semantic-ia-describe-class)
        (define-key senator-prefix-map "v" 'semantic-ia-show-variants)
        (define-key senator-prefix-map [(return)] 'semantic-ia-complete-symbol)
        (define-key senator-prefix-map [(control return)] 'semantic-ia-complete-symbol-menu)
        (define-key senator-prefix-map ">" 'semantic-complete-analyze-inline)
        (define-key senator-prefix-map "=" 'semantic-decoration-include-visit)

        (define-key senator-prefix-map [(control ?p)] 'senator-previous-tag)
        (define-key senator-prefix-map [(control ?n)] 'senator-next-tag)
        ))

    (add-hook 'senator-minor-mode-hook 'senator-tweaks t)

    ;; 'semantic-ia-complete-tip
    ;; NOTE: Why isn't `push-tag-mark' defined?
    ;; TODO: Skip pushing mark if advicee fails (use `around' advice instead).
    (defadvice semantic-ia-fast-jump (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'semantic-ia-fast-jump)
    (defadvice semantic-complete-jump-local (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'semantic-complete-jump-local)
    (defadvice semantic-complete-jump (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'semantic-complete-jump)
    (defadvice senator-go-to-tag (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'senator-go-to-tag)
    (defadvice senator-go-to-up-reference (before push-mark-advice activate compile)
      "Reference current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'senator-go-to-up-reference)
    (defadvice senator-jump (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'senator-jump)
    (defadvice imenu (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'imenu)
    (defadvice cscope-call (before push-mark-advice activate compile)
      "Remember current buffer position.
Use \\[pop-tag-mark] to go back."
      (ring-insert find-tag-marker-ring (point-marker)))
    (ad-activate 'cscope-call)
    (when (require 'repeatable nil t)
      (add-hook 'senator-minor-mode-hook
                (lambda ()
                  (when (fboundp 'senator-previous-tag) (repeatable-command-advice senator-previous-tag))
                  (when (fboundp 'senator-next-tag) (repeatable-command-advice senator-next-tag))
                  (when (fboundp 'senator-go-to-up-reference) (repeatable-command-advice senator-go-to-up-reference))))
      )
    (when (fboundp 'global-senator-minor-mode)
      (global-senator-minor-mode 1))    ;Enable Senator
    ))

;;; NOTE: Disabled stuff follows
(when nil

  ;; pulse is currently part of cedet.
  (when pnw/use-pulse
    (pulse-toggle-integration-advice +1) ;; Note: Deactivated because it is buggy!

    ;; We could also got via add-hook
    (remove-hook 'find-tag-hook
                 (lambda ()
                   (when (and pulse-command-advice-flag (interactive-p))
                     (pulse-momentary-highlight-one-line (point)))))
    )

  (when (if cedet-dev (require 'semantic-lex nil t) (require 'semantic/lex nil t))
    )

  (require 'cedet-compat nil t)
  ;; (defalias 'cedet-split-string 'split-string)

  ;; SemanticDB
  (when (and pnw/use-semanticdb
             (if cedet-dev (require 'semanticdb nil t) (require 'semantic/db nil t)))

    ;; WARNING: Override to skip warnings!
    (defun semantic-ectag-test-version ()
      "Make sure the version of ctags we have is up to date."
      t)

    ;; "Exuberant CTags" Backend for SemanticDB
    ;; The parsing engine appears in the cedet/semantic/ctags directory.
    ;; When enabled, it works by using ctags to parse files not in an Emacs
    ;; buffer, and it uses the Emacs parser once a file is loaded into a
    ;; buffer.  Ctags is a very fast parser, so offloading this parsing step
    ;; makes initial parsing of a project very fast.
    (when nil
      (when (if cedet-dev (require 'semantic-ectag-parse nil t) (require 'semantic/ectag-parse nil t))
        ;;(semantic-load-enable-all-exuberent-ctags-support)
        (semantic-load-enable-secondary-exuberent-ctags-support) ;Important: Enable only for verified languages, currently C and Emacs-Lisp.
        (defcustom semantic-ectag-program "ctags-exuberant"
          "The Exuberent Ctags program to use."
          :group 'semantic
          :type 'file)
        ))


    )

  (when (and
         (require 'semantic-tag-folding nil t)) ;semantic decoration style to enable folding of semantic tags
    (when (fboundp 'global-semantic-tag-folding-mode)
      (global-semantic-tag-folding-mode 1))) ;source code folding

  (if cedet-dev (require 'semantic-ctxt nil t) (require 'semantic/ctxt nil t))
  (if cedet-dev (require 'semantic-format nil t) (require 'semantic/format nil t))
  (if cedet-dev (require 'semantic-edit nil t) (require 'semantic/edit nil t))

  ;; Semantic Symref
  (when (if cedet-dev (require 'semantic-symref-list nil t) (require 'semantic/symref/list nil t))
    (defun semantic-symref-list-query-call-macro-on-open-hits ()
      "Call the most recently created keyboard macro on each hit.
Cursor is placed at the beginning of the symbol found, even if
there is more than one symbol on the current line.  The
previously recorded macro is then executed."
      (interactive)
      (save-window-excursion
        (let* ((last-choice nil)
               (call-count 0)
               (total-count (semantic-symref-list-map-open-hits
                             (lambda ()
                               (switch-to-buffer (current-buffer) t)
                               (when (or (memq last-choice '(?! ?q)) ;loop-short-circuiters
                                         (progn
                                           (pulse-momentary-highlight-one-line (point)) ;highlight current line
                                           (setq last-choice (read-char-spec
                                                              "Call macro at point? "
                                                              '((?y ?y "Apply macro on current hit")
                                                                (?n nil "Skip current hit")
                                                                (?! ?! "Apply on all the remaining hits")
                                                                (?q ?q "Skip all the remaining hits"))))))
                                 (when (memq last-choice '(?! ?y)) ;approving chars
                                   (setq call-count (1+ call-count))
                                   (kmacro-call-macro nil t)))))))
          (semantic-symref-list-update-open-hits)
          (message "Executed Macro %d out of %d possible times." call-count total-count))))
    (define-key semantic-symref-results-mode-map "e" 'semantic-symref-list-query-call-macro-on-open-hits)
    )

  (require 'bovine-grammar nil t)
  (require 'cedet-build nil t)          ;Builds CEDET from within Emacs.

  ;; Uncomment next line to have "." start autocompletion in C++ mode
  (when nil
    (define-key c-mode-map "." 'semantic-complete-self-insert)
    ;;ToDo: Check that a '-' comes prefixes '> using thing-at-point().
    (define-key c-mode-map ">" 'semantic-complete-self-insert)
    )

  (if cedet-dev (require 'semantic-el nil t) (require 'semantic/bovine/el nil t)) ;emacs-lisp
  (if cedet-dev (require 'semantic-make nil t) (require 'semantic/bovine/make nil t)) ;makefile
  (if cedet-dev (require 'semantic-util-modes nil t) (require 'semantic/util-modes nil t)) ;utils

  ;; Hints for Semantic to Parse C/C++ Library Headers
  ;; See: http://www.emacswiki.org/emacs-en/SemanticLibraryParsing
  (when (and (if cedet-dev (require 'semantic-dep nil t) (require 'semantic/dep nil t))
             (if cedet-dev (require 'semantic-c nil t) (require 'semantic/bovine/c nil t)))
    (if cedet-dev (require 'semantic-lex-spp nil t) (require 'semantic/lex-spp nil t))
    )

  ;; lmcompile.el/linemark.el. ToDo: Merge with fringe?
  (when (and nil
             (require 'lmcompile nil t)) ;TODO: Disabled because of errors.
    (add-hook 'compilation-finish-functions 'compilation-finish-highlight-linemarks)
    (defun compilation-finish-highlight-linemarks (buffer result-str)
      (interactive)
      (lmcompile-do-highlight))
    )


  ;; Toggle Source
  ;; Toggle between C/C++ source and header files in current directory.
  (load-file-if-exist (elsub "sourcepair.elc"))
  ;; toggle-source.el --- Toggle between source and implementation files.
  (when (require 'toggle-source nil t)
    )
  ;; switch-file.el --- switch from one file to another.
  (when (require 'switch-file nil t)
    )

  ;; EDE
  (when pnw/use-ede
    (when (require 'ede nil t)

      ;; You can wrap your C++ project in a simple EDE wrapper.  See the
      ;; ede-cpp-root project type in either the CEDET general documentation,
      ;; the ede documentation, or in ede-cpp-root.el comments itself.  You
      ;; probably want to do something like this:
      (when nil

        ;; (ede-cpp-root-project "NAME" :file "FILENAME"
        ;;     :include-path '( "/include" "../include" "/c/include" )
        ;;     :system-include-path '( "/usr/include/c++/3.2.2/" )
        ;;     :spp-table '( ("MOOSE" . "")
        ;;                   ("CONST" . "const") ) )
        (ede-cpp-root-project "OpenCog"
                              :name "OpenCog Project"
                              :file "~/OpenCog/opencog/CMakeLists.txt"
                              :include-path '("/")
                              :system-include-path '("/usr/include/"
                                                     "/usr/include/c++/4.4")
                              ;;:spp-table '(("isUnix" . "")
                              ;;("BOOST_TEST_DYN_LINK" . ""))

                              ;; where FILENAME is something like /dir/to/my/project/CMakefile
                              ;; or some other file at the root of your project.

                              ;; This is probably the best way to apply include paths, extra CPP macros
                              ;; you need, and system include paths there is for C++.  It wraps
                              ;; everything up in a simple way.

                              ;; If you feel particularly brave, you can create a new EDE project type
                              ;; for CMake.

                              ;; The system include path is used for <include.h> type includes, not
                              ;; "include.h" type includes.
                              ))))


  ;; Datastructure Debugger
  ;; See: http://www.emacswiki.org/emacs-en/DataDebug
  ;; In order words prettier output of eval-expression.
  (when (require 'data-debug nil t)
    ;; In the data-debug buffer, using SPC will expand or contract a
    ;; line so you can move navigate down through complex structures
    ;; without worrying about recursion, or looking at parts of the
    ;; structure you don’t care about.
    (global-set-key [(meta ?:)] 'eval-expression) ;internal view
    ;;(global-set-key [(meta ?:)] 'data-debug-eval-expression) ;internal view
    (global-set-key [(control meta ?:)] 'icicle-pp-eval-expression) ;easier read view
    )

  ;; Semantic Speedbar
  (when (if cedet-dev (require 'semantic-sb nil t) (require 'semantic/sb nil t))
    ;; Bring speedbar up, and put it into Class Browser mode.
    ;; The structure of the class hierarchy can then be navigated
    ;; using traditional speedbar interactions.

    ;;(semantic-cb-speedbar-mode)
    ;;(semantic-speedbar-analysis)

    ;; full Function signatures on single line in speedbar?
    ;; You can customize `semantic-sb-button-format-tag-function
    ;; any of the semantic tag formatting functions

    ;; It is possible to change `speedbar-key-map', or
    ;; `speedbar-file-key-map' to be whatever you like.
    )

  ;; (setq semanticdb-default-file-name "semantic.cache")
  ;; Got this from the follwing Mailing List Thread:
  ;; See: http://sourceforge.net/mailarchive/forum.php?thread_name=d0e2f05e0706211727k4d0611b3j3892b1142e2c0900%40mail.gmail.com&forum_name=cedet-semantic
  ;; If you want to give it a try, update
  ;; `semantic--format-tag-arguments' to allow for full type info.
  ;; Arguments from various languages could be strings, lists of
  ;; who-knows-what, or tags, so it can be a bit
  ;; tricky. ;)
  (when nil
    (defun semantic--format-tag-arguments (args formatter color)
      "Format the argument list ARGS with FORMATTER.
FORMATTER is a function used to format a tag.
COLOR specifies if color should be used."
      (let ((out nil))
        (while args
          (push (if (semantic-tag-p (car args))
                    (unless (equal (semantic-tag-type (car args))
                                   "void")
                      (semantic-format-tag-prototype (car args)
                                                     nil color))
                  (semantic-format-tag-name-from-anything
                   (car args) nil color 'variable))
                out)
          (setq args (cdr args)))
        (mapconcat 'identity (nreverse out)
                   semantic-function-argument-separator)
        ))
    )
  (defun pnw-semantic-ia-find-definition (arg)
    "Jump to the definition of the symbol, type or function at point.
  With prefix arg, find in other window."
    (interactive "P")
    (let* ((tag (or (semantic-idle-summary-current-symbol-info-context)
                    (semantic-idle-summary-current-symbol-info-brutish)
                    (error "No known tag at point")))
           (pos (or (semantic-tag-start tag)
                    (error "Tag definition not found")))
           (file (semantic-tag-file-name tag)))
      (if file
          (if arg (find-file-other-window file) (find-file file))
        (if arg (switch-to-buffer-other-window (current-buffer))))
      (push-mark)
      (goto-char pos)
      (end-of-line))
    )
  )

(provide 'pgo-cedet)
