#!/bin/bash

# --- Configurações ---
KEY="key-pair-stf.pem"
HOST="ubuntu@98.93.106.75"
USER="root"
PASS=""
DB="stf_data"
# Lista separada por espaço para evitar erro de sintaxe em shells simples
COLLECTIONS="deslocamentos recursos processos partes processos_unificados andamentos info"

echo "Iniciando exportação de $DB..."

for COL in $COLLECTIONS; do
    echo "------------------------------------------------"
    echo "Baixando coleção: $COL..."
    
    ssh -i "$KEY" "$HOST" \
    "docker exec mongo mongoexport --username $USER --password $PASS --authenticationDatabase admin --db $DB --collection $COL --quiet | gzip" > "${DB}_${COL}.jsonl.gz"
    
    echo "Finalizado: ${DB}_${COL}.jsonl.gz"
done

echo "------------------------------------------------"
echo "Todos os downloads foram concluídos!"
