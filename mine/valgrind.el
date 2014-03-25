;;; valgrind.el - An Emacs Interface to the Valgrind Suite of Debugging Tools.
;; Author: Per Nordlöw <per.nordlow@gmail.com>

;; ============================================================================

;; ToDo: Make the flags `valgrind-flags-history'
;; depend on the `valgrind-tool-current' chosen.

(require 'filedb)

(defgroup valgrind nil
  "Valgrind."
  :group 'wp
  :prefix "valgrind-")

(defvar valgrind-tool-current "memcheck")

;; cachegrind:
;; is a cache simulator. It can be used to annotate every line of your
;; program with the number of instructions executed and cache misses
;; incurred.
;;
;; callgrind:
;; adds call graph tracing to cachegrind. It can be used to get call
;; counts and inclusive cost for each call happening in your
;; program. In addition to cachegrind, callgrind can annotate threads
;; separatly, and every instruction of disassembler output of your
;; program with the number of instructions executed and cache misses
;; incurred.
;;
;; helgrind:
;; spots potential race conditions in your program.
;;
;; lackey:
;; is a sample tool that can be used as a template for generating your
;; own tools. After the program terminates, it prints out some basic
;; statistics about the program execution.
;;
;; massif:
;; is a heap profiler. It measures how much heap memory your program uses.
;;
;; memcheck:
;; is a fine-grained memory checker.
(defvar valgrind-tool-alist '("cachegrind"
                              "callgrind"
                              "helpgrind"
                              "lackey"
                              "massif"
                              "memcheck"))
(defvar valgrind-tool-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'valgrind-tool-history t))

(defvar valgrind-massif-leak-check-current "full")
(defvar valgrind-massif-leak-check-alist '("no"
                                           "summary"
                                           "yes"
                                           "full"))

(defvar valgrind-flags-current "")
(defvar valgrind-flags-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'valgrind-flags-history t))

(defvar valgrind-flags-additional "")
(defvar valgrind-buffer nil)
(defvar valgrind-process nil)

(defun valgrind-sentinel (process event)
  (with-current-buffer valgrind-buffer
    (compilation-mode)))

(defun valgrind-run (&optional filename args)
  "Run the program PROGRAM through Valgrind with the Valgrind options FLAGS."
  (interactive (read-file-name-debuggable "Check (valgrind) program file" nil '(ELF)))

  (let (flags)

    ;; attach to debugger
    (when (y-or-n-p "Attach to Debugger? ")
      (setq flags (concat flags " --db-attach=yes"))
      (when (y-or-n-p "Use Embedded GDB (from valgrind version 3.7 and higher)? ")
        (setq flags (concat flags " --vgdb-error=0"))))

    (let ((completion-ignore-case t))
      (setq valgrind-tool-current
            (completing-read "Tool: "
                             valgrind-tool-alist nil t
                             valgrind-tool-current
                             'valgrind-tool-history
                             valgrind-tool-current)))

    ;; memcheck options
    (if (equal valgrind-tool-current "memcheck")
        (let ((completion-ignore-case t)
              (leak-check (completing-read "Leak Check: " valgrind-massif-leak-check-alist nil t
                                           valgrind-massif-leak-check-current
                                           nil
                                           valgrind-massif-leak-check-current)))
          (when (stringp leak-check)
            (setq flags (concat flags " --leak-check=" leak-check)))
          )
      )

    ;;massif options
    (if (equal valgrind-tool-current "massif")
        (let ((completion-ignore-case t))
          (let ((do-heap (y-or-n-p "Profile heap? "))
                (do-stack (y-or-n-p "Profile stack? ")))
            (if do-heap
                (let ((heap-admin (read-number "Number of administrative bytes per block?: " 8))
                      ))))))

    ;; additional flags
    (setq valgrind-flags-additional
          (read-from-minibuffer (concat "Additional Flags to " valgrind-tool-current ": ")
                                "" nil nil
                                'valgrind-flags-history))

    (setq valgrind-flags-current flags) ;save in global variable

    (if (executable-find "valgrind")
        (progn
          (switch-to-buffer "*Valgrind Output*" t)
          (setq buffer-read-only nil)
          (erase-buffer)

          ;; modes
          ;;(compilation-minor-mode)
          (when (compilation-shell-minor-mode);; See: http://www.mostlymaths.net/2010/02/debugging-with-emacsvalgrind.html
            (define-key compilation-minor-mode-map (kbd "")'comint-send-input)
            (define-key compilation-minor-mode-map (kbd "S-")'compile-goto-error))
          (compilation-mode)

          (let ((valgrind-command
                 (concat "valgrind"
                         " " "--tool=" valgrind-tool-current
                         (when flags
                           (concat " " flags))
                         (when valgrind-flags-additional
                           (concat " " valgrind-flags-additional))
                         " " filename
                         (when args
                           (concat " " (mapconcat 'identity args " ")))
                         )))
            (if t
                (compilation-start valgrind-command t)
              (setq valgrind-buffer "*Valgrind Output*")
              (setq valgrind-process
                    (start-process-shell-command "Valgrind"
                                                 valgrind-buffer
                                                 valgrind-command
                                                 ))
              (set-process-sentinel valgrind-process 'valgrind-sentinel)
              (run-with-timer 3 nil 'valgrind-sentinel nil nil))
            ))
      (message "Program executable \"valgrind\" not found"))))
(defalias 'run-valgrind 'valgrind-run)

(global-set-key [(control c) (v)] 'valgrind-run)

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [valgrind]
  '(menu-item "Simulate (Valgrind)..." valgrind-run
              :help "Run a program from within Emacs with Valgrind"))

;; Other Interface

(defvar valgrind-gdb-current "valgrind --db-attach=yes")

(defvar valgrind-gdb-history nil)
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'valgrind-gdb-history t))

(defun valgrind-gdb-run (&optional filename args)
  "Run the program PROGRAM through Valgrind and GDB."
  (interactive)
  (let ((program (or filename
                     (read-file-name "Program (to Valgrind): " nil nil nil nil
                                     'file-elf-p))))
    (let ((cmd (concat valgrind-gdb-current " " program
                       (when args
                         (concat " " (mapconcat 'identity args " "))))))
      (gdb (read-from-minibuffer "Run valgrind plus gdb (like this): "
                                 cmd nil nil
                                 'valgrind-gdb-history)))))

(global-set-key [(control c) (V)] 'valgrind-gdb)

;; Add it to the "Tools" menu
(define-key menu-bar-tools-menu [valgrind-gdb]
  '(menu-item "Simulate & Debug (Valgrind+GDB)..." valgrind-gdb
              :help "Run a program from within Emacs with Valgrind and GDB"))

(provide 'valgrind)
