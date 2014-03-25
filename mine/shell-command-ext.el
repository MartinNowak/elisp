;;; shell-command-ext.el - shell-command() extension
;; Copyright (C) 2007 by Per Nordlöw

(defun shell-command-silent (command &optional output-buffer error-buffer silence)
  "Execute string COMMAND in inferior shell; display output, if any.
With prefix argument, insert the COMMAND's output at point.

If COMMAND ends in ampersand, execute it asynchronously.
The output appears in the buffer `*Async Shell Command*'.
That buffer is in shell mode.

Otherwise, COMMAND is executed synchronously.  The output appears in
the buffer `*Shell Command Output*'.  If the output is short enough to
display in the echo area (which is determined by the variables
`resize-mini-windows' and `max-mini-window-height'), it is shown
there, but it is nonetheless available in buffer `*Shell Command
Output*' even though that buffer is not automatically displayed.

To specify a coding system for converting non-ASCII characters
in the shell command output, use \\[universal-coding-system-argument]
before this command.

Noninteractive callers can specify coding systems by binding
`coding-system-for-read' and `coding-system-for-write'.

The optional second argument OUTPUT-BUFFER, if non-nil,
says to put the output in some other buffer.
If OUTPUT-BUFFER is a buffer or buffer name, put the output there.
If OUTPUT-BUFFER is not a buffer and not nil,
insert output in current buffer.  (This cannot be done asynchronously.)
In either case, the output is inserted after point (leaving mark after it).

If the command terminates without error, but generates output,
and you did not specify \"insert it in the current buffer\",
the output can be displayed in the echo area or in its buffer.
If the output is short enough to display in the echo area
\(determined by the variable `max-mini-window-height' if
`resize-mini-windows' is non-nil), it is shown there.  Otherwise,
the buffer containing the output is displayed.

If there is output and an error, and you did not specify \"insert it
in the current buffer\", a message about the error goes at the end
of the output.

If there is no output, or if output is inserted in the current buffer,
then `*Shell Command Output*' is deleted.
If the optional third argument ERROR-BUFFER is non-nil, it is a buffer
or buffer name to which to direct the command's standard error output.
If it is nil, error output is mingled with regular output.
In an interactive call, the variable `shell-command-default-error-buffer'
specifies the value of ERROR-BUFFER.

If SILENCE is true, then '*Shell Command Output*' is created, but not displayed.
"

  (interactive (list (read-from-minibuffer "Shell command: "
					   nil nil nil 'shell-command-history)
		     current-prefix-arg
		     shell-command-default-error-buffer))
  ;; Look for a handler in case default-directory is a remote file name.
  (let ((handler
	 (find-file-name-handler (directory-file-name default-directory)
				 'shell-command)))
    (if handler
	(funcall handler 'shell-command command output-buffer error-buffer)
      (if (and output-buffer
	       (not (or (bufferp output-buffer)  (stringp output-buffer))))
	  ;; Output goes in current buffer.
	  (let ((error-file
		 (if error-buffer
		     (make-temp-file
		      (expand-file-name "scor"
					(or small-temporary-file-directory
					    temporary-file-directory)))
		   nil)))
	    (barf-if-buffer-read-only)
	    (push-mark nil t)
	    ;; We do not use -f for csh; we will not support broken use of
	    ;; .cshrcs.  Even the BSD csh manual says to use
	    ;; "if ($?prompt) exit" before things which are not useful
	    ;; non-interactively.  Besides, if someone wants their other
	    ;; aliases for shell commands then they can still have them.
	    (call-process shell-file-name nil
			  (if error-file
			      (list t error-file)
			    t)
			  nil shell-command-switch command)
	    (when (and error-file (file-exists-p error-file))
	      (if (< 0 (nth 7 (file-attributes error-file)))
		  (with-current-buffer (get-buffer-create error-buffer)
		    (let ((pos-from-end (- (point-max) (point))))
		      (or (bobp)
			  (insert "\f\n"))
		      ;; Do no formatting while reading error file,
		      ;; because that can run a shell command, and we
		      ;; don't want that to cause an infinite recursion.
		      (format-insert-file error-file nil)
		      ;; Put point after the inserted errors.
		      (goto-char (- (point-max) pos-from-end)))
		    (if (not silence) (display-buffer (current-buffer)))))
	      (delete-file error-file))
	    ;; This is like exchange-point-and-mark, but doesn't
	    ;; activate the mark.  It is cleaner to avoid activation,
	    ;; even though the command loop would deactivate the mark
	    ;; because we inserted text.
	    (goto-char (prog1 (mark t)
			 (set-marker (mark-marker) (point)
				     (current-buffer)))))
	;; Output goes in a separate buffer.
	;; Preserve the match data in case called from a program.
	(save-match-data
	  (if (string-match "[ \t]*&[ \t]*\\'" command)
	      ;; Command ending with ampersand means asynchronous.
	      (let ((buffer (get-buffer-create
			     (or output-buffer "*Async Shell Command*")))
		    (directory default-directory)
		    proc)
		;; Remove the ampersand.
		(setq command (substring command 0 (match-beginning 0)))
		;; If will kill a process, query first.
		(setq proc (get-buffer-process buffer))
		(if proc
		    (if (yes-or-no-p "A command is running.  Kill it? ")
			(kill-process proc)
		      (error "Shell command in progress")))
		(with-current-buffer buffer
		  (setq buffer-read-only nil)
		  (erase-buffer)
		  (if (not silence) (display-buffer buffer))
		  (setq default-directory directory)
		  (setq proc (start-process "Shell" buffer shell-file-name
					    shell-command-switch command))
		  (setq mode-line-process '(":%s"))
		  (require 'shell) (shell-mode)
		  (set-process-sentinel proc 'shell-command-sentinel)
		  ))
	    (shell-command-on-region (point) (point) command
				     output-buffer nil error-buffer)))))))
;; Use: (shell-command-silent "du -sh &" "*du-output*" nil t)

;; ============================================================================

;; Background jobs
(when (require 'background nil t)
  )

(defalias 'shell-command-in-bg 'background)
;; (defun shell-command-in-bg (cmd)
;;   "Execute string CMD in inferior shell."
;;   (interactive "sShell Command: ")
;;   (background cmd)
;;   )

(define-key-after menu-bar-tools-menu [shell-in-bg]
  '(menu-item "Shell Command in background..." background
	      :help "Invoke a shell command in background and catch its output")
  'shell)

(defun shell-command-at (cmd &optional dir output-buffer error-buffer)
  "Execute string CMD at directory DIR in inferior shell."
  (interactive "sShell Command: \nDIn Directory: ")
  (shell-command (concat
                  (when dir (concat "cd " dir "; "))
                  cmd)
		 output-buffer error-buffer) ;
  )

(defun shell-command-silent-at (cmd &optional dir output-buffer error-buffer)
  "Execute string CMD at directory DIR in inferior shell."
  (interactive "sShell Command: \nDIn Directory: ")
  (shell-command-silent (concat
                         (when dir (concat "cd " dir "; "))
                         cmd)
			output-buffer error-buffer t)
  )

(defun shell-command-at-in-bg (cmd &optional dir)
  "Execute string CMD at directory DIR in background exterior shell."
  (interactive "sShell Command (in background): \nDIn Directory: ")
  (background (concat "cd " dir "; " cmd))
  )

(provide 'shell-command-ext)
