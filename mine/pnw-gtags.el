;;; pnw-gtags.el --- gtags facility for Emacs

;;
;; Copyright (c) 1997, 1998, 1999, 2000, 2006, 2007, 2008
;;	Tama Communications Corporation
;;
;; This file is part of GNU GLOBAL.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;

;; GLOBAL home page is at: http://www.gnu.org/software/global/
;; Author: Tama Communications Corporation
;; Version: 2.5
;; Keywords: tools
;; Required version: GLOBAL 5.7 or later

;; Gtags-mode is implemented as a minor mode so that it can work with any
;; other major modes. Gtags-select mode is implemented as a major mode.
;;
;; Please copy this file into emacs lisp library directory or place it in
;; a directory (for example "~/lisp") and write $HOME/.emacs like this.
;;
;;	(setq load-path (cons "~/lisp" load-path))
;;
;; If you hope gtags-mode is on in c-mode then please add c-mode-hook to your
;; $HOME/.emacs like this.
;;
;;	(setq c-mode-hook
;;	    (lambda ()
;;		(gtags-mode 1)
;;	))
;;
;; There are two hooks, gtags-mode-hook and gtags-select-mode-hook.
;; The usage of the hook is shown as follows.
;;
;; [Setting to reproduce old 'Gtags mode']
;;
;; (setq gtags-mode-hook
;;   (lambda ()
;;      (setq gtags-pop-delete t)
;;      (setq gtags-path-style 'absolute)
;; ))
;;
;; [Setting to make 'Gtags select mode' easy to see]
;;
;; (setq gtags-select-mode-hook
;;   (lambda ()
;;      (setq hl-line-face 'underline)
;;      (hl-line-mode 1)
;; ))

;;; Code

(eval-when-compile
  (require 'cl))

(defvar gtags-mode nil
  "Non-nil if Gtags mode is enabled.")
(make-variable-buffer-local 'gtags-mode)

;;;
;;; Customizing gtags-mode
;;;
(defgroup gtags nil
  "Minor mode for GLOBAL source code tag system."
  :group 'tools
  :prefix "gtags-")

(defcustom gtags-path-style 'root
  "*Controls the style of path in [GTAGS SELECT MODE]."
  :type '(choice (const :tag "Relative from the root of the current project" root)
                 (const :tag "Relative from the current directory" relative)
                 (const :tag "Absolute" absolute))
  :group 'gtags)

(defcustom gtags-read-only nil
  "Gtags read only mode"
  :type 'boolean
  :group 'gtags)

(defcustom gtags-pop-delete nil
  "*If non-nil, gtags-pop will delete the buffer."
  :group 'gtags
  :type 'boolean)

;; Variables
(defvar gtags-current-buffer nil
  "Current buffer.")
(defvar gtags-buffer-stack nil
  "Stack for tag browsing.")
(defvar gtags-point-stack nil
  "Stack for tag browsing.")
(defvar gtags-complete-list nil
  "Gtags complete list.")
(defvar gtags-history-list nil
  "Gtags history list.")
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'gtags-history-list t))
(defconst gtags-symbol-regexp "[A-Za-z_][A-Za-z_0-9]*"
  "Regexp matching tag name.")
(defconst gtags-definition-regexp "#[ \t]*define[ \t]+\\|ENTRY(\\|ALTENTRY("
  "Regexp matching tag definition name.")
(defvar gtags-read-only nil
  "Gtags read only mode")
(defvar gtags-mode-map (make-sparse-keymap)
  "Keymap used in gtags mode.")
(defvar gtags-running-xemacs (string-match "XEmacs\\|Lucid" emacs-version)
  "Whether we are running XEmacs/Lucid Emacs")
(defvar gtags-rootdir nil
  "Root directory of source tree.")

(defconst gtags-default-error ": tag not found")

(defvar gtags-flag-table
  ;; name <cmd-line string> <buffer-name prefix> <error-msg>
  `((symbol    "s" "(S)" ": symbol not found")
    (context   "c" "(CONTEXT)" ,gtags-default-error)
    (grep      "g" "(GREP)" ": pattern not found")
    (idutils   "I" "(IDUTILS)" ": token not found")
    (path      "P" "(P)" ": path not found")
    (reference "r" "(Ref)" ,gtags-default-error)
    ;; optional flags
    (local     "l" "(local)"))
  " table of legitimate flags")

(defmacro gtags-flag-sym (flag)
  `(car ,flag))

(defmacro gtags-flag-cmd-line-arg (flag)
  `(cadr ,flag))

(defmacro gtags-flag-prefix-msg (flag)
  `(caddr ,flag))

(defmacro gtags-flag-err-msg (flag)
  `(cadddr ,flag))

;
; New key assignment to avoid conflicting with ordinary assignments.
;
(define-key gtags-mode-map "\e*" 'gtags-pop-stack)
(define-key gtags-mode-map "\e." 'gtags-find-tag)
(define-key gtags-mode-map "\C-x4." 'gtags-find-tag-other-window)
;
; Old key assignment.
;
; If you hope old style key assignment. Please include following code
; to your $HOME/.emacs:
;
; (setq gtags-mode-hook
;   (lambda ()
;         (define-key gtags-mode-map "\eh" 'gtags-display-browser)
;         (define-key gtags-mode-map "\C-]" 'gtags-find-tag-from-here)
;         (define-key gtags-mode-map "\C-t" 'gtags-pop-stack)
;         (define-key gtags-mode-map "\el" 'gtags-find-file)
;         (define-key gtags-mode-map "\eg" 'gtags-find-with-grep)
;         (define-key gtags-mode-map "\eI" 'gtags-find-with-idutils)
;         (define-key gtags-mode-map "\es" 'gtags-find-symbol)
;         (define-key gtags-mode-map "\er" 'gtags-find-rtag)
;         (define-key gtags-mode-map "\et" 'gtags-find-tag)
;         (define-key gtags-mode-map "\ev" 'gtags-visit-rootdir)
; ))

(if (not gtags-running-xemacs) nil
  (define-key gtags-mode-map 'button3 'gtags-pop-stack)
  (define-key gtags-mode-map 'button2 'gtags-find-tag-by-event))
(if gtags-running-xemacs nil
  (define-key gtags-mode-map [mouse-3] 'gtags-pop-stack)
  (define-key gtags-mode-map [mouse-2] 'gtags-find-tag-by-event))

(defvar gtags-select-mode-map (make-sparse-keymap)
  "Keymap used in gtags select mode.")
(define-key gtags-select-mode-map "\e*" 'gtags-pop-stack)
(if (not gtags-running-xemacs) nil
  (define-key gtags-select-mode-map 'button3 'gtags-pop-stack)
  (define-key gtags-select-mode-map 'button2 'gtags-select-tag-by-event))
(if gtags-running-xemacs nil
  (define-key gtags-select-mode-map [mouse-3] 'gtags-pop-stack)
  (define-key gtags-select-mode-map [mouse-2] 'gtags-select-tag-by-event))
(define-key gtags-select-mode-map "\^?" 'scroll-down)
(define-key gtags-select-mode-map " " 'scroll-up)
(define-key gtags-select-mode-map "\C-b" 'scroll-down)
(define-key gtags-select-mode-map "\C-f" 'scroll-up)
(define-key gtags-select-mode-map "k" 'previous-line)
(define-key gtags-select-mode-map "j" 'next-line)
(define-key gtags-select-mode-map "p" 'previous-line)
(define-key gtags-select-mode-map "n" 'next-line)
(define-key gtags-select-mode-map "q" 'gtags-pop-stack)
(define-key gtags-select-mode-map "u" 'gtags-pop-stack)
(define-key gtags-select-mode-map "\C-t" 'gtags-pop-stack)
(define-key gtags-select-mode-map "\C-m" 'gtags-select-tag)
(define-key gtags-select-mode-map "\C-o" 'gtags-select-tag-other-window)
(define-key gtags-select-mode-map "\e." 'gtags-select-tag)

;;
;; utility
;;
(defun gtags-match-string (n)
  (buffer-substring (match-beginning n) (match-end n)))

;; Return a default tag to search for, based on the text at point.
(defun gtags-current-token ()
  "Return a default tag to search for, based on the text at point."
  (interactive)
  (save-excursion
    (cond
   ((looking-at "[0-9A-Za-z_]")
    (while (looking-at "[0-9A-Za-z_]")
	(forward-char -1))
      (forward-char 1))
     (t
      (while (looking-at "[ \t]")
	(forward-char 1))))
    (if (and (bolp) (looking-at gtags-definition-regexp))
	(goto-char (match-end 0)))
    (if (looking-at gtags-symbol-regexp)
	(gtags-match-string 0) nil)))

;; push current context to stack
(defun gtags-push-context ()
  (setq gtags-buffer-stack (cons (current-buffer) gtags-buffer-stack))
  (setq gtags-point-stack (cons (point) gtags-point-stack)))

;; pop context from stack
(defun gtags-pop-context ()
  (if (not gtags-buffer-stack) nil
    (let (buffer point)
      (setq buffer (car gtags-buffer-stack) gtags-buffer-stack (cdr gtags-buffer-stack)
            point  (car gtags-point-stack)  gtags-point-stack  (cdr gtags-point-stack))
      (list buffer point))))

;; if the buffer exist in the stack
(defun gtags-exist-in-stack (buffer)
  (memq buffer gtags-buffer-stack))

;; get current line number
(defun gtags-current-lineno ()
  (if (= 0 (count-lines (point-min) (point-max)))
      0
    (save-excursion
      (end-of-line)
      (if (equal (point-min) (point))
          1
        (count-lines (point-min) (point))))))

;; is it a function?
(defun gtags-is-function ()
  (save-excursion
    (while (and (not (eolp)) (looking-at "[[:alnum:_]]"))
      (forward-char 1))
    (while (and (not (eolp)) (looking-at "[ \t]"))
      (forward-char 1))
    (if (looking-at "(") t nil)))

;; is it a definition?
(defun gtags-is-definition ()
  (save-excursion
    (if (and (string-match "\.java$" buffer-file-name) (looking-at "[^(]+([^)]*)[ \t]*{"))
	t
      (if (bolp)
	  t
        (forward-word -1)
        (cond
         ((looking-at "define")
	  (forward-char -1)
	  (while (and (not (bolp)) (looking-at "[ \t]"))
	    (forward-char -1))
	  (if (and (bolp) (looking-at "#"))
	      t nil))
         ((looking-at "ENTRY\\|ALTENTRY")
	  (if (bolp) t nil)))))))

;; completsion function for completing-read.
(defun gtags-completing-gtags (string predicate code)
  (gtags-completing 'gtags string predicate code))
(defun gtags-completing-gsyms (string predicate code)
  (gtags-completing 'gsyms string predicate code))
;; common part of completing-XXXX
;;   flag: 'gtags or 'gsyms
(defun gtags-completing (flag string predicate code)
  (let ((option "-c")
        (complete-list (make-vector 63 0))
        (prev-buffer (current-buffer)))
					; build completion list
    (set-buffer (generate-new-buffer "*Completions*"))
    (if (eq flag 'gsyms)
        (setq option (concat option "s")))
    (call-process "global" nil t nil option string)
    (goto-char (point-min))
    (while (looking-at gtags-symbol-regexp)
      (intern (gtags-match-string 0) complete-list)
      (forward-line))
    (kill-buffer (current-buffer))
					; recover current buffer
    (set-buffer prev-buffer)
					; execute completion
    (cond ((eq code nil)
           (try-completion string complete-list predicate))
          ((eq code t)
           (all-completions string complete-list predicate))
          ((eq code 'lambda)
           (if (intern-soft string complete-list) t nil)))))

;; get the path of gtags root directory.
(defun gtags-get-rootpath ()
  (let (path buffer)
    (save-excursion
      (setq buffer (generate-new-buffer (generate-new-buffer-name "*rootdir*")))
      (set-buffer buffer)
      (setq n (call-process "global" nil t nil "-pr"))
      (if (= n 0)
        (setq path (file-name-as-directory (buffer-substring (point-min)(1- (point-max))))))
      (kill-buffer buffer))
    path))

;;
;; interactive command
;;
(defun gtags-visit-rootdir ()
  "Tell tags commands the root directory of source tree."
  (interactive)
  (let (path input n)
    (if gtags-rootdir
      (setq path gtags-rootdir)
     (setq path (gtags-get-rootpath))
     (if (equal path nil)
       (setq path default-directory)))
    (setq input (read-file-name "Visit root directory: " path path t))
    (if (equal "" input) nil
      (if (not (file-directory-p input))
	  (message "%s is not directory." input)
	(setq gtags-rootdir (expand-file-name input))
	(setenv "GTAGSROOT" gtags-rootdir)))))

(defun gtags-prepare-window-buffers ()
  "Prepare the windows of the current frame for a tag lookup."
  (interactive)
  (if (one-window-p)			;frame has one window only
      (progn
	;; (message "split-window-vertically and other-window 1")
	(split-window-vertically) (other-window 1))
    (progn
      ;; (message "other-window 1 and balance-windows")
      (other-window 1) (balance-windows))
    ))

(defun gtags-find-tag (&optional other-win)
  "Input tag name and move to the definition."
  (interactive)
  (let (tagname prompt input)
    (setq tagname (gtags-current-token))
    (if tagname
      (setq prompt (concat "Find tag: (default \"" tagname "\") "))
     (setq prompt "Find tag: "))
    (setq input (completing-read prompt 'gtags-completing-gtags
                  nil nil nil gtags-history-list))
    (if (not (equal "" input))
	(setq tagname input))
    (gtags-push-context)
    (gtags-goto-tag tagname "" other-win)))

(defun gtags-find-tag-other-window ()
  "Input tag name and move to the definition in other window."
  (interactive)
  (gtags-find-tag t))

(defmacro concat-local-macro (local)
  `(if ,local (assq 'local gtags-flag-table)))

(defun gtags-find-rtag (tagname &optional local)
  "Input tag name and move to the referenced point."
  (interactive
  (let (tagname prompt input)
   (setq tagname (gtags-current-token))
   (if tagname
     (setq prompt (concat "Find tag (reference): (default \"" tagname "\") "))
    (setq prompt "Find tag (reference): "))
   (setq input (completing-read prompt 'gtags-completing-gtags
                 nil nil nil gtags-history-list))
     (if (not (equal "" input)) (setq tagname input))
     (list tagname current-prefix-arg)))
    (gtags-push-context)
  (gtags-goto-tag tagname (list (assq 'reference gtags-flag-table)
                                (concat-local-macro local))))

(defun gtags-find-symbol (tagname &optional local)
  "Input symbol and move to the locations."
  (interactive
  (let (tagname prompt input)
    (setq tagname (gtags-current-token))
    (if tagname
        (setq prompt (concat "Find symbol: (default \"" tagname "\") "))
      (setq prompt "Find symbol: "))
    (setq input (completing-read prompt 'gtags-completing-gsyms
                  nil nil nil gtags-history-list))
    (if (not (equal "" input)) (setq tagname input))
     (list tagname current-prefix-arg)))
    (gtags-push-context)
    (message "local: %s" local)
    (gtags-goto-tag tagname (list (assq 'symbol gtags-flag-table)
                                  (concat-local-macro local))))

(defun gtags-find-pattern ()
  "Input pattern, search with grep(1) and move to the locations."
  (interactive)
  (gtags-find-with-grep))

(defun gtags-find-with-grep ()
  "Input pattern, search with grep(1) and move to the locations."
  (interactive)
  (gtags-find-with (list (assq 'grep gtags-flag-table))))

(defun gtags-find-with-idutils ()
  "Input pattern, search with idutils(1) and move to the locations."
  (interactive)
  (gtags-find-with (list (assq 'grep gtags-flag-table))))

(defun gtags-find-file (tagname &optional local)
  "Input pattern and move to the top of the file."
  (interactive
   (let (tagname input)
     (setq input (read-string "Find files: "))
    (if (not (equal "" input)) (setq tagname input))
     (list tagname current-prefix-arg)))
    (gtags-push-context)
  (gtags-goto-tag tagname (list (assq 'path gtags-flag-table)
                                (concat-local-macro local))))

(defun gtags-parse-file (tagname &optional local)
  "Input file name, parse it and show object list."
  (interactive
  (let (tagname prompt input)
    (setq input (read-file-name "Parse file: "
		nil nil t (file-name-nondirectory buffer-file-name)))
    (if (not (equal "" input)) (setq tagname input))
     (list tagname current-prefix-arg)))
    (gtags-push-context)
  (gtags-goto-tag tagname "f"))

(defun gtags-find-tag-from-here (tagname &optional local)
  "Get the expression as a tagname around here and move there."
  (interactive
  (let (tagname flag)
    (setq tagname (gtags-current-token))
     (list tagname current-prefix-arg)))
  (when tagname
      (gtags-push-context)
    (gtags-goto-tag tagname (list (assq 'context gtags-flag-table)
                                  (concat-local-macro local)))))

; This function doesn't work with mozilla.
; But I will support it in the near future.
(defun gtags-display-browser ()
  "Display current screen on hypertext browser."
  (interactive)
  (call-process "gozilla"  nil nil nil (concat "+" (number-to-string (gtags-current-lineno))) buffer-file-name))

; Private event-point
; (If there is no event-point then we use this version.
(eval-and-compile
  (if (not (fboundp 'event-point))
      (defun event-point (event)
	(posn-point (event-start event)))))

(defun gtags-find-tag-by-event (event)
  "Get the expression as a tagname around here and move there."
  (interactive "e")
  (let (tagname flag)
    (if (= 0 (count-lines (point-min) (point-max)))
        (setq tagname "main")
      (if gtags-running-xemacs
          (goto-char (event-point event))
	(select-window (posn-window (event-end event)))
        (set-buffer (window-buffer (posn-window (event-end event))))
        (goto-char (posn-point (event-end event))))
      (setq tagname (gtags-current-token))
      (setq flag (assq 'context gtags-flag-table)))
    (if (not tagname)
        nil
      (gtags-push-context)
      (gtags-goto-tag tagname (list flag)))))

(defun gtags-select-tag (&optional other-win)
  "Select a tag in [GTAGS SELECT MODE] and move there."
  (interactive)
  (gtags-push-context)
  (gtags-select-it nil other-win))

(defun gtags-select-tag-other-window ()
  "Select a tag in [GTAGS SELECT MODE] and move there in other window."
  (interactive)
  (gtags-select-tag t))

(defun gtags-select-tag-by-event (event)
  "Select a tag in [GTAGS SELECT MODE] and move there."
  (interactive "e")
  (if gtags-running-xemacs (goto-char (event-point event))
    (select-window (posn-window (event-end event)))
    (set-buffer (window-buffer (posn-window (event-end event))))
    (goto-char (posn-point (event-end event))))
  (gtags-push-context)
  (gtags-select-it nil))

(defun gtags-pop-stack ()
  "Move to previous point on the stack."
  (interactive)
  (let (delete context buffer)
    (if (and (not (equal gtags-current-buffer nil))
             (not (equal gtags-current-buffer (current-buffer))))
	(switch-to-buffer gtags-current-buffer)
         ; By default, the buffer of the referred file is left.
         ; If gtags-pop-delete is set to t, the file is deleted.
         ; Gtags select mode buffer is always deleted.
         (if (and (or gtags-pop-delete (equal mode-name "Gtags-Select"))
                  (not (gtags-exist-in-stack (current-buffer))))
	  (setq delete t))
      (setq context (gtags-pop-context))
      (if (not context)
	  (message "The tags stack is empty.")
        (if delete
	    (kill-buffer (current-buffer)))
        (switch-to-buffer (nth 0 context))
        (setq gtags-current-buffer (current-buffer))
        (goto-char (nth 1 context))))))

;;
;; common function
;;

;; find with grep or idutils.
(defun gtags-find-with (flags)
  (let (tagname prompt input)
    (setq tagname (gtags-current-token))
    (if tagname
        (setq prompt (concat "Find pattern: (default \"" tagname "\") "))
      (setq prompt "Find pattern: "))
    (setq input (completing-read prompt 'gtags-completing-gtags
                 nil nil nil gtags-history-list))
    (if (not (equal "" input)) (setq tagname input))
    (gtags-push-context)
    (gtags-goto-tag tagname flags)))

;; goto tag's point
(defun gtags-goto-tag (tagname flags &optional other-win)
  (message "!!!!!(gtags-goto-tag %s %s %s)" tagname flags other-win)
  (let (option context prefix buffer process-result lines rootdir) ;;prev-buf
    ;; Always use ctags-x format.
    (setq option "-x")
    (dolist (flag flags)
      (if (equal (gtags-flag-sym flag) 'context)
        (setq context (concat "--from-here=" (number-to-string (gtags-current-lineno)) ":" buffer-file-name))
        (setq option (concat option (gtags-flag-cmd-line-arg flag))))
      (setq prefix (concat prefix (gtags-flag-prefix-msg flag))))

    ;; load tag
    (setq buffer (generate-new-buffer (generate-new-buffer-name (concat "*GTAGS SELECT* " prefix tagname))))

    ;; Path style is defined in gtags-path-style:
    ;;   root: relative from the root of the project (Default)
    ;;   relative: relative from the current directory
    ;;	absolute: absolute (relative from the system root directory)
    ;;
    (cond ((equal gtags-path-style 'absolute) (setq option (concat option "a")))
          ((and (equal gtags-path-style 'root) (not (assq 'local flags)))
           (setq rootdir (or gtags-rootdir (gtags-get-rootpath)))
           (message "changing dir to: %s" rootdir)
           (message "default-dir: %s" default-directory)
           (if rootdir (cd rootdir))))

    (message "Searching %s ..." tagname)

    (message "(start-process \"gtags\" \"%s\" \"global\" \"%s\" \"%s\"  \"%s\")"
             buffer option context tagname)
    (setq process-result (if context
                             (start-process "gtags" buffer "global" option context tagname)
                           (start-process "gtags" buffer "global" option tagname)))
    (lexical-let ((other-win other-win) (prev-buf (current-buffer)) (flags flags)
                  (tagname tagname) (rootdir rootdir) gtags-process-sentinel)
      (defun gtags-process-sentinel (process event)
        (message "(gtags-process-sentinel %s %s)" process event)
        (let ((buf (process-buffer process)))
        (cond ((string-match "finished" event)
               (set-buffer buf)
               ;; must change to rootdir once we change buffers
               (if rootdir (cd rootdir))
      (goto-char (point-min))
      (setq lines (count-lines (point-min) (point-max)))
               (cond ((= 0 lines)
                      (message (concat "%s" (gtags-flag-err-msg (car flags))) tagname)
	(gtags-pop-context)
                      (kill-buffer buf)
                      (set-buffer prev-buf))
                     ((= 1 lines)
	(message "Searching %s ... Done" tagname)
	(gtags-select-it t other-win))
                     (t (if (null other-win)
                            (switch-to-buffer buf)
                          (switch-to-buffer-other-window buf))
                        (gtags-select-mode))))
              ;; otherwise assume failure
              (t (message "failure")
                 (message (buffer-substring (point-min) (1- (point-max))))
                 (gtags-pop-context)))))
      (set-process-sentinel process-result 'gtags-process-sentinel))))

;; select a tag line from lines
(defun gtags-select-it (delete &optional other-win)
  (let (line file)
    ;; get context from current tag line
    (beginning-of-line)
    (if (not (looking-at "[^ \t]+[ \t]+\\([0-9]+\\)[ \t]\\([^ \t]+\\)[ \t]"))
        (gtags-pop-context)
      (setq line (string-to-number (gtags-match-string 1)))
      (setq file (gtags-match-string 2))
      ;;
      ;; Why should we load new file before killing current-buffer?
      ;;
      ;; If you kill current-buffer before loading new file, current directory
      ;; will be changed. This might cause loading error, if you use relative
      ;; path in [GTAGS SELECT MODE], because emacs's buffer has its own
      ;; current directory.
      ;;
      (let ((prev-buffer (current-buffer)))
        ;; move to the context
        (if gtags-read-only
	    (if (null other-win) (find-file-read-only file)
	      (find-file-read-only-other-window file))
	  (if (null other-win) (find-file file)
	    (find-file-other-window file)))
        (if delete (kill-buffer prev-buffer)))
      (setq gtags-current-buffer (current-buffer))
      (goto-line line)
      (gtags-mode 1))))

;; make complete list (do nothing)
(defun gtags-make-complete-list ()
  "Make tag name list for completion."
  (interactive)
  (message "gtags-make-complete-list: Deprecated. You need not call this command any longer."))

;;;###autoload
(defun gtags-mode (&optional forces)
  "Toggle Gtags mode, a minor mode for browsing source code using GLOBAL.

Specify the root directory of project.
	\\[gtags-visit-rootdir]
Input tag name and move to the definition.
	\\[gtags-find-tag]
Input tag name and move to the definition in other window.
        \\[gtags-find-tag-other-window]
Input tag name and move to the referenced point.
	\\[gtags-find-rtag]
Input symbol and move to the locations.
	\\[gtags-find-symbol]
Input pattern, search with grep(1) and move to the locations.
	\\[gtags-find-with-grep]
Input pattern, search with idutils(1) and move to the locations.
	\\[gtags-find-with-idutils]
Input pattern and move to the top of the file.
	\\[gtags-find-file]
Get the expression as a tagname around here and move there.
	\\[gtags-find-tag-from-here]
Display current screen on hypertext browser.
	\\[gtags-display-browser]
Get the expression as a tagname around here and move there.
	\\[gtags-find-tag-by-event]
Move to previous point on the stack.
	\\[gtags-pop-stack]

Key definitions:
\\{gtags-mode-map}
Turning on Gtags mode calls the value of the variable `gtags-mode-hook'
with no args, if that value is non-nil."
  (interactive)
  (or (assq 'gtags-mode minor-mode-alist)
      (setq minor-mode-alist (cons '(gtags-mode " Gtags") minor-mode-alist)))
  (or (assq 'gtags-mode minor-mode-map-alist)
      (setq minor-mode-map-alist
	    (cons (cons 'gtags-mode gtags-mode-map) minor-mode-map-alist)))
  (setq gtags-mode
	(if (null forces) (not gtags-mode)
	  (> (prefix-numeric-value forces) 0)))
  (run-hooks 'gtags-mode-hook))

;; make gtags select-mode
(defun gtags-select-mode ()
  "Major mode for choosing a tag from tags list.

Select a tag in tags list and move there.
	\\[gtags-select-tag]
Move to previous point on the stack.
	\\[gtags-pop-stack]

Key definitions:
\\{gtags-select-mode-map}
Turning on Gtags-Select mode calls the value of the variable
`gtags-select-mode-hook' with no args, if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (use-local-map gtags-select-mode-map)
  (setq buffer-read-only t
	truncate-lines t
        major-mode 'gtags-select-mode
        mode-name "Gtags-Select")
  (setq gtags-current-buffer (current-buffer))
  (goto-char (point-min))
  (message "[GTAGS SELECT MODE] %d lines" (count-lines (point-min) (point-max)))
  (run-hooks 'gtags-select-mode-hook))

(provide 'pnw-gtags)

;;; gtags.el ends here
