#!/usr/bin/env bash
# Copia para este repositório as configurações do VPS que permitem remontá-lo.
# Nunca copia chaves privadas nem valores de .env: só os NOMES das variáveis (.env.example).
# Senhas que apareçam em outros arquivos são trocadas por <SEGREDO:NOME> pelo filtro git
# (/IncontreIA/scripts/git_segredos.py). Uso: ./coletar.sh && git add -A && git commit
set -euo pipefail
cd "$(dirname "$0")"
R=$PWD

copiar() { mkdir -p "$R/$2"; sudo cp -a "$1" "$R/$2/"; }

# nginx
sudo rm -rf nginx; mkdir -p nginx
sudo cp -a /etc/nginx/nginx.conf /etc/nginx/sites-available /etc/nginx/snippets /etc/nginx/conf.d nginx/
ls -l /etc/nginx/sites-enabled | awk 'NR>1{print $9" -> "($11==""?"(arquivo próprio, em sites-enabled/)":$11)}' > nginx/sites-enabled.txt
# sites ativos que são arquivo comum (não link para sites-available)
mkdir -p nginx/sites-enabled
find /etc/nginx/sites-enabled -maxdepth 1 -type f -exec sudo cp -a {} nginx/sites-enabled/ \;

# certificados: só a configuração de renovação (sem chaves)
sudo rm -rf letsencrypt; mkdir -p letsencrypt
sudo cp -a /etc/letsencrypt/renewal letsencrypt/

# cron e systemd
mkdir -p cron systemd
crontab -l > cron/crontab-ubuntu.txt
sudo cp -a /etc/systemd/system/smart-nextjs.service systemd/

# firewall
mkdir -p firewall
sudo iptables-save | sed -E 's/\[[0-9]+:[0-9]+\]/[0:0]/' > firewall/iptables.rules

# ssh: só o config (as chaves ficam fora)
mkdir -p ssh; cp ~/.ssh/config ssh/config

# Supabase self-hosted: compose + .env só com os nomes das variáveis
sudo rm -rf supabase; mkdir -p supabase
cp /home/ubuntu/supabase/docker/docker-compose.yml supabase/
(cd /home/ubuntu/supabase && git diff docker/docker-compose.yml) > supabase/docker-compose.alteracoes.diff
(cd /home/ubuntu/supabase && git rev-parse HEAD) > supabase/versao-upstream.txt
sed -E 's/^([A-Za-z_][A-Za-z0-9_]*)=.*/\1=/' /home/ubuntu/supabase/docker/.env > supabase/.env.example

# App GVEE: nomes das variáveis do .env.local
mkdir -p gvee; sed -E 's/^([A-Za-z_][A-Za-z0-9_]*)=.*/\1=/' /home/ubuntu/projects/GVEE/.env.local > gvee/.env.local.example

# Systextil: lista dos clones em /Systextil/workspace (o código é da Systextil e não vem para cá).
# Endereço sem credenciais + branch + commit, para reclonar tudo na mesma versão.
mkdir -p systextil
{
  printf 'pasta\torigem\tbranch\tcommit\n'
  for d in /Systextil/workspace/*/; do
    [ -d "$d.git" ] || continue
    url=$(sudo git -C "$d" remote get-url origin 2>/dev/null | sed -E 's#(https?://)[^@/]+@#\1#' || true)
    br=$(sudo git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    ci=$(sudo git -C "$d" rev-parse HEAD 2>/dev/null || true)
    printf '%s\t%s\t%s\t%s\n' "$(basename "$d")" "${url:--}" "${br:--}" "${ci:--}"
  done
} > systextil/repositorios.tsv

sudo chown -R "$(id -u):$(id -g)" "$R"
echo "coletado em $(date '+%d/%m/%Y %H:%M')"
