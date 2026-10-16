# vps.infra

Configuração do VPS da Incontre (Oracle Cloud, Ubuntu) que serve gvee.com.br, incontre.net.br,
os subdomínios dos clientes Oracle APEX (`*.gvee.com.br`) e a plataforma Next.js + Supabase.

Os arquivos são **cópias** coletadas por `./coletar.sh`; a fonte de verdade continua no servidor.
Para registrar uma mudança: `./coletar.sh && git add -A && git commit -m "..." && git push`.

| Pasta | Origem no servidor |
|---|---|
| `nginx/` | `/etc/nginx` (nginx.conf, sites-available, snippets; `sites-enabled.txt` lista os ativos) |
| `letsencrypt/renewal/` | `/etc/letsencrypt/renewal` (só configuração; as chaves não vêm) |
| `cron/` | `crontab -l` do usuário ubuntu |
| `systemd/` | units próprias em `/etc/systemd/system` |
| `firewall/` | `iptables-save` |
| `ssh/config` | `~/.ssh/config` (aliases das deploy keys; as chaves não vêm) |
| `supabase/` | `/home/ubuntu/supabase/docker`: compose, diff contra o upstream e `.env.example` (só nomes) |
| `gvee/` | nomes das variáveis do `.env.local` do app GVEE |
| `systextil/repositorios.tsv` | lista dos ~330 clones em `/Systextil/workspace` (origem sem credenciais, branch, commit). O código é da Systextil e **não** vem para cá. Para reclonar: `tail -n +2 repositorios.tsv \| while IFS=$'\t' read p u b c; do git clone -b "$b" "$u" "$p" && git -C "$p" checkout -q "$c"; done` |

**Nunca entram:** chaves privadas, certificados, valores de `.env`. Senhas que apareçam em outros
arquivos são trocadas por `<SEGREDO:NOME>` pelo filtro `/IncontreIA/scripts/git_segredos.py`.
Os valores reais ficam no gerenciador de senhas e no backup criptografado (Oracle Object Storage).

Código: app GVEE em `useGvee/vps.gvee.com.br`; agentes em `useGvee/Incontre.IA`.
