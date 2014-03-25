;;; swig-mode-ext.el --- SWIG minor mode for CC-Mode.
;; Author: Per Nordlöw

;; (@* "Minor Mode for Swig") ---------------------------------------
;;
;; When Swig minor mode is active, links are displayed using
;; overlays, and keybindings are available for common Swig functions.
;; The keybindings are in accord with the convention for minor-modes:
;; `C-c' followed by one of a set of reserved punctuation characters.

(defvar swig-map nil "Keymap used by SWIG mode.")
(when (null swig-map)
  (setq swig-map (make-sparse-keymap))
  ;; (define-key swig-map (kbd "C-c *")   'swig-process-block)
  ;; (define-key swig-map (kbd "C-c [")   'swig-previous-link)
  ;; (define-key swig-map (kbd "C-c ]")   'swig-next-link)
  ;; (define-key swig-map (kbd "C-c '")   'swig-follow-at-point)
  ;; (define-key swig-map [mouse-4]       'swig-back)
  ;; (define-key swig-map (kbd "C-c , b") 'swig-back)
  ;; (define-key swig-map (kbd "C-c , ,") 'swig-insert-link)
  ;; (define-key swig-map (kbd "C-c , t") 'swig-insert-tag)
  ;; (define-key swig-map (kbd "C-c , s") 'swig-insert-star)
  ;; (define-key swig-map (kbd "C-c , w") 'swig-insert-wiki)
  ;; (define-key swig-map (kbd "C-c , l") 'swig-insert-lisp)
  ;; (define-key swig-map (kbd "C-c , e") 'swig-edit-link-at-point)
  ;; (define-key swig-map (kbd "C-c , x") 'swig-escape-datablock)
  )

;; SWIG menu for menu bar.
(easy-menu-define swig-menu swig-map "SWIG"
  '("SWIG"
    :visible swig-use-menu
    ["Follow" swig-follow-at-point :active (get-char-property (point) 'swig)]
    ["Back" swig-back :active (get-char-property (point) 'swig)]
    ["Previous link" swig-previous-link :active (get-char-property (point) 'swig)]
    ["Next link" swig-next-link :active (get-char-property (point) 'swig)]
    ("Insert"
     ["Tag" swig-insert-tag]
     ["Star" swig-insert-star]
     ["Link" swig-insert-link])
    ["Edit" 	swig-edit-link-at-point :active (get-char-property (point) 'swig)]))

(define-minor-mode swig-mode
  "Highlight and Imenu support for Simple Wrapper Interface Generator (SWIG) Tags."
  nil :lighter " SWIG" :keymap swig-map (if swig-mode (swig-enable) (swig-disable)))

(defun swig-enable ()
  "Enable SWIG mode."
  (let ((modified-p (buffer-modified-p)))
    (add-hook 'before-save-hook 'swig-deactivate-all-datablocks :append :local)
    (add-hook 'after-save-hook 'swig-activate-all-datablocks :append :local)
    ;;(swig-do-font-lock 'font-lock-add-keywords)
    (font-lock-fontify-buffer)
    (set-buffer-modified-p modified-p)))

(defun swig-disable ()
  "Disable SWIG mode."
  (let ((modified-p (buffer-modified-p)))
    (remove-hook 'before-save-hook 'swig-deactivate-all-datablocks)
    (remove-hook 'after-save-hook 'swig-activate-all-datablocks)
    ;; remove all swig's overlays
    (mapc (lambda (overlay)
            (when (get-text-property (overlay-start overlay) 'swig-fontified)
              (delete-overlay overlay)))
          (overlays-in (point-min) (point-max)))
    ;; remove font-lock rules, textprops, and then refontify the buffer
    ;; (swig-do-font-lock 'font-lock-remove-keywords)
    (remove-text-properties (point-min) (point-max) '(swig-fontified))
    (font-lock-fontify-buffer)
    (set-buffer-modified-p modified-p)))

(provide 'swig-mode-ext)
