;;; =====================================================
;;; dubious-paragraphs.el --- Dubious paragraph movements
;;; =====================================================
;;;
;;; :Author: Martin Blais <blais@furius.ca>
;;; :Date:   2005
;;; :Abstract:
;;;     
;;;     Enhance the vertical cursor line movement with smart behaviour.
;;;
;;; Description
;;; ===========
;;;
;;; The problem can be defined as such:
;;;
;;; 1. I want to be able to move the cursor vertically by a small number of
;;;    lines, but always more than a few, and never too many.  This makes it
;;;    much easier to navigate the cursor up and down quickly in source code;
;;;
;;; 2. I also like for the editor to be intelligent and move by paragraphs,
;;;    between lines separated by whitespace.  forward-paragraph and
;;;    backward-paragraph for example, make it easier to select meaningful
;;;    chunks of code.  The problem with those is that they make it hard to
;;;    quickly get into the middle of large continuous sections of lines because
;;;    they skip them.
;;;
;;; The role of these dubious functions is to work like the paragraph movement
;;; functions, but only when a movement is of a certain minimal number of lines,
;;; and not above a certain maximum number of lines.  Otherwise, we move a fixed
;;; number of lines.
;;;
;;; History
;;; =======
;;; 
;;; It all started a long time ago when the author realized that M-n and M-p
;;; were not bound to anything.  Now, C-f and C-b meant forward and backward
;;; character, and M-f and M-b similarly meant forward and backward words.
;;; C-n and C-p did the same, but horizontally, but there was no equivalent
;;; for M-n and M-p.
;;; 
;;; So I build simplistic functions which would move the cursor up or down by
;;; a fixed number of lines, typically set to 4 (I used four for years and it
;;; got into my fingers).
;;; 
;;; Years later, wandering in the packages, I discovered the forward-paragraph
;;; and backward-paragraph functions, which were smart, they could detect the
;;; paragraph boundaries, and so I thought it would be great to use that
;;; instead for "slightly larger" upwards and downwards movement.
;;; 
;;; The problem was that skipping one-line paragraphs was too small-- I would
;;; prefer to use the more predictable single line movements for that-- and
;;; also, move the cursor in the middle of long code paragraphs, it was
;;; difficult because the paragraph movement commands would skip over the
;;; entire thing, and I would have to scroll many individual lines to get to
;;; the middle.
;;;
;;; I needed something in between.  A heuristic: move "some" lines, and stick
;;; to the [vertical] edges of paragraphs as much as possible.  "Some" means
;;; more than 2 or 3 lines, and less than 7 or 8 lines.
;;;
;;; Henceforth, dubious paragraph movements were created.  The functions
;;; attempt normal paragraph movement.  If the number of lines is too small,
;;; it keeps on going.  If the number of lines moved is too large, the
;;; movement is dubbed "dubious" and a fixed number of lines is moved instead
;;; (like 4 or 5).  Otherwise it pretty much has the stickiness of paragraph
;;; movements, which really makes selecting stuff without the extra vertical
;;; whitespace so much more pleasant.  It's as if emacs knew what you want
;;; most of the time.  Can't like without it now.  
;;;
;;; Usage
;;; =====
;;;
;;; Try it.  Put this in your .emacs::
;;;
;;;       (require 'dubious-paragraphs)
;;;       (global-set-key [(meta n)] 'dubious-forward-paragraph)
;;;       (global-set-key [(meta N)] 'dubious-forward-paragraph-scroll)
;;;       (global-set-key [(meta p)] 'dubious-backward-paragraph)
;;;       (global-set-key [(meta P)] 'dubious-backward-paragraph-scroll)
;;;
;;; Download
;;; ========
;;;
;;; Click `Here <dubious-paragraphs.el>`_ for download.
;;;
;;; Future Work / TODO
;;; ==================
;;;
;;; - forward-paragraph and backward-paragraph don't work too well when there is
;;;   only some whitespace on the line in some source code modes.  This may be
;;;   just a question of setting the appropriate paragraph-* variables or we
;;;   might be able to change the functions themselves.
;;;
;;; END
;;;
;;; Code:
;;;
(defun dubious-scroll-up-still (&optional n)
  "Scroll lines and move the cursor the same amount in the opposite direction.
This is not really dubious but used here so we define it privately.  N is the
number of lines to scroll."
  (let ((nn (or n 1)))
    (scroll-up nn)
    (if (not running-precisely-emacs-21)
	(forward-line nn)) ))

(defvar dubious-min 3
  "Minimum number of lines to travel for a dubious paragraph movement.")
(defvar dubious-max 8
  "Maximum number of lines to travel for a dubious paragraph movement.")
(defvar dubious-dubious 5
  "Number of lines to travel if paragraph movement is dubious.")

(defun dubious-forward-paragraph-lines (&optional n)
  "Compute the number of lines for dubious paragraph movement of N paragraphs."
  (let* ((ninit (or n 1))
	 (bp (point))
	 nl )
    ;; count the number of lines required to move by paragraphs beyond
    ;; that needed to satisfy the minimum lines requirement.
    (setq nl
	  (save-excursion
	    (let ((inc (if (>= ninit 0) 1 -1))
		  ;; if we're moving up, we want to not move to the line before
		  ;; the paragraph, because we want to be on the first line of
		  ;; the paragraph when we're moving up (it makes it easier to
		  ;; select meaningful chunks).
		  (offset (if (>= ninit 0) 0 1)) ;;; moving up only
		  ;; previous point, to avoid infinite loop at buffer boundaries
		  ppoint (point))
	      ;; first move the requested number of paragraphs
	      (forward-paragraph ninit)
	      ;; then move one more paragraph in the same direction until
	      ;; the number of lines is greater than the minimum.
	      (while (and (< (- (count-lines bp (point)) offset)
			     dubious-min)
			  (not (equal ppoint (point))))
		(setq ppoint (point))
		(forward-paragraph inc) )
	      ;; and return that number of lines
	      (if (equal (point) (point-min))
		  (setq offset 0))
	      (- (count-lines bp (point)) offset)
	      )))

    ;; here, we've got the number of lines moved by paragraphs to get
    ;; beyond the minimum.

    ;; if the number of lines is beyond the maximum as well
    (if (> nl dubious-max)
	;; set if to the dubious fixed value
	(setq nl dubious-dubious))

    ;; return an appropriately signed value
    (if (>= ninit 0) nl (- nl))
    ))

(defun dubious-forward-paragraph (&optional n)
  "Move forward to end of N paragraphs, if within a set range of lines.
Otherwise move a fixed number of lines."
  (interactive)
  (forward-line (dubious-forward-paragraph-lines n)))

(defun dubious-backward-paragraph (&optional n)
  "Move backward to end of N paragraphs, if within a set range of lines.
Otherwise move a fixed number of lines."
  (interactive)
  (forward-line
   (dubious-forward-paragraph-lines (- (or n 1)))))

(defun dubious-forward-paragraph-scroll (&optional n)
  "Scroll forward to end of N paragraphs, if within a set range of lines.
Otherwise scroll a fixed number of lines."
  (interactive)
  (scroll-up-still
   (dubious-forward-paragraph-lines n)))

(defun dubious-backward-paragraph-scroll (&optional n)
  "Scroll backward to end of N paragraphs, if within a set range of lines.
Otherwise scroll a fixed number of lines."
  (interactive)
  (scroll-up-still
   (dubious-forward-paragraph-lines (- (or n 1)))))

(global-set-key [(meta n)] 'dubious-forward-paragraph)

(global-set-key [(meta n)] 'dubious-forward-paragraph)
(global-set-key [(meta N)] 'dubious-forward-paragraph-scroll)
(global-set-key [(meta p)] 'dubious-backward-paragraph)
(global-set-key [(meta P)] 'dubious-backward-paragraph-scroll)


(provide 'dubious-paragraphs)

;;; dubious-paragraphs.el ends here
