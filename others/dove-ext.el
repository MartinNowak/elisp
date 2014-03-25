;;; dove-ext.el --- Emacs minor extensions written by David young

;; Copyright (C) 2009  David Young <dove.young@gmail.com>

;; Author: David Young
;; Maintainer: David Young <dove.young@gmail.com>
;; Keywords: shell,shell-mode, copy, help, tools, convenience
;; URL: http://www.emacswiki.org/cgi-bin/wiki/download/dove-ext.el
;; Site: http://www.emacswiki.org/cgi-bin/emacs/DavidYoung

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; miscellaneous

;; 2012-10-06 modified macros copy-something & dove-roll-buffers
;; 2010-08-04 improved rename-buffer-in-ssh-login function
;; 2010-08-08 rewrote function rename-buffer-in-ssh-login
;; 2010-08-08 added function rename-buffer-in-ssh-exit
;; 2010-08-21 added my-overwrite, updated jump function
;; 2010-09-18 added very fancy function split-v-3 and split-h-3
;; 2010-09-27 added roll-v-3
;; 2010-10-01 Rewrote some functions in more Lisp like style
;; 2010-10-09 Rewrote those functions related to copy without selection
;; 2012-01-22 Multiple modify and enhancement

(defun get-point (symbol &optional arg)
 "get the point"
     (progn (funcall symbol arg) (point)))

(defun copy-thing (begin-of-thing end-of-thing &optional arg)
  "copy thing between beg & end into kill ring"
      (let ((beg (get-point begin-of-thing 1))
	    (end (get-point end-of-thing arg)))
	(copy-region-as-kill beg end))
)

(defun paste-to-mark(condition &optional arg)
  "Paste things to mark, or to the prompt in shell-mode"
  (let ((pasteMe 
	 (lambda()
	   (if (funcall condition)
	     (progn (comint-next-prompt 25535) (yank))
	   (progn (goto-char (mark)) (yank) )))))
	(if arg
	    (if (= arg 1)
		nil
	      (funcall pasteMe))
	  (funcall pasteMe) )))
	      
(defun test-get-point (&optional arg)
  "test-get-point"
  (interactive "P")
  (message "%s" (get-point 'forward-word 3))
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                 ;;
;;             shell mode related                  ;;
;;                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun come-here (&optional arg)
  "Bring content from specific buffer to current buffer"
  (interactive (list (let (( arg (read-buffer "Input buffer Name: " "*Shell Command Output*") ))
            (insert-buffer-substring (get-buffer arg))  ))
  )
)


(defun ccc (&optional some)
  "try interactive"
  (interactive (list (let ((some (read-string "Input a string: " nil) ))
             (message "%S" "erwerw") )
        ) )
)


(defun jump (&optional arg)
  "Put current line to another window."
  (interactive "P")
  (let ((command (comint-get-old-input-default))
	 (num (or arg 1)))
       (progn (other-window num)
	      ;; if in shell-mode, goto shell input prompt, else just insert at point
	      (if (string= "shell-mode" major-mode)
		  (progn
		    (goto-char (point-max))
		    ;; First delete any old unsent input at the end
		    (delete-region
		     (or (marker-position comint-accum-marker)
			 (process-mark (get-buffer-process (current-buffer))))
		     (point))
		    )
		)
	      (insert command)
	      )
       )
)


;(defun beforeLast (&optional arg)
;  (interactive "P")
;  (let ((num (or arg 1)))
;    (comint-previous-prompt num)
;    )
;  (let ((input (funcall comint-get-old-input))
;	      (goto-char (process-mark process))
;
;	      (insert input))))
;
;

;(defun some (&optional arg)
;  "Delete Shell command output, to which C-c C-o cannot do for you."
;  (interactive "P")
;  (let ((end 
;	 (get-point  '(lambda (&optional arg) "" (interactive "P")
;		(comint-previous-prompt (or arg 1))
;;		(previous-line)   -- this command is for interactive only
;		(forward-line -1)
;;		(move-beginning-of-line 1)
;		(move-end-of-line 1)
;		)  arg))
;	(start
;	 (get-point '(lambda (&optional arg) "" (interactive "P")
;		 (comint-previous-prompt 1)
;;		(next-line)
;		(move-beginning-of-line 2)
;		)  arg))
;	)
;    (delete-region start end)
;    )
;
;)

 (defun mywrite-region (&optional string)
   "Append current region to specified file. Leverage write-region to implement this function"
   (interactive "BInput file name: ")
   (write-region (region-beginning) (region-end) string "append")
 )


