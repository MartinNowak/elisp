;;; iedit-dwim.el: IEdit Do What I Mean.

;; Edit multiple regions with the same content simultaneously.
;; See: http://groups.google.com/group/gnu.emacs.sources/browse_thread/thread/8f4699bb409ff5c5#
;; http://www.masteringemacs.org/articles/2012/10/02/iedit-interactive-multi-occurrence-editing-in-your-buffer/
;; I've been using mark-multiple to achieve this effect.
;; mark-multiple has been superseded by multiple-cursors.el

(require 'path-utils)

(defvar iedit-path (elsub "iedit")
  "Path to location of iedit package if any.")
(and iedit-path
     (append-to-load-path iedit-path)
     (load-file (expand-file-name "iedit.elc" iedit-path))
     (require 'iedit nil t))

(defun iedit-dwim (arg)
  "Starts iedit but uses \\[narrow-to-defun] to limit its scope."
  (interactive "P")
  (iedit-mode arg)
  (when nil
    (when (require 'iedit nil t)
      (if arg
          (iedit-mode arg)
        (save-excursion
          (save-restriction
            (widen)
            ;; this function determines the scope of `iedit-start'.
            (narrow-to-defun)
            (if iedit-mode
                (iedit-done)
              ;; `current-word' can of course be replaced by other
              ;; functions.
              (let* ((bounds (bounds-of-defun-atpt))
                     (beg (car bounds))
                     (end (cadr bounds)))
                (if (and beg end)
                    (iedit-start (current-word) beg end)
                  (iedit-mode arg))))))))))
(global-set-key (kbd "C-;") 'iedit-dwim)
;; (define-key global-map (kbd "C-;") 'iedit-mode)
;; (define-key isearch-mode-map (kbd "C-;") 'iedit-mode)

(provide 'iedit-dwim)
