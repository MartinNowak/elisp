;;; notify-app.el --- Example uses of notify.
;; Author: Per Nordlöw

(require 'notify)

;; See: http://emacs-fu.blogspot.com/2009/11/showing-pop-ups.html
(defun notify-ext (title msg &optional icon sound &rest args)
  "Show a popup if we're on X, or echo it otherwise.
TITLE is the title of the message, MSG is the context. You can
optionally provide an ICON file and a SOUND which can be either a
file or a string containing an XDG Sound Theme spec/id. See \"yelp
sound-naming-spec.xml\" at
http://www.freedesktop.org/wiki/Specifications/sound-theme-spec
for sample sound names."
  (interactive)
  (when sound
    ;; TODO Use `start-proces' instead.
    (shell-command
     (concat "canberra-gtk-play "
             (when (file-regular-p sound)
               "-f "         ;its a file
               "--id= ")        ;its an id
             sound
             " 2> /dev/null")))
  (if (eq window-system 'x)
      (if (fboundp 'notify)
          (notify title msg)            ;resure `notify' package
        (shell-command (concat "notify-send "
                               (if icon (concat "-i " icon) "")
                               " '" title "' '" msg "'")))
    (message (concat title ": " msg)))) ;text only version
;; Use: (notify-ext "Up and running" "Ready to code?")

;; showing pop-ups from org-mode appointments
(progn
  ;; the appointment notification facility
  (setq
   appt-message-warning-time 15 ;; warn 15 min in advance
   appt-display-mode-line t     ;; show in the modeline
   appt-display-format 'window) ;; use our func
  (appt-activate 1)              ;; active appt (appointment notification)
  (display-time)                 ;; time display is required for this...
  ;; update appt each time agenda opened
  (add-hook 'org-finalize-agenda-hook 'org-agenda-to-appt)
  ;; our little façade-function for djcb-popup
  (defun appt-notify-display (min-to-app new-time msg)
    (notify-ext (format "Appointment in %s minute(s)" min-to-app) msg
            ;; "/usr/share/icons/gnome/32x32/status/appointment-soon.png"
            ;; "/usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg"
            ))
  (setq appt-disp-window-function (function appt-notify-display)))

;; showing pop-ups for new mail
;; Another event you might want to be warned about is new mail. There
;; is something to be set for not letting yourself be disturbed for
;; new mail, but if you sufficiently filter your mails before they
;; enter your inbox, it can be a good way to periodically bring you
;; back from your deep sl ^H^H thinking. For Wanderlust, I use
;; something like this:
(add-hook 'wl-biff-notify-hook
          (lambda()
            (notify-ext "Emacs: Wanderlust" "You have new mail!"
                    ;; "/usr/share/icons/gnome/32x32/status/mail-unread.png"
                    ;; "/usr/share/sounds/ubuntu/stereo/phone-incoming-call.ogg"
                    )))

(provide 'notify-app)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; notify-app.el ends here
