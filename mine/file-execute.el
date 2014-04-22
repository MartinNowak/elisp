;;; file-dwim.el --- Execute (Buffer/File).

;; TODO: Add apitrace to trace OpenGL: https://github.com/apitrace/apitrace

;; TODO: Call setup_coredumps containing
;; ulimit -c 100000000;            # Dump all Segfaults smaller than 100 Megs
;; #COREDIR=/tmp/coredumps;         # /tmp/coredumps or $HOME/.cache/coredumps
;; if [ $COREDIR ]; then
;; export COREDIR;
;; if [ ! -e ${COREDIR} ] ; then
;; mkdir ${COREDIR}
;; fi
;; #chmod 777 ${COREDIR}
;; fi
;; echo "%e.%s.core" | sudo tee /proc/sys/kernel/core_pattern;

(provide 'file-execute)
(provide 'faze)

;; ---------------------------------------------------------------------------

;; Use: (locate-file-completion-table exec-path '("") "gcc" nil nil)

;;; TODO: Remove these variables and store these using dcache and fcache instead.
(defvar file-execute-args-last nil "Last Execute Arguments.")
(defvar file-execute-args-history nil "Execute Arguments History.")
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'file-execute-args-history t))

(defvar file-execute-last-process nil
  "Last process executed.")

(defvar file-execute-prog nil
  "Filename of program currently being executed.")

(defvar file-execute-pre-filter nil
  "Filename of program pre filter currently being executed.")

(defvar file-execute-args nil
  "Arguments of program currently being executed.")

(defvar file-execute-output-file nil
  "Filename of output of program currently being executed.")

;; SEE: http://www.delorie.com/gnu/docs/elisp-manual-21/elisp_614.html
(defun file-execute-completed (process event)
  "Called when execute process is finished."
  (let* ((pbuffer (process-buffer process))
         (pwindow (get-buffer-window pbuffer))
         (xfile (with-current-buffer pbuffer file-execute-prog))
         (id (process-id process))
         (status (process-status process))
         (exit-status (process-exit-status process))
         )
    (when (and (bufferp pbuffer)
               (buffer-live-p pbuffer))
      (display-buffer pbuffer)          ;display it
      (with-current-buffer pbuffer
        (setq buffer-read-only t)
        ;;(message "status:%s" status)
        (goto-char (point-min))         ;goto beginning

        ;; TODO: No effect probably because of a save-excursion somewhere. Use
        ;; `add-hook' or `defadvice' instead.

        ;; (goto-char (point-min))         ;goto beginning

        ;; TODO: Expand window height to half that of current frame.
        ;; (min (/ (frame-height) 2)
        ;;      (window-buffer-height (current-window pbuffer)))

        ;; (balance-windows pwindow)

        ;; (message "buf:%s" pbuffer)
        ;; (shrink-window-if-larger-than-buffer pwindow)
        ;; (fit-window-to-buffer pwindow (/ (frame-height) 2))
        ;;(delete-other-windows pwindow)
        ;;(dfsd)

        ;; (let* ((desired-height (/ (frame-height) 2))
        ;;        (delta (- desired-height
        ;;                  (window-height pwindow))))
        ;;   (message "delta:%s" delta)
        ;;   (save-excursion
        ;;     (save-selected-window (select-window pwindow)
        ;;                           (enlarge-window delta))))
        (shrink-window-if-larger-than-buffer
         (buffer-window pbuffer))

        (goto-char (point-min))         ;goto beginning

        ))
    (cond ((string-match "finished" event)
           (when xfile
             (message "Execution of %s finished %s"
                      (faze xfile 'file)
                      (faze "successfully" 'success)))
           ;; TODO: Display using GREEN in `mode-line'.
           (when (and (bufferp pbuffer)
                      (buffer-live-p pbuffer))
             (let* ((output-file (with-current-buffer pbuffer
                                   file-execute-output-file)))

               ;; post apitrace handling
               (when (with-current-buffer pbuffer
                       (and (string-equal file-execute-pre-filter "apitrace")
                            (y-or-n-p (format "View apitrace %s?" (faze output-file 'lfile)))))
                 (let ((output-buffer (concat "*apitrace-dump" xfile)))
                   (with-current-buffer (get-buffer-create output-buffer)
                     ;;(compilation-shell-minor-mode)
                     (setq buffer-read-only nil) (erase-buffer))
                   (let ((split-height-threshold 1)) ;force vertical split
                     (display-buffer output-buffer))
                   (start-process "apitrace-dump"
                                  output-buffer
                                  "apitrace" "dump" "--color=never"
                                  (concat "--arg-names=" (if (y-or-n-p "Dump argument names?") "yes" "no"))
                                  (concat "--thread-ids=" (if (y-or-n-p "Dump thread ids?") "yes" "no"))
                                  output-file)))

               ;; post gprof handling
               (let ((gmon (expand-file-name "gmon.out"
                                             (file-name-directory xfile))))
                 (when (and (require 'gprof-utils nil t)
                            (file-exists-p gmon))
                   (post-gprof xfile gmon)
                   ))

               ;; TODO: post gperftools handling

               )))
          ((string-match "exited abnormally with code \\([0-9]+\\)\n" event)
           ;; TODO: Display using `font-lock-warning-face' in `mode-line'.
           (message "Execution of %s finished with %s exitcode %s"
                    (faze xfile 'file)
                    (faze "abnormal" 'compilation-error)
                    (faze (string-to-number (match-string 1)) 'number)))
          ((or (eq status 'signal) ;SEE: https://en.wikipedia.org/wiki/Unix_signal
               (string-match "\\(.*\\) (core dumped)" event))
           (cond ((eq exit-status 19)   ;SIGSTOP
                  (when (y-or-n-p (format "Debug stopped process %s with id %s?"
                                          (faze process 'process)
                                          (faze id 'number)))))
                 ((or
                   (eq exit-status 1)   ;SIGHUP: Hangup
                   (eq exit-status 3)   ;SIGQUIT: Quit and dump core
                   (eq exit-status 4)   ;SIGILL: Illegal instruction
                   (eq exit-status 5)   ;SIGTRAP: Trace/breakpoint trap
                   (eq exit-status 7) ;SIGBUS: Bus error: "access to undefined portion of memory object"
                   (eq exit-status 8) ;SIGFPE: Floating point exception: "erroneous arithmetic operation"
                   (eq exit-status 9) ;SIGKILL: Kill (terminate immediately)
                   (eq exit-status 11)  ;SIGSEGV: Segmentation violation
                   )
                  ;; TODO: Display using `font-lock-alert-face' in `mode-line'.
                  (when (and (bufferp pbuffer)
                             (buffer-live-p pbuffer))
                    (with-current-buffer pbuffer
                      (if xfile
                          (let ((core (concat xfile ".11.core"))) ;TODO: First set this format in /proc/
                            (unless (file-exists-p core) ;if core file does not exists
                              (setq core "core")) ;default to standard naming
                            (when (and (file-exists-p core) ;if core file exists
                                       (y-or-n-p (format "Debug core dump of %s?" (faze xfile 'file))))
                              (file-debug-elf-core xfile core)
                              )
                            ;; (message "file-execute-completed: TODO: Call file-debug-single with core file %s"
                            ;;          core)
                            )
                        (warn "Symbol `file-execute-prog' is nil!")))))
                 (t
                  (message "file-execute-completed: TODO: Handle exit-status %s" exit-status))))
          (t
           (message "file-execute-completed: TODO: Handle %s" event)
           ))))

(defun read-file-execute-args (filename)
  "Read execution arguments of FILENAME."
  (let* ((prop :execute-args)
         (fcache (fcache-of filename))
         (history (fcache-get-property fcache prop)) ;recent history element
         (args
          (split-string
           (read-string (format "Execute %s with arguments: "
                                (faze (file-name-sans-directory filename) 'file))
                        nil 'history (car history)))
          ;; (multi-read-thing (format "Execute %s with arguments"
          ;;                           (faze (file-name-sans-directory filename) 'file))
          ;;                   nil nil nil nil history (car history))
          ))
    (when args                          ;store args
      (setq file-execute-args-last args)
      (add-to-list 'file-execute-args-history args) ;store in history
      (fcache-add-to-history-property fcache prop args))
    args))
;; Use: (read-file-execute-args "/bin/ls")
;; (fcache-get-property (fcache-of "/bin/ls") :execute-args)

(defun file-execute-without-filter (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "Execute program file"))
  (file-execute filename nil args nil compilation-window nil nil nil build-type working-directory))

(defun file-execute-through-strace (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "STrace program file"))
  (file-execute filename "strace" (delq nil (append
                                             '("-f") ;include forked processes
                                             args)) nil compilation-window nil nil nil build-type working-directory))

(defun file-execute-through-ltrace (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "LTrace program file"))
  (file-execute filename "ltrace"
                (delq nil (append
                           '("-f")      ;include forked processes
                           args))
                nil compilation-window nil nil nil build-type working-directory))

(defun file-execute-through-perf (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "Perf program file"))
  (let* ((cmds '("record"
                 "stat"))
         (cmd (completing-read "Perf command: " cmds nil nil nil nil (car cmds))))
    (file-execute filename (list "perf" cmd)
                  (delq nil args)
                  nil compilation-window nil nil nil build-type working-directory)
    (start-process "perf" "*perf-report*" (executable-find "perf") "report")
    ))

(defun file-execute-through-optirun (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "Optirun program file"))
  (file-execute filename "optirun" args nil compilation-window nil nil nil build-type working-directory))

(defun file-execute-through-oprofile-optirun (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "Oprofile-Optirun program file"))
  (file-execute filename (list "oprofile"
                               "optirun") args nil compilation-window nil nil nil build-type working-directory))

(defun file-execute-through-apitrace (filename build-type compilation-window working-directory &rest args)
  (interactive (read-file-name-debuggable "Apitrace program file"))
  (let* ((api (completing-read (format "Trace 3D Graphics API%s: "
                                       " (default gl)")
                               '("gl" "egl")
                               nil nil nil nil "gl"))
         (verbose (y-or-n-p "Verbose Output?"))
         (input-dir (file-name-directory filename))
         (output-file (concat
                  (if (file-writable-p input-dir)
                      (expand-file-name filename)
                    (let ((output-dir "~/.apitraces"))
                      (make-directory output-dir t)
                      (expand-file-name
                       (replace-regexp-in-string "/" "!" (expand-file-name filename))
                       output-dir)))
                  "." api "-trace")))
    (file-execute filename
                  (list "apitrace" "trace" (concat "--api=" api) (concat "--output=" output-file))
                  args
                  nil compilation-window nil nil output-file build-type working-directory)))
;; Use: (call-interactively 'file-execute-through-apitrace)
;; Use: (file-execute-through-apitrace (executable-find "/usr/bin/glxinfo"))
;; Use: (file-execute-through-apitrace (executable-find "~/tmp/glxinfo"))

(make-variable-buffer-local 'compilation-search-path)

(defun file-execute (filename &optional prefix args display-output compilation-window source-file threaded output-file build-type working-directory)
  "Execute FILENAME.
Optionally execute through the process PREFIX, typically \"[sl]trace\" or (PRE-FILTER-COMMAND PRE-FILTER-ARGS).
Optionally display output buffer if DISPLAY-OUTPUT is non-nil.
Optional COMPILATION-WINDOW gives the window where FILENAME was compiled."
  ;;(set (make-local-variable 'executable-command) command)
  ;; TODO: Use standard compilation mode if we are executing a Makefile or similar.
  ;; (let ((compilation-error-regexp-alist executable-error-regexp-alist))
  ;;   (compilation-start command t (lambda (x) (concat "*interpretation-" command "-" "*"))))
  (interactive (read-file-name-debuggable "Execute program file"))
  (let* ((filename (expand-file-name filename))
         (args (delq nil args))

         (pre-filter (if (listp prefix)
                         (car prefix)
                       prefix))
         (pre-filter-args (when (listp prefix)
                            (cdr prefix)))

         (fcache (fcache-of filename))
         (tag :working-directory)
         (fcached-working-directory-hist (fcache-get-tag fcache tag))
         (working-directory (if (eq working-directory 'ask)
                                (read-directory-name "Working Directory: " nil
                                                     (first fcached-working-directory-hist) t)
                              working-directory))

         (args (cond ((eq args 'skip)                   ;if args is `skip'
                      nil)                              ;don't ask for them
                     (args                              ;if args given
                      args)                             ;use them
                     (t                                 ;if no args given
                      (read-file-execute-args filename) ;ask for them
                      ))))
    (when (and fcache
               working-directory)
      (fcache-add-to-history-tag fcache tag working-directory))

    ;; See: http://www.haskell.org/ghc/docs/latest/html/users_guide/using-smp.html
    (when (and source-file
               (file-match source-file 'Haskell))
      (when threaded
        (setq args
              ;; Number of OS threads to map to Haskell logical threads.
              (append args `("+RTS"
                             ,(concat "-N" (number-to-string
                                            (read-number "Number of OS threads to use: " compilation-jobs-count)))
                             "-RTS")))
        ;; TODO: Use ghc flag -sstderr and ask to trigger call of ThreadScope
        )        )

    (when compilation-window (delete-window compilation-window)) ;hide compilation-window if visible

    ;; do it
    (cond
     ((file-executable-p filename)      ;if filename is executable
      ;; just execute it
      (let* ((default-directory
               (or working-directory
                   (file-name-directory filename) ;go to directory containing l`filename'
                   default-directory))
             (buffer-name (concat "*" (or pre-filter "exec") "-*" filename)))
        ;; setup buffer used by `start-process' below
        (save-current-buffer
          (set-buffer (get-buffer-create buffer-name)) ;switch to exec buffer
          (setq buffer-read-only nil)   ;make it writeable for now
          (erase-buffer)                ;empty it

          ;; major mode
          (if (and (stringp pre-filter)
                   (string-equal pre-filter "strace")
                   (require 'strace-mode nil t))
              (progn
                (setq pre-filter-args
                      (append pre-filter-args
                              '("-tt")  ;timestamp
                              ;; TODO: Lookup all commands called by ELF filename
                              (let ((types (multi-read-thing "Trace" nil nil nil nil nil "all"
                                                             '("file"

                                                               "execve"
                                                               "access"
                                                               "mmap" "mprotect"
                                                               "rt_sigaction" "rt_sigprocmask"
                                                               "getrlimit"
                                                               "brk"
                                                               "ioctl"
                                                               "fcntl"
                                                               "getdents"
                                                               "set_tid_address" "set_robust_list"
                                                               "futex"
                                                               "open" "openat" "close"
                                                               "stat" "stat64" "statfs" "lstat" "chmod"
                                                               "link" "linkat" "unlink"
                                                               "read" "write"

                                                               "process"

                                                               ;; Network
                                                               "network"
                                                               "socket" "connect" "getpeername" "getsockname"
                                                               "sendto" "sendmsg" "recvmsg"

                                                               "signal"
                                                               "ipc"
                                                               "desc"
                                                               "all"
                                                               "none"
                                                               ))))
                                (list "-e" (concat "trace="
                                                   (mapconcat 'identity types ","))))))
                (strace-mode))          ;colorize strace output
            (comint-mode))              ;so we can interact with prompts.

          ;; minor modes
          (compilation-shell-minor-mode)
          ;;(compilation-mode)

          ;; Store states
          (set (make-local-variable 'file-execute-prog) filename) ;"store" program
          (set (make-local-variable 'file-execute-pre-filter) pre-filter) ;"store" pre-filter
          (set (make-local-variable 'file-execute-args) args) ;"store" arguments
          (when (string-equal pre-filter "apitrace")
            (set (make-local-variable 'file-execute-output-file) output-file))

          ;; start the process
          (when (and file-execute-last-process
                     (memq (process-status file-execute-last-process)
                           '(run stop open listen closed connect failed)))
            (when (y-or-n-p (message "Kill last execution of %s?" (faze file-execute-prog 'file)))
              (kill-process file-execute-last-process)))

          ;; (when (string-equal pre-filter "strace")
          ;;   (setq args (append args
          ;;                      '(">/dev/null"))))

          (let* ((basename (file-name-sans-extension filename))
                 (process-environment (if (string-equal build-type "GPerfTools-Profile")
                                          (append
                                           ;; See https://google-perftools.googlecode.com/svn/trunk/doc/heap_checker.html#types
                                           (let ((heapcheck (completing-read "Heapcheck: " '("none"
                                                                                             "minimal"
                                                                                             "normal"
                                                                                             "strict"
                                                                                             "draconian")
                                                                             nil t nil nil "normal")))
                                             (unless (string-equal heapcheck "none")
                                               (list (concat "HEAPCHECK=" heapcheck))))
                                           ;; See https://google-perftools.googlecode.com/svn/trunk/doc/heapprofile.html
                                           (list (concat "HEAPPROFILE=" basename ".heapprofile"))
                                           ;; See https://google-perftools.googlecode.com/svn/trunk/doc/cpuprofile.html
                                           (list (concat "CPUPROFILE=" basename ".cpuprofile"))
                                           process-environment)
                                        process-environment)))
            (setq file-execute-last-process (eval
                                             (if pre-filter
                                                 `(start-file-process ,(concat "exec-"
                                                                               pre-filter
                                                                               (when pre-filter-args
                                                                                 (concat "-" (car pre-filter-args)))
                                                                               "-" filename)
                                                                      ,buffer-name
                                                                      ,pre-filter
                                                                      ,@pre-filter-args ,filename ,@args)
                                               `(start-file-process ,(concat "exec-"
                                                                             filename)
                                                                    ,buffer-name
                                                                    ,filename
                                                                    ,@args))))
            (set-process-sentinel file-execute-last-process
                                  'file-execute-completed)) ;set completion callback
          )

        (let ((split-height-threshold 1)) ;force vertical split
          (display-buffer buffer-name))
        (with-current-buffer buffer-name
          (compilation-minor-mode 1)
          (setq compilation-search-path '("./" "../" "../../")))))
     (t                                 ;if not executable run xdg-open on it
      (case window-system
        (x
         (let ((default-directory (or (file-name-directory filename)
                                      default-directory)))
           (eval `(start-process ,(concat "xdg-open-" filename)
                                 ,(concat "*xdg-open-" filename "*")
                                 "xdg-open" filename ,@args))))
        (win32
         (when (fboundp 'w32-shell-execute)
           (w32-shell-execute "open" (convert-standard-filename filename))))
        )))))
;; Use: (file-execute "~/bin/wc.d")
;; Use: (file-execute "/bin/ls" "strace")
;; Use: (file-execute "/bin/ls" "ltrace")
;; Use: (file-execute "/usr/bin/evince" "strace")
;; Use: (file-execute"~/Skrivbord/HardLinkShellExt_win32.exe")

(defun pbuild (&optional prefix args display-output compilation-window source-file threaded output-file build-type)
  "Run pbuild."
  (interactive)
  (file-execute (expand-file-name "~/bin/pbuild")
                prefix args display-output compilation-window source-file threaded output-file build-type))

(global-set-key [(control c) (x)] 'file-execute)
(global-set-key [(control c) (X)] 'file-reexecute)
