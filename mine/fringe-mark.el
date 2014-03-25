;;; fringe-mark.el --- indicate position of the current mark. Handy when popping off the ring.

(require 'fringe-helper)

;; overlay an arrow where the mark is
(defvar mp-overlay-arrow-position)
(make-variable-buffer-local 'mp-overlay-arrow-position)
(add-to-list 'overlay-arrow-variable-list  'mp-overlay-arrow-position)

(defun mp-mark-hook ()
  ;; (make-local-variable 'mp-overlay-arrow-position)
  (unless (or (minibufferp (current-buffer)) (not (mark)))
    (set
     'mp-overlay-arrow-position
     (save-excursion
       (goto-char (mark))
       (forward-line 0)
       (point-marker)))))
(add-hook 'post-command-hook 'mp-mark-hook)
;; If you want to change the bitmap, defaults to the left arrow, change the
;; attribute for mp-overlay-arrow-position:

(put 'mp-overlay-arrow-position 'overlay-arrow-bitmap 'right-triangle)
;; or you can make a custom one, here’s mine:

;; make the mark fringe bitmap look cool dude
(define-fringe-bitmap 'mp-hollow-right-arrow [128 192 96 48 24 48 96 192 128] 9 8 'center)
(put 'mp-overlay-arrow-position 'overlay-arrow-bitmap 'mp-hollow-right-arrow)
