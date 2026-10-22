#!/bin/bash

# ====================================================
# CERINTA 1: Importa codurile valide din coduri.txt
# ====================================================

# Fisierele sunt cautate langa script, indiferent din ce folder este rulat
cd "$(dirname "$0")" || exit 1

CODURI_FILE="coduri.txt"
FOLOSITE_FILE="coduri_folosite.txt"
REZULTATE_FILE="rezultate.txt"
OPTIUNI_FILE="optiuni.txt"

# Optiunile de vot se citesc din optiuni.txt (cate una pe linie)
OPTIUNI=()
if [[ -s "$OPTIUNI_FILE" ]]; then
    while IFS= read -r linie || [[ -n "$linie" ]]; do
        linie=$(echo "$linie" | tr -d '\r' | xargs | tr '[:lower:]' '[:upper:]')
        [[ -n "$linie" ]] && OPTIUNI+=("$linie")
    done < "$OPTIUNI_FILE"
fi

# Daca fisierul lipseste sau e gol, folosim optiunile implicite
[[ ${#OPTIUNI[@]} -eq 0 ]] && OPTIUNI=("A" "B" "C")

# Culori (doar daca rulam intr-un terminal real)
if [[ -t 1 ]]; then
    VERDE=$'\e[32m'; ROSU=$'\e[31m'; GALBEN=$'\e[33m'; BOLD=$'\e[1m'; RESET=$'\e[0m'
else
    VERDE=""; ROSU=""; GALBEN=""; BOLD=""; RESET=""
fi

function eroare { echo "${ROSU}✗ $1${RESET}"; }
function succes { echo "${VERDE}✓ $1${RESET}"; }

# Ne vom asigura ca fisierele exista
touch "$CODURI_FILE"
touch "$FOLOSITE_FILE"
touch "$REZULTATE_FILE"

# ====================================================
# CERINTA 2: Permite introducerea codului de vot(cheile
#            de acces) si verifica daca este valid
#            si nefolosit
# ====================================================

function valideaza_cod {
    cod="$1"
    # -i: nu conteaza literele mari/mici; tr -d '\r': accepta si fisiere salvate pe Windows
    if tr -d '\r' < "$CODURI_FILE" | grep -Fxqi -- "$cod"; then
        if grep -Fxqi -- "$cod" "$FOLOSITE_FILE"; then
            eroare "Codul a fost deja folosit."
            return 1
        else
            return 0
        fi
    else
        eroare "Codul este invalid."
        return 1
    fi
}

# ====================================================
# CERINTA 3: Prezinta o lista de optiuni (ex: A, B, C)
# ====================================================

function afiseaza_optiuni {
    echo "Optiuni disponibile pentru vot:"
    for opt in "${OPTIUNI[@]}"; do
        echo " - $opt"
    done
}

# ====================================================
# CERINTELE 4, 5: Inregistreaza votul in rezultate.txt
#                si marchează codul in coduri_folosite.txt
# ====================================================

function voteaza {
    read -r -p "Introdu codul tau de votare: " cod || return
    cod=$(echo "$cod" | xargs)
    cod=$(echo "$cod" | tr '[:lower:]' '[:upper:]')

    if [[ -z "$cod" ]]; then
        eroare "Nu ai introdus niciun cod. Incearca din nou."
        return
    fi

    if ! [[ "$cod" =~ ^[A-Za-z0-9]+$ ]]; then
        eroare "Codul contine caractere invalide. Incearca din nou."
        return
    fi
    valideaza_cod "$cod" || return

    afiseaza_optiuni
    read -r -p "Introdu optiunea ta ($(IFS=/; echo "${OPTIUNI[*]}")): " vot || return
    if [[ -z "$vot" ]]; then
        eroare "Nu ai introdus nicio optiune. Votul nu a fost inregistrat. Incearca din nou."
        return
    fi

    vot_upper=$(echo "$vot" | xargs | tr '[:lower:]' '[:upper:]')

    # Verificam optiunea comparand-o exact cu fiecare element din lista
    valid=1
    for opt in "${OPTIUNI[@]}"; do
        [[ "$opt" == "$vot_upper" ]] && valid=0
    done

    if (( valid == 0 )); then

        # CERINTA 4: Salvare vot in rezultate.txt
        echo "$vot_upper" >> "$REZULTATE_FILE"

        # CERINTA 5: Salvare cod in coduri_folosite.txt
        echo "$cod" >> "$FOLOSITE_FILE"

        succes "Votul a fost inregistrat cu succes."
    else
        eroare "Optiune invalida. Incearca din nou"
    fi
}

# ====================================================
# CERINTA 6: Ofera optiunea de a vizualiza rezultatele
# ====================================================

function afiseaza_rezultate {
    total=$(( $(wc -l < "$REZULTATE_FILE") ))
    echo "${BOLD}Rezultate vot:${RESET}"

    # Daca nu exista voturi, nu avem ce afisa (si evitam impartirea la 0)
    if (( total == 0 )); then
        echo "Nu a fost exprimat inca niciun vot."
        return
    fi

    # Latimea coloanei = cea mai lunga optiune, ca barele sa fie aliniate
    latime=0
    for opt in "${OPTIUNI[@]}"; do
        (( ${#opt} > latime )) && latime=${#opt}
    done

    maxim=0
    castigatori=()
    for opt in "${OPTIUNI[@]}"; do
        count=$(grep -c "^$opt$" "$REZULTATE_FILE")
        procent=$(( count * 100 / total ))

        # Bara de 20 de casute: una plina pentru fiecare 5%
        bara=""
        for (( i = 0; i < 20; i++ )); do
            if (( i < procent / 5 )); then bara+="█"; else bara+="░"; fi
        done

        if (( count == 1 )); then cuvant="vot"; else cuvant="voturi"; fi
        printf "  %-*s  %s %3d%%  (%d %s)\n" "$latime" "$opt" "$bara" "$procent" "$count" "$cuvant"

        # Retinem optiunea (sau optiunile, la egalitate) cu cele mai multe voturi
        if (( count > maxim )); then
            maxim=$count
            castigatori=("$opt")
        elif (( count == maxim )); then
            castigatori+=("$opt")
        fi
    done

    echo "Totalul voturilor exprimate este: $total"
    if (( ${#castigatori[@]} == 1 )); then
        echo "${GALBEN}${BOLD}🏆 Castigator: ${castigatori[0]}${RESET}"
    else
        echo "${GALBEN}${BOLD}⚖️  Egalitate intre: ${castigatori[*]}${RESET}"
    fi
}

# ====================================================
# Genereaza coduri noi de vot, unice si aleatoare
# ====================================================

function genereaza_coduri {
    read -r -p "Cate coduri noi vrei sa generezi? " n || return

    # Acceptam doar numere intre 1 si 1000
    if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 || n > 1000 )); then
        eroare "Introdu un numar intre 1 si 1000."
        return
    fi

    generate=0
    while (( generate < n )); do
        # VOT + 6 caractere aleatoare (litere mari si cifre)
        cod="VOT$(LC_ALL=C tr -dc 'A-Z0-9' < /dev/urandom | head -c 6)"

        # Il adaugam doar daca nu exista deja
        if ! grep -Fxq "$cod" "$CODURI_FILE"; then
            echo "$cod" >> "$CODURI_FILE"
            echo "  $cod"
            (( generate++ ))
        fi
    done
    succes "Au fost adaugate $n coduri noi in $CODURI_FILE."
}

# ====================================================
# Meniu principal – interfata aplicatiei
# ====================================================

while true; do
    echo ""
    echo "=== Sistem de Vot Colectiv ==="
    echo "1. Voteaza"
    echo "2. Vizualizeaza rezultatele voturilor"
    echo "3. Genereaza coduri noi de vot"
    echo "4. Iesire din aplicatie"

    # Daca inputul se termina (Ctrl+D), iesim curat in loc sa intram in bucla infinita
    if ! read -r -p "Alege o optiune: " alegere; then
        echo ""
        echo "Ai iesit din aplicatie. La revedere!"
        exit 0
    fi

    case "$alegere" in
        1) voteaza ;;
        2) afiseaza_rezultate ;;
        3) genereaza_coduri ;;
        4) echo "Ai iesit din aplicatie. La revedere!"; exit 0 ;;
        *) eroare "Optiune invalida. Incearca din nou!" ;;
    esac
done
