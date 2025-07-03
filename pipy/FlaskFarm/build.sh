#!/bin/bash
HOME=/data/flaskfarm_support/pipy/FlaskFarm
rm -rf $HOME/flaskfarm
rm -rf $HOME/build
rm -rf $HOME/dist
rm -rf $HOME/FlaskFarm.egg-info
cp -R /data/flaskfarm $HOME

find $HOME/flaskfarm -type f -name "*.sh" -exec rm {} \;
find $HOME/flaskfarm -type f -name "*.log" -exec rm {} \;
find $HOME/flaskfarm -type d -name "__pycache__" -exec rm -rf {} \;

python setup.py sdist bdist_wheel
python -m twine upload dist/*

rm -rf $HOME/flaskfarm
rm -rf $HOME/build
rm -rf $HOME/dist
rm -rf $HOME/FlaskFarm.egg-info
