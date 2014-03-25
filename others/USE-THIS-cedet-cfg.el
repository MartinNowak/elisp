(eval-when-compile (require 'cl))

(eval-and-compile
  (load-file "~/src/cedet/common/cedet.el"))

(semantic-load-enable-minimum-features)
(semantic-load-enable-excessive-code-helpers)

(require 'semantic-idle)
(require 'semantic-complete)

(setq semanticdb-default-save-directory
      "/home/dhansen/.emacs.d/semanticdb")
;; (setq semanticdb-default-system-save-directory
;;       "/home/dhansen/.emacs.d/semanticdb/system")

(push "~/Documents/" semanticdb-project-roots)
(push "~/src/" semanticdb-project-roots)

(global-semantic-idle-scheduler-mode 1)
(global-semantic-idle-summary-mode 1)
(global-semantic-idle-completions-mode 1)
(global-semantic-mru-bookmark-mode 1)
(global-semantic-stickyfunc-mode 1)
(global-semantic-show-parser-state-mode 1)
(global-semantic-show-unmatched-syntax-mode 1)
(global-senator-minor-mode 1)
(global-semantic-decoration-mode 1)
(global-semanticdb-minor-mode 1)

(setq semantic-complete-inline-analyzer-displayor-class
      'semantic-displayor-ghost)

(setq semantic-complete-inline-analyzer-idle-displayor-class
      'semantic-displayor-tooltip)        ; semantic-displayor-tooltip

(defvar dh-semantic-major-modes
  '(emacs-lisp-mode lisp-interaction-mode
    c-mode c++-mode
    srecode-template-mode))

(defun dh-enable-semantic-p ()
  (not (member major-mode dh-semantic-major-modes)))

(add-hook 'semantic-inhibit-functions #'dh-enable-semantic-p)

(require 'semantic-c)

(dolist (p '("/usr/lib/gcc/i486-linux-gnu/4.2/include/"
             "/home/dhansen/include/"
             "/home/dhansen/include/webkit-1.0/"
             "/home/dhansen/include/gtk-2.0/"
             "/home/dhansen/include/glib-2.0/"
             "/home/dhansen/include/dbus-1.0/"
             ))
  ;; (push p semantic-c-dependency-system-include-path)
  (semantic-add-system-include p 'c-mode)
  (semantic-add-system-include p 'c++-mode))

;; (defvar-mode-local c-mode semantic-dependency-include-path
;;   '("/usr/include" "/usr/lib/gcc/i486-linux-gnu/4.2/include/"
;;     "/home/dhansen/include/" "/home/dhansen/include/webkit-1.0/"
;;     "/home/dhansen/include/gtk-2.0/" "/home/dhansen/include/glib-2.0/"
;;     "/home/dhansen/include/dbus-1.0/"))

;; (defvar-mode-local c++-mode semantic-dependency-include-path
;;   '("/usr/include" "/usr/lib/gcc/i486-linux-gnu/4.2/include/"
;;     "/home/dhansen/include/" "/home/dhansen/include/webkit-1.0/"
;;     "/home/dhansen/include/gtk-2.0/" "/home/dhansen/include/glib-2.0/"
;;     "/home/dhansen/include/dbus-1.0/"))



(provide 'cedet-cfg)