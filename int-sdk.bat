@echo on
@echo int-sdk.bat
REM
REM batch file to set up integration sdk builds
REM


if "%INTEGRATIONS_REPO%" == "" set INTEGRATIONS_REPO=integrations-core
set OMNIBUS_RUBY_BRANCH=datadog-5.5.0

@echo bundle update
call bundle update
@echo bundle install
call bundle install

set PROJECT_ROOT=%~dp0
if #%PROJECT_ROOT:~-1%# == #\# set PROJECT_ROOT=%PROJECT_ROOT:~0,-1%

@echo PROJECT_ROOT is -%PROJECT_ROOT%-
@echo .
@echo INTEGRATIONS_REPO: %INTEGRATIONS_REPO%
@echo OMNIBUS_RUBY_BRANCH: %OMNIBUS_RUBY_BRANCH%
@echo INTEGRATION: %INTEGRATION%
@echo .
@echo type rake agent:build-integration to start build