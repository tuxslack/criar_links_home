#!/usr/bin/env bash
#
# ========================================================================================
#
# Autor:         Fernando Souza https://github.com/tuxslack / https://www.youtube.com/@fernandosuporte
# Versão:        1.0
# Data:          06/11/2025
# Script:        criar_links_home.sh
# Repositório:   https://github.com/tuxslack/criar_links_home/
#
# Descrição:     
#                
# Mover as pastas dos usuários (Documentos, Modelos, Público, Imagens, Downloads, Vídeos, Músicas, Desktop, etc.) para outra partição ou HD no Linux.
#               
#
# Uso:
# 
#                
#
#
# Requisitos:    yad, bash etc...
#
# Compatibilidade: 
#
# notify-send não funciona se o script for executado em TTY (sem ambiente gráfico).
#
# ========================================================================================

# https://plus.diolinux.com.br/t/mover-as-pastas-de-usuario-documentos-imagens-downloads-etc-para-outra-particao-ou-hd/78412


# No Windows:

# 4:34 até 8:56 https://www.youtube.com/watch?v=vrS3iviGDFY

# No Linux seria altera o arquivo /etc/fstab e o ~/.config/user-dirs.dirs

# Ser essa teoria funcionar vai ajuda na migração do Windows 10.



# Configura partição NTFS compartilhada com Windows

# Se você vai compartilhar dados com uma partição NTFS usada pelo Windows — por exemplo, 
# montar o disco do Windows em /mnt/windows_dados e apontar user-dirs.dirs para lá. Assim, 
# seus Documentos e Downloads ficam acessíveis tanto no Windows quanto no Linux.

# https://plus.diolinux.com.br/t/mover-as-pastas-de-usuario-documentos-imagens-downloads-etc-para-outra-particao-ou-hd/78412/14

# ----------------------------------------------------------------------------------------

clear

# Arquivo de log

log="/tmp/erro.log"

sudo rm -Rf "$log"


logo="/usr/share/icons/gnome/48x48/apps/system-users.png"


# Pega o usuário ativo da sessão (usuário que executou o script) para usar esse nome no comando chown

USER_ATIVO=$(logname)


# Garantir que o script pare em qualquer erro

# set -euo pipefail

# Interrompe automaticamente se algum comando falhar.

# Isso também protege contra variáveis não definidas (-u) e falhas em pipelines (-o pipefail).

# ----------------------------------------------------------------------------------------

export DISPLAY=:0


# Forçar locale

# Nem todos os sistemas têm locale UTF-8 corretamente configurado, e o mv ou ln pode falhar 
# com nomes como Área de Trabalho.

# locale -a | grep -q 'pt_BR.utf8' || locale-gen pt_BR.UTF-8

export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8



# ----------------------------------------------------------------------------------------

# Função para sair se algo der errado

erro() {

  echo -e "\n❌ Erro: $1 \n"

  exit 1
}


# ----------------------------------------------------------------------------------------

# Verifica dependências

command -v yad >/dev/null 2>&1 || { echo "Programa yad não está instalado."; exit 1; }



MISSING=""

for CMD in notify-send sudo lsblk blkid umount mount mv cp xdg-user-dirs-update chown chmod tee rsync; do

    if ! command -v "$CMD" >/dev/null 2>&1; then

        MISSING="$MISSING $CMD"

    fi

done

if [ -n "$MISSING" ]; then

    yad --center --window-icon "$logo" --error --title="Erro de dependências" --text="Os seguintes programas não estão instalados:$MISSING\nInstale-os e tente novamente." --buttons-layout=center  --button=OK:0   --width="500" --height="100" 2>/dev/null

    exit 1
fi

# ----------------------------------------------------------------------------------------

yad \
    --center \
    --window-icon "$logo" \
    --icon-name=dialog-warning \
    --title="Aviso Importante" \
    --text="ATENÇÃO:\n\nEste script está em fase experimental.\nUso por sua conta e risco." \
    --text-align=center \
    --buttons-layout=center \
    --button=OK:0 \
    --no-wrap \
    --on-top \
    --width="400" \
    --height="200" \
    2>/dev/null



# Capturar o código de saída do YAD

