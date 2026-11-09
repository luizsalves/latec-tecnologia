#!/bin/bash
# Instala/atualiza o site latecsolucoes.com.br no VPS (Ubuntu 24.04 + nginx).
# Uso (como root no VPS):
#   curl -fsSL https://raw.githubusercontent.com/luizsalves/latec-tecnologia/main/deploy/vps-setup.sh | bash
# Depois que o DNS apontar para o VPS, emitir o certificado:
#   certbot --nginx -d latecsolucoes.com.br -d www.latecsolucoes.com.br --redirect -m luiz@latecsolucoes.com.br --agree-tos -n
set -e
REPO=https://github.com/luizsalves/latec-tecnologia.git
SITE=/var/www/latecsolucoes

if [ -d "$SITE/.git" ]; then
  git -C "$SITE" pull --ff-only
else
  git clone -q "$REPO" "$SITE"
fi
chown -R www-data:www-data "$SITE"

cp "$SITE/deploy/nginx-latecsolucoes.conf" /etc/nginx/sites-available/latecsolucoes
ln -sf /etc/nginx/sites-available/latecsolucoes /etc/nginx/sites-enabled/latecsolucoes
nginx -t
systemctl reload nginx

# Atalho para futuras atualizações: basta rodar "deploy-latecsolucoes"
cat > /usr/local/bin/deploy-latecsolucoes <<'EOS'
#!/bin/bash
set -e
git -C /var/www/latecsolucoes pull --ff-only
chown -R www-data:www-data /var/www/latecsolucoes
cp /var/www/latecsolucoes/deploy/nginx-latecsolucoes.conf /etc/nginx/sites-available/latecsolucoes
nginx -t && systemctl reload nginx
echo "latecsolucoes atualizado: $(git -C /var/www/latecsolucoes log -1 --oneline)"
EOS
chmod +x /usr/local/bin/deploy-latecsolucoes

ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null

if ! command -v certbot >/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot python3-certbot-nginx >/dev/null
fi

echo "== teste local =="
curl -s -o /dev/null -w "site status=%{http_code} bytes=%{size_download}\n" -H "Host: www.latecsolucoes.com.br" http://127.0.0.1/
curl -s -o /dev/null -w "img  status=%{http_code}\n" -H "Host: latecsolucoes.com.br" http://127.0.0.1/img/rafa.png
echo "OK. Aponte o DNS de latecsolucoes.com.br e www para 200.141.19.25 e rode o certbot (ver cabecalho deste script)."
