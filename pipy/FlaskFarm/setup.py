#f = open('/data/PIPY/flaskfarm/flaskfarm/lib/framework/version.py').read()
import platform

import setuptools

#with open("README.md", "r") as fh:
#    long_description = fh.read()


if platform.system() == 'Windows':
    f = open('C:\\work\\FlaskFarm\\flaskfarm_support\\pipy\\flaskfarm\\flaskfarm\\lib\\framework\\version.py').read()
else:
    f = open('/data/flaskfarm_support/pipy/FlaskFarm/flaskfarm/lib/framework/version.py').read()

version = f.split('=')[1].replace('"', '').strip()
print(version)

setuptools.setup(
    name="FlaskFarm", # Replace with your own username
    version=version,
    author="flaskfarm",
    author_email="flaskfarm@gmail.com",
    description="FlaskFarm",
    long_description="",
    long_description_content_type="text/markdown",
    url="https://github.com/flaskfarm/flaskfarm",
    #packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU General Public License (GPL)",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.9',

    #package_dir={"flaskfarm": "src"},
    #packages=setuptools.find_packages(where="src"),
    #packages=['flaskfarm'],
    #py_modules=['flaskfarm'],
    #package_data={'flaskfarm' :['flaskfarm/files/*','flaskfarm/lib/*']}

    packages = [
        'flaskfarm',
        'flaskfarm.files',
        'flaskfarm.cli',
        'flaskfarm.lib.framework',
        'flaskfarm.lib.framework.static.css',
        'flaskfarm.lib.framework.static.css.theme',
        'flaskfarm.lib.framework.static.js',
        'flaskfarm.lib.framework.static.file',
        'flaskfarm.lib.framework.static.img',
        'flaskfarm.lib.framework.templates',
        'flaskfarm.lib.plugin',
        'flaskfarm.lib.support',
        'flaskfarm.lib.support.base',
        'flaskfarm.lib.support.expand',
        'flaskfarm.lib.support.libsc',
        'flaskfarm.lib.system',
        'flaskfarm.lib.system.templates',
        'flaskfarm.lib.system.files',
        'flaskfarm.lib.tool',
    ],

    package_data={
        'flaskfarm.files':['*'],
        'flaskfarm.cli':['*'],
        'flaskfarm.lib.framework':['*'],
        'flaskfarm.lib.framework.static.css':['*'],
        'flaskfarm.lib.framework.static.css.theme':['*'],
        'flaskfarm.lib.framework.static.js':['*'],
        'flaskfarm.lib.framework.static.file':['*'],
        'flaskfarm.lib.framework.static.img':['*'],
        'flaskfarm.lib.framework.templates':['*'],
        'flaskfarm.lib.plugin':['*'],
        'flaskfarm.lib.support':['*'],
        'flaskfarm.lib.support.base':['*'],
        'flaskfarm.lib.support.expand':['*'],
        'flaskfarm.lib.support.libsc':['*'],
        'flaskfarm.lib.system':['*'],
        'flaskfarm.lib.system.templates':['*'],
        'flaskfarm.lib.system.files':['*'],
        'flaskfarm.lib.tool':['*'],
    },

    install_requires=[
        "Flask",
        "Flask-SQLAlchemy",
        "Flask-Login",
        "Flask-Cors",
        #"Flask-Markdown",
        "Flask-SocketIO",
        "python-engineio",
        "python-socketio",
        "Werkzeug",
        "Jinja2",
        "markupsafe",
        "itsdangerous",
        "apscheduler",
        "pytz",
        "requests",
        "discord-webhook",
        "pyyaml",
        "telepot-mod",
        "Flask-Dropzone",
        "psutil",
        "pillow",
        "gevent",
        "gevent-websocket",
        "pycryptodome",
        #"celery",
        #"redis",
        "json_fix",
    ],
)
