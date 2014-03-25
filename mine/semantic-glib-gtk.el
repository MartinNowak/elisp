;;; semantic-glib-gtk.el --- Semantic for Glib/GTK

(semantic-add-system-include "/usr/include/glib-2.0" 'c-mode)
(semantic-add-system-include "/usr/include/glib-2.0" 'c++-mode)
(semantic-add-system-include "/usr/include/gtk-3.0" 'c-mode)
(semantic-add-system-include "/usr/include/gtk-3.0" 'c++-mode)

(provide 'semantic-glib-gtk)
