;;; oprofile.el --- An Emacs Interface to the OProfile Profiling tool.
;; Description: An Emacs Interface to the OProfile Profiling tool.

(require 'filedb)
(require 'auto-deb)

(defgroup oprofile nil
  "Oprofile."
  :group 'wp
  :prefix "oprofile-")

(defvar oprofile-program-history nil
  "History of programs that are currently registered for
profiling by OProfile.")
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'oprofile-program-history t))

(defvar oprofile-last-program nil
  "Recent program last registered for profiling by OProfile.")

(defvar oprofile-oreports-directory "opreports"
  "Local Directory name to save oreports inside.")

(defvar oprofile-default-calldepth 6
  "Default Call Depth for Profiling.")

(defcustom file-oprofileable-p 'file-elf-p
  "Predicate that filters out files that Oprofile can run."
  :group 'oprofile)

(defun oprofile-read-last-program (prompt filename)
  "Read program named FILENAME from disk using PROMPT."
  (let ((dir (if filename (file-name-directory filename) nil))
	(file (if filename (file-name-nondirectory filename) nil))
	)
    (read-file-name prompt dir nil nil file 'file-oprofileable-p)))

;;; TODO: Support `args'.
(defun oprofile-start-single (&optional filename args)
  "Start profiling a program with OProfile."
  (interactive)
  (let ((program (or filename
                     (oprofile-read-last-program "Program (to oprofile): "
                                                 oprofile-last-program)))
        (cg-depth (read-number "Callgraph Depth: " oprofile-default-calldepth))
        )
    (if (executable-find-auto-install-on-demand "opcontrol")
        (save-excursion
          (shell)
          (insert "sudo opcontrol --init; ") ;insert kernel module
          (comint-send-input)

          (insert (concat "sudo opcontrol" " "
                          "--shutdown; " ;shutdown profiling
                          ))
          (comint-send-input)

          (insert (concat "sudo opcontrol" " "
                          "--no-vmlinux" " " ;no kernel profiling
                          "--image=" (expand-file-name program) " " ;program to profile
                          "--callgraph=" (number-to-string cg-depth) " "
                          "--start; "	;start profiling
                          ))
          (comint-send-input)

          (setq oprofile-last-program program)
          (add-to-list 'oprofile-program-history oprofile-last-program)
          )
      (message "Cannot profile because OProfile (opcontrol) was not found."))))
(defalias 'run-oprofile 'oprofile-start-single)

(defun oprofile-start-all ()
  "Start profiling all processes with OProfile."
  (interactive)
  (let ((cg-depth (read-number "Callgraph Depth: " oprofile-default-calldepth))
	)
    (if (executable-find-auto-install-on-demand "opcontrol")
	(save-excursion
	  (shell)
	  (insert "sudo opcontrol --init; ") ;insert kernel module
	  (comint-send-input)

	  (insert (concat "sudo opcontrol" " "
			  "--shutdown; " ;shutdown profiling
			  ))
	  (comint-send-input)

	  (insert (concat "sudo opcontrol" " "
			  "--no-vmlinux" " " ;no kernel profiling
			  "--image=all" " "  ;profile all
			  "--callgraph=" (number-to-string cg-depth) " "
			  "--start; "	;start profiling
			  ))
	  (comint-send-input)

	  (setq oprofile-last-program nil) ;indicate that all processes are profiled.
	  )
      (message "Cannot profile because OProfile (opcontrol) was not found."))))

(defun oprofile-dump ()
  "Dump current profiling with OProfile."
  (interactive)
  (if (executable-find-auto-install-on-demand "opcontrol")
      (save-excursion
	(shell)
	(insert "sudo opcontrol --dump; ")
	(comint-send-input)
	)
    (message "Cannot profile because OProfile (opcontrol) was not found.")))

(defun oprofile-stop ()
  "Stop current profiling with OProfile."
  (interactive)
  (if (executable-find-auto-install-on-demand "opcontrol")
      (save-excursion
	(shell)
	(insert "sudo opcontrol --dump; ")
	(insert "sudo opcontrol --stop; ")
	(comint-send-input)
	)
    (message "Cannot profile because OProfile (opcontrol) was not found.")))

(defun oprofile-reset ()
  "Reset current profiling with OProfile."
  (interactive)
  (if (executable-find-auto-install-on-demand "opcontrol")
      (save-excursion
	(shell)
	(insert "sudo opcontrol --reset; ")
	(comint-send-input)
	;; 	(setq oprofile-program-history nil
	;; 	      oprofile-last-program nil) ;empty state
	)
    (message "Cannot profile because OProfile (opcontrol) was not found.")))

(defun oprofile-shutdown ()
  "Shutdown profiler OProfile."
  (interactive)
  (if (executable-find-auto-install-on-demand "opcontrol")
      (save-excursion
	(shell)
	(insert "sudo opcontrol --shutdown; ")
	(comint-send-input)
	)
    (message "Cannot profile because OProfile (opcontrol) was not found.")))

(defun oprofile-report (program flags)
  "Produce OProfile report (opreport)."
  (if (executable-find-auto-install-on-demand "opcontrol")
      (let ((new-buffer (concat "*oprofile-" (if program program "all") "*")))
	(shell-command (concat "opreport " flags) new-buffer)
	(switch-to-buffer new-buffer t)
	(delete-other-windows)
	(buffer-disable-undo)
	(buffer-enable-undo)
	(setq buffer-read-only t)
	(when (require 'oprofile-mode nil t)
          (oprofile-mode))
	)
    (message "Cannot report because OProfile (opreport) was not found.")))

(defun oprofile-report-relative ()
  "Produce OProfile report (opreport) with relative times."
  (interactive)
  (let ((program (if oprofile-last-program
		     (read-file-name "Program (to oprofile): "
				     oprofile-last-program
				     nil nil
				     oprofile-last-program
				     'file-oprofileable-p) nil)
		 ))
    (oprofile-report program "--callgraph --long-filenames")))

(defalias 'opreport-relative 'oprofile-report-relative)

(defun oprofile-report-absolute ()
  "Produce OProfile report (opreport) with absolute times."
  (interactive)
  (let ((program (if oprofile-last-program
		     (read-file-name "Program (to oprofile): "
				     oprofile-last-program
				     nil nil
				     oprofile-last-program
				     'file-oprofileable-p) nil)
		 ))
    (oprofile-report program "--callgraph --long-filenames -%")))

(defalias 'opreport-absolute 'oprofile-report-relative)

(defun oprofile-save-session (session-name)
  "Save the current OProfile session as SESSION-NAME."
  (interactive "sSession name: ")
  (if (executable-find-auto-install-on-demand "opcontrol")
      (save-excursion
	(shell)
	(insert "sudo opcontrol --save=" session-name "; ")
	(comint-send-input)
	)
    (message "Cannot profile because OProfile (opcontrol) was not found.")))

(defun oprofile-write-session-to-file (program)
  "Write the OProfile of PROGRAM to file."
  (let ((dir
	 (if program
	       (file-name-directory program))))
    (expand-file-name oprofile-oreports-directory)
    (concat program (format-time-string "%Y%m%d-%H:%M:%S") ".opreport")
    ))

(progn
  (global-set-key [(control c) (o) (b)] 'oprofile-start-single)
  (global-set-key [(control c) (o) (B)] 'oprofile-start-all)
  (global-set-key [(control c) (o) (e)] 'oprofile-stop)
  (global-set-key [(control c) (o) (d)] 'oprofile-dump)
  (global-set-key [(control c) (o) (r)] 'oprofile-reset)
  (global-set-key [(control c) (o) (q)] 'oprofile-shutdown)
  (global-set-key [(control c) (o) (a)] 'oprofile-report-absolute)
  (global-set-key [(control c) (o) (R)] 'oprofile-report-relative)
  (global-set-key [(control c) (o) (w)] 'oprofile-write-session-to-file)

  ;; (global-set-key [(control f10)] 'oprofile-start-single)
  ;; (global-set-key [(control f11)] 'oprofile-stop)
  ;; (global-set-key [(control f12)] 'oprofile-report-absolute)
  )

;; Menu Bar stuff

;;;###autoload
(defvar menu-bar-oprofile-menu
  (let ((m (make-sparse-keymap "OProfile")))
    (define-key m [shutdown]
      '(menu-item "Shutdown Profiling" oprofile-shutdown
		  :help "Shutdown the OProfile daemon"))
    (define-key m [report-relative]
      '(menu-item "Report Profile (rel)..." oprofile-report-relative
		  :help "Fetch a Report from OProfile daemon with relative times and put into a buffer"))
    (define-key m [report-absolute]
      '(menu-item "Report Profile (abs)..." oprofile-report-absolute
		  :help "Fetch a Report from OProfile daemon with absolute times and put into a buffer"))
    (define-key m [dump]
      '(menu-item "Dump the current profiling" oprofile-dump
		  :help "Signal OProfile daemon to Dump profiling"))
    (define-key m [stop]
      '(menu-item "Stop the current profiling" oprofile-stop
		  :help "Signal OProfile daemon to Stop profiling"))
    (define-key m [reset]
      '(menu-item "Reset Profiling" oprofile-reset
		  :help "Signal OProfile daemon to Reset profiling"))
    (define-key m [all]
      '(menu-item "Start Profiling all Processes..." oprofile-start-all
		  :help "Signal OProfile daemon to Start profiling all processes"))
    (define-key m [start]
      '(menu-item "Start Profiling a Single Process..." oprofile-start-single
		  :help "Signal OProfile daemon to Start profiling a specific binary (process)"))
    (fset 'menu-bar-oprofile-menu m)))

;; Add it to the "Tools" on the Emacs top menu bar.
(define-key-after menu-bar-tools-menu [oprofile]
  '(menu-item "OProfile" menu-bar-oprofile-menu) 'gdb)

(provide 'oprofile)
