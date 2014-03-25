;;; gprof-utils.el --- Setup Interface to GNUs gprof.

(require 'faze)

(defun post-gprof (program &optional mon)
  "Gather Profile of PROGRAM with gprof.
MON optionally specify filename of monitor data."
  (interactive "fProfile program: ")
  (let ((mon (or mon "gmon.out")))
    (if (executable-find "gprof")
        (let* ((buf-name (concat "*gprof-" program "*"))
               (buf (get-buffer-create buf-name)))
          (with-current-buffer buf
            (setq buffer-read-only nil)
            (erase-buffer))
          ;; Call gprof
          (shell-command (concat "gprof " program " " mon) buf)
          (if (file-exists-p mon)
              (progn
                (display-buffer buf)
                (with-current-buffer buf
                  (buffer-disable-undo)
                  (buffer-enable-undo)
                  (setq buffer-read-only t)
                  (when (require 'gprof-mode nil t)
                    (gprof-mode))))
            (message "Could not generate profile because %s was not compiled with profiling code (GCC flag -pg)"
                     (faze program 'file)))
          ;; gprof2dot
          (when (and (executable-find "gprof2dot")
                     (executable-find "dot"))
            (let ((png-file (concat
                             (mktemp (concat "/tmp/"
                                             (file-name-sans-directory program)
                                             "-gprof2dot"))
                             ".png")))
              (shell-command (concat "gprof " program " " mon " | "
                                     (format "gprof2dot -w | dot -Tpng -o %s; xdg-open %s"
                                             png-file png-file))))))
      (message "Cannot profile because program gprof was not found")
      )))

(defun post-pprof (program mon)
  "Gather Profile of PROGRAM with google-pprof.
MON specify filename of monitor data."
  (interactive "fProfile program: ")
  (let ((exec (or (executable-find "google-pprof")
                  (executable-find "pprof"))))
    (if exec
        (let* ((buf-name (concat "*pprof-" program "*"))
               (buf (get-buffer-create buf-name)))
          (with-current-buffer buf
            (setq buffer-read-only nil)
            (erase-buffer))
          (shell-command (concat "pprof " program " " mon) buf)
          (if (file-exists-p mon)
              (progn
                (display-buffer buf)
                (with-current-buffer buf
                  (buffer-disable-undo)
                  (buffer-enable-undo)
                  (setq buffer-read-only t)
                  ))
            (message "Could not generate profile because monitor file % was not found " (faze mon 'file))))
      (message "Cannot profile because neither google-pprof nor pprof program was found")
      )))

(defun gprof-file (program)
  "Run and Gather Profile of PROGRAM with gprof."
  (interactive "fProfile program: ")
  (shell-command program)
  (post-gprof program))

(add-to-list 'auto-mode-alist '("\\.gprof\\'" . gprof-mode))
;;(global-set-key [(control c) (p)] 'gprof-file)
;; Add it to the "Tools" menu
(define-key-after menu-bar-tools-menu [gprof-file]
  '(menu-item "Profile (gprof)..." gprof-file
              :help "Profile a Program with gprof")
  'gdb)

(provide 'gprof-utils)