exit_code=$?

if [ $exit_code -eq 0 ]; then

    echo "Usuário clicou em OK."

else

    echo "Usuário fechou a janela com X ou ocorreu um erro."

    exit 1
fi

# ----------------------------------------------------------------------------------------


# Verifica se é root

if [ "$EUID" -ne 0 ]; then

  echo -e "\n⚠️  Este script precisa ser executado como Root (sudo). \n" | tee -a "$log"

  yad --center --window-icon "$logo" --error --title="Erro" --text="\n⚠️  Este script precisa ser executado como Root (sudo). \n" --buttons-layout=center  --button=OK:0   --width="400" --height="100" 2>/dev/null

  exit 1

fi

# ----------------------------------------------------------------------------------------

echo "
⚠️ Aviso Técnico: Compartilhamento de Partições entre Windows e Linux em Ambientes Dual Boot

Em configurações de dual boot entre Windows e Linux, é possível montar e utilizar a mesma partição de dados (por exemplo, o diretório Imagens do Windows 
sendo acessado também pelo Linux).
Embora essa integração possa parecer prática inicialmente, há limitações e riscos técnicos conhecidos que podem comprometer a integridade dos dados e a 
compatibilidade entre os sistemas de arquivos.

1. Diferenças nas Regras de Nomes de Arquivos

O Windows impõe restrições a determinados caracteres que são válidos em sistemas Linux, como : * ? < > |.
Arquivos e diretórios criados no Linux contendo esses caracteres podem se tornar ilegíveis ou inacessíveis no Windows, dificultando o uso compartilhado 
da partição.

2. Sensibilidade a Maiúsculas e Minúsculas (Case Sensitivity)

Embora o NTFS possua suporte interno a distinção de maiúsculas e minúsculas, o Windows trata nomes de arquivos de forma case-insensitive.
Assim, arquivos como foto.jpg e FOTO.JPG, que coexistem normalmente em sistemas Linux (EXT4, por exemplo), são considerados o mesmo arquivo pelo Windows, 
gerando conflitos e perda de dados durante cópias entre partições.

3. Integridade de Dados em Caso de Falha do Windows

Se o Windows não for desligado corretamente (por exemplo, devido a queda de energia ou travamento), o sistema de arquivos NTFS pode ficar marcado como 
\"sujo\" (dirty bit).
Nessas situações, o Linux pode recusar montar a partição ou montá-la apenas em modo de leitura, impedindo gravações até que o Windows conclua a 
verificação do disco.

4. Limitações de Permissões e Atributos do Linux

O NTFS não oferece suporte completo às permissões POSIX (como chmod, chown e setfacl) nem a atributos estendidos usados em sistemas Linux.
Consequentemente, scripts e binários armazenados em partições NTFS podem perder permissões de execução ou apresentar comportamento incorreto.

5. Incompatibilidade com Links Simbólicos e Hard Links

O suporte a symlinks e hard links no NTFS é limitado e difere semanticamente do comportamento em sistemas Linux.
Aplicativos e ferramentas que dependem desses recursos podem apresentar falhas ou erros quando executados a partir de diretórios compartilhados entre 
os sistemas.

📁 Recomendações

O compartilhamento de partições entre Windows e Linux é adequado apenas para arquivos pessoais (como fotos, vídeos, documentos e PDFs).

Para usos técnicos ou de desenvolvimento (scripts, ferramentas, projetos com controle de versão, etc.), recomenda-se manter partições separadas com 
seus sistemas de arquivos nativos (EXT4 para Linux, NTFS para Windows).

Em ambientes mistos, considere o uso de sincronização via rede (ex.: Samba, Syncthing, ou serviços em nuvem) em vez de montar partições diretamente.
" | yad --center --window-icon="$logo" --title "Problemas conhecidos (Windows - NTFS)" --text-info --fontname "mono 10" --buttons-layout=center --button=OK:0 --width="1300" --height="830"  2> /dev/null

# ----------------------------------------------------------------------------------------

# Obtenha o UUID do disco

echo "🔍 Lista de partições disponíveis..." | tee -a "$log"

#  Usando 'lsblk' para listar partições.

