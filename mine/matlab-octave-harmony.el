;;; matlab-octave-harmony.el --- Setup Matlab and Octave in Harmony.

;; Loading Octave after Matlab to give correct priority int `auto-mode-alist'.
(when (eload 'pgo-octave)
  (ignore-errors (eload 'pgo-matlab))

  ;; Fix Correct Priority for choosing between Matlab, Octave and Objective-C
  ;; Modeds for files ending with .m
  (setq auto-mode-alist (delete '("\\.m$" . matlab-mode) auto-mode-alist))
  (setq auto-mode-alist (delete '(".*[oO]ctave.*/.*\\.m\\'" . octave-mode) auto-mode-alist))
  (setq auto-mode-alist (delete '("\\.octave\\'" . octave-mode) auto-mode-alist))
  (add-to-list 'auto-mode-alist '("\\.m$" . matlab-mode)) ;put last not conflict with octave
  (add-to-list 'auto-mode-alist '(".*[oO]ctave.*/.*\\.m\\'" . octave-mode))
  (add-to-list 'auto-mode-alist '("\\.octave\\'" . octave-mode))
  )

(provide 'matlab-octave-harmony)
