;;; pgo-undo.el --- Setup Undo and Redo Behaviour
;; Author: Per Nordlöw

;; See: http://www.emacswiki.org/emacs/CategoryUndo

;; Undo and Redo both through Ctrl and Meta.
;; always bind undo
(global-set-key [(meta z)] 'undo)
(global-set-key [(control z)] 'undo)
(global-set-key [(control shift z)] 'redo)

;; Note: Disabled in favor of `undo-tree'.
(when nil
  (when (and (require 'redo nil t)
             (require 'redo+ nil t))
    (global-set-key [(meta shift z)] 'redo)
    ;;(global-set-key [(control shift z)] 'redo)
    ;;(global-set-key [(control meta _)] 'redo)

    (defun undo-redo (arg)
      "Undo or redo changes.  If ARG is present or negative, redo ARG
    changes.  If ARG is positive, repeatedly undo ARG changes."
      (interactive "P")
      (if (null arg)
          (undo)
        (let ((n (prefix-numeric-value arg)))
          (cond ((= n 0) (redo))
                ((< n 0) (redo (- n)))
                ((> n 0) (undo n))))))
    ))

;;; Select an area of text, then press C-u C-_ (undo with a prefix
;;; argument). This undoes the last change to the selected region,
;;; even if you've later made changes to some other area. You can
;;; repeat it. How cool!
;; (load-file-if-exist (elsub "selective-undo-xmas.elc"))

;;; undo-tree.el --- Treat undo history as a tree
;;; Home: http://www.dr-qubit.org/emacs.php#undo-tree
;;; See: http://www.emacswiki.org/emacs/UndoTree
(append-to-load-path (elsub "undo-tree"))
(when (eload 'undo-tree (elsub "undo-tree/") "undo-tree.el")
  (when (global-undo-tree-mode) ;TODO Errors in `called-interactively-p' on Emacs 23 but not on 24.
    (progn
      (setq-default undo-tree-visualizer-timestamps t) ;show timestamps
      (setq-default undo-tree-visualizer-spacing 11)
      (setq undo-tree-visualizer-spacing 11)
      (setq-default undo-tree-auto-save-history t)
      (setq undo-tree-auto-save-history t)
      (setq-default undo-tree-history-directory-alist (quote (("." . "~/.emacs.d/undo/"))))
      )
    (global-set-key [(meta z)] 'undo-tree-undo)
    (global-set-key [(meta shift z)] 'undo-tree-redo)

    (global-set-key [(control z)] 'undo-tree-undo)
    (global-set-key [(control shift z)] 'undo-tree-redo)

    (add-to-list 'auto-mode-alist '("\\..*\\.~undo-tree~\\'" . emacs-lisp-mode))
    )
  )

;; Note: I don't know what to have this for.
(when (and nil (eload 'point-undo (elsub "others") "point-undo.el"))
  (global-set-key [(control meta z)] 'point-undo))

;;(eload 'ub)             ;undo-browse.el --- Powerful Undo system. Browser/movie/redo/hilit

;; Peek at Emacs's undo state.
;;(load-file-if-exist (elsub "view-undo.elc")))

;;; Note: Obseleted by `undo-tree-save-history'
;;(eload 'persistent-undo)

(eload 'goto-last-change) ;Move point through buffer-undo-list positions

;; See: http://www.emacswiki.org/emacs/SelectiveUndo
;; Select an area of text, then press C-u C-_ (undo with a prefix
;; argument). This undoes the last change to the selected region, even
;; if you’ve later made changes to some other area. You can repeat
;; it. How cool!


(provide 'pgo-undo)
