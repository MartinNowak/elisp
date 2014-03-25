;;; multi-read.el --- Multi-Element Read.
;; Author: Per Nordlöw

;;;###autoload
(defun completing-read-ng (prompt collection &optional predicate require-match
                                  initial-input hist def inherit-input-method)
  (if (fboundp 'icicle-completing-read)
      ;; `icicle-completing-read' already has fancy feature for displaying default value
      (icicle-completing-read prompt collection predicate require-match
                              initial-input hist def inherit-input-method)
    (let ((prompt (concat prompt
                          (when def
                            (format " (default: %s)" def)))))
      (completing-read prompt collection predicate require-match
                       initial-input hist def inherit-input-method))))

;;;###autoload
(defun read-symbol-string-at-point (prompt &optional syntax-table)
  "Read the symbol at point and return its name as a string.
PROMPT is the prompt to use."
  (let* ((default (if (region-active-p)
                      (buffer-substring-no-properties
                       (region-beginning)
                       (region-end))
                    (let ((sym (symbol-at-point)))
                      (when sym (symbol-name sym)))))
         )
    (read-string
     (if default
         (concat prompt " (" default "): ")
       (concat prompt ": "))
     nil nil default)))
;; Use: (read-symbol-string-at-point "Key String to scan for")

;;;###autoload
(defun read-regexp-at-point (&optional prompt syntax-table)
  "Read regexp as a string at point and return it.
PROMPT is the prompt to use."
  (let* ((default (if (region-active-p)
                      (buffer-substring-no-properties
                       (region-beginning)
                       (region-end))
                    (let ((sym (symbol-at-point)))
                      (when sym (symbol-name sym)))))
         )
    (read-regexp
     (or prompt "Regexp")
     ;;(if default (concat prompt " (" default "): ") (concat prompt ": "))
     default)
    ))
;; Use: (read-regexp-at-point)
;; Use: (read-regexp-at-point "Key regexp to scan for")

;;;###autoload
(defun multi-read-thing-1 (&optional prompt uniquify)
  "Construct a list of strings interactively from minibuffer.
An empty string (RET) terminates the read loop."
  (interactive)
  (let ((sl nil))
    (let (str)
      (while (not (equal
                   (setq str (read-string
                              (concat (or prompt
                                          "String")
                                      " (or RET to end list): ")))
                   ""))
        (if uniquify
            (add-to-list 'sl str t)
          (setq sl (append sl `(,str))))
        ))
    sl))

(defun read-rx (prompt)
  "Read rx using PROMPT."
  (interactive)
  ;; TODO: Implement!
  )

(defun multi-read-thing-done ()
  "exit minibuffer and stop loop in multi-read-thing2"
  (interactive)
  (setq keepLooping nil)
  (exit-minibuffer))

