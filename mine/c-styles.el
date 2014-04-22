;;; c-styles.el --- Setup CC Mode Styles.
;; Author: Per Nordlöw

;; Microsoft C,C++ Style
;; Here is a style that pretty much matches the observed style of
;; Microsoft (R)'s C and C++ code:
(c-add-style "microsoft"
             '("stroustrup"
               (c-offsets-alist
                (innamespace . -)
                (inline-open . 0)
                (inher-cont . c-lineup-multi-inher)
                (arglist-cont-nonempty . +)
                (template-args-cont . +))))

;; Style for OpenBSD source code, also valid for OpenSSH? and other
;; BSD based OSs source.
(c-add-style "openbsd"
             '("bsd"
               (indent-tabs-mode . t)
               (defun-block-intro . 8)
               (statement-block-intro . 8)
               (statement-case-intro . 8)
               (substatement-open . 4)
               (substatement . 8)
               (arglist-cont-nonempty . 4)
               (inclass . 8)
               (knr-argdecl-intro . 8)))

;; Linux Kernel C
;; This will define the M-x linux-c-mode command.  When hacking on a
;; module, if you put the string -*- linux-c -*- somewhere on the
;; first two lines, this mode will be automatically invoked. Also, you
;; may want to add
(defun linux-kernel-c-mode ()
  "C mode with adjusted defaults for use with the Linux kernel."
  (interactive)
  (c-mode)
  (c-set-style "K&R")
  (setq c-basic-offset 8)
  (setq c-font-lock-extra-types
        (append c-font-lock-extra-types
                '("__signed__" "__unsigned__"
                  "__u8" "__u16" "__u32" "__u64"
                  "__s8" "__s16" "__s32" "__s64"
                  "u8" "u16" "u32" "u64"
                  "s8" "s16" "s32" "s64"
                  "FILE" "\\sw+_t"))
        )
  )
(add-to-list 'auto-mode-alist
             '("/usr/src/linux.*/.*\\.[ch]\\'" . linux-kernel-c-mode))

(setq my-linux-style-path-alist (list (expand-file-name
                                       "~/src/version_control/sexy")))

(add-hook 'c-mode-hook (lambda ()
                         (dolist (path my-linux-style-path-alist)
                           (if (string-match path buffer-file-name)
                               (c-set-style "linux")))))

(when nil
  ;; When you have a long method name with long arguments, you would like to lay it out as follows:
  ;; public void veryLongMethodNameHereWithArgs(
  ;;                                            String arg1,
  ;;                                                   String arg2,
  ;;                                                   int arg3)
  ;; Here’s how to do it thanks to KnutForkalsrud? and KaiGrossjohann:
  (defun my-indent-setup ()
    (c-set-offset 'arglist-intro '+))
  (add-hook 'java-mode-hook 'my-indent-setup)
  ;; A very cool thing to do is automatically switching to that
  ;; behavior for long lines only.
  (defconst my-c-lineup-maximum-indent 30)

  (defun my-c-lineup-arglist (langelem)
    (let ((ret (c-lineup-arglist langelem)))
      (if (< (elt ret 0) my-c-lineup-maximum-indent)
          ret
        (save-excursion
          (goto-char (cdr langelem))
          (vector (+ (current-column) 8))))))

  (defun my-indent-setup ()
    (setcdr (assoc 'arglist-cont-nonempty c-offsets-alist)
            '(c-lineup-gcc-asm-reg my-c-lineup-arglist)))
  )

(require 'c-style-vtk nil t)

;; GStreamer C
(defun gstreamer-c-mode ()
  "C mode with adjusted defaults for use with GStreamer."
  (interactive)
  (c-mode)
  (c-set-style "K&R")
  (setq c-basic-offset 2))
(add-to-list 'auto-mode-alist
             '("gst.*/.*\\.[ch]\\'" . gstreamer-c-mode))

(provide 'c-styles)
