;;; pgo-shellfm.el --- Setup SHELLFM.
;; Author: Per Nordlöw

(defcustom pnw/use-shellfm nil
  "Flags whether or not to load shellfm upon startup." :type 'boolean :group 'pnw-options)
(when pnw/use-shellfm
  (add-to-list 'load-path (elsub "emacs-shellfm"))
  (when (require 'shellfm nil t)
    (global-set-key [(meta XF86AudioNext)] 'shellfm-skip-track)
    (global-set-key [(meta XF86AudioPrev)] 'shellfm-love-track)
    (global-set-key [(meta XF86AudioStop)] 'shellfm-ban-track)
    (global-set-key [(meta XF86AudioPause)] 'shellfm-pause)
    )
  (defun my-show-lyrics ()
    "Show lyrics of shellfm current song in w3m."
    (interactive)
    (if emms-player-playing-p
        (let* ((track (emms-playlist-current-selected-track))
               (artist (cdr (assoc 'info-artist track)))
               (title (cdr (assoc 'info-title track))))
          (w3m-goto-url
           (format "http://www.lyricsplugin.com/wmplayer03/plugin/?artist=%s&title=%s" artist title)))
      (let* ((art-tit (split-string (substring (shellfm-track-info) 18) " — "))
             (artist (car art-tit))
             (title (cadr art-tit)))
        (w3m-goto-url
         (format "http://www.lyricsplugin.com/wmplayer03/plugin/?artist=%s&title=%s" artist title)))))
  )
;;(global-set-key [(control XF86AudioPause)] 'my-show-lyrics)

(provide 'pgo-shellfm)
