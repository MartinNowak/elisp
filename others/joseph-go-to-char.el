;;; joseph-go-to-char
;;bind this func to `?\C-f' typing :`?\C-faaa' will goto the location of 3th a after point.
;;`?\C-fa?\C-h' will go back for char  'a'.
(defun joseph-go-to-char (n)
  "Move forward to Nth occurence of CHAR.
Typing `joseph-go-to-char-key' again will move forwad to the next Nth
occurence of CHAR. Typing \C-h will move back ."
  (interactive "p")
  (forward-char n)
  (let((char (read-event "Go to Char:" )))
    (if (characterp char) 
        (if (string-match "[[:cntrl:]]" (string char))
            (if (char-equal ?\C-f char)
                (progn (forward-char n)
                       (let ((readed-char (read-event " ")))
                         (while (and  (characterp readed-char) (char-equal ?\C-f readed-char)) 
                           (forward-char)
                           (setq readed-char (read-event " "))))
                       (setq unread-command-events (list last-input-event)))
              (setq unread-command-events (list last-input-event)))
          (progn 
            (when (search-forward (string char) nil nil n) (backward-char))                 
                 (let ((readed-char (read-event
                                     (concat "(?\C-h for backward search ,\""
                                             (string char) "\" for forward search):"))))
                   (while (and (characterp readed-char)
                               (or (char-equal readed-char char)  
                                   (char-equal ?\C-h readed-char)))
                     (if    (char-equal ?\C-h readed-char)
                         (search-backward (string char) nil nil n)
                       (forward-char)
                       (when (search-forward (string char) nil nil n) (backward-char))
                       )
                     (setq readed-char (read-event
                                        (concat "(?\C-h for backward search ,\""
                                                (string char)"\" for forward search):"))))
                   (setq unread-command-events (list last-input-event)))))
      (setq unread-command-events (list last-input-event))
      )
    )
  )

(define-key global-map (kbd "C-f") 'joseph-go-to-char)

;;此函数可以进行快速定位 ,vi 中有个f命令如fa 搜索a 并跳到相应位置,  
;; 而这个命令与之相似，如将命令绑到C-f后，按下C-f后 连续按一个字母如s则会一直搜索s 并定位到相应的位置，按C-h可反向搜索
;;直到按下不同的字母 
; ;郑重向大家推荐我写的 ,把它绑定到C-f ,它具有普通C-f 向前移到一个字符的功能,同时又能根据特定字符快速定位


