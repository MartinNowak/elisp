;;; pgo-ansi-color.el --- Setup ANSI Coloring Logic
;; Author: Per Nordlöw

(when (require 'ansi-color nil t))
;; SGR control sequences are defined in section 3.8.117 of the ECMA-48
;; standard (identical to ISO/IEC 6429), which is freely available as
;; a PDF file. The "Graphic Rendition Combination Mode (GRCM)"
;; implemented is "cumulative mode" as defined in section
;; 7.2.8. Cumulative mode means that whenever possible, SGR control
;; sequences are combined (ie. blue and bold).
;;; See: http://www.ecma-international.org/publications/standards/Ecma-048.htm
;; Installation for ls --color=yes in shell-mode

;; After installing the ansi-color EmacsLisp file, add the following
;; to your ~/.emacs file:

(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)

(when nil
  (add-hook 'eshell-preoutput-filter-functions 'ansi-color-filter-apply) ;remove from output
  (add-hook 'eshell-preoutput-filter-functions 'ansi-color-apply) ;very slow
  (when (require 'multi-eshell nil t))

  ;; M-x term and M-x ansi-term do their own hilighting. It makes no
  ;; sense to add ansi-color to these modes. If you still want to
  ;; investigate this, take a look at term-emulate-terminal. That is the
  ;; function where you would have to add your stuff.
  (defun visit-ansi-term ()
    "If we are in an *ansi-term*, rename it.
If there is no *ansi-term*, run it.
If there is one running, switch to that buffer."
    (interactive)
    (if (equal "*ansi-term*" (buffer-name))
        (call-interactively 'rename-buffer)
      (if (get-buffer "*ansi-term*")
          (switch-to-buffer "*ansi-term*" t)
        (ansi-term "/bin/bash"))))

  ;; For those of you using term mode in Emacs, this suggestion here
  ;; might be useful if you want to tinker with the colour scheme.
  ;; Basically you need to hook the following into term mode as
  ;; mentioned in the thread.
  ;; Redefine the 8 primary terminal colors to look good against black
  (setq ansi-term-color-vector [unspecified "#000000" "#963F3C" "#5FFB65" "#FFFD65"
                                            "#0082FF" "#FF2180" "#57DCDB" "#FFFFFF"])

  ;;; multi-term.el --- Multi term buffer.
  (when (require 'multi-term nil t)
    (setq multi-term-program "/bin/bash")
    )

  ;; tty-format.el --- text file backspacing and ANSI SGR as faces
  ;; See: http://user42.tuxfamily.org/tty-format/index.html
  (when (require 'tty-format nil t)
    ;;(add-hook 'find-file-hooks 'tty-format-guess)
    )

  )

(provide 'pgo-ansi-color)