(defun matrixSum (start end)
  "Calculate matrix statistics by row & column. Then insert result into current buffer."
  (interactive "r")
  (progn (shell-command-on-region start end "matrixSum")
	 (let ((buf "*Shell Command Output*"))
	   (progn (come-here buf) (kill-buffer buf) (delete-other-windows))
	   )
	   )
)


(defun exitshell(&optional arg)
  " Exit from login shell, with prefix to exit many levels "
  (interactive "P")
  (let (( nlist (make-list (or arg 1) 1) ))
    (while nlist
      (comint-next-prompt 1)
      (insert "exit ")
      (comint-send-input)
      (sit-for 1)
      (pop nlist)
      )
    )
)


; The function will ignore command like this
; ssh msg@tivx24.cn.ibm.com ls bin
; It could response only to command like this
; ssh msg@tivx24.cn.ibm.com 

(add-hook 'shell-mode-hook 
	  (lambda()
	    (setq shell-buffer-name-list (list "*shell*") )
	    (message "%s" shell-buffer-name-list)
	    )
	  t
)

(eval-after-load 'shell
  '(progn

      ; rewrote this function to co-work with rename-buffer-in-ssh-exit

      (defun rename-buffer-in-ssh-login (cmd)
        "Rename buffer to the destination hostname in ssh login"
        (if (string-match "ssh .* [-_a-z0-9A-Z]+@[-_a-z0-9A-Z.]+[ ]*[^-_a-z0-9-A-Z.]*$" cmd)
            (let (( host (nth 1 (split-string cmd "[@\n]" t) ))
      	    )
;            (message "%s" (split-string cmd "[ @\n]" t) )
            (rename-buffer (concat "*" host))
            (add-to-list 'shell-buffer-name-list (concat "*" host))
            (message "%s" shell-buffer-name-list)
            )
          )
      ;  (if (string-match "^bash$") 
      ;      (add-to-list 'shell-buffer-name-list nil)
      ;    )
      )
      (add-hook 'comint-input-filter-functions 'rename-buffer-in-ssh-login)
      
      ;; This function works only in a single shell session. 
      ;; Not sure how to make it work and safe in multi-session.
      ;; how to handle commands like 'bash' and then 'exit' is also a problem

;;      (defun rename-buffer-in-ssh-exit (cmd)
;;        "Rename buffer to its previous name when user exit from a ssh login"
;;      ;  (message "%s" cmd)
;;        (message "%s" shell-buffer-name-list)
;;        (if (string-match "^exit$" cmd)
;;            (if (> (length shell-buffer-name-list) 1)
;;      	  (progn (pop shell-buffer-name-list)
;;      		 (rename-buffer  (car shell-buffer-name-list)))
;;          )
;;        )
;;        (message "%s" shell-buffer-name-list)
;;      )
      	     
;;      (add-hook 'comint-input-filter-functions 'rename-buffer-in-ssh-exit t)
     
      
      (defun kill-shell-buffer(process event)
        "The one actually kill shell buffer when exit. "
        (kill-buffer (process-buffer process))
      )
      
      (defun kill-shell-buffer-after-exit()
        "kill shell buffer when exit."
        (set-process-sentinel (get-buffer-process (current-buffer))
      		      #'kill-shell-buffer)
      )
      
      (add-hook 'shell-mode-hook 'kill-shell-buffer-after-exit t)

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                 ;;
;;             copy & paste related                ;;
;;                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(defun insert-buffer-name (&optional arg)
 "Insert current buffer name at point"
  (interactive (list (let (( arg  (read-buffer "Input buffer Name: " (buffer-name (current-buffer))) ))
            (insert (buffer-name (get-buffer arg)))  ))
  )
)

(setq dove-auto-paste-mode-list
      '( "shell-mode" "eshell-mode"))

(defun dove-paste-condition (&optional arg)
  "Return t if major-mode match predefined list"
  (mapcan (lambda (x)
            (string= x major-mode))
  dove-auto-paste-mode-list))

(defmacro copy-something-to-mark (begin-fn end-fn arg)
  `(progn (copy-thing  ,begin-fn ,end-fn ,arg)
          (paste-to-mark 'dove-paste-condition ,arg)))

; (macroexpand '(copy-something-to-mark 
;                beginning-of-string end-of-string arg))



(defun copy-line (&optional arg)
 "Copy lines at point and paste them to mark"
 (interactive "P")
 (copy-something-to-mark 'beginning-of-line 'end-of-line arg))

; (progn 
;   (copy-thing 'beginning-of-line 'end-of-line arg) 
;   (paste-to-mark (quote dove-paste-condition) arg)))


(defun copy-word (&optional arg)
 "Copy words at point and paste them to mark"
  (interactive "P")
  (copy-something-to-mark 'backward-word 'forward-word arg))

(defun copy-paragraph (&optional arg)
 "Copy paragraphes at point and paste them to mark"
  (interactive "P")
  (copy-something-to-mark 'backward-paragraph 'forward-paragraph arg))

(defun thing-copy-string-to-mark(&optional arg)
  "Copy string at point or region selected and paste them to mark"
  (interactive "P")
  (cond                   ; This cannot be done by copy-something-to-mark macro
   ((and mark-active transient-mark-mode)
    (pop-mark))
   (t
;    (copy-something-to-mark 'beginning-of-string 'end-of-string arg)))
    (copy-thing 'beginning-of-string 'end-of-string arg)))
  (paste-to-mark 'dove-paste-condition arg))


(defun thing-copy-parenthesis-to-mark(&optional arg)
 "Copy region between {[(<\"''\">)]} and paste them to mark

Automatic due with nesting {[(<\"''\">)]} characters"

  (interactive "P")
  (copy-something-to-mark 'beginning-of-parenthesis 'end-of-parenthesis arg))


(defun duplicate-line(&optional arg)
   "duplicate current line"
   (interactive "P")
   (let ((line (thing-at-point 'line)))
     (forward-line)
     (insert line)
     (forward-line -1)
     (if arg
	 (if (> arg 1)
	     (duplicate-line (- arg 1) -1)))))

(defun dove-forward-kill-word (&optional arg)
  "Backward kill word, but do not insert it into kill-wring"
  (interactive "P")
  (let (( beg (point) )
	( end (get-point 'forward-word arg)))
    (delete-region beg end)
    )
)


(defun beginning-of-string(&optional arg)
  "  "
  (re-search-backward "[ \t]" (line-beginning-position) 3 1)
	     (if (looking-at "[\t ]") 
                 (goto-char (+ (point) 1)) 
               (point))
)
(defun end-of-string(&optional arg)
  " "
  (re-search-forward "[ \t,]" (line-end-position) 3 arg)
	     (if (looking-back "[,;\.\t ]") 
                 (goto-char (- (point) 1)) 
               (point))
)

(defun go-there(arg) 
  ""
  (goto-char (funcall arg)))


(setq dove-parenthesis-list 
      '( ("[" "]") 
         ("(" ")")
         ("<" ">")
         ("{" "}")
         ("\"" "\"")
         ("'"  "'")
         ))

(defun beginning-of-parenthesis(&optional arg)
  "Go to the beginning of parenthesis 
and set the dove-parenthesis-begin found there"

  (re-search-backward "[[<(?\'\"]" (line-beginning-position) 3 1)
	     (if (looking-at "[[<(?\'\"]")
                 (progn
                   (goto-char (+ (point) 1))
                   (setq dove-parenthesis-begin (string (char-before (point))))
                   ))
)
(defun end-of-parenthesis(&optional arg)
  "Go to the end of parenthesis.
Parenthesis character was defined by beginning-of-parenthesis"

  (setq dove-parenthesis-end
         (mapconcat (lambda (x)
                      (if (string= dove-parenthesis-begin (nth 0 x))
                          (nth 1 x)))
                    dove-parenthesis-list nil))
  (goto-char (+ (point) 1))
  (re-search-forward dove-parenthesis-end
                     (line-end-position) 3 arg)
	     (if (looking-back dove-parenthesis-end)
                 (goto-char (- (point) 1)) )
)

(defun backward-symbol (&optional arg)
  (interactive "P")
  "Go backward a symbol, just like forward-symbol, by provide a -1 arg to it"
   (if arg  (forward-symbol arg) (forward-symbol -1))
   (message "%s" arg)
)

(defun move-forward-paren (&optional arg)

  (interactive "sInput a Parenthesis:")
  (message "%s" arg)
  (re-search-forward arg (point-max) 3 1)
)

(defun move-backward-paren (&optional arg)

  (interactive "sInput a Parenthesis:")
  (message "%s" arg)
  (re-search-backward arg (point-max) 3 1)
)

(defun move-to-the-word (&optional arg)
 "Moving to next occurrance of current word"
 (interactive "P")
 (let (( cur-word (current-word nil nil) ))
   (message "%s" cur-word)
   (search-forward cur-word))
)

(defun back-to-the-word (&optional arg)
 "Moving to next occurrance of current word"
 (interactive "P")
 (let (( cur-word (current-word nil nil) ))
   (message "%s" cur-word)
   (search-backward cur-word))
)


(defun convert-Table(start end)
"Convert Emacs table into HTML table"
  (interactive "r")
    (shell-command-on-region start end "sed -e 's%^.%<tr><td>&%' -e 's%    *%</td><td>%g' -e 's%<td>$%</tr>%'")
	 (set-buffer "*Shell Command Output*")
;	 (beginning-of-buffer)
	 (goto-char (point-min))
	 (insert "<table border=\"1\" cellspacing=\"0\" cellpadding=\"0\">\n")
;	 (end-of-buffer)
	 (goto-char (point-max))
	 (insert "</table>\n")
)


(defun insert-line-number(&optional arg)
  "Insert a numeric sequence at beginning of each line"
  (interactive "P")
  (let ((insert-number 
	 (lambda (start beg end)
	   "insert a numeric sequence at beginning of each line"
	   (goto-char beg)
	   (beginning-of-line)
	   (insert (number-to-string start))
	   (setq start (+ start 1))
	   (while (< (point) end)
	     (beginning-of-line 2)
	     (insert (number-to-string start))
	     (setq start (+ start 1))))))
    (cond 
     ((or mark-active transient-mark-mode)
      (if (> (point) (mark))
	  (exchange-point-and-mark))
      (if arg
	  (funcall insert-number arg (point) (mark))
	  (funcall insert-number 0 (point) (mark)))
      )
     (t
      (if arg
	  (funcall insert-number arg (point-min) (point-max))
	(funcall insert-number 0 (point-min) (point-max)))
      ))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                 ;;
;;             window layout related               ;;
;;                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  +-----------------------+----------------------+
;  |                       |                      |
;  |                       |                      |
;  |                       |                      |
;  +-----------------------+----------------------+
;  |                       |                      |
;  |                       |                      |
;  |                       |                      |
;  +-----------------------+----------------------+

(defun split-window-4()
 "Splite window into 4 sub-window"
 (interactive)
 (if (= 1 (length (window-list)))
     (progn (split-window-vertically)
	    (split-window-horizontally)
	    (other-window 2)
	    (split-window-horizontally)
	    )
   )
)


;  +----------------------+                +---------- +----------+
;  |                      |          \     |           |          |
;  |                      |  +-------+\    |           |          |
;  +----------------------+  +-------+/    |           |          |
;  |                      |          /     |           |          |
;  |                      |                |           |          |
;  +----------------------+                +---------- +----------+
;
;  +--------- +-----------+                +----------------------+
;  |          |           |          \     |                      |
;  |          |           |  +-------+\    |                      |
;  |          |           |  +-------+/    +----------------------+
;  |          |           |          /     |                      |
;  |          |           |                |                      |
;  +--------- +-----------+                +----------------------+



(defun change-split-type ()
  "Changes splitting from vertical to horizontal and vice-versa"
  (interactive)
  (message "%s --> %d" (window-list) (length (window-list)))

  (if (= 2 (length (window-list)))
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



;  +-----------------------+                  +----------- +-----------+ 
;  |                       |            \     |            |           | 
;  |                       |    +-------+\    |            |           | 
;  +-----------------------+    +-------+/    |            |-----------|
;  |           |           |            /     |            |           | 
;  |           |           |                  |            |           | 
;  +-----------------------+                  +----------- +-----------+ 

;  +----------- +-----------+                 +------------------------+ 
;  |            |           |            \    |                        | 
;  |            |           |    +-------+\   |                        | 
;  |            |-----------|    +-------+/   +------------------------+ 
;  |            |           |            /    |            |           | 
;  |            |           |                 |            |           | 
;  +----------- +-----------+                 +------------------------+ 

(defun change-split-type-3 ()
  "Change 3 window style from horizontal to vertical and vice-versa"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (length (window-list)))
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
                     (set-window-buffer nil 2ndBuf)
                     (funcall split-2)
                     (set-window-buffer (next-window) 3rdBuf)
                     (other-window 2)
                     (set-window-buffer nil 1stBuf)))         

                  (split-type-1 nil)
                  (split-type-2 nil)
                  )
              (if (= (window-width) (frame-width))
                  (setq split-type-1 'split-window-horizontally 
                        split-type-2 'split-window-vertically)
                (setq split-type-1 'split-window-vertically  
                      split-type-2 'split-window-horizontally))
              (funcall split-3 1stBuf 2ndBuf 3rdBuf split-type-1 split-type-2)

))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(defmacro dove-change-3-buffers ((buf_1 buf_2 buf_3) &body body)
;  `(progn (select-window (get-largest-window))
;    (if (= 3 (length (window-list)))
;        (let ((winList (window-list)))
;          (let ((1stWin (car winList))
;                (2ndWin (car (cdr winList)))
;                (3rdWin (car (cdr (cdr winList)))))
;            (let ((1stBuf (window-buffer 1stWin))
;                  (2ndBuf (window-buffer 2ndWin))
;                  (3rdBuf (window-buffer 3rdWin)))
;              (progn ,@body)))))))
;
;(macroexpand '(dove-change-3-buffers 
;               (3rdBuf 1stBuf 2ndBuf))
;             (progn
;               (set-window-buffer 1stWin ,buf_1)
;               (set-window-buffer 2ndWin ,buf_2)
;               (set-window-buffer 3rdWin ,buf_3)))
;
;;               (lambda () (message "%s" '123))))



(defun change-split-type-3 ()
  "Change 3 window style from horizontal to vertical and vice-versa"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (length (window-list)))
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
                     (set-window-buffer nil 2ndBuf)
                     (funcall split-2)
                     (set-window-buffer (next-window) 3rdBuf)
                     (other-window 2)
                     (set-window-buffer nil 1stBuf)))         

                  (split-type-1 nil)
                  (split-type-2 nil)
                  )
              (if (= (window-width) (frame-width))
                  (setq split-type-1 'split-window-horizontally 
                        split-type-2 'split-window-vertically)
                (setq split-type-1 'split-window-vertically  
                      split-type-2 'split-window-horizontally))
              (funcall split-3 1stBuf 2ndBuf 3rdBuf split-type-1 split-type-2)

))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;  +----------- +-----------+                    +----------- +-----------+ 
;  |            |     C     |            \       |            |     A     | 
;  |            |           |    +-------+\      |            |           | 
;  |     A      |-----------|    +-------+/      |     B      |-----------| 
;  |            |     B     |            /       |            |     C     | 
;  |            |           |                    |            |           | 
;  +----------- +-----------+                    +----------- +-----------+ 
;
;  +------------------------+                     +------------------------+ 
;  |           A            |           \         |           B            | 
;  |                        |   +-------+\        |                        | 
;  +------------------------+   +-------+/        +------------------------+ 
;  |     B     |     C      |           /         |     C     |     A      | 
;  |           |            |                     |           |            | 
;  +------------------------+                     +------------------------+ 


(defmacro dove-roll-buffers (sort_fn)
  `(progn (select-window (get-largest-window))
              (let ((winList (window-list))  ; sort buffer list by plugin function sort_fn
                    (bufferList (funcall ,sort_fn (mapcar 'window-buffer (window-list)))))
                (mapcar* (lambda (win buf) 
                           "set bufffer to window"
                           (set-window-buffer win buf))
                         winList bufferList))))

(defun roll-3-buffers-anti-clockwise ()
  "Roll 3 window buffers anti-clockwise"
  (interactive)
  (if (= 3 (length (window-list)))
      (dove-roll-buffers '(lambda (bufList)  ; put the last to the first
                              (cons (car (last bufList)) (butlast bufList))))))

(defun roll-3-buffers-clockwise ()
  "Roll 3 window buffers clockwise"
  (interactive)
  (if (= 3 (length (window-list)))
      (dove-roll-buffers '(lambda (bufList)  ; put the first to the last
                              (append (cdr bufList) (list (car bufList)))))))

;(defun dove-hide-shell-output()
;  "Hide Shell Output"
;  (interactive)
;;  (let ((beg (progn (move-end-of-line 0) (point))))
;;        (end (progn (comint-previous-prompt 0) (move-beginning-of-line 2) (point)
;;
;;   (set-mark-command (progn (move-end-of-line 0) (point)))
;  (let ((start (point)))
;    (progn
;      (comint-previous-prompt 1)
;      (move-beginning-of-line 2)
;      (set-mark (point))
;      (comint-next-prompt 1)
;      (move-end-of-line -1)
;      (hide-region-hide)
;      (set-mark start))
;    )
;)

;; edit related

;(defun try-expand-dabbrev-path (old)
;  (setq hippie-expand-dabbrev-as-symbol nil)
;  (try-expand-dabbrev old)
;  (setq hippie-expand-dabbrev-as-symbol t)
;)

;(message "%s" hippie-expand-try-functions-list)

(when (require 'hippie-exp nil t)
  (setq hippie-expand-try-functions-list
	(append (list (car  hippie-expand-try-functions-list)
		      'try-expand-dabbrev-path)
		(cdr  hippie-expand-try-functions-list)
		)
	))

(defun my-overwrite (&optional arg)
  "Encapsulate overwrite-mode function, to enable red alert in mode-line "
  (interactive "P")
  (if (not overwrite-mode)
      (progn (add-to-list 'mode-line-format (propertize overwrite-mode-textual 'face '(:foreground "white" :background "red") ))
	     (setq my-overwrite-mode-line (car mode-line-format))
	     (overwrite-mode 1)
	     )
    (progn (overwrite-mode 0)
	   (if (memq my-overwrite-mode-line mode-line-format) (setq mode-line-format (delq my-overwrite-mode-line mode-line-format)))
	   )
    )
)


; auto-type

(defun i-babel-quote (beg end str1 str2)
  (goto-char end)
  (forward-line 1)
  (insert str2)
  (newline)
  (goto-char beg)
  (forward-line -1)
  (newline)
  (insert str1)
)

(defun i-babel-quote-str (beg end Str)
  ""
    (goto-char end)
    (insert Str)
    (goto-char beg)
    (insert Str)
    (goto-char (+ end 2))
)

(defun iexp (St Ed)
  "Enclose example for org-mode"
  (interactive "r")
  (i-babel-quote St Ed "#+BEGIN_EXAMPLE" "#+END_EXAMPLE"))

(defun isrc (St Ed)
  "Enclose code for org-mode"
  (interactive "r")
  (i-babel-quote St Ed "#+begin_src " "#+end_src"))


(defun ihtml (St Ed)
  "Enclose code for Emacser.cn"
  (interactive "r")
  (i-babel-quote St Ed 
                 (concat "#+BEGIN_HTML\n " "<pre lang=\"lisp\" line=\"1\">\n")

                 (concat "</pre>\n" "#+END_HTML\n")))


(defmacro dove-org-babel-shortcut-para (str-begin str-end &optional arg)
  `(i-babel-quote (+ (progn (backward-paragraph) (point)) 1)
                  (- (progn (forward-paragraph arg) (point)) 1)
                  ,str-begin ,str-end))

               
(defun iexp-para (&optional arg)
  "Enclose code at point for org-mode"
  (interactive "P")
  (dove-org-babel-shortcut-para "#+BEGIN_EXAMPLE" "#+END_EXAMPLE" arg))


(defun isrc-para (&optional arg)
  "Enclose code at point for org-mode"
  (interactive "P")
  (dove-org-babel-shortcut-para "#+begin_src " "#+end_src" arg))


(defmacro dove-org-babel-shortcut (St Ed x)
  `(cond
   ((and mark-active transient-mark-mode)
    (i-babel-quote-str ,St ,Ed ,x))
   (t
    (let ((St (and (beginning-of-string) (point)))
          (Ed (and (end-of-string) (point))))
      (i-babel-quote-str ,St ,Ed ,x)))))


(macroexpand '(dove-org-babel-shortcut St Ed x))

(defun i= (St Ed)
  "Set string-at-point to =string-at-point= 

Used in org-mode. For arbitrary content, select them first"
  (interactive "r")
  (dove-org-babel-shortcut St Ed "="))

(defun i* (St Ed)
  "Set string-at-point to *string-at-point*

Used in org-mode. For arbitrary content, select them first"
  (interactive "r")
  (dove-org-babel-shortcut St Ed "*"))

(defun i: (&optional arg)
  "Insert ': ' at each line of code

Used in org-mode. For operating on multiple lines, use prefix argument"
  (interactive "P")
  (beginning-of-line )
  (insert ": ")
  (if arg
      (dotimes (i (- arg 1))
        (progn 
          (beginning-of-line 2)
          (insert ": ")))))


;  (cond
;   ((and mark-active transient-mark-mode)
;    (i-babel-quote-str St Ed "="))
;   (t
;    (let ((St (and (beginning-of-string) (point)))
;          (Ed (and (end-of-string) (point))))
;      (i-babel-quote-str St Ed "="))))
;)



;  (cond
;   ((and mark-active transient-mark-mode)
;    (i-babel-quote-str St Ed "*"))
;   (t
;    (let ((St (and (beginning-of-string) (point)))
;          (Ed (and (end-of-string) (point))))
;      (i-babel-quote-str St Ed "*"))))
;)


(defun action-to-list (action lst)
  "Perform action to each element in the list"
  (mapcar (lambda(ext) (funcall action ext)) lst))


;(defun require-extensions (action lst)
;  ""
;  (mapcar (lambda(ext) "" (funcall action ext)) lst))


(defun set-key-bindings (action bindingList)
  ""
  (mapcar (lambda(lst)
	  ""
	  (let ((x (car lst))
		(y (car (last lst))))
	    (funcall action x y))) bindingList ))

(defun set-outline-minor-mode-regexp ()
  ""
  (outline-minor-mode 1)
  (let ((regexp-list (append outline-minor-mode-list nil))
	(find-regexp
	 (lambda (lst)
	   ""
	   (let ((innerList (car lst)))
	     (if innerList
		 (if (string= (car innerList) major-mode)
		     (car (cdr innerList))
		   (progn (pop lst)
			  (funcall find-regexp lst))))
	     ))))
    (make-local-variable 'outline-regexp)
    (setq outline-regexp (funcall find-regexp regexp-list)))
	
  (set-key-bindings 'local-set-key
		    (list
		     (list (kbd "C-c C-t") 'hide-body)
		     (list (kbd "C-c C-a") 'show-all)
		     (list (kbd "C-c C-e") 'show-entry)))
)



(defun hs-hide-all-comments ()
  "Find all comments in the file and hide them via hs-hide-comment-region"
  (interactive)
  (goto-char (point-min))
  (while (re-search-forward "^[ \t]*#." (point-max) 3 )
    (let ((beg (line-beginning-position))
	  (count 1)
	  (end nil))
      (forward-line)
      (while (re-search-forward "^[ \t]*#." (line-end-position) 3 1) 
	(setq count (+ count 1))
	(forward-line)
	(setq end (line-end-position)))
      (if (> count 1)
	  (hs-hide-comment-region beg end))
      (forward-line count)
      )
    )
)

(defun goto-symbol (arg &optional flag)
  "find the next function definition"
  (interactive)
  (if (or flag nil)
      (re-search-backward (eval arg) )
    (re-search-forward (eval arg) ))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun sdcv (&optional arg)
  "sdcv dictionary plugin"
  (interactive "P")
  (shell-command (concat "sdcv " (current-word nil nil))))

(provide 'dove-ext)
