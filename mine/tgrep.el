;;; tgrep.el --- Tree Grep and Locate Fancyfied.
;; Author: Per Nordlöw
;; todo: Support git grep

(require 'multi-read)
(require 'combinations)
(require 'lex-utils)
(require 'relex)
(require 'grep)
(require 'case-utils)
(require 'path-utils)

(defvar tgrep-exclusion-list
      (append vc-directory-exclusion-list '(".VirtualBox" ".arch-ids"))
      "Directories to exclude/ignore when scanning files recursively.")

;; TODO: Auto-add all `filedb' patterns with `name-recog'.
(defun tgrep-get-exclude-string ()
  "Argument string to grep that exludes/ignore stuff that we normally
  don't want to include in search."
      (concat

       ;; Reuse Emacs's own `vc-directory-exclusion-list'.
       (mapconcat
        (lambda (s) (concat "--exclude-dir=\"" s "\" "))
        (append vc-directory-exclusion-list '(".wact")) "")

       "--exclude-dir=\".trash\" "
       "--exclude-dir=\".Trashes\" "
       "--exclude-dir=\"._.Trashes\" "
       "--exclude-dir=\"thumbs.db\" "
       "--exclude-dir=\".DS_Store\" "
       "--exclude-dir=\".VirtualBox\" "
       "--exclude-dir=\"lost+found\" "
       "--exclude-dir=\"System Volume Information\" "

       "--exclude-dir=\".deps\" "
       "--exclude-dir=\".backups\" "
       "--exclude-dir=\"autom4te.cache\" "

       "--exclude=\"*~\" "		;skip backup-files
       "--exclude=\"#.*\" "		;skip Emacs backup-files
       "--exclude=\"\.#.*\" "		;skip Emacs backup-files

       "--exclude=\"*\.cdeps\" "    ;skip my C-source dependency files
       "--exclude=\"*\.cppdeps\" " ;skip my C++-source dependency files

       "--exclude=\"*\.c.deps\" "    ;skip my C-source dependency files
       "--exclude=\"*\.cpp.deps\" "    ;skip my C-source dependency files

       "--exclude=\"*\.elc\" "		;Emacs-Lisp Compiled
       "--exclude=\"*\.pyc\" "		;Python Compiled

       "--exclude=\"*\.elf\" "		;skip object files
       "--exclude=\"*\.o\" "		;skip object files
       "--exclude=\"*\.ko\" "		;skip kernel object files
       "--exclude=\"*\.so\" "		;shared object files
       "--exclude=\"*\.Po\" "		;autotools dependency file
       "--exclude=\"*\.pdf\" "		;PDF
       "--exclude=\"*\.ali\" "		;Ada Library File

       "--exclude=\"lib*\.a\" "		;skip archive files
       "--exclude=\"#*#\" "		;skip Emacs backup-files

       "--exclude=\"tags\" "		;by ctags (Vi tags)
       "--exclude=\"TAGS\" "		;by etags (Emacs tags)
       "--exclude=\"GTAGS\" "		;GNU GLOBAL
       "--exclude=\"GRTAGS\" "		;GNU GLOBAL
       "--exclude=\"GPATH\" "		;GNU GLOBAL
       "--exclude=\"GSYMS\" "		;GNU GLOBAL
       "--exclude=\"BROWSE\" "		;by ebrowse (Emacs)
       "--exclude=\"ID\" "		;idutils

       "--exclude=\"Makefile.in\" "     ;Makefile.in
       "--exclude=\"*semantic\.cache\" "
       "--exclude=\"config\.log\" "
       "--exclude=\"*\.svn-base\" "	;Subversion Locals

       "--exclude=\"doxygen-error-log\.txt\" "	;Doxygen Error Log
       ))

;;Test replace for quoting "-symbols
;; (replace-regexp-in-string "\"" "\\\\\"" "\"")

(defvar tgrep-flags-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'tgrep-flags-history t))

;; TODO: Replace this with fmd structures and members
(setq grep-language-syntax-modes
  '(
    ("Text" . text-mode)
    ("C" . c-mode)
    ("C++" . c++-mode)
    ("Java" . java-mode)
    ("Shell" . sh-mode)
    ("Python" . python-mode)
    ("Ruby" . ruby-mode)
    ("Lisp" . lisp-mode)
    ("Emacs-Lisp" . emacs-lisp-mode)
    ("Matlab" . matlab-mode)
    ("Octave" . octave-mode)
    ))
;; Use: (rassoc 'c-mode grep-language-syntax-modes)

(add-to-list 'grep-files-aliases
             (cons "chpp" "*.[ch]pp"))

(defvar tgrep-directory nil)
(make-variable-buffer-local 'tgrep-directory)

(defvar tgrep-input-string nil
  "Last tgrep input string (or string regexp).")
(make-variable-buffer-local 'tgrep-input-string)

(defvar tgrep-command nil
  "Last tgrep command.")
(make-variable-buffer-local 'tgrep-command)

(make-variable-buffer-local 'compilation-buffer-name-function)

(defun tgrep-read-keys (regexp-flag &optional multi-flag)
  "Read keys to search for in grep."
  )

;; Emacs to Grep Regexp Conversion
;; - Basic    Regexp:   Quote:        ?, +   =>   \?, \+
;; - Extended Regexp: Unquote:
(defun tgrep-any (regexp-flag &optional multi-flag)
  "Search files recursively using grep.
REGEXP-FLAG is non-nil if we should grep for a regular
expression. If REGEXP-FLAG is set to `extended' pass an Extended
Regular Expression to grep. if MULTI-FLAG is 'all or 'some. If
any of the searched expression contains an uppercase character
perform a case-sensitive search otherwise perform a
case-insensitive search (mimicing the behaviour of Emacs Search
and Replace)."
  (let* ((case-fold-flag t)
         (suppress-flag t)
         (symbol-flag nil)
         (thing (if (use-region-p)
                    (buffer-substring-no-properties
                     (region-beginning)
                     (region-end))
                  (let ((sym (ignore-errors (and (require 'semantic-ctxt nil t)
                                                 (semantic-ctxt-current-symbol)))))
                    (if sym
                        (mapconcat 'identity sym "::")
                      (or (when (fboundp 'symbol-name-next-to-point)
                            (setq symbol-flag t)
                            (symbol-name-next-to-point))
                          (when (and (require 'thingatpt+ nil t)
                                     (fboundp 'symbol-name-at-point))
                            (setq symbol-flag t)
                            (symbol-name-at-point)))))))
         (history (if regexp-flag grep-regexp-history grep-history)))
    (let ((patt
           (if multi-flag
               (let* ((keys (multi-read-thing (format "Search for %s %s"
                                                      (faze (if regexp-flag "regexp" "string") 'type)
                                                      (when thing (concat "(default \""
                                                                          (if (get-text-property 0 'face thing) ;already propertized
                                                                              thing ;use that
                                                                            (faze thing 'string) ;otherwise add new
                                                                            )
                                                                          "\")")))
                                              (if regexp-flag 'regexp 'string)
                                              t))) ;temporary list
                 (setq case-fold-flag (downcased-p keys))
                 (if (> (length keys) 1)
                     (if regexp-flag
                         (progn (setq regexp-flag 'extended)
                                (string-list-to-regexp keys regexp-flag nil 'posix))
                       (mapconcat 'identity keys "\n"))
                   (car keys)))
             (read-string
              (concat "Search for "
                      (faze (if regexp-flag "regexp" "string") 'type)
                      (when thing (concat " (default \"" (faze thing 'string) "\")"))
                      ": ")
              nil history)
             )))
      (let* ((patt (if (and patt (not (equal patt ""))) patt thing))
             (npatt patt))
	(if npatt
	    (let* ((dir (read-directory-name "Starting at: "))
                   (glob (read-string "Files (wildcard) to search in (default is any file): "))
                   (ws-relax-flag (if (y-or-n-p-defaults "Relax whitespace? ")
                                      'space
                                    nil))
                   (major-mode-string (car (rassoc major-mode grep-language-syntax-modes))) ;try to lookup major-mode description. TODO: Reuse fmd or some other structure here!
                   (mode (cdr (assoc (completing-read (format "Syntax Language (default %s): "
                                                              (faze (if major-mode-string major-mode-string "C") 'type)) ;default to C syntax
                                                      grep-language-syntax-modes nil t nil nil
                                                      major-mode-string)
                                     grep-language-syntax-modes)))
                   (flags (read-from-minibuffer
                           (concat "Search for \"" npatt "\" with grep flags: ")
                           nil nil nil 'tgrep-flags-history)))

              ;; make double-quotes work for greps regexp syntax
              (setq npatt (replace-regexp-in-string "\"" "\\\\\"" npatt))

              ;; handle relaxing of whitespace
              (when ws-relax-flag

                (when regexp-flag
                  (setq ws-relax-flag 'space)) ;if regexp are not yet parsed to to default to `space'

                (if (eq ws-relax-flag 'lex)
                    (setq npatt (relax-lexical-whitespace-in-string npatt mode t 'grep))
                  ;; we force regexp grep so we first need to quote user input
                  (if (not regexp-flag) (setq npatt (regexp-quote npatt)))
                  (setq npatt (relax-whitespace-in-string npatt t))
                  )
                (setq regexp-flag 'extended) ;for this we need extended regular expressions
                )

              (unless (string-regexp-p npatt) ;if string contains no regexp special characters
                (setq regexp-flag nil))       ;dont' treat it as such

              (setq symbol-flag
                    (string-equal "Symbol"
                     (completing-read "Context as: " '("Any" "Symbol")
                                      nil nil nil nil
                                      (if symbol-flag
                                          "Symbol"
                                        "Any"))))

              (when symbol-flag
                (setq regexp-flag t))

              (case regexp-flag
                ('extended
                 ;; in grep extended regexp ? and + must be backquoted
                 ;;(setq npatt (replace-regexp-in-string "\\([+?]\\)" "\\\\\\1" npatt))
                 )
                (t
                 ;; TODO: Handle this case
                 )
                )

              ;; perform grep
              (let ((command (concat
                              "grep -n -R " ;display line numbers and run recursively
                              (when suppress-flag "-s ") ;Suppress error messages about nonexistent or unreadable files. See: man:grep for details.
                              (when case-fold-flag "-i ")
                              (tgrep-get-exclude-string) " "
                              flags " "
                              (if regexp-flag (case regexp-flag
                                                ('extended "-E ") ;extended regexp
                                                ('t "-e ")        ;basic regexp
                                                )
                                "-F ")  ;fixed string(s)
                              "\""
                              (if symbol-flag
                                  (concat "\\<" npatt "\\>")
                                npatt)
                              "\" "
                              "." ;compacter representation: (file-relative-name dir)
                              (if (and glob
                                       (not (equal glob "")))
                                  (concat " --include=" glob)))
                             )
                    (buffer-name-function
                     `(lambda (mode)
                        (concat "*" (downcase mode) ":" ,patt "@" ,dir "*"))))

                (let ((compilation-buffer-name-function buffer-name-function) ;change it temporary
                      (default-directory dir))
                  (grep command))       ;during this grep

                (with-current-buffer grep-last-buffer ;in last grep buffer
                  (setq )
                  (setq-default tgrep-input-string patt) ;store input globally
                  (setq-default tgrep-command command)   ;store command globally
                  (setq-default tgrep-directory compilation-directory) ;store directory globally
                  (setq tgrep-input-string patt) ;store input
                  (setq tgrep-command command)   ;store command locally
                  (setq tgrep-directory compilation-directory) ;store directory locally

                  (setq compilation-buffer-name-function buffer-name-function) ;store buffer-name-function
                  )
                ))
          (message "No input to grep for was given")
          )))))

(defun tgrep-string ()
  "Search files recursively for an exact string using GNU Grep."
  (interactive)
  (tgrep-any nil t))

(defun tgrep-regexp ()
  "Search files recursively for a regexp using GNU Grep."
  (interactive)
  (tgrep-any 'extended t))

(defun tgrep-repeat ()
  "Repeat last GNU Grep using local variables."
  (interactive)
  (let ((last-buffer (or (next-error-find-buffer)
                         grep-last-buffer)))
    (if last-buffer
        (with-current-buffer last-buffer
          (let ((compilation-buffer-name-function
                 `(lambda (mode)
                    (concat "*" (downcase mode)
                            ":" ,tgrep-input-string ;use last input
                            "@" (or tgrep-directory ;use last directory
                                    compilation-directory) "*")))
                (command tgrep-command))
            (when command
              (grep command))))
      (message "Could not find a previous grep buffer!")
      (ding))))

(global-set-key [(control c) (g)]      'tgrep-string)
(global-set-key [(control c) (meta g)] 'tgrep-regexp)
(global-set-key [(control c) (G)]      'tgrep-repeat)

(defvar tlocate-flags-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'tlocate-flags-history t))

(defun tlocate-action ()
  (interactive)
  (let ((file (ffap-file-at-point)))
    (when file
      (find-file-other-window
       file))))

(defun tlocate-add-font-locking (patt regexp-flag)
  (font-lock-add-keywords
   nil
   (list
    (cons (concat "\\(" patt "\\)")
          '(1 'font-lock-warning-face t))
    ))
  (when (and (append-to-load-path (elsub "button-lock"))
             (require 'button-lock nil t))
    (setq buffer-read-only t)
    (button-lock-mode t)
    (setq url-button
          (button-lock-set-button "^/.*$"
                                  'tlocate-action
                                  :face 'link
                                  :face-policy 'prepend))
    ;; (set (make-local-variable 'font-lock-defaults)
    ;;      ;; Two levels.  Use 3-element list, since it is standard to have one more
    ;;      ;; than the number of levels.  This is necessary for it to work with
    ;;      ;; `font(-lock)-menus.el'.
    ;;      '((dired-font-lock-keywords
    ;;         dired-font-lock-keywords
    ;;         diredp-font-lock-keywords-1)
    ;;        t nil nil beginning-of-line))
    ;; Refresh `font-lock-keywords' from `font-lock-defaults'
    (when (fboundp 'font-lock-refresh-defaults) (font-lock-refresh-defaults))
    ))

(defun tlocate-any (regexp-flag)
  "Find files using locate. REGEXP-FLAG is set if we should locate a regular expression. "
  (let ((case-fold-flag t)
        (thing (if (use-region-p)
                   (buffer-substring-no-properties
                    (region-beginning)
                    (region-end))
                 (thing-at-point 'symbol))))
    (let* ((patt (read-from-minibuffer
                  (concat "Locate "
                          (if regexp-flag "regexp" "string")
                          (when thing (concat " (default \"" thing "\")"))
                          ": ")))
           (npatt (if (and patt (not (equal patt ""))) patt thing)))
      (when (not (downcased-p patt)) ;if any symbol contains upper case characters
        (setq case-fold-flag nil)) ;we default to case-sensitive search
      (if npatt
          (let ((flags (read-from-minibuffer
                        (concat "Locate " npatt " with flags: ")
                        nil nil nil
                        'tlocate-flags-history))
                (q-patt (replace-regexp-in-string "\"" "\\\\\"" npatt)))
            (require 'background)
            (deactivate-mark)
            (background (concat
                         "locate -e "
                         (when case-fold-flag "-i ")
                         (if regexp-flag "-r ")
                         flags " "
                         "\"" q-patt "\""))
            (balance-windows)
            (other-window 1)
            (tlocate-add-font-locking npatt regexp-flag)
            )
        (message "No input to locate was given")
        ))))

(defun tlocate-string ()
  "Search files recursively for a string using grep."
  (interactive)
  (tlocate-any nil)
  )

(defun tlocate-regexp ()
  "Search files recursively for a regexp using grep."
  (interactive)
  (tlocate-any t)
  )

(defun xsteve-locate (search-string)
  "Run locate, but delete meta directories from svn"
  (interactive "sLocate: ")
  (locate search-string)
  (save-excursion
    (goto-char (point-min))
    (let ((buffer-read-only nil))
      (delete-matching-lines
       "\\(\.svn-" "\\(base\\|work\\)$"
       "\\|.arch./..pristine-trees\\|/.arch-ids/.+\.id$\\)"))))

(global-set-key [(control c) (l)] 'tlocate-string)
(global-set-key [(control c) (meta l)] 'tlocate-regexp)

(defalias 'grep-locally 'lgrep)
(defalias 'grep-recursively 'rgrep)

(provide 'tgrep)
