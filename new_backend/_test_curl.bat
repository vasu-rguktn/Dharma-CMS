@echo off
cd /d c:\Hari\Personal\Dharma-CMS-main\new_backend
set /p TOKEN=<_token.txt

echo === GET /accounts/me ===
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8000/accounts/me > _r1.json
type _r1.json
echo.

echo === PATCH /accounts/me (camelCase) ===
curl -s -X PATCH -H "Authorization: Bearer %TOKEN%" -H "Content-Type: application/json" -d "{\"displayName\":\"CamelCase Test\",\"phoneNumber\":\"9876543210\"}" http://localhost:8000/accounts/me > _r2.json
type _r2.json
echo.

echo === GET citizen-profile ===
curl -s -H "Authorization: Bearer %TOKEN%" http://localhost:8000/accounts/me/citizen-profile > _r3.json
type _r3.json
echo.
