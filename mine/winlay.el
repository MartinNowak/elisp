;;; winlay.el --- Window Layouts.
;; Author: Per Nordlöw

;;; ===========================================================================
;; Window Splitting and Balancing

(defun balanced-delete-window ()
  (interactive)
  (delete-window)
  (balance-windows))

(defun balanced-split-window-horizontally ()
  (interactive)
  (split-window-horizontally)
  (balance-windows))

(defun balanced-split-window-vertically ()
  (interactive)
  (split-window-vertically)
  (balance-windows))

(global-set-key [(control ?x) (?0)] 'balanced-delete-window)
(global-set-key [(control ?x) (?2)] 'balanced-split-window-vertically)
(global-set-key [(control ?x) (?3)] 'balanced-split-window-horizontally)

(global-set-key [(control ?x) (meta ?2)] 'split-window-vertically)
(global-set-key [(control ?x) (meta ?3)] 'split-window-horizontally)

(repeatable-command-advice delete-window)
(repeatable-command-advice split-window-horizontally)
(repeatable-command-advice split-window-vertically)

(repeatable-command-advice balanced-delete-window)
(repeatable-command-advice balanced-split-window-horizontally)
(repeatable-command-advice balanced-split-window-vertically)

;;; ===========================================================================

(defun swap-windows ()
  "Swap the order of the windows in the current frame preservering the window focus."
  (interactive)
  (let ((cur-buffer (current-buffer))
        (top-buffer)
        (bottom-buffer))
    (pop-to-buffer (window-buffer (frame-first-window)))
    (setq top-buffer (current-buffer))
    (other-window 1)
    (setq bottom-buffer (current-buffer))
    (switch-to-buffer top-buffer t)
    (other-window -1)
    (switch-to-buffer bottom-buffer t)
    (pop-to-buffer cur-buffer)))
(when (require 'repeatable)
  (repeatable-command-advice swap-windows))
(defalias 'flip-windows 'swap-windows)
(global-set-key [(control x) (?9)] 'flip-windows)

(defun toggle-window-split-pnw ()
  "Vertical split shows more of each line, horizontal split shows
more lines. This code toggles between them. It only works for
frames with exactly two windows."
  (interactive)
  (when (= (count-windows) 2)
    (let* ((this-win-buffer (window-buffer))
           (next-win-buffer (window-buffer (next-window)))
           (this-win-edges (window-edges (selected-window)))
           (next-win-edges (window-edges (next-window)))
           (this-win-2nd (not (and (<= (car this-win-edges)
                                       (car next-win-edges))
                                   (<= (cadr this-win-edges)
                                       (cadr next-win-edges)))))
           (splitter
            (if (= (car this-win-edges)
                   (car (window-edges (next-window))))
                'split-window-horizontally
              'split-window-vertically)))
      (delete-other-windows)
      (let ((first-win (selected-window)))
        (funcall splitter)
        (if this-win-2nd (other-window 1))
        (set-window-buffer (selected-window) this-win-buffer)
        (set-window-buffer (next-window) next-win-buffer)
        (select-window first-win)
        (if this-win-2nd (other-window 1))))))

(global-set-key [(control x) (|)] 'toggle-window-split)
(repeatable-command-advice toggle-window-split)
(define-key ctl-x-4-map [?|] 'toggle-window-split)

;;; ===========================================================================

;;  +-----------------------+----------------------+
;;  |                       |                      |
;;  |                       |                      |
;;  |                       |                      |
;;  +-----------------------+----------------------+
;;  |                       |                      |
;;  |                       |                      |
;;  |                       |                      |
;;  +-----------------------+----------------------+
(defun split-window-4()
  "Splite window into 4 sub-window"
  (interactive)
  (if (= 1 (count-windows))
      (progn (split-window-vertically)
             (split-window-horizontally)
             (other-window 2)
             (split-window-horizontally)
             )
    )
  )

;;  +----------------------+                 +----------- +-----------+
;;  |                      |           \     |            |           |
;;  |                      |   +-------+\    |            |           |
;;  +----------------------+   +-------+/    |            |           |
;;  |                      |           /     |            |           |
;;  |                      |                 |            |           |
;;  +----------------------+                 +----------- +-----------+
(defun split-window-v ()
  (interactive)
  (if (= 2 (count-windows))
      (let (( thisBuf (window-buffer))
            ( nextBuf (progn (other-window 1) (buffer-name))))
        (progn   (delete-other-windows)
                 (split-window-horizontally)
                 (set-window-buffer nil thisBuf)
                 (set-window-buffer (next-window) nextBuf)
                 ))
    )
  )

;;  +----------- +-----------+                  +----------------------+
;;  |            |           |            \     |                      |
;;  |            |           |    +-------+\    |                      |
;;  |            |           |    +-------+/    +----------------------+
;;  |            |           |            /     |                      |
;;  |            |           |                  |                      |
;;  +----------- +-----------+                  +----------------------+
(defun split-window-h ()
  (interactive)
  (if (= 2 (count-windows))
      (let (( thisBuf (window-buffer))
            ( nextBuf (progn (other-window 1) (buffer-name))))
        (progn   (delete-other-windows)
                 (split-window-vertically)
                 (set-window-buffer nil thisBuf)
                 (set-window-buffer (next-window) nextBuf)
                 ))
    )
  )

;;  +----------------------+                 +----------- +-----------+
;;  |                      |           \     |            |           |
;;  |                      |   +-------+\    |            |           |
;;  +----------------------+   +-------+/    |            |-----------|
;;  |          |           |           /     |            |           |
;;  |          |           |                 |            |           |
;;  +----------------------+                 +----------- +-----------+
(defun split-window-v-3 ()
  "Change 3 window style from horizontal to vertical"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (count-windows))
      (let ((winList (window-list)))
        (let ((1stBuf (window-buffer (car winList)))
              (2ndBuf (window-buffer (car (cdr winList))))
              (3rdBuf (window-buffer (car (cdr (cdr winList))))))
          (message "%s %s %s" 1stBuf 2ndBuf 3rdBuf)
          (delete-other-windows)
          (split-window-horizontally)
          (set-window-buffer nil 1stBuf)
          (other-window 1)
          (set-window-buffer nil 2ndBuf)
          (split-window-vertically)
          (set-window-buffer (next-window) 3rdBuf)
          (select-window (get-largest-window))
          )
        )
    )
  )

;;  +----------- +-----------+                  +----------------------+
;;  |            |           |            \     |                      |
;;  |            |           |    +-------+\    |                      |
;;  |            |-----------|    +-------+/    +----------------------+
;;  |            |           |            /     |           |          |
;;  |            |           |                  |           |          |
;;  +----------- +-----------+                  +----------------------+
(defun split-window-h-3 ()
  "Change 3 window style from vertical to horizontal"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (count-windows))
      (let ((winList (window-list)))
        (let ((1stBuf (window-buffer (car winList)))
              (2ndBuf (window-buffer (car (cdr winList))))
              (3rdBuf (window-buffer (car (cdr (cdr winList))))))
          (message "%s %s %s" 1stBuf 2ndBuf 3rdBuf)
          (delete-other-windows)
          (split-window-vertically)
          (set-window-buffer nil 1stBuf)
          (other-window 1)
          (set-window-buffer nil 2ndBuf)
          (split-window-horizontally)
          (set-window-buffer (next-window) 3rdBuf)
          (select-window (get-largest-window))
          )
        )
    )
  )

;;  +----------- +-----------+                    +----------- +-----------+
;;  |            |     C     |            \       |            |     A     |
;;  |            |           |    +-------+\      |            |           |
;;  |     A      |-----------|    +-------+/      |     B      |-----------|
;;  |            |     B     |            /       |            |     C     |
;;  |            |           |                    |            |           |
;;  +----------- +-----------+                    +----------- +-----------+
;;
;;  +------------------------+                     +------------------------+
;;  |           A            |           \         |           B            |
;;  |                        |   +-------+\        |                        |
;;  +------------------------+   +-------+/        +------------------------+
;;  |     B     |     C      |           /         |     C     |     A      |
;;  |           |            |                     |           |            |
;;  +------------------------+                     +------------------------+
(defun roll-window-v-3 ()
  "Rolling 3 window buffers clockwise"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (count-windows))
      (let ((winList (window-list)))
        (let ((1stWin (car winList))
              (2ndWin (car (cdr winList)))
              (3rdWin (car (cdr (cdr winList)))))
          (let ((1stBuf (window-buffer 1stWin))
                (2ndBuf (window-buffer 2ndWin))
                (3rdBuf (window-buffer 3rdWin))
                )
            (set-window-buffer 1stWin 3rdBuf)
            (set-window-buffer 2ndWin 1stBuf)
            (set-window-buffer 3rdWin 2ndBuf)
            )
          )
        )
    )
  )

;;  +----------------------+                +---------- +----------+
;;  |                      |          \     |           |          |
;;  |                      |  +-------+\    |           |          |
;;  +----------------------+  +-------+/    |           |          |
;;  |                      |          /     |           |          |
;;  |                      |                |           |          |
;;  +----------------------+                +---------- +----------+
;;
;;  +--------- +-----------+                +----------------------+
;;  |          |           |          \     |                      |
;;  |          |           |  +-------+\    |                      |
;;  |          |           |  +-------+/    +----------------------+
;;  |          |           |          /     |                      |
;;  |          |           |                |                      |
;;  +--------- +-----------+                +----------------------+
(defun toggle-window-split ()
  "Toggle splitting from vertical to horizontal and vice-versa."
  (interactive)
  (if (= 2 (count-windows))
      (let ((thisBuf (window-buffer))
            (nextBuf (progn (other-window 1) (buffer-name)))
            (split-type (if (= (window-width)
                               (frame-width))
                            'split-window-horizontally
                          'split-window-vertically)))
        (progn
          (delete-other-windows)
	  (funcall split-type)
          (set-window-buffer nil thisBuf)
          (set-window-buffer (next-window) nextBuf)))))

;;  +----------------------+                 +----------- +-----------+
;;  |                      |           \     |            |           |
;;  |                      |   +-------+\    |            |           |
;;  +----------------------+   +-------+/    |            |-----------|
;;  |          |           |           /     |            |           |
;;  |          |           |                 |            |           |
;;  +----------------------+                 +----------- +-----------+
;;
;;  +----------- +-----------+                  +----------------------+
;;  |            |           |            \     |                      |
;;  |            |           |    +-------+\    |                      |
;;  |            |-----------|    +-------+/    +----------------------+
;;  |            |           |            /     |           |          |
;;  |            |           |                  |           |          |
;;  +----------- +-----------+                  +----------------------+
(defun toggle-window-split-3 ()
  "Toggle 3 window style from horizontal to vertical and vice-versa."
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (count-windows))
      (let ((winList (window-list)))
        (let ((1stBuf (window-buffer (car winList)))
              (2ndBuf (window-buffer (car (cdr winList))))
              (3rdBuf (window-buffer (car (cdr (cdr winList)))))
              (split-3
               (lambda(1stBuf 2ndBuf 3rdBuf split-1 split-2)
                 "change 3 window from horizontal to vertical and vice-versa"
                 (message "%s %s %s" 1stBuf 2ndBuf 3rdBuf)
                 (delete-other-windows)
                 (funcall split-1)
                 (set-window-buffer nil 1stBuf)
                 (other-window 1)
                 (set-window-buffer nil 2ndBuf)
                 (funcall split-2)
                 (set-window-buffer (next-window) 3rdBuf)
                 (select-window (get-largest-window))
                 ))
              (split-type-1 nil)
              (split-type-2 nil)
              )
          (if (= (window-width) (frame-width))
              (setq split-type-1 'split-window-horizontally split-type-2 'split-window-vertically)
            (setq split-type-1 'split-window-vertically  split-type-2 'split-window-horizontally))
          (funcall split-3 1stBuf 2ndBuf 3rdBuf split-type-1 split-type-2)
          ))))

(provide 'winlay)
