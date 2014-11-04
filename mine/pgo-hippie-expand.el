;;; pgo-hippie-expand.el --- Setup Hippie Expand and its Extensions.
;; `try-expand-whole-kill'
;; TODO Support `hictx' of modified part of abbrev expansions.

(require 'dabbrev-substring)
(require 'dabbrev-acronym)

(defun hippie-expand-case-sensitive (arg)
  "Do case sensitive searching so we deal with gtk_xxx and GTK_YYY."
  (interactive "P")
  (let ((case-fold-search nil))
    (hippie-expand arg)))

;;; Tags
(defun he-tag-beg ()
  "Find cursor position for beginning of tag."
  (let ((p (save-excursion
             (beginning-of-symbol-next-to-point)
             (point))))
    p))
(defun try-expand-tag (old)
  "Try to complete text with something from the TAGS table.
The argument old has to be nil the first call of this function,
and t for subsequent calls (for further possible completions of
the same string). It returns t if a new completion is found, nil
otherwise. See: http://www.emacswiki.org/cgi-bin/wiki/HippieExpand#toc4"
  (unless old
    (he-init-string (he-tag-beg) (point))
    (setq he-expand-list (sort (all-completions he-search-string 'complete-tag) 'string-lessp)))
  (while (and he-expand-list (he-string-member (car he-expand-list) he-tried-table))
    (setq he-expand-list (cdr he-expand-list)))
  (if (null he-expand-list)
      (progn (when old (he-reset-string)) nil)
    (he-substitute-string (car he-expand-list))
    (setq he-expand-list (cdr he-expand-list))
    t))
(defun try-expand-ectag (old)
  "Try to complete text with something from the tags table.
The argument old has to be nil the first call of this function,
and t for subsequent calls (for further possible completions of
the same string). It returns t if a new completion is found, nil
otherwise. See: http://www.emacswiki.org/cgi-bin/wiki/HippieExpand#toc4"
  (unless old                         ;if first expension
    (he-init-string (he-tag-beg) (point))
    (setq he-expand-list (sort
                          (mapcar
                           (lambda (tag-key) (ectag-get tag-key :name))
                           (all-completions he-search-string (ectags-lazy-completion-table)))
                          'string-lessp))) ;TODO Sort on :file instead. Filter out :name before sort()
  (while (and he-expand-list (he-string-member (car he-expand-list) he-tried-table))
    (setq he-expand-list (cdr he-expand-list)))
  (if (null he-expand-list)
      (progn (when old (he-reset-string)) nil)
    (he-substitute-string (car he-expand-list))
    (setq he-expand-list (cdr he-expand-list))
    t))

(defun try-complete-with-calc-result (arg)
  (and
   (not arg) (eolp)
   (save-excursion
     (beginning-of-line)
     (when (and (boundp 'comment-start)
                comment-start)
       (when (looking-at
              (concat
               "[ \n\t]*"
               (regexp-quote comment-start)))
         (goto-char (match-end 0))
         (when (looking-at "[^\n\t ]+")
           (goto-char (match-end 0)))))
     (looking-at ".* \\(\\([;=]\\) +$\\)"))
   (save-match-data
     (require 'calc-ext nil t))
   ;;(require 'calc-aent)
   (let ((start (match-beginning 0))
         (op (match-string-no-properties 2)))
     (save-excursion
       (goto-char (match-beginning 1))
       (if (re-search-backward (concat "[\n" op "]") start t)
           (goto-char (match-end 0)) (goto-char start))
       (looking-at (concat " *\\(.*[^ ]\\) +" op "\\( +\\)$"))
       (goto-char (match-end 2))
       (let* ((b (match-beginning 2))
              (e (match-end 2))
              (a (match-string-no-properties 1))
              (r (calc-eval a nil nil)))
         (when (string= a r)
           (let ((b (save-excursion
                      (and (search-backward "\n\n" nil t)
                           (match-end 0))))
                 (p (current-buffer))
                 (pos start)
                 (s nil))
             (setq r
                   (calc-eval
                    (with-temp-buffer
                      (insert a)
                      (goto-char (point-min))
                      (while (re-search-forward
                              "[^0-9():!^ \t-][^():!^ \t]*" nil t)
                        (setq s (match-string-no-properties 0))
                        (let ((r
                               (save-match-data
                                 (with-current-buffer p
                                   (goto-char pos)
                                   (and
                                    ;; ToDo: support for line
                                    ;; indentation
                                    (re-search-backward
                                     (concat "^" (regexp-quote s)
                                             " =")
                                     b t)
                                    (progn
                                      (end-of-line)
                                      (search-backward "=" nil t)
                                      (and (looking-at "=\\(.*\\)$")
                                           (match-string-no-properties 1))))))))
                          (if r (replace-match (concat "(" r ")") t t))))
                      (buffer-substring (point-min) (point-max)))
                    nil nil))))
         (and
          r
          (progn
            (he-init-string b e)
            (he-substitute-string (concat " " r))
            t)))))))

;; TODO Doesn't work form suffixes such `-command-list'.
(defun hippie-expand-mode-local (arg)
  (interactive "P")
  (setq hippie-expand-try-functions-list
        (append
         '(
           try-expand-dabbrev-visible ;from visible parts of all windows
           try-expand-dabbrev-substring-visible
           try-expand-dabbrev-acronym-visible

           try-expand-dabbrev           ;from current buffer
           try-expand-dabbrev-substring
           try-expand-dabbrev-acronym

           try-expand-dabbrev-all-buffers ;from all other buffers
           try-expand-dabbrev-substring-all-buffers
           try-expand-dabbrev-acronym-all-buffers

           ;; try-expand-yas-if-inside-code ;YASnippet Expand
           ;; try-expand-tag
           ;; try-expand-ectag
           ;; try-expand-thing-at-point
           ;; try-expand-all-abbrevs
           ;; try-expand-list
           ;; try-expand-list-all-buffers
           ;; try-expand-line            ;Line
           ;; try-expand-line-all-buffers ;Line
           ;; try-expand-dabbrev-from-kill    ;Kill Ring
           ;; try-expand-whole-kill ;Kill Ring
           )
         (when (eq 'emacs-lisp-mode major-mode)
           '(try-complete-lisp-symbol-partially ;Lisp
             try-complete-lisp-symbol))         ;Lisp
         '(try-complete-file-name-partially     ;File Name
           try-complete-file-name               ;File Name
           try-complete-with-calc-result
           )
         ;;try-complete-OpenGL-symbol      ;OpenGL Symbol
         )) (hippie-expand arg))
(global-set-key [(meta ?/)] 'hippie-expand-mode-local)

;;; ============================================================================================
;;; ============================================================================================
;;; ============================================================================================
;;; ============================================================================================
;;; ============================================================================================

(when nil
  (require 'cc-utils)
  (require 'power-utils)
  (require 'obarray-utils)

  ;;(when (require 'hippie-namespace nil t))

  ;; ----------------------------------------------------------------------------

  (defun try-expand-complete-file-name (old)
    "Try complete as a filename."
    (interactive "P")
    (apply (make-hippie-expand-function '(try-complete-file-name))
           `(,old)))
  ;; Use: (try-expand-complete-file-name nil)
  (defun try-expand-complete-file-name-partially (old)
    "Try complete partially as a filename."
    (interactive "P")
    (apply (make-hippie-expand-function '(try-complete-file-name-partially))
           `(,old)))
  ;; Use: (try-expand-complete-file-name-partially nil)

  ;; Note: Activate yasnippet
  (defun try-expand-yas-if-inside-code (old)
    "Integrate with hippie expand. Just put this function in
`hippie-expand-try-functions-list'."
    (when (and (at-syntax-code-p)
               (fboundp 'yas/hippie-try-expand)
               (yas/hippie-try-expand old))))

  ;; ----------------------------------------------------------------------------

  (defun try-expand-from-cc-mode (old)
    "Try Expand in C mode.
It returns t if a new expansion is found, nil otherwise.
See: `hippie-expand-try-functions-list'."
    (cond
     ((at-syntax-code-p)
      (cond ((looking-back (concat "\\_<" (regexp-opt '("creat" "open" "fopen"))
                                   _* "(" _*
                                   "\""
                                   "\\(?:" "\\sw" "\\|" "\s." "\\)*"))
             (try-complete-file-name old) t)
            (t
             (try-expand-ectag old))
            ))))

  (defun try-expand-from-emacs-lisp-mode (old)
    "Try Expand in Emacs-Lisp mode.
It returns t if a new expansion is found, nil otherwise.
See: `hippie-expand-try-functions-list'."
    (cond
     ((at-syntax-code-p)
      (cond ((looking-back (concat "(" _* (regexp-opt '("find-file" "find-file-literally"))
                                   _+
                                   "\"" "\\(" ".*" "\\)"))
             (try-complete-file-name old) t)
            (t
             (or (try-complete-lisp-symbol-partially old)
                 (try-complete-lisp-symbol old))
             )))))
  (when nil (find-file "/var/local/../"))

  (defun try-expand-from-sh-mode (old)
    "Try Expand in Shell mode.
It returns t if a new expansion is found, nil otherwise.
See: `hippie-expand-try-functions-list'."
    (cond
     ((at-syntax-code-p)
      (when (looking-back (concat (regexp-opt '("cat" "less" "grep"))
                                  _+
                                  "\"?"
                                  "\\(" ".*" "\\)"))
        (try-complete-file-name old) t))))

  (defun try-expand-from-python-mode (old)
    "Try Expand in Python mode.
It returns t if a new expansion is found, nil otherwise.
See: `hippie-expand-try-functions-list'."
    (cond
     ((at-syntax-code-p)                ;Code
      (and (fboundp 'py-complete-try-complete-symbol)
           (py-complete-try-complete-symbol)))
     ))

  (defun try-expand-thing-at-point (old)
    "Try Expand Anything using major mode, context, etc.
It returns t if a new expansion is found, nil otherwise.
See: `hippie-expand-try-functions-list'."
    (cond
     ((and (memq major-mode cc-derived-modes) ;C-like
           (try-expand-from-cc-mode old)))
     ((and (memq major-mode '(emacs-lisp-mode)) ;Emacs-Lisp
           (try-expand-from-emacs-lisp-mode old)))
     ((and (memq major-mode '(sh-mode)) ;Shell
           (try-expand-from-sh-mode old)))
     ((and (memq major-mode '(python-mode)) ;Python
           (try-expand-from-python-mode old)))
     ((at-syntax-code-p)
      nil
      )
     ((at-syntax-string-p)
      ;; TODO dabbrev-complete-string
      nil
      )
     ((at-syntax-comment-p)
      (when (fboundp 'mdabbrev-expand)
        (mdabbrev-expand))
      )
     (t
      nil
      )))

  ;; See: http://www.emacswiki.org/cgi-bin/wiki/MicheleBini

  (when nil                             ;TODO We already have this in Emacs.
    (define-key esc-map "\t" 'complete-symbol)
    (defun complete-symbol (arg) "\
Perform tags completion on the text around point.
Completes to the set of names listed in the current tags table.
The string to complete is chosen in the same way as the default
for \\[find-tag] (which see).

With a prefix argument, this command does completion within
the collection of symbols listed in the index of the manual for the
language you are using."
      (interactive "P")
      (if arg
          (info-complete-symbol)
        (cond ((fboundp 'complete-ectag)
               (complete-ectag))
              ((fboundp 'complete-tag)
               (complete-tag))
              (t
               ;; Don't autoload etags if we have no tags table.
               (error "%s" (substitute-command-keys
                            "No tags table loaded; use \\[visit-tags-table] to load one")))))))

  ;; ----------------------------------------------------------------------------

  (defun find-thing-at-point-emacs-lisp (name)
    (interactive
     (list
      (let ((default (thing-at-point 'symbol)))
        ;; TODO Use icicle-transform-function instead?
        (completing-read (concat "Find symbol" (when default (concat " (default " default ")")) ": ")
                         (obarray-lazy-completion-table) nil t nil nil default))))
    (when (fboundp 'elisp-find-definition)
      (elisp-find-definition name)))

  (defun find-thing-at-point-cc ()
    (interactive)
    (cond ((call-interactively 'find-ectag))
          ((when (c-on-identifier)     ;prevent keywords from being searched for
             (ignore-errors (man (symbol-name (symbol-at-point))))
             ))))

  (defun find-thing-at-point-sh ()
    (interactive)
    (cond ((call-interactively 'find-ectag))
          ((ignore-errors (man (symbol-name (symbol-at-point)))))))

  (defun find-thing-at-point-octave ()
    (interactive)
    (cond ((call-interactively 'find-ectag))
          ((ignore-errors (man (symbol-name (symbol-at-point)))))))

  (defun find-thing-at-point-dired ()
    (interactive)
    (cond ((call-interactively 'find-ectag))
          ((ignore-errors (man (symbol-name (symbol-at-point)))))))

  (defun find-thing-at-point ()
    (interactive)
    (cond
     ((and (memq major-mode '(emacs-lisp-mode lisp-interaction-mode))
           (call-interactively 'find-thing-at-point-emacs-lisp)))
     ((and (memq major-mode cc-derived-modes)
           (find-thing-at-point-cc)))
     ((and (memq major-mode '(sh-mode))
           (find-thing-at-point-sh)))
     ((and (memq major-mode '(octave-mode))
           (find-thing-at-point-octave)))
     ((and (memq major-mode '(dired-mode))
           (find-thing-at-point-dired)))
     ((at-syntax-code-p)
      ;; TODO
      nil
      )
     ((at-syntax-string-p)
      ;; TODO dabbrev-complete-string
      nil
      )
     ((at-syntax-comment-p)
      (mdabbrev-expand)
      )
     (t
      nil
      ))  )

;;; ----------------------------------------------------------------------------
;;; See: EmacsWiki: HippieExpand: http://www.emacswiki.org/cgi-bin/wiki/HippieExpand

  ;; Create a hippie-expand function with a given list of strings
  (defvar dcsh-command-list '("all_registers"
                              "check_design" "check_test" "compile"
                              "current_design" "link" "uniquify"
                              "report_timing" "report_clocks"
                              "report_constraint" "get_unix_variable"
                              "set_unix_variable" "set_max_fanout"
                              "report_area" "all_clocks" "all_inputs"
                              "all_outputs")
    "List of dsch (D C-shell) commands.")

  (defun he-dcsh-command-beg ()
    (let ((p))
      (save-excursion
        (backward-word 1)
        (setq p (point)))
      p))

  (defun try-expand-dcsh-command (old)
    (unless old
      (he-init-string (he-dcsh-command-beg) (point))
      (setq he-expand-list (sort
                            (all-completions he-search-string (mapcar 'list dcsh-command-list))
                            'string-lessp)))
    (while (and he-expand-list
                (he-string-member (car he-expand-list) he-tried-table))
      (setq he-expand-list (cdr he-expand-list)))
    (if (null he-expand-list)
        (progn
          (when old (he-reset-string))
          ())
      (he-substitute-string (car he-expand-list))
      (setq he-tried-table (cons (car he-expand-list) (cdr he-tried-table)))
      (setq he-expand-list (cdr he-expand-list))
      t))

  ;; Create a keybinding with a list of hippie-expand functions
  ;; (global-set-key [(meta f5)] (make-hippie-expand-function
  ;;                           '(try-expand-dcsh-command
  ;;                             try-expand-dabbrev-visible
  ;;                             try-expand-dabbrev
  ;;                             try-expand-dabbrev-all-buffers) t))
  )

(provide 'pgo-hippie-expand)
