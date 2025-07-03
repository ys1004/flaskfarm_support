SET ENV_HOME=C:\work\FlaskFarm\flaskfarm_support\pipy\flaskfarm\.env_win
SET CONFIG=C:\work\FlaskFarm\flaskfarm_support\pipy\data_win\config.yaml

CALL %ENV_HOME%\Scripts\activate
SET COUNT=0
:loop
    pip install --upgrade FlaskFarm
    python -B -m flaskfarm.main --repeat %COUNT% --config %CONFIG%
    ECHO PYTHON EXIT CODE : %errorlevel%..............
    if errorlevel == 1 (
        ECHO REPEAT....
        SET /a COUNT=%COUNT%+1
        GOTO loop
    ) else (
        ECHO FINISH....
    )
