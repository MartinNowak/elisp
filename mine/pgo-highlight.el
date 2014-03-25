;; pgo-highlight.el --- Setup Highlighting of current Line, Column, etc.
;; Author: Per Nordlöw

;; Dectivated because this causes problem: old-read-from-minibuffer
(when nil
  (when (require 'highlight-completion nil t)
    (highlight-completion-mode -1)      ;I didn't find this that useful.
    ))
(when nil
  (when (require 'highlight-tail nil t)
    (highlight-tail-mode -1)  ;I didn't find this that useful, actually.
    ))

;; Highlights the current line
;; http://www.emacswiki.org/emacs-en/HighlightCurrentLine

;; WARNING: Previously made GDB interaction slow.  The hookery used
;; might affect response noticeably on a slow machine.  The local
;; mode may be useful in non-editing buffers such as Gnus or PCL-CVS
;; though.
(defcustom pnw/use-hl-line t
  "Flags whether or not to load hl-line-mode upon startup." :type 'boolean :group 'pnw-options)
(when pnw/use-hl-line
  (when (require 'hl-line nil t)
    (setq hl-line-sticky-flag t)
    ;;(global-hl-line-mode -1)
    ))

;; hl-line+.el --- Extensions to hl-line.el.
(when (require 'hl-line+ nil t)
  (hl-line-toggle-when-idle 1)         ;Turn it on
  (hl-line-when-idle-interval 0.5)      ;Note: I find 0.5 s optimal.
  )
;; hl-spotlight.el --- Extension of hl-line.el to spotlight current few lines.
(when nil
  (when (require 'hl-spotlight nil t)
    ))
;; hl-needed.el --- Turn on hl-needed mode when needed
(defcustom pnw/use-hl-needed nil
  "Flags whether or not to load hl-needed-mode upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-hl-needed
    (progn
      (when (require 'hl-needed nil t)
        (hl-needed-mode t)
        )))
;; highline.el --- minor mode to highlight current line in buffer
;; Note: Warning: Performance sucks and buffer flickers! DO NOT USE!
(defcustom pnw/use-highline nil
  "Flags whether or not to load highline-mode upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-highline
    (when (require 'highline nil t)
      (global-highline-mode t)
      ))
;; vline.el --- show vertical line mode.
;; See: http://www.emacswiki.org/cgi-bin/wiki/VlineMode
(defcustom pnw/use-vline nil
  "Flags whether or not to load vline-mode upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-vline
    (when (require 'vline nil t)
      (defalias 'global-vline-mode 'vline-global-mode)
      (vline-mode t)
      ))
;; Instead use this code.
(defcustom pnw/use-crosshairs nil
  "Flags whether or not to load crosshairs-mode upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-crosshairs
    (when (require 'crosshairs nil t)
      (crosshairs-mode -1)
      ))

;; ---------------------------------------------------------------------------
;; Highlight symbol at cursor

(defcustom pnw/use-light-symbol nil
  "Flags whether or not to load light-symbol upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-light-symbol
    (when (require 'light-symbol nil t)
      (setq light-symbol-face 'highlight-symbol-face) ;copy from highlight-symbol
      (light-symbol-mode nil))  ;disabled in place of highlight-symbol
  )

;; ---------------------------------------------------------------------------
;; highlight-symbol.el --- automatic and manual symbol highlighting
;; See: http://nschum.de/src/emacs/highlight-symbol/

(defcustom pnw/use-highlight-symbol nil
  "Flags whether or not to load highlight-symbol-mode upon startup."
  :type 'boolean :group 'pnw-options)

(if pnw/use-highlight-symbol
    (when (require 'highlight-symbol nil t)
      (defalias 'hl-symbol-mode 'highlight-symbol-mode)

      (when nil
        (defun hi-lock-font-lock-hook ()
          "Add hi-lock patterns to font-lock's."
          (if font-lock-mode
              (progn
                (font-lock-add-keywords nil hi-lock-file-patterns t)
                (font-lock-add-keywords nil hi-lock-interactive-patterns 'append))
            (hi-lock-mode -1)))
        )
      ))

;; ---------------------------------------------------------------------------
;; highlight-parentheses.el --- highlight surrounding parentheses
;; See: http://nschum.de/src/emacs/highlight-parentheses/
;; Note: Disabled because it make navigation really slow on large buffers!

(defcustom pnw/use-highlight-parentheses nil
  "Flags whether or not to load highlight-parentheses-mode upon startup."
  :type 'boolean :group 'pnw-options)

(if pnw/use-highlight-parentheses
    (when (require 'highlight-parentheses nil t)
      ;; (highlight-parentheses-mode 1)
      (dolist (hook '(c-mode-common-hook ada-mode-hook
                                         text-mode-hook outline-mode-hook
                                         lisp-mode-hook emacs-lisp-mode-hook
                                         sh-mode-hook
                                         octave-mode-hook matlab-mode-hook
                                         help-mode-hook info-mode-hook
                                         file-magic-mode-hook
                                         python-mode-hook
                                         proced-mode-hook))
        (add-hook hook (lambda () (highlight-parentheses-mode 1))))
      ))

;; Note: Emacs 23 has this in whitespace-mode so disable it.
(if nil (when (require 'highlight-80+ nil t))) ;highlight characters beyond column 80

;; ---------------------------------------------------------------------------

;; Highlight Changes
(when nil
  (add-hook 'c-mode-hook 'highlight-changes-mode)
  (defun my-highlight-changes-mode-hook ()
    (if highlight-changes-mode
        (add-hook 'write-file-functions 'highlight-changes-rotate-faces nil t)
      (remove-hook 'write-file-functions 'highlight-changes-rotate-faces t)
      ))
  (global-set-key '[C-right] 'highlight-changes-next-change)
  (global-set-key '[C-left]  'highlight-changes-previous-change)
  highlight-changes-mode
  highlight-changes-toggle-visibility
  highlight-changes-remove-highlight
  highlight-compare-with-file
  highlight-compare-buffers
  highlight-changes-rotate-faces
  )
;; Highlight the Current Sentence
(when (eload 'sentence-highlight))
;;; Highlight Current Symbol
(when (eload 'auto-highlight-symbol)
  (when (eload 'auto-highlight-symbol-config)
    (add-to-list 'ahs-modes 'matlab-mode t)
    (add-to-list 'ahs-modes 'octave-mode t)
    (add-to-list 'ahs-modes 'julia-mode t)
    (defadvice ahs-backward (after ahs-backward-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ahs-backward)
    (defadvice ahs-forward (after ahs-forward-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ahs-forward)
    (defadvice ahs-backward-definition (after ahs-backward-definition-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ahs-backward-definition)
    (defadvice ahs-forward-definition (after ahs-forward-definition-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'ahs-forward-definition)
    )
  (global-auto-highlight-symbol-mode -1) ;A bit annoying at times
  )
(when (require 'highlight-tail nil t)
  (highlight-tail-mode -1))

;; Displaying buffer changes with special face
(defcustom pnw/use-change-mode nil
  "Flags whether or not to load change-mode upon startup." :type 'boolean :group 'pnw-options)
(if pnw/use-change-mode
    (when (require 'change-mode nil t)
      ;;(change-mode 1)
      ;; Add it to the "Tools" menu
      (define-key-after menu-bar-options-menu [change-mode]
        `(menu-item "Highlight Changes" change-mode
                    :help "Highlight Changes made (Change Mode)"
                    :button  (:toggle . change-mode)
                    :visible t)
        'highlight-symbol-mode
        )
      ))
;;,(file-name-shadow-mode t)               ;Highlight `shadowed' part of read-file-name input text

(provide 'pgo-highlight)
