#!/usr/bin/env bash
# Job semanal (cron, domingo 04:50): commit + push do que mudou em
#   /IncontreIA          → github useGvee/Incontre.IA  (evolução dos agentes)
#   /home/ubuntu/vps.infra → github useGvee/vps.infra  (config do servidor, via coletar.sh)
# Senhas conhecidas saem pelo filtro git (<SEGREDO:NOME>). Se a varredura achar algo com cara
# de senha nova, o repositório NÃO é enviado: o commit fica parado e o log registra o arquivo.
set -uo pipefail
LOG=/IncontreIA/VPS/Temp/versionar_semanal.log
DATA=$(date '+%d/%m/%Y')
exec >>"$LOG" 2>&1
echo "=== $(date '+%d/%m/%Y %H:%M') ==="

SUSPEITO='eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY|://[^/ :"]+:[^@/ <$"]{6,}@|PGPASSWORD=["'"'"']?[^<"'"'"' $]{6,}|client_secret["'"'"']?\s*[:=]\s*["'"'"']?[A-Za-z0-9._~-]{12,}'

versionar() {
  local dir=$1 nome=$2
  cd "$dir" || { echo "$nome: pasta não encontrada"; return 1; }
  git add -A
  if git diff --cached --quiet; then echo "$nome: sem mudanças"; return 0; fi
  local achados
  achados=$(git diff --cached -U0 | grep '^+' | grep -v '^+++' | grep -E -c "$SUSPEITO")
  if [ "$achados" -gt 0 ]; then
    echo "$nome: ⚠️ $achados linha(s) com cara de senha — NÃO enviado. Arquivos:"
    git diff --cached --name-only | while read -r f; do git diff --cached -U0 -- "$f" | grep '^+' | grep -q -E "$SUSPEITO" && echo "   $f"; done
    git reset -q
    return 2
  fi
  git commit -q -m "Atualização semanal $DATA

$(git diff --cached --stat | tail -1)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git push -q origin main && echo "$nome: enviado ($(git log -1 --format=%h))"
}

versionar /IncontreIA Incontre.IA
/home/ubuntu/vps.infra/coletar.sh >/dev/null && versionar /home/ubuntu/vps.infra vps.infra