sleep 1

# Selecionar partição com yad e registrar no log


# Exibe lista de partições no yad (usando sudo)

sudo lsblk -o NAME,MOUNTPOINT,LABEL,FSTYPE,SIZE,UUID

particoes=$(sudo lsblk -o NAME,MOUNTPOINT,LABEL,FSTYPE,SIZE,UUID | tee -a "$log")


# Mostra a lista num diálogo informativo

yad --center --window-icon "$logo" --title="Partições detectadas" \
    --text="Lista de partições disponíveis:\n\n<tt>$particoes</tt>\n\n⚠️ Obs: Não selecione dispositivos USB (pendrives ou HDs/SSD externos)." \
    --button="Continuar:0" \
    --width="1200" --height="400" \
    2>/dev/null

# Pede o UUID da partição desejada

UUID=$(yad --center --window-icon "$logo"  --entry \
    --title="Selecionar partição de dados" \
    --text="👉 Cole o UUID da partição de dados abaixo:" \
    --entry-label="UUID:" \
    --width="400" \
    2>/dev/null)

# Verifica se o usuário digitou algo

if [[ -z "$UUID" ]]; then

    yad --center --window-icon "$logo" --error --title="Erro" --text="Nenhum UUID informado. Operação cancelada." 2>/dev/null

    exit 1

fi

echo "UUID selecionado: $UUID" | tee -a "$log"

yad --center --window-icon "$logo" --info --title="Confirmação" --text="UUID informado:\n\n<b>$UUID</b>\n\nRegistro salvo em $log" 2>/dev/null





# Define ponto de montagem

MOUNT_POINT="/mnt/dados"

# Nontar a nova partição

# A variável $particao será definida automaticamente a partir do UUID que o usuário informar.


# Descobre o nome do dispositivo com base no UUID informado

particao=$(blkid -U "$UUID" 2>/dev/null)

# blkid -U "$UUID" → retorna o dispositivo (exemplo: /dev/sda2) correspondente ao UUID informado.

if [ -z "$particao" ]; then

    echo -e "\n❌ UUID não encontrado. Verifique e tente novamente. \n"

    yad --center --window-icon "$logo" --error --title="Erro" --text="\n❌ UUID não encontrado. Verifique e tente novamente. \n" --buttons-layout=center  --button=OK:0   --width="400" --height="100" 2>/dev/null

    exit 1

fi


echo "✅ Partição detectada: $particao" | tee -a "$log"


notify-send -i gtk-dialog-info  -t 100000 "✅ Arquivo de log..." "
           
Partição detectada: $particao"


# Desmonta se já estiver montada

sudo umount "$particao" 2>/dev/null



# Cria o ponto de montagem se necessário

sudo mkdir -p "$MOUNT_POINT" 2>> "$log"

# Monta a partição


fstype=$(blkid -o value -s TYPE "$particao")

# Para NTFS, o driver correto é ntfs-3g, mas blkid retorna apenas ntfs.

if [ "$fstype" = "ntfs" ]; then

    fstype="ntfs-3g"

fi


sudo mount -t "$fstype" "$particao" "$MOUNT_POINT" 2>> "$log"



echo -e "\n✅ Partição $fstype montada em $MOUNT_POINT \n"


notify-send -i gtk-dialog-info  -t 100000 "✅ Arquivo de log..." "
           
Partição $fstype montada em $MOUNT_POINT"


# Backup do arquivo fstab

cp /etc/fstab /etc/fstab.backup_$(date +%d%m%Y_%H%M%S) 2>> "$log"


# Edite o arquivo /etc/fstab

notify-send -i gtk-dialog-info  -t 100000 "✅ Arquivo de log..." "
           
Editando o arquivo /etc/fstab..."

echo -e "\nEditando o arquivo /etc/fstab... \n"

sleep 1

# Adiciona entrada no fstab se não existir


if ! grep -q "$UUID" /etc/fstab; then


# Suportar EXT4 e NTFS

