;;; pgo-color-theme.el --- Setup Color Themes
;; Author: Per Nordlöw

(defcustom pnw/use-color-theme t
  "Flags whether or not to load color-themes upon startup." :type 'boolean :group 'pnw-options)

(append-to-load-path (elsub "replace-colorthemes"))

;; http://www.emacswiki.org/emacs-en/ColorThemeCollection
(when pnw/use-color-theme
  (append-to-load-path (elsub "color-theme"))
  (append-to-load-path (elsub "color-theme/themes"))
  (if (not darwin-p)
      (when (eload 'color-theme (elsub "color-theme") "color-theme.el")
        (color-theme-initialize)
        (eload 'color-theme-cl-frame (elsub "color-theme/themes/") "color-theme-cl-frame.el")
        (eload 'color-theme-deep-gold (elsub "color-theme/themes/") "color-theme-deep-gold.el")
        (eload 'color-theme-rlx nil (elsub "color-theme/themes/") "color-theme-rlx.el")
        (eload 'color-theme-domq nil (elsub "color-theme/themes/") "color-theme-domq.el")
        (eload 'color-theme-reg (elsub "color-theme/themes/") "color-theme-reg.el")
        (eload 'color-theme-tango nil (elsub "color-theme/themes/") "color-theme-tango.el")
        ;;(eload 'color-theme-ubuntu2 (elsub "color-theme/themes/" "color-theme-ubuntu2.el")

        ;; Color Theme Solarized:
        ;; \see http://ethanschoonover.com/solarized
        ;; \see https://github.com/sellout/emacs-color-theme-solarized
        (eload 'color-theme-solarized (elsub "emacs-color-theme-solarized/") "color-theme-solarized.el")

        ;; I get a problem compiling this.
        ;;(eload nil (elsub "color-theme/themes/" "color-theme-hober2.el")
        (require 'switch-color-theme-matlab-latex nil t)
        )))

(provide 'pgo-color-theme)
