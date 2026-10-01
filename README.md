# Lite Academy — Moodle alojado por nós

Moodle oficial (o mesmo do MoodleCloud), num servidor nosso, **sem limite de utilizadores**.
Servidor: **PTisp VPS Linux Business** (6 vCPU, 6 GB RAM, 200 GB NVMe, Ubuntu 24) — 20,60 €/mês c/ IVA.
Cópia externa dos backups: Google Drive da conta do liteacademy.eu (0 €). **Total ≈ 20,60 €/mês.**
Prazo: a plataforma funciona até **1 de fevereiro de 2028** (ver "Plano até fevereiro de 2028").

```
Internet ──► Caddy (HTTPS automático) ──► Moodle (Apache + PHP 8.3) ──► PostgreSQL 17
                                              │                    └─► Redis (sessões)
                                              └─ cron (tarefas agendadas, a cada minuto)
```

| Ficheiro | Para quê |
|---|---|
| `docker-compose.yml` | Define todos os serviços |
| `.env.example` | Modelo das definições (copiar para `.env`) |
| `moodle/` | Imagem do Moodle (Dockerfile, config.php, PHP, Apache) |
| `scripts/setup-servidor.sh` | Prepara um servidor novo (Docker, firewall, swap) — 1 vez |
| `scripts/instalar.sh` | Instala o Moodle — 1 vez |
| `scripts/backup.sh` | Backup da base de dados + ficheiros (diário, automático) |
| `scripts/restaurar.sh` | Repõe um backup |
| `scripts/exportar-cursos.sh` | Exporta todas as disciplinas (.mbz), uma por ficheiro |
| `scripts/configurar-drive.sh` | Liga o servidor ao Google Drive para os backups — 1 vez |
| `scripts/atualizar.sh` | Atualiza o Moodle (com backup e modo de manutenção) |

---

## 1. O que é preciso antes de começar

- **Servidor**: PTisp **VPS Linux Business**, configurado assim:
  - Hostname: `forum.liteacademy.eu` (o mesmo subdomínio da plataforma)
  - Sistema operativo: **Ubuntu 24**
  - Segurança de sistema: *Sem segurança adicional* (o kit já instala firewall e fail2ban)
  - Painel de controlo: **Vou gerir pela linha de comandos** (sem cPanel/Plesk)
  - Backups: *Não quero…* (os backups são feitos pelo kit e copiados para o Google Drive)
  - LiteSpeed: *Sem LiteSpeed*
  - Periodicidade: **Mensal** (para cancelar exatamente em fevereiro de 2028)
- **Cópia externa dos backups**: Google Drive da conta do liteacademy.eu (ligado no passo 6).
- **Memória**: o `.env.example` já vem afinado para 6 GB. Noutro plano, ver os perfis no próprio ficheiro.
- **Domínio**: um subdomínio, ex.: `forum.liteacademy.eu`.
- **Email (SMTP)**: conta gratuita na Brevo (ou Mailgun/SES) com o domínio verificado — para os emails não irem para spam.

## 2. Criar o servidor e apontar o domínio

1. Criar o servidor (Ubuntu 24.04). Guardar o **IP**.
2. No painel da PTisp (zona DNS do domínio), criar um registo **A**: `forum` → `IP do servidor`.
3. Entrar no servidor: `ssh root@IP_DO_SERVIDOR`

## 3. Copiar o kit e preparar o servidor

```bash
git clone https://github.com/rochadesign-pt/lite-academy-moodle.git /opt/lite-academy-moodle
cd /opt/lite-academy-moodle
bash scripts/setup-servidor.sh
```

## 4. Preencher as definições

```bash
cp .env.example .env
openssl rand -base64 24     # gerar palavras-passe fortes (correr 2x: base de dados e admin)
nano .env                   # preencher domínio, palavras-passe, email/SMTP
```

## 5. Instalar o Moodle

```bash
bash scripts/instalar.sh
```

Demora ~5–10 minutos. No fim: abrir `https://forum.liteacademy.eu` e entrar com o utilizador admin.

## 6. Ativar os backups diários (às 03:00)

Primeiro, ligar o Google Drive (uma vez — precisa do Mac para autorizar no browser):
```bash
bash scripts/configurar-drive.sh
```
O servidor só tem acesso à pasta `LiteAcademy-Moodle` que ele próprio cria no Drive.

Depois, agendar:

```bash
crontab -e
```
Acrescentar a linha:
```
0 3 * * * cd /opt/lite-academy-moodle && bash scripts/backup.sh >> /var/log/moodle-backup.log 2>&1
```
E, para exportar todas as disciplinas no dia 1 de cada mês:
```
0 4 1 * * cd /opt/lite-academy-moodle && bash scripts/exportar-cursos.sh >> /var/log/moodle-export.log 2>&1
```
No servidor ficam 7 dias de backups (`backups/`) e as exportações (`exportacoes/`).
No Google Drive, em `LiteAcademy-Moodle/`:
- `base-de-dados/` — uma cópia por dia, 14 dias
- `ficheiros/` — espelho dos ficheiros da plataforma (só envia o que muda)
- `disciplinas/AAAA-MM-DD/` — exportação mensal de todas as disciplinas

Espaço: ocupa aproximadamente o tamanho dos conteúdos + ~1 GB. Com 15 GB livres chega,
a não ser que os professores carreguem muitos vídeos (nesse caso: vídeos no YouTube/Vimeo
em modo "não listado", e o Moodle só com o link).