if [ "$fstype" = "ntfs-3g" ]; then

    # Para NTFS, adiciona auto ou users para permitir montagem automática por usuários.

    # Caso o Windows use Fast Startup, a partição NTFS pode ser montada apenas em leitura.

    echo "UUID=$UUID  $MOUNT_POINT  $fstype  defaults,uid=1000,gid=1000,windows_names,auto 0 0" >> /etc/fstab

else

    echo "UUID=$UUID  $MOUNT_POINT  $fstype  defaults  0  2" >> /etc/fstab

fi



fi



# Exemplo para ntfs

# UUID=9ABCDEF012345678  /mnt/dados  ntfs-3g  defaults,uid=1000,gid=1000,windows_names  0  0


# Isso garante que o disco será montado automaticamente a cada boot.


# Monta a partição

# Se a linha nova tiver erro de sintaxe, isso pode desmontar ou falhar silenciosamente.

mount -a -v | tee -a "$log" || erro "Falha ao montar a partição (verifique o fstab)."


# ----------------------------------------------------------------------------------------


USUARIOS=$(yad --center --window-icon "$logo" --entry --title="Usuários" --text="Digite todos os nomes separados por espaço (ex: joao maria pedro)" 2>/dev/null)


if [ -z "$USUARIOS" ]; then

    echo -e "\n❌ Usuários não encontrado.\n"

    yad --center --window-icon "$logo" --error --title="Erro" --text="\n❌ Usuários não encontrado. \n" --buttons-layout=center  --button=OK:0   --width="400" --height="100" 2>/dev/null

    exit 1

fi



for USUARIO in $USUARIOS; do

  echo -e "\n⚙️  Configurando usuário: $USUARIO \n"

  HOME_DIR="/home/$USUARIO"

  if [ ! -d "$HOME_DIR" ]; then

    echo -e "\n❗ Usuário $USUARIO não encontrado, pulando... \n"

    continue

  fi


notify-send -i gtk-dialog-info  -t 100000 "👥 Arquivo de log..." "
Configurando os usuários..."

echo -e "\n👥 Configurando os usuários... \n"

sleep 1

# ----------------------------------------------------------------------------------------

# Verifica se o diretório existe


if [[ -d "$HOME_DIR/Área de Trabalho" ]]; then

  pasta_desktop="Área de Trabalho"

elif [[ -d "$HOME_DIR/Desktop" ]]; then

  pasta_desktop="Desktop"

else

  pasta_desktop="Desktop"  # fallback

fi


# ----------------------------------------------------------------------------------------

# Cria pastas compartilhadas


# Com vários usuários

# sudo mkdir -p $MOUNT_POINT/$USUARIO/{Documentos,Modelos,Público,Imagens,Downloads,Vídeos,Músicas,Desktop}


# mkdir -p ~/{Documentos,Modelos,Público,Imagens,Downloads,Vídeos,Músicas,Desktop}


for pasta in Documentos Modelos Público Imagens Downloads Vídeos Músicas "$pasta_desktop"; do

  mkdir -p "$MOUNT_POINT/$USUARIO/$pasta" 2>> "$log"

  sudo chown -R "$USUARIO:$USUARIO" "$MOUNT_POINT/$USUARIO/$pasta" 2>> "$log"

done

# ----------------------------------------------------------------------------------------


# Mover as pastas de usuário (Documentos, Modelos, Público, Imagens, Downloads, Vídeos, Músicas, Desktop, etc.)

notify-send -i gtk-dialog-info  -t 100000 "👤️ Arquivo de log..." "
📁 Movendo as pastas (Documentos, Modelos, Público, Imagens, Downloads, Vídeos, Músicas, Desktop, etc.) do usuário $USUARIO..."



# Se já existirem pastas dentro de $MOUNT_POINT/$USUARIO/, o mv falha ou mescla de forma incorreta.

for pasta in Documentos Modelos Público Imagens Downloads Vídeos Músicas "$pasta_desktop"; do

  if [ -d "$HOME_DIR/$pasta" ] && [ ! -d "$MOUNT_POINT/$USUARIO/$pasta" ]; then

   # Movimentação de pastas pode sobrescrever dados

   # sudo mv -v "$HOME_DIR/$pasta" "$MOUNT_POINT/$USUARIO/" 2>&1 | tee -a "$log"


   sudo rsync -aAXv --remove-source-files "$HOME_DIR/$pasta/" "$MOUNT_POINT/$USUARIO/$pasta/" 2>&1

   sudo find "$HOME_DIR/$pasta" -type d -empty -delete




  else

    echo "Pasta $pasta não existe." | tee -a "$log"

  fi

