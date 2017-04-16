#!/bin/bash
#Objetivo do script e verificar quais arquivos tiveram alteracao.

set -u

E_OPTERROR=85

err() {
  echo "$@" >&2
}

log() {
  echo "$@"
}

main() {
  branchs=""
  local parameters="h:b:wb"

  if ( ! getopts "${parameters}" opt); then
    usage
  fi

  while getopts "${parameters}" opt; do
    case $opt in
      h)
        usage
        ;;	  
      b)
		branchs=$OPTARG
		;;      
      \?)
        err "Invalid option: -$OPTARG "
        usage
        ;;
      :)
        err "Option -$OPTARG requires an argument."
        usage
        ;;
    esac
  done

  #printf "Branch que sera utilizada para comparar>%s\n" $branchs
  
  printf "=============================================================================================\n\n"
  printf "                                  INICIO DO PROCESSAMENTO\n\n"

  verifica_modulos $branchs
  
  printf "=============================================================================================\n\n"
  printf "                                     FIM DO PROCESSAMENTO\n\n"
  printf "=============================================================================================\n"

}

verificarDiferenca() {
	# Verifica a diferenca entre branchs, desconsidera os arquivos: pom.xml,.gitattributes
    alteracaoModulo=`git diff --name-only $(git merge-base origin/master origin/$1)..origin/$1 2>/dev/null | grep gpvf- | egrep -v "pom.xml|.gitattributes" | wc -l`
    	
	if [ "$alteracaoModulo" -gt 0 ] ; then
	    git diff --name-only $(git merge-base origin/master origin/$1)..origin/$1 2>/dev/null | grep gpvf- | egrep -v "pom.xml|.gitattributes"
	else 
		printf "Nenhuma diferenca encontrada"	
    fi
}

existeBranch() {
	branchsEncontradas=`git branch -a | egrep origin/$1 | wc -l`
	
	if [ "$branchsEncontradas" -gt 0 ]; then
		return 1
	else
		return 0
	fi
}

verifica_modulos() {
	arrayModulosAlterados=()

	#Necessario que essa lista esteja na mesma ordem da lista anterior, como o modulo ops esta dentro do ope, utiliza-se o mesmo valor.
	#Esssa e a lista que contem o diretorio raiz do modulo
	modulosDir=("vale-gpvf" "vale-gpvf-adm" "vale-gpvf-mgmt" "vale-gpvf-ope" "vale-gpvf-ind")

	#Indice que controla a lista de modulos x modulosDir
	dirIndice=0

	# Transforma a lista de jira em um array
	IFS=, read -ra branchsArray <<<"$branchs"
	
	for branch in ${branchsArray[@]}; do
		printf "=============================================================================================\n"
		printf "                                       %s\n" $branch	
	
		for modulo in ${modulosDir[@]}; do
			cd $modulo		
						
			git fetch origin
						
			existeBranch $branch			
			encontrou=$?			
			textoModulo=${modulo:10}
			
			if [ -z "${textoModulo// }" ]; then
				textoModulo="COMMONS"
			else
				textoModulo=${textoModulo^^}				
			fi			
			
			if [ $encontrou -eq 1 ]; then				
				printf "=============================================================================================\n"
				printf "                                          %s\n" $textoModulo
				printf "=============================================================================================\n"
				
				verificarDiferenca $branch $modulo
			fi			
		cd ..			
		done
		printf "\n"
	done
}

usage() {
read -d '' help <<- EOF
USAGE:
    `basename $0` OPTIONS
OPTIONS:

#
-b branches separadas por ",". NAO usar espaco entre a virgula [REQUIRED]
-h ajuda
EOF
	err "$help"
	exit $E_OPTERROR # Exit and explain usage.
}

main $@
