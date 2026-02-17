@echo off
echo 🧪 Test du vrai backend (sans données mockées)
echo.

echo 🔍 1. Test de l'endpoint des rôles...
curl -s http://localhost:3002/api/v1/roles | jq .

echo.
echo 🔍 2. Test de l'endpoint des utilisateurs...
curl -s http://localhost:3002/api/v1/users | jq .

echo.
echo ✅ Test terminé ! Vérifiez que seul le rôle admin apparaît.

pause