done


# Para o comando mv:

# -v => mostra progresso.




# sudo rsync -aAXv --remove-source-files /origem/pasta/ /destino/pasta/


# Explicação:

# -a → modo arquivamento (recursivo + preserva metadados básicos)

# -A → preserva ACLs

# -X → preserva atributos estendidos

# -v → verbose (mostra o que está sendo feito)

# --remove-source-files → remove arquivos da origem depois de copiar com sucesso



# Para remover diretórios vazios que ficaram em /origem/pasta/:

# find /origem/pasta/ -type d -empty -delete


# ----------------------------------------------------------------------------------------

  # Corrige permissões gerais

notify-send -i gtk-dialog-info  -t 50000 "👮️ Arquivo de log..." "
Corrigindo permissões nas pastas (Documentos, Modelos, Público, Imagens, Downloads, Vídeos, Músicas, Desktop, etc.) para o usuário $USUARIO via chown..."

  # Garanta que o usuário tenha permissão total nas pastas dele na nova partição.

  chown -R "$USUARIO:$USUARIO" "$MOUNT_POINT/$USUARIO" 2>> "$log"




# Atualizar o arquivo user-dirs.dirs

echo -e "\nAtualizando o arquivo $HOME_DIR/.config/user-dirs.dirs... \n"

sleep 1

notify-send -i gtk-dialog-info  -t 100000 "🔥️ Arquivo de log..." "Atualizando o arquivo $HOME_DIR/.config/user-dirs.dirs..."


  # Configura user-dirs.dirs

  USER_DIRS_FILE="$HOME_DIR/.config/user-dirs.dirs"


  # Se o diretório ~/.config não existir, o cat > ... <<EOF pode falhar silenciosamente.

  mkdir -p "$(dirname "$USER_DIRS_FILE")" || erro "Falha ao criar $(dirname "$USER_DIRS_FILE")"



# Backup do arquivo user-dirs.dirs

cp "$USER_DIRS_FILE" "$USER_DIRS_FILE"_$(date +%d%m%Y_%H%M%S) 2>> "$log"



# Alguns sistemas não lidam bem com acentuação em "Área de Trabalho".

  cat > "$USER_DIRS_FILE" <<EOF

# Arquivo gerado automaticamente

XDG_DESKTOP_DIR="$MOUNT_POINT/$USUARIO/$pasta_desktop"
XDG_DOWNLOAD_DIR="$MOUNT_POINT/$USUARIO/Downloads"
XDG_DOCUMENTS_DIR="$MOUNT_POINT/$USUARIO/Documentos"
XDG_PICTURES_DIR="$MOUNT_POINT/$USUARIO/Imagens"
XDG_VIDEOS_DIR="$MOUNT_POINT/$USUARIO/Vídeos"
XDG_MUSIC_DIR="$MOUNT_POINT/$USUARIO/Músicas"
XDG_TEMPLATES_DIR="$MOUNT_POINT/$USUARIO/Modelos"
XDG_PUBLICSHARE_DIR="$MOUNT_POINT/$USUARIO/Público"
EOF


# Usar xdg-user-dirs-update --set em vez de sobrescrever o arquivo manualmente:

# sudo -u "$USUARIO" xdg-user-dirs-update --set DOCUMENTS "$MOUNT_POINT/$USUARIO/Documentos"


  # Permissões

  sudo chown -R "$USUARIO:$USUARIO" "$USER_DIRS_FILE" 2>> "$log"

  sudo chmod -R 755 "$USER_DIRS_FILE" 2>> "$log"


  # Usa o nome para ajustar o dono

  sudo chown -R "$USER_ATIVO":"$USER_ATIVO" "$USER_DIRS_FILE"*




# Removendo as pastas...

rm -Rf "$HOME_DIR"/{Documentos,Modelos,Público,Imagens,Downloads,Vídeos,Músicas,"$pasta_desktop"} 2>> "$log"

