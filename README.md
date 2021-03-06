# Django Manage

Django minor mode for commanding `manage.py`

## Note

Influenced by [Django-mode](https://github.com/myfreeweb/django-mode)

## How to install

You can install it through Melpa:

```
package-install RET django-manage RET
```

## Setup

To have package automatically turned on when you go to a Django project. Add the following hook. Otherwise, to call it manually, just run `django-manage`.

```lisp
(add-hook 'python-mode-hook 'django-manage-setup)
```

You can also add a hook to your Html/Js/Css files if you want to be able to run
one of the commands such as `runserver`.

### virtualenv

If you develop in a virtualenv but don’t start Emacs from within, you
can set the `python-shell-interpreter` variable to the path of the
`python` binary inside the virtualenv (e.g. `venv/bin/python`.) This
makes sure all your Python packages get loaded from the virtualenv,
instead from the globally installed environment. You can do this with
`M-: (setq python-shell-interpreter "path/to/virtualenv/bin/python")`,
or using a `.dir-locals.el` file.

## Features
- Ability to control `manage.py`, no need to switch to a shell to run commands.
- Set custom variable `django-manage-root` for directory where `manage.py` lives.
- Command completion is available when running `C-c C-x mm`
- [Hydra](https://github.com/abo-abo/hydra) menu showing most commonly used commands. (At least for my setup :P)
- Select a string you want to translate and press `C-c C-x i` or call `django-insert-transpy`. This works in both Python and templates.

## Running management commands
Check out the Django menu :)
BTW, only one keybinding:

- `C-c C-x` Shows the Hydra menu


![Hydra Menu](https://cloud.githubusercontent.com/assets/1545083/10549513/6713b7e0-73f6-11e5-9e1a-7aacf3976174.png)
