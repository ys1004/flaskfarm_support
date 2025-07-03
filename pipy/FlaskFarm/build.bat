call C:\work\FlaskFarm\.env\Scripts\activate 
SET HOME=C:\work\FlaskFarm\flaskfarm_support\pipy\FlaskFarm

rmdir /s /q %HOME%\flaskfarm
rmdir /s /q %HOME%\build
rmdir /s /q %HOME%\dist
rmdir /s /q %HOME%\FlaskFarm.egg-info

mkdir %HOME%\flaskfarm
XCOPY C:\work\FlaskFarm\flaskfarm %HOME%\flaskfarm  /e /h /k

del /q %HOME%\flaskfarm\cli\*.log
del /q %HOME%\flaskfarm\lib\support\site\tving.py
del /q %HOME%\flaskfarm\lib\support\site\wavve.py
del /q %HOME%\flaskfarm\lib\support\site\seezn.py
del /q %HOME%\flaskfarm\lib\support\site\kakaotv.py
del /q %HOME%\flaskfarm\lib\support\site\cppl.py
del /q %HOME%\flaskfarm\lib\support\site\dl_watcha.py
python setup.py sdist bdist_wheel
python -m twine upload dist/*

rmdir /s /q %HOME%flaskfarm
rmdir /s /q %HOME%\build
rmdir /s /q %HOME%\dist
rmdir /s /q %HOME%\FlaskFarm.egg-info

