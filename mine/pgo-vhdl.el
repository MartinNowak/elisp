;;; pgo-vhdl.el --- Setup VHDL Mode.
;; Author: Per Nordlöw

;; See: http://www.iis.ee.ethz.ch/~zimmi/emacs/vhdl-mode.html

;;(byte-recompile-directory (elsub "vhdl-mode/") 0 t)

(append-to-load-path (elsub "vhdl-mode"))
(autoload 'vhdl-mode "vhdl-mode" "VHDL Mode" t)
(add-to-list 'auto-mode-alist '("\\.vhdl?\\'" . vhdl-mode))

(defun vhdl-beautify-this-block ()
  "Beautify a block. A block is deliminited with an empty line.
If the region is active beautify the marked region. The beautification
is done via vhdl-beautify-region."
  (interactive)
  (save-excursion
    (let ((block-sep "\n[ \t]*\n")
          (beg)
          (end))
      (if (use-region-p)
          (progn
            (setq beg (region-beginning))
            (setq end (region-end)))
        (re-search-backward block-sep (point-min))
        (next-line 2)
        (beginning-of-line)
        (setq beg (point))
        (re-search-forward block-sep (point-max))
        (next-line -1)
        (setq end (point)))
      (vhdl-beautify-region beg end))))


(defun vhdl-finish-statement ()
  (interactive)
  (let ((indent (- (current-indentation) 2))
        (pos (point))
        (insert-string))
    (save-excursion
      (beginning-of-line -0)
      (while (and (not (bobp))
                  (or (looking-at "^\\s-*\\(--.*\\)?$")
                      (> (current-indentation) indent)))
        (beginning-of-line -0))
      (if (= (current-indentation) indent)
          (progn
            (back-to-indentation)
            (cond ((looking-at "\\(if\\|else\\|elsif\\) ")
                   (message "looking-at if")
                   (setq insert-string "end if;"))))))
    (when insert-string
      (back-to-indentation)
      (insert insert-string)
      (indent-according-to-mode)
      (insert "\n")
      (indent-according-to-mode))))

;;(defvar vhdl-actual-port-name '(".*" . "\\&_i"))
(defun vhdl-set-actual-port-name-postfix (postfix)
  (interactive "sPortname Postfix: ")
  (setq vhdl-actual-port-name (cons ".*" (concat "\\&" postfix))))

                                        ;(define-key vhdl-mode-map "\C-c]" 'vhdl-finish-statement)

(defvar compilation-file-regexp-alist nil) ;avoid a waring on the first call to vhdl-save-and-compile
(defvar vhdl-sim-directory "./" "vhdl simulation directory")
(defvar vhdl-compiler-options "-93 -quiet" "vhdl compiler options")
(defun vhdl-save-and-compile ()
  "Saves the buffer and starts the modelsim compiler vcom.
If the file vhdl-project.el exists this is evalueated first.
If C-u is given as prefix argument: the command line can be edited."
  (interactive)
  (vhdl-compile-init)
  (save-buffer)
  (when (file-exists-p "vhdl-project.el")
    (load (expand-file-name "vhdl-project.el")))
  (let* ((options vhdl-compiler-options)
         (default-directory (expand-file-name vhdl-sim-directory))
         (file-name buffer-file-name)
         (command "vcom")
         (before-compile-cmd (concat "cd " default-directory " && "))
         (cmd-line (concat before-compile-cmd command " " options " \"" file-name "\"")))
    (when (equal current-prefix-arg '(4))
      (setq cmd-line (read-string "Compile cmd: " cmd-line)))
    (compile cmd-line)))

                                        ;-- vhdl-sim-directory: "../../sim/"
                                        ;-- vhdl-compiler-options: "-93 -quiet"

(defun vhdl-activate-new-font-lock-settings ()
  (interactive)
                                        ;(normal-mode)
  (hack-local-variables)
  (vhdl-font-lock-init)
  (vhdl-fontify-buffer))
                                        ;-- vhdl-special-syntax-alist: (("type" "T_\\w+" "ForestGreen" "ForestGreen") ("constant" "C_\\w+" "DarkGoldenrod" "DarkGoldenrod"))

                                        ;28.09.2001
(defun xsteve/vhdl-electric-return ()
  "newline-and-indent or indent-new-comment-line if in comment and preceding
character is a space."
  (interactive)
  (if (and (= (preceding-char) ? ) (vhdl-in-comment-p))
      (indent-new-comment-line)
    (when (and (>= (preceding-char) ?a) (<= (preceding-char) ?z))
      (vhdl-fix-case-word -1))
    (reindent-then-newline-and-indent)))


(defvar vhdl-modelsim-server nil "modelsim socket connection")
(defun vhdl-modelsim-server-connect ()
  (interactive)
  (unless vhdl-modelsim-server
    (setq vhdl-modelsim-server (open-network-stream "modelsim" "*modelsim*" "localhost" 9005))
    (message "modelsim-server connected")))

(defun vhdl-modelsim-server-disconnect ()
  (interactive)
  (when vhdl-modelsim-server
    (delete-process vhdl-modelsim-server)
    (setq vhdl-modelsim-server nil)
    (message "modelsim-server disconnected")))

(defun vhdl-modelsim-server-reconnect ()
  (interactive)
  (vhdl-modelsim-server-disconnect)
  (vhdl-modelsim-server-connect))

(defvar vhdl-modelsim-point nil)
(defun vhdl-modelsim-server-send(cmd)
  (interactive "sModelsim cmd: ")
  (unless vhdl-modelsim-server
    (if (y-or-n-p "Modelsim Connection not established. Open a connection? ")
        (vhdl-modelsim-server-connect)))
  (when vhdl-modelsim-server
    (condition-case nil
        (save-window-excursion
          (switch-to-buffer "*modelsim*")
          (goto-char (point-max))
          (insert ">> " cmd "\n")
          (setq vhdl-modelsim-point (point-max))
          (set-marker (process-mark (get-buffer-process (current-buffer))) (point-max))
          (process-send-string "modelsim" (concat cmd "\n")))
      (error (progn
               (setq vhdl-modelsim-server nil))))))

(defun vhdl-modelsim-server-getresponse(&optional delay)
  (interactive)
  (save-window-excursion
    (switch-to-buffer "*modelsim*")
    (sit-for (or delay 0.4))
    (let ((response (buffer-substring-no-properties vhdl-modelsim-point (point-max))))
      (setq response (dired-string-replace-match "\n" response "" nil t))
      response)))


(defun vhdl-modelsim-server-activate-and-send(cmd)
  (interactive "sModelsim cmd: ")
  (when win32-p
    (sww "ModelSim")
    (sww "fastcmd"))
  (vhdl-modelsim-server-send cmd))

                                        ;13.04.2000 - show connection status with ModelSim
(if (not (assq 'vhdl-modelsim-server minor-mode-alist))
    (setq minor-mode-alist
          (cons '(vhdl-modelsim-server " ModelSim")
                minor-mode-alist)))


                                        ;(vhdl-modelsim-server-activate-and-send "sim_syncwrapper; run 8000")
(defvar vhdl-modelsim-cmd "" "modelsim command to use for simulation")
(defvar vhdl-modelsim-cmd-history nil "modelsim command history")
(when (require 'desktop nil t) (add-to-list 'desktop-globals-to-save 'vhdl-modelsim-cmd-history t))
(defvar vhdl-modelsim-last-cmd nil "the last command sent to modelsim")

                                        ;(setq vhdl-modelsim-cmd "sim_irda_test1; run 8000")
                                        ;(setq vhdl-modelsim-cmd '(("sim hac". "vsim hac; run 100") ("sim rtl". "vsim rtl; run 100")))
                                        ;(setq vhdl-modelsim-cmd '("vsim hac; run 100" "vsim rtl; run 100"))

(defun vhdl-modelsim-server-send-fast-command(force-ask)
  "Send `vhdl-modelsim-cmd' to the vhdl simulator.
When called with a prefix argument, ask the user, which command to execute,
if `vhdl-modelsim-cmd' is a list."
  (interactive "P")
  (when (file-exists-p "vhdl-project.el")
    (load (expand-file-name "vhdl-project.el")))
  (let ((cmd (if (listp vhdl-modelsim-cmd)
                 (if (or force-ask (not vhdl-modelsim-last-cmd))
                     (ido-completing-read "Select Modelsim command: "  vhdl-modelsim-cmd nil nil
                                          (car vhdl-modelsim-cmd-history) 'vhdl-modelsim-cmd-history)
                   vhdl-modelsim-last-cmd)
               vhdl-modelsim-cmd)))
    (when (listp vhdl-modelsim-cmd)
      (setq cmd (or (cdr (assoc cmd vhdl-modelsim-cmd)) cmd)))
    (setq vhdl-modelsim-last-cmd cmd)
    (message "sending vsim command: '%s'" cmd)
    (vhdl-modelsim-server-activate-and-send cmd)))

(defun vhdl-beautify-write-file-hook ()
  "See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/a7e2048a66d8c6e2#"
  (interactive)
  (when (eq major-mode 'vhdl-mode)
    (vhdl-beautify-buffer)
    (untabify (point-min) (point-max))))
;;(add-hook 'before-save-hook 'vhdl-beautify-write-file-hook))

(provide 'pgo-vhdl)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-vhdl.el ends here
