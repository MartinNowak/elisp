;;;; predict-future.el -- try to predict what command the user will do next
;;;  works by looking at the command history for longer sequences matching
;;;  what you have just done
;;; Time-stamp: <2005-01-04 10:52:16 john>
;;; started early 2001

;;;; Mechanism for prediction of likely next commands recording of extra commands

;;  This program is free software; you can redistribute it and/or modify it
;;  under the terms of the GNU General Public License as published by the
;;  Free Software Foundation; either version 2 of the License, or (at your
;;  option) any later version.

;;  This program is distributed in the hope that it will be useful, but
;;  WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;  General Public License for more details.

;;  You should have received a copy of the GNU General Public License along
;;  with this program; if not, write to the Free Software Foundation, Inc.,
;;  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

(defvar pseudo-interactive nil
  "If true, some of our stuff will pretend it was called interactively.")

(defmacro record-as-history (pseudo-history &optional force)
  "Put pseudo-history onto the command history.
Done as a macro, so that interactive-p will still work."
  `(if (or ,force
	   pseudo-interactive
	   (interactive-p))
       (setq command-history
	     (cons ,pseudo-history
		   command-history))))

;;;; Redefine some commands that don't normally go onto the command history
;;; We need some of these on the command history to give us context, and
;;; some as being useful in their own right.

(if (subrp (symbol-function 'other-window))
    (setq original-other-window (symbol-function 'other-window)))

(defun other-window-with-history (arg &optional all-frames)
  "Like other-window, which see.
Puts a `switch-to-buffer' on the command history list, for the
buffer that we end up in."
  (interactive "p")
  (funcall original-other-window arg)
  (record-as-history `(switch-to-buffer ,(buffer-name))))

(fset 'other-window (symbol-function 'other-window-with-history))

;; comint-send-input

(defun comint-send-string-interactive (process string)
  "To PROCESS send STRING.
This is defined to get an interactive definition of process-send-string."
  (interactive "sProcess name: 
sString to send to %s: ")
  (process-send-string process string))

(defun comint-input-to-command-history (command)
  "Record a command history item for sending COMMAND to a shell."
  (remove-text-properties 0 (length command) '('face nil) command)
  (record-as-history
   `(comint-send-string-interactive
     ,(process-name (get-buffer-process (current-buffer)))
     ,command)
   t))

(add-hook 'comint-input-filter-functions 'comint-input-to-command-history)

(defadvice erase-buffer (before record-erase-buffer)
  (record-as-history '(erase-buffer)))
(ad-activate 'erase-buffer)

(defadvice isearch-done (after record-search)
  ;; this isn't working?
  (record-as-history `(search-forward ,isearch-string nil nil nil)))
(ad-activate 'isearch-done)

;; choosing buffers from menu, too, including list-all-buffers
;; search string (on finishing search)

;;;; prediction

(defconst history-head-max 6
  "Number of recent commands that you think may be useful in predicting next command.")

(defvar history-heads (make-vector (1+ history-head-max) nil)
  "Array of history heads lists.
The index into this array is the length of the history heads in that element.
Each of the elements is an alist, with the car being a reversed history head.
We reverse them to make it possible to share storage with shorter heads.
The cdr of each element is also an alist, in which cars are commands and cdrs
are weighted counts of how many times that command has followed that tailing
head. The weighting is the actual count times the length of the tail, to give
a bias towards matches on longer tails. The old weights decay with time.")

(defvar length-factor 1.0
  "The relative importance of the length of the match.")

(defun record-history-head (history)
  "Record head of HISTORY in the prediction structure."
  (let* ((command (car history))
	 (head (nreverse (subseq (cdr history) 0 (min (length (cdr history)) history-head-max))))
	 (head-len (length head)))
    ;; (message "Recording %S as occurring after tails of %S" command head)
    (while head
      ;; (message "  Recording %S as occurring after %S" command head)
      (let* ((at-this-length (aref history-heads head-len))
	     (match (assoc head at-this-length)))
	(unless match
	  (setq match (cons head nil))
	  (aset history-heads head-len (cons match at-this-length)))
	(let* ((commands-for-match (cdr match))
	       (pair-for-command (assoc command commands-for-match)))
	  (unless pair-for-command
	    (setq pair-for-command (cons command 0))
	    (rplacd match (cons pair-for-command commands-for-match)))
	  (rplacd pair-for-command
		  (+ (cdr pair-for-command)
		     (* head-len length-factor)))))
      (setq head (cdr head)
	    head-len (1- head-len)))))

(defvar end-of-recorded-history nil
  "How far we have recorded history.")

(defun record-history-catchup-to (history)
  "Catch up on recording the command history up to HISTORY."
  (unless (or (null history) (eq history end-of-recorded-history))
    (record-history-catchup-to (cdr history))
    (setq end-of-recorded-history history)
    (message "Recording %S onto command history" history)
    (record-history-head history)))

(defun record-history-catchup ()
  "Catch up on recording the command history."
  (interactive)
  (dolist (old-heads (cdr (aref history-heads history-head-max)))
    (message "Updating old weightings in %S" old-heads)
    (dolist (old-head old-heads)
      (message "  old-head %S" old-head)
      (rplacd old-head (* .9 (cdr old-head)))))
  (record-history-catchup-to command-history))

(defun record-history-reset ()
  "Go back to the beginning."
  (interactive)
  (setq history-heads (make-vector (1+ history-head-max) nil)
	end-of-recorded-history nil))

(defun future-predictions (&optional history)
  "Return a list of commands that might follow the latest sequence."
  (unless history
    (setq history command-history))
  (let* ((command (car history))
	 (head (nreverse (subseq history 0 (min (length history) history-head-max))))
	 (head-len (length head))
	 (prediction-pairs nil))
    (while head
      (let* ((at-this-length (aref history-heads head-len))
	     (match (cdr (assoc head at-this-length))))
	(message "at length %d got match %S" head-len match)
	(while match
	  (message " adding prediction %s" (car match))
	  (setq prediction-pairs (cons (car match) prediction-pairs)
		match (cdr match))))
      (setq head (cdr head)
	    head-len (1- head-len)))
    (message "Unsorted predictions: %S" prediction-pairs)
    (setq prediction-pairs (sort prediction-pairs (function (lambda (a b) (> (cdr a) (cdr b))))))
    (message "Sorted predictions: %S" prediction-pairs)
    (mapcar 'car prediction-pairs)))

(defun show-future-predictions ()
  "Show what commands you have often done after the recent ones."
  (interactive)
  (record-history-catchup)
  (with-output-to-temp-buffer "*Predictions*"
    (let ((predictions (future-predictions)))
      (dolist (prediction predictions)
	(princ (format "%S\n" prediction))))))

(defun show-prediction-data ()
  "Show the command prediction data"
  (interactive)
  (record-history-catchup)
  (with-output-to-temp-buffer "*Prediction data*"
    (dotimes (i (length history-heads))
      (princ (format "Heads of length %d:\n" i))
      (let ((heads (aref history-heads i)))
	(dolist (head heads)
	  (princ (format "  Command sequence:\n" (car head)))
	  (dolist (command (car head))
	    (princ (format "      %S\n" command)))
	  (dolist (tail (cdr head))
	    (princ (format "    %S: %d\n" (car tail) (cdr tail)))))))))

(defun predict-complex-command ()
  "Use a history mechanism on the command prediction system."
  (interactive)
  
)

(global-set-key [   M-f12 ] 'predict-complex-command)
  
;;; end of predict-future.el
