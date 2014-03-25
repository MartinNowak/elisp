(when (require 'linkd nil t)
  ;; icons
  (setq linkd-use-icons t)
  (setq linkd-icons-directory
        (elsub "linkd-icons/")) ;; or wherever you put it
  ;; You can set up linkd-mode to turn on automatically whenever you
  ;; enter certain major modes. Here is an example that causes linkd-mode
  ;; to activate whenever you open an
  ;; Emacs Lisp, Common Lisp, shell-script, or text-mode file:
  (add-hook 'lisp-mode-hook 'linkd-mode)
  (add-hook 'emacs-lisp-mode-hook 'linkd-mode)
  ;;(add-hook 'lisp-mode-hook 'linkd-mode)
  ;;(add-hook 'sh-mode-hook 'linkd-mode)
  ;;(add-hook 'text-mode-hook 'linkd-mode)
  ;; Linkd-mode's keybindings follow the standard conventions for minor
  ;; modes: C-c followed by one of a set of reserved punctuation
  ;; characters. For speed, I rebind some of them as follows:
  ;;       (global-set-key [(control \&)] 'linkd-follow-on-this-line)
  ;;       (global-set-key [(control f3)] 'linkd-process-block)
  ;;       (global-set-key (kbd "M-[") 'linkd-previous-link)
  ;;       (global-set-key (kbd "M-]") 'linkd-next-link)
  ;;       (global-set-key (kbd "M-RET") 'linkd-follow-at-point)
  (define-prefix-command 'linkd-overlay-map nil "")
  (global-set-key [(control x) (?,)] 'linkd-overlay-map)
  (global-set-key [mouse-4] 'mwheel-scroll)
  (define-key linkd-overlay-map [mouse-4] nil)
  (define-key linkd-overlay-map [(meta mouse-4)] 'linkd-back)
  (define-key linkd-map [mouse-4] nil)
  (define-key linkd-map [(meta mouse-4)] 'linkd-back)

  (repeatable-command-advice linkd-back)
  (repeatable-command-advice linkd-previous-link)
  (repeatable-command-advice linkd-next-link)
  (repeatable-command-advice linkd-process-block)
  (repeatable-command-advice linkd-escape-datablock)
  (repeatable-command-advice linkd-follow-at-point)
  (defadvice linkd-back (after linkd-back-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'linkd-back)
  (defadvice linkd-previous-link (after linkd-previous-link-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'linkd-previous-link)
  (defadvice linkd-next-link (after linkd-next-link-ctx-flash activate) (when (called-interactively-p 'any) (hictx-line))) (ad-activate 'linkd-next-link)
  )

(provide 'pgo-linkd)