## 7. Primeira configuração no Moodle (no browser, como admin)

1. **Idioma**: confirmar que está em Português (o instalador tenta instalar automaticamente;
   se não, *Administração do site › Geral › Idioma › Pacotes de idioma › Português*).
2. **Email**: *Administração do site › Servidor › Email › Testar configuração de email*.
3. **Aspeto**: *Administração do site › Aparência › Temas › Boost* — logótipo e cores da Lite Academy.
4. **Página inicial e política de privacidade** (RGPD): *Administração do site › Utilizadores › Privacidade e políticas*.

---

## Professores: só entram e colocam conteúdo

Toda a administração fica connosco; os professores só gerem as suas disciplinas.

1. **Criar a estrutura**: *Administração do site › Disciplinas › Gerir disciplinas e categorias* — criar categorias (ex.: por área/módulo).
2. **Criar as contas dos professores**: *Utilizadores › Contas › Adicionar utilizador* (ou carregar CSV).
3. **Dar acesso** — escolher uma das opções:
   - **A) Nós criamos a disciplina e inscrevemos o professor** com o papel *Professor* — ele edita tudo dentro dessa disciplina, e só dessa. *(mais controlo — recomendado)*
   - **B) O professor cria as próprias disciplinas**: atribuir o papel *Criador de disciplinas* na categoria dele
     (*Categoria › Atribuir papéis*). Fica automaticamente Professor das disciplinas que criar.
4. **Alunos**: carregar por CSV (*Utilizadores › Contas › Carregar utilizadores*) e inscrever nas disciplinas
   (ou usar coortes para inscrever turmas inteiras de uma vez).

Os professores **não** conseguem instalar plugins, mudar o tema ou mexer em definições do site.

---

## Migrar do MoodleCloud

1. **Ver a versão** do MoodleCloud (*Administração do site › Notificações*, no fundo). O nosso Moodle tem de ser
   **igual ou mais recente** para restaurar os cursos.
2. **Cursos**: em cada curso no MoodleCloud → *Mais › Reutilização de disciplinas › Cópia de segurança*
   → descarregar o `.mbz`. No novo Moodle → *Administração do site › Disciplinas › Restaurar disciplina*.
   (Desmarcar "incluir utilizadores" na cópia se quisermos apenas o conteúdo.)
3. **Utilizadores**: no MoodleCloud, *Utilizadores › Contas › Exportar utilizadores* (CSV); no novo,
   *Carregar utilizadores* com a opção de **gerar palavra-passe e enviar por email**.
4. Avisar professores e alunos do novo endereço.

---

## Conteúdos para o website da universidade

Há sempre três formas de ter o conteúdo fora da plataforma:

| O quê | Para quê | Como |
|---|---|---|
| **Backup completo** (diário) | Recuperar a plataforma inteira em caso de desastre | `scripts/backup.sh` (automático) |
| **Exportação das disciplinas** (.mbz, mensal) | Guardar cada disciplina completa (atividades, testes, ficheiros); restaurar noutro Moodle | `scripts/exportar-cursos.sh` |
| **ZIP do conteúdo da disciplina** | Material pronto a pôr no website: PDFs, vídeos, imagens e páginas | Na disciplina: *Mais › Descarregar conteúdo da disciplina* (já ativado pelo instalador) |

Nota: os ZIP incluem os recursos (ficheiros, páginas, pastas, URLs); atividades interativas
(testes, trabalhos, fóruns) só existem dentro do Moodle e ficam guardadas nos .mbz.

---

## Plano até fevereiro de 2028

| Quando | O quê |
|---|---|
| Arranque | Instalar com Moodle 5.2.x e migrar do MoodleCloud |
| Quando sair a 5.3 estável (≈ out./nov. 2026) | Atualizar para 5.3.x — garante atualizações de segurança até ao fim do projeto |
| Mensal | Atualizações menores (5.3.1, 5.3.2…) com `scripts/atualizar.sh` |
| Janeiro de 2028 | Descarregar o ZIP de cada disciplina para o website + exportação final (.mbz) + último backup completo, guardados fora do servidor |
| 1 de fevereiro de 2028 | Desligar a plataforma, cancelar o VPS, remover o registo DNS |
| Depois | Guardar apenas o que for necessário; apagar dados pessoais dos alunos (RGPD) |

---

## Manutenção (≈ 30 min/mês)

| Quando | O quê |
|---|---|
| Mensal | Atualizar o Moodle: ver a última versão em https://github.com/moodle/moodle/tags (mesma série, ex.: `v5.2.x`), mudar `MOODLE_VERSION` no `.env`, correr `bash scripts/atualizar.sh` |
| Mensal | Confirmar que há backups recentes: `ls -lh backups/` |
| Automático | Atualizações de segurança do Ubuntu (unattended-upgrades) |

Comandos úteis:
```bash
docker compose ps                     # estado dos serviços
docker compose logs -f moodle         # registos do Moodle
docker compose restart moodle         # reiniciar o Moodle
bash scripts/restaurar.sh 2026-10-01_0300   # repor um backup (pede confirmação)
```

Em caso de problema: copiar o resultado de `docker compose ps` e `docker compose logs --tail 100 moodle`
e enviar ao Claude.