;;;###autoload
(defun multi-read-thing (&optional prompt type uniquify syntax-table read-fn history default-value collection)
  "Construct a list of strings interactively from minibuffer.
  <M-Return> to terminate all items except the last, which is
  ended with <Return>."
  (interactive)
  (let ((things nil))
    (let (thing)
      (let ((minibuffer-local-map minibuffer-local-map)) ;temporary override
        ;; TODO: This is really ugly! If we break before `minibuffer-local-map' is
        ;; restored it will be changed globally!
        (define-key minibuffer-local-map (kbd "<M-return>") 'exit-minibuffer)
        (define-key minibuffer-local-map (kbd "<return>") 'multi-read-thing-done)
        (setq keepLooping t)
        (while keepLooping
          (let ((post-prompt (format " nr:%d. M-RET to enter more: " (1+ (length things)))))
            (setq thing
                  (cond (collection
                         (completing-read-ng (concat (or prompt (upcase (symbol-name type)))
                                                  (when default-value
                                                    (format " (default: %s)"
                                                            (faze default-value 'string)))
                                                  post-prompt)
                                          collection nil nil nil nil default-value ))
                        ((eq type 'string)
                         (funcall (or read-fn 'read-string)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt)))
                        ((eq type 'symbol-string-at-point)
                         (funcall (or read-fn 'read-symbol-string-at-point)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt) syntax-table))
                        ((eq type 'regexp)
                         (funcall (or read-fn 'read-regexp)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt)))
                        ((eq type 'regexp-at-point)
                         (funcall (or read-fn 'read-regexp-at-point)
                                  (concat (or prompt "Regexp") post-prompt)))
                        ((eq type 'rx)
                         (funcall (or read-fn 'read-rx) ;TODO: Implement `read-rx'. Extend `rx' format to support semantic patterns such as functions.
                                  (concat (or prompt "Rx") post-prompt)))
                        ((eq type 'file)
                         (funcall (or read-fn 'read-file-name)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt)))
                        ((eq type 'directory)
                         (funcall (or read-fn 'read-directory-name)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt)))
                        ((eq type 'color)
                         (funcall (or read-fn 'read-color)
                                  (concat (or prompt (upcase (symbol-name type))) post-prompt)))
                        (t
                         (let ((prompt (concat (or prompt "String")
                                               (when default-value
                                                 (format " (default: \"%s\")" default-value))
                                               post-prompt
                                               )))
                          (if read-fn
                              (funcall read-fn prompt)
                            (read-string prompt nil history default-value)))
                         ;;(setq keepLooping nil)
                         ))))
          (when (and thing
                     (not (string-equal
                           (if (stringp thing) thing
                             (car thing)) "")))
            (if uniquify
                (add-to-list 'things thing t)
              (setq things (append things `(,thing))))
            ))
        (define-key minibuffer-local-map (kbd "<return>") 'exit-minibuffer)))
    things))
(defalias 'read-things 'multi-read-thing)
(defun read-numbers (&optional prompt) (interactive) (multi-read-thing prompt 'number t))
(defun read-strings (&optional prompt) (interactive) (multi-read-thing prompt 'string t))
(defalias 'read-string-list 'read-strings)
(defun read-regexps (&optional prompt) (interactive) (multi-read-thing prompt 'regexp t))
(defun read-files (&optional prompt) (interactive) (multi-read-thing prompt 'file t))
(defun read-colors (&optional prompt) (interactive) (multi-read-thing prompt 'color t))
(defun read-directories (&optional prompt) (interactive) (multi-read-thing prompt 'directory t))
;; Use: (read-strings)
;; Use: (multi-read-thing "Symbol" 'symbol-string-at-point)
;; Use: (multi-read-thing "String")
;; Use: (multi-read-thing "String" nil nil nil nil nil "alpha" '("alpha" "beta"))
;; Use: (multi-read-thing "String" nil nil nil nil nil '("a" "b"))
;; Use: (read-regexps)
;; Use: (read-files)
;; Use: (read-strings "Key string")

;;;###autoload
(defun* multi-read-thing-alt (&optional (fn 'read-string))
  "Prompt as many time you add the character + to end of prompt.
Return a list of all inputs.  FN is the input function to use."
  (interactive)
  (let (var)
    (cl-labels ((mread ()
                    (let ((stock)
                          (str (funcall fn (cond ((eq fn 'read-string)
                                                  "String (append + to repeat): ")
                                                 ((eq fn 'read-directory-name)
                                                  "Directory(add + to repeat): ")
                                                 (t
                                                  "File (append + to repeat): ")))))
                      (push (replace-regexp-in-string "\+" "" str) stock)
                      (cond ((string-match "\+" str)
                             (push (car stock) var)
                             (mread))
                            (t
                             (push (car stock) var)
                             (nreverse var))))))
      (mread)
      ) var))
;; Use: (multi-read)

;; mcp (to ".mcp")
;;;###autoload
(defun multi-copy-file (file &optional dir-list)
  "Copy `file' in multi directory.
At each prompt of directory add + to input to be prompt for next
directory.  When you do not add a + to directory name input is
finish and function executed"
  (interactive "fFile: ")
  (let* ((dest-list nil)
         (final-list
          (if dir-list dir-list
            (multi-read-thing-alt 'read-directory-name))))
    (loop for i in final-list
          do (copy-file file i t))))

(provide 'multi-read)
