(defun moz-connect()
  "Refresh current buffer."
  (interactive)
  (make-comint "moz-buffer" (cons "127.0.0.1" "4242"))
  (global-set-key
   "\C-x\C-g"
   (lambda () 
     (interactive)
     (save-buffer)
     (comint-send-string "*moz-buffer*" "this.BrowserReload()\n"))))
