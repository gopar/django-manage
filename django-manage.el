;;; django-manage.el --- Django minor mode for commanding manage.py

;; Copyright (C) 2015 Daniel Gopar

;; Author: Daniel Gopar <gopardaniel@yahoo.com>
;; Package-Requires: ((hydra "0.13.2"))
;; Version: 0.1
;; Keywords: languages

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(condition-case nil
    (require 'python)
  (error
   (require 'python-mode)))
(require 'hydra)

(defvar django-files-regexp
  "\\<\\(models\\|views\\|handlers\\|feeds\\|sitemaps\\|admin\\|context_processors\\|urls\\|settings\\|tests\\|assets\\|forms\\)\\.py\\'")

(defcustom django-manage-shell-preference 'pyshell
  "What shell to use"
  :type 'symbol
  :options '(eshell term pyshell)
  :group 'shell)

(defun django-manage-root (&optional dir home)
  "Return the root directory of Django project"
  ;; Check if projectile is in use, and if it is. Return root directory
  (if (fboundp 'projectile-project-root)
      (projectile-project-root)
    ;; Try looking for the directory holding 'manage.py'
    (locate-dominating-file default-directory "manage.py")))

(defun django-manage-python-command ()
  (if (boundp 'python-shell-interpreter)
      (concat python-shell-interpreter " " python-shell-interpreter-args)
    ;; For old python.el
    (mapconcat 'identity (cons python-python-command python-python-command-args) " ")))

(defun django-manage-get-commands ()

  (let ((help-output (shell-command-to-string (concat python-shell-interpreter" manage.py -h")))
        (default-directory (django-manage-root)))
    (setq dj-commands-str
          (with-temp-buffer
            (progn
              (insert help-output)
              (beginning-of-buffer)
              (delete-region (point) (search-forward "Available subcommands:" nil nil nil))
              ;; cleanup [auth] and stuff
              (beginning-of-buffer)
              (save-excursion
                (replace-regexp "\\[.*\\]" ""))
              (buffer-string))))
    ;; get a list of commands from the output of manage.py -h
    ;; What would be the pattern to optimize this ?
    (setq dj-commands-str (s-split "\n" dj-commands-str))
    (setq dj-commands-str (-remove (lambda (x) (string= x "")) dj-commands-str))
    (setq dj-commands-str (mapcar (lambda (x) (s-trim x)) dj-commands-str))
    (sort dj-commands-str 'string-lessp)))

(defun django-manage-command (command)
  ;; nil nil: enable user to exit with any command. Still, he can not edit a completed choice.
  (interactive (list (completing-read "Command: " (django-manage-get-commands) nil nil)))
  ;; Now ask to edit the command. How to do the two actions at once ?
  (setq command (read-shell-command "Run command like this: " command))
  (compile (concat (django-manage-python-command) " " (django-manage-root) "manage.py " command)))

(defun django-manage-makemigrations (&optional app-name)
  (interactive "sName: ")
  (django-manage-command (concat "makemigrations " app-name)))

(defun django-manage-flush ()
  (interactive)
  (django-manage-command "flush --noinput"))

(defun django-manage-runserver ()
  (interactive)
  (django-manage-command "runserver")
  (switch-to-buffer "*compilation*")
  (rename-buffer "*runserver*"))

(defun django-manage-migrate ()
  (interactive)
  (django-manage-command "migrate"))

(defun django-manage-assets-rebuild ()
  (interactive)
  (django-manage-command "assets rebuild"))

(defun django-manage-startapp (name)
  (interactive "sName:")
  (django-manage-command (concat "startapp " name)))

(defun django-manage-makemessages ()
  (interactive)
  (django-manage-command "makemessages --all --symlinks"))

(defun django-manage-compilemessages ()
  (interactive)
  (django-manage-command "compilemessages"))

(defun django-manage-test (name)
  (interactive "sTest app:")
  (django-manage-command (concat "test " name)))

(defun django-manage--prep-shell (pref-shell)
  (if (eq 'term django-manage-shell-preference)
      (term (concat (django-manage-python-command) " " (django-manage-root) "manage.py " pref-shell)))
  (if (eq 'eshell django-manage-shell-preference)
      (progn
        (unless (get-buffer eshell-buffer-name)
          (eshell))
        (insert (concat (django-manage-python-command) " " (django-manage-root) "manage.py " pref-shell))
        (eshell-send-input)))
  (if (eq 'pyshell django-manage-shell-preference)
      (let ((setup-code "os.environ.setdefault(\"DJANGO_SETTINGS_MODULE\", \"%s.settings\")")
            (parent-dir (file-name-base (substring (django-manage-root) 0 -1)))
            (cmd ";from django.core.management import execute_from_command_line")
            (exe (format ";execute_from_command_line(['manage.py', '%s'])" pref-shell))
            (default-directory (django-manage-root)))
        (python-shell-send-string (concat (format setup-code parent-dir) cmd exe))
        (switch-to-buffer (python-shell-get-buffer))))
  (rename-buffer (if (string= pref-shell "shell") "*Django Shell*" "*Django DBshell*")))

(defun django-manage-shell ()
  (interactive)
  (django-manage--prep-shell "shell"))

(defun django-manage-dbshell ()
  (interactive)
  (django-manage--prep-shell "dbshell"))

(defun django-manage-insert-transpy (from to &optional buffer)
  ;; From http://garage.pimentech.net/libcommonDjango_django_emacs/
  ;; Modified a little
  (interactive "*r")
  (save-excursion
    (save-restriction
      (narrow-to-region from to)
      (goto-char from)
      (iso-iso2sgml from to)
      (insert "_(")
      (goto-char (point-max))
      (insert ")")
      (point-max))))

(defhydra django-manage-hydra (:color blue
                                      :hint nil)
  "
                    Manage.py
--------------------------------------------------

_mm_: Enter manage.py commnand    _r_: runserver      _f_: Flush             _t_: Run rest
_ma_: Makemigrations             _sa_: Start new app  _i_: Insert transpy
_mg_: Migrate                    _ss_: Run shell      _a_: Rebuild Assets
_me_: Make messages              _sd_: Run DB Shell   _c_: Compile messages

_q_: Cancel

"
  ("mm" django-manage-command)
  ("ma" django-manage-makemigrations)
  ("mg" django-manage-migrate)
  ("me" django-manage-makemessages)

  ("r"  django-manage-runserver "Start server")
  ("sa" django-manage-startapp)
  ("ss" django-manage-shell)
  ("sd" django-manage-dbshell)

  ("f"  django-manage-flush)
  ("a"  django-manage-assets-rebuild)
  ("c"  django-manage-compilemessages)
  ("t"  django-manage-test)

  ("i"  django-manage-insert-transpy)
  ("q"  nil "cancel"))

(defvar django-manage-map
      (let ((map (make-keymap)))
        (define-key map (kbd "C-c C-x") 'django-manage-hydra/body)
        map))

(defun setup-django-manage-mode ()
  "Determine whether to start minor mode or not"
  (when (and (stringp buffer-file-name)
             ;; (string-match django-files-regexp buffer-file-name)
             (locate-dominating-file default-directory "manage.py"))
    (django-manage-command)))

;;;###autoload
(define-minor-mode django-manage
  "Minor mode for handling Django's manage.py"
  :lighter " Manage"
  :keymap django-manage-map)

(easy-menu-define django-manage-menu django-manage-map "Django menu"
  '("Django"
    ["Start an app" django-manage-startapp t]
    ["Run tests" django-manage-test t]
    ["Make migrations" django-manage-makemigrations t]
    ["Flush database" django-manage-flush t]
    ["Runserver" django-manage-runserver t]
    ["Run database migrations" django-manage-migrate t]
    ["Rebuild assets" django-manage-assets-rebuild t]
    ["Make translations" django-manage-makemessages t]
    ["Compile translations" django-manage-compilemessages t]
    ["Open Python shell" django-manage-shell t]
    ["Open database shell" django-manage-dbshell t]
    ["Run other command" django-manage-command t]
    "-"
    ["Insert translation mark" django-manage-insert-transpy t]))

(easy-menu-add django-manage-menu django-manage-map)

(provide 'django-manage)
;; django-manage.el ends here
