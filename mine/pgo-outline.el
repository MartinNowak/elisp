;;; pgo-outline.el --- Setup Outline Mode and Its Extensions.

(when (require 'outline nil t)
  ;; See: http://groups.google.com/group/gnu.emacs.help/browse_thread/thread/d3bd34d73aa700cd/c60db09e63d8dc8d#c60db09e63d8dc8d
  (let ((func (lambda () (outline-minor-mode 1))))
    (dolist (hook '(c-mode-common-hook
                    text-mode-hook
                    lisp-mode-hook
                    emacs-lisp-mode-hook
                    sh-mode-hook
                    ada-mode-hook
                    octave-mode-hook
                    matlab-mode-hook
                    help-mode-hook
                    Info-mode-hook
                    python-mode-hook
                    latex-mode-hook
                    LaTeX-mode-hook
                    ))
      (add-hook hook func)))

  (setq outline-minor-mode-prefix "\C-c\C-o")

  (progn
    (define-prefix-command 'ol-map nil
      (if t
          "Outline: Hide-[q,t,o,c,l,d], Show-[a,e,i,k,s], Move-[u,n,p,f,b,^,v,<,>,RET]"
        "Outline:\n  - Hide-[q,t,o,c,l,d]\n  - Show-[a,e,i,k,s]\n  - Move-[u,n,p,f,b,^,v,<,>,RET]"))
    (global-set-key [(shift meta o)] ol-map)
    (unless (keymapp ol-map) (setq ol-map (make-sparse-keymap)))

    (progn
      ;; HIDE
      (define-key ol-map "q" 'hide-sublevels) ; Hide everything but the top-level headings
      (define-key ol-map "t" 'hide-body) ; Hide everything but headings (all body lines)
      (define-key ol-map "o" 'hide-other) ; Hide other branches
      (define-key ol-map "c" 'hide-entry) ; Hide this entry's body
      (define-key ol-map "l" 'hide-leaves) ; Hide body lines in this entry and sub-entries
      (define-key ol-map "d" 'hide-subtree) ; Hide everything in this entry and sub-entries
      ;; SHOW
      (define-key ol-map "a" 'show-all)   ; Show (expand) everything
      (define-key ol-map "e" 'show-entry) ; Show this heading's body
      (define-key ol-map "i" 'show-children) ; Show this heading's immediate child sub-headings
      (define-key ol-map "k" 'show-branches) ; Show all sub-headings under this heading
      (define-key ol-map "s" 'show-subtree) ; Show (expand) everything in this heading & below
      ;; MOVE
      (define-key ol-map "u" 'outline-up-heading)               ; Up
      (define-key ol-map "n" 'outline-next-visible-heading)     ; Next
      (define-key ol-map "p" 'outline-previous-visible-heading) ; Previous
      (define-key ol-map "f" 'outline-forward-same-level) ; Forward - same level
      (define-key ol-map "b" 'outline-backward-same-level) ; Backward - same level

      (define-key ol-map "^" 'outline-move-subtree-up)
      (define-key ol-map "v" 'outline-move-subtree-down)
      (define-key ol-map [?<] 'outline-promote)
      (define-key ol-map [?>] 'outline-demote)
      (define-key ol-map "\C-m" 'outline-insert-heading)
      ;; Where to bind outline-cycle ?
      )
    )

  (add-hook 'outline-mode-hook
            (lambda ()
               (setq fill-column 79)
               (abbrev-mode t)
               (turn-off-auto-fill)
               ))

  (require 'outline-ext nil t)

  ;; outline-magic.el --- outline mode extensions for Emacs
  (when (require 'outline-magic nil t)
    (add-hook 'outline-mode-hook
              (lambda () (require 'outline-magic nil t)))
    (add-hook 'outline-minor-mode-hook
              (lambda () (require 'outline-magic nil t)
;;;                 (define-key outline-minor-mode-map [(f10)] 'outline-cycle)
;;;                 (define-key outline-minor-mode-map [(? )] 'outline-cycle)
                )))
  )

(provide 'pgo-outline)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pgo-outline.el ends here