sleep 1

  # Crie links simbólicos apontando para o novo local.

  # Não esta criando o link simbólico da pasta Desktop.

echo -e "\n$(date '+%d-%m-%Y %H:%M:%S')\n\nCriando os links simbólicos em $HOME_DIR... \n"  | tee -a "$log"

notify-send -i gtk-dialog-info  -t 100000 "🔥️ Arquivo de log..." "
Criando os links simbólicos das pastas (Documentos, Modelos, Público, Imagens, Downloads, Vídeos, Músicas, Desktop, etc.) para o usuário $USUARIO em $HOME_DIR..."




sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/$pasta_desktop" "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Downloads"      "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Documentos"     "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Imagens"        "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Vídeos"         "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Músicas"        "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Modelos"        "$HOME_DIR/"   2>> "$log"
sudo -u "$USUARIO" ln -sf "$MOUNT_POINT/$USUARIO/Público"        "$HOME_DIR/"   2>> "$log"




# Desta forma, cada link simbólico terá o nome correto dentro do diretório do usuário.


sleep 2

# Assim, programas que esperam essas pastas no /home continuam funcionando normalmente.


notify-send -i gtk-dialog-info  -t 10000 "👤️ Arquivo de log..." "
Executando xdg-user-dirs-update para o usuário $USUARIO..."

# Rode para o usuário:

# Pode falhar se o script for executado fora do ambiente gráfico (por exemplo, via TTY ou cron), porque DISPLAY e DBUS_SESSION_BUS_ADDRESS podem não estar definidos.

sudo -u "$USUARIO" bash -c "xdg-user-dirs-update" 2>> "$log"

  sleep 1


  echo -e "\n✅ Usuário $USUARIO configurado. \n"

  sleep 5

notify-send -i gtk-dialog-info  -t 10000 "🎉 Arquivo de log..." "
👤️ Usuário $USUARIO configurado..."



done

# ----------------------------------------------------------------------------------------


# A variavel $pasta_desktop no final do script, esta fora do for USUARIO in ..., que é redefinida a cada iteração.


if [[ -d "$HOME_DIR/Área de Trabalho" ]]; then

  pasta_desktop="Área de Trabalho"

else

  pasta_desktop="Desktop"

fi


# ----------------------------------------------------------------------------------------

# Configuração concluída!

echo -e '\n------------------------------------------------------------------------------------\n

🎉 Configuração concluída para os usuários: '$USUARIOS'

📁 Partição montada em: '$MOUNT_POINT'
📂 Pastas configuradas em: '$MOUNT_POINT'/{Documentos,Modelos,Público,Imagens,Downloads,Vídeos,Músicas,'$pasta_desktop'}
🧾 Backup do fstab salvo em: /etc/fstab.backup_...
📁 Arquivo de configuração: '$USER_DIRS_FILE'
💡 Reinicie a sessão do usuário ('$USUARIOS') ou o sistema para aplicar totalmente as mudanças.


Se o Windows usar "Inicialização Rápida" (Fast Startup), desative

Painel de Controle → Opções de Energia → Escolher a função dos botões de energia → 
Desmarque "Ligar inicialização rápida"

Para desfazer essas ações:

$ rm ~/{Documentos,Modelos,Público,Imagens,Downloads,Vídeos,Músicas,Desktop}

$ rm ~/.config/user-dirs.dirs

$ sudo reboot

\n------------------------------------------------------------------------------------\n' | yad --center --window-icon="$logo" --title "Configuração concluída!" --text-info --fontname "mono 10" --buttons-layout=center --button=OK:0 --width="1300" --height="650"  2>> /dev/null

# ----------------------------------------------------------------------------------------

sudo chmod 777 "$log"


# Usa o nome para ajustar o dono

sudo chown -R "$USER_ATIVO":"$USER_ATIVO" "$log"

sleep 1


echo -e "\n\nArquivo de log: \n"

cat "$log"


notify-send -i gtk-dialog-info  -t 100000 "📄️ Arquivo de log..." "
           
Verifique o arquivo: $log"

# ----------------------------------------------------------------------------------------

# Reinicie...




exit 0